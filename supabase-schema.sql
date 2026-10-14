-- SURAJTRADERX • Supabase production-ready starter schema
-- Run once in Supabase SQL Editor.
-- IMPORTANT: never put a Supabase service-role/secret key in the website.

create extension if not exists pgcrypto;

create table if not exists public.profiles(
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  age integer,
  phone text,
  telegram_username text,
  created_at timestamptz default now()
);

alter table public.profiles add column if not exists email text;

create table if not exists public.admin_users(
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);

create table if not exists public.courses(
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text unique,
  description text,
  published boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.modules(
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  title text not null,
  position integer default 1,
  created_at timestamptz default now()
);

create table if not exists public.lessons(
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.modules(id) on delete cascade,
  title text not null,
  content text,
  video_url text,
  position integer default 1,
  created_at timestamptz default now()
);

create table if not exists public.payment_requests(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  email text not null,
  plan text not null check(plan in ('basic','premium','renewal')),
  amount numeric(10,2) not null,
  utr text not null,
  paid_at date not null,
  status text not null default 'pending' check(status in ('pending','approved','rejected')),
  approved_by uuid references auth.users(id),
  approved_at timestamptz,
  created_at timestamptz default now(),
  unique(utr)
);

create table if not exists public.enrollments(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  plan text not null check(plan in ('basic','premium','renewal')),
  amount_paid numeric(10,2) not null,
  status text not null default 'active' check(status in ('active','revoked')),
  payment_request_id uuid references public.payment_requests(id),
  created_at timestamptz default now(),
  unique(user_id,course_id)
);

alter table public.profiles enable row level security;
alter table public.admin_users enable row level security;
alter table public.courses enable row level security;
alter table public.modules enable row level security;
alter table public.lessons enable row level security;
alter table public.payment_requests enable row level security;
alter table public.enrollments enable row level security;

-- Helper used by RLS. It checks the current authenticated user only.
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.admin_users where user_id=auth.uid());
$$;

-- Automatically create/update the profile from Auth metadata.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.profiles(id,full_name,email,age,phone,telegram_username)
  values(
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name',''),
    new.email,
    nullif(new.raw_user_meta_data->>'age','')::integer,
    coalesce(new.raw_user_meta_data->>'phone',''),
    coalesce(new.raw_user_meta_data->>'telegram_username','')
  )
  on conflict(id) do update set
    full_name=excluded.full_name,
    email=excluded.email,
    age=excluded.age,
    phone=excluded.phone,
    telegram_username=excluded.telegram_username;
  return new;
exception when others then
  -- A profile problem must not prevent Auth account creation.
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

-- Clean/re-runnable policies.
drop policy if exists "profile own read" on public.profiles;
drop policy if exists "profile own update" on public.profiles;
drop policy if exists "admin profiles read" on public.profiles;
drop policy if exists "admin self read" on public.admin_users;
drop policy if exists "published courses readable" on public.courses;
drop policy if exists "admin create courses" on public.courses;
drop policy if exists "admin update courses" on public.courses;
drop policy if exists "admin delete courses" on public.courses;
drop policy if exists "modules readable" on public.modules;
drop policy if exists "admin manage modules" on public.modules;
drop policy if exists "lessons readable" on public.lessons;
drop policy if exists "admin manage lessons" on public.lessons;
drop policy if exists "student create payment" on public.payment_requests;
drop policy if exists "student own payments" on public.payment_requests;
drop policy if exists "admin update payments" on public.payment_requests;
drop policy if exists "student own enrollments" on public.enrollments;
drop policy if exists "admin create enrollments" on public.enrollments;
drop policy if exists "admin update enrollments" on public.enrollments;

create policy "profile own read" on public.profiles for select using(auth.uid()=id);
create policy "profile own update" on public.profiles for update using(auth.uid()=id) with check(auth.uid()=id);
create policy "admin profiles read" on public.profiles for select using(public.is_admin());

-- Allows the single login page to check whether the current account is an admin.
create policy "admin self read" on public.admin_users for select using(auth.uid()=user_id);

create policy "published courses readable" on public.courses for select using(published=true or public.is_admin());
create policy "admin create courses" on public.courses for insert with check(public.is_admin());
create policy "admin update courses" on public.courses for update using(public.is_admin()) with check(public.is_admin());
create policy "admin delete courses" on public.courses for delete using(public.is_admin());

create policy "modules readable" on public.modules for select using(
  public.is_admin() or exists(select 1 from public.enrollments e where e.user_id=auth.uid() and e.course_id=modules.course_id and e.status='active')
);
create policy "admin manage modules" on public.modules for all using(public.is_admin()) with check(public.is_admin());

create policy "lessons readable" on public.lessons for select using(
  public.is_admin() or exists(
    select 1 from public.modules m join public.enrollments e on e.course_id=m.course_id
    where m.id=lessons.module_id and e.user_id=auth.uid() and e.status='active'
  )
);
create policy "admin manage lessons" on public.lessons for all using(public.is_admin()) with check(public.is_admin());

create policy "student create payment" on public.payment_requests for insert with check(auth.uid()=user_id);
create policy "student own payments" on public.payment_requests for select using(auth.uid()=user_id or public.is_admin());
create policy "admin update payments" on public.payment_requests for update using(public.is_admin()) with check(public.is_admin());

create policy "student own enrollments" on public.enrollments for select using(auth.uid()=user_id or public.is_admin());
create policy "admin create enrollments" on public.enrollments for insert with check(public.is_admin());
create policy "admin update enrollments" on public.enrollments for update using(public.is_admin()) with check(public.is_admin());


-- Seed the main SURAJTRADERX course and its 8 core modules from PDF 1.
-- Safe to run repeatedly: existing rows with the same course/module titles are reused.
do $$
declare
  c_id uuid;
  m_id uuid;
begin
  insert into public.courses(title,slug,description,published)
  values('NIFTY 15-Minute Breakout Strategy','nifty-15-minute-breakout','Structured educational course covering trading fundamentals, market structure, liquidity, the 15-minute breakout setup, entry and exit, risk management, backtesting and trading psychology.',true)
  on conflict(slug) do update set title=excluded.title, description=excluded.description, published=true
  returning id into c_id;

  if c_id is null then
    select id into c_id from public.courses where slug='nifty-15-minute-breakout' limit 1;
  end if;

  insert into public.modules(course_id,title,position)
  select c_id,'Trading Fundamentals',1 where not exists(select 1 from public.modules where course_id=c_id and title='Trading Fundamentals');
  insert into public.modules(course_id,title,position)
  select c_id,'Market Structure',2 where not exists(select 1 from public.modules where course_id=c_id and title='Market Structure');
  insert into public.modules(course_id,title,position)
  select c_id,'Liquidity',3 where not exists(select 1 from public.modules where course_id=c_id and title='Liquidity');
  insert into public.modules(course_id,title,position)
  select c_id,'Your Trading Setup',4 where not exists(select 1 from public.modules where course_id=c_id and title='Your Trading Setup');
  insert into public.modules(course_id,title,position)
  select c_id,'Entry & Exit',5 where not exists(select 1 from public.modules where course_id=c_id and title='Entry & Exit');
  insert into public.modules(course_id,title,position)
  select c_id,'Risk Management',6 where not exists(select 1 from public.modules where course_id=c_id and title='Risk Management');
  insert into public.modules(course_id,title,position)
  select c_id,'Backtesting',7 where not exists(select 1 from public.modules where course_id=c_id and title='Backtesting');
  insert into public.modules(course_id,title,position)
  select c_id,'Trading Psychology',8 where not exists(select 1 from public.modules where course_id=c_id and title='Trading Psychology');

  -- One concise lesson per module keeps the unlocked dashboard useful immediately.
  insert into public.lessons(module_id,title,content,position)
  select id,'Candlesticks, indices & options basics','Understand candle body and wick, bullish/bearish closes, NIFTY as an index, and basic option concepts and risks.',1 from public.modules where course_id=c_id and title='Trading Fundamentals' and not exists(select 1 from public.lessons where module_id=public.modules.id);
  insert into public.lessons(module_id,title,content,position)
  select id,'Trend, range, support & resistance','Identify uptrends, downtrends and ranges using higher highs/lows or lower highs/lows; treat support and resistance as zones.',1 from public.modules where course_id=c_id and title='Market Structure' and not exists(select 1 from public.lessons where module_id=public.modules.id);
  insert into public.lessons(module_id,title,content,position)
  select id,'Previous highs/lows & liquidity areas','Learn why previous highs/lows and equal highs/lows may attract orders; a wick or sweep is not a guaranteed reversal signal.',1 from public.modules where course_id=c_id and title='Liquidity' and not exists(select 1 from public.lessons where module_id=public.modules.id);
  insert into public.lessons(module_id,title,content,position)
  select id,'Previous-day levels + opening 15-minute candle','Mark the previous trading day high and low, select the session and opening 15-minute candle, and define exact rules before testing.',1 from public.modules where course_id=c_id and title='Your Trading Setup' and not exists(select 1 from public.lessons where module_id=public.modules.id);
  insert into public.lessons(module_id,title,content,position)
  select id,'Breakout confirmation, entry & stop-loss','Wait for the required candle close beyond the chosen level, define the entry trigger and invalidation point, and avoid chasing missed moves.',1 from public.modules where course_id=c_id and title='Entry & Exit' and not exists(select 1 from public.lessons where module_id=public.modules.id);
  insert into public.lessons(module_id,title,content,position)
  select id,'Risk-to-reward & position sizing','Plan risk before entry, understand 1:2 R:R, calculate quantity from maximum planned loss and stop distance, and account for costs and slippage.',1 from public.modules where course_id=c_id and title='Risk Management' and not exists(select 1 from public.lessons where module_id=public.modules.id);
  insert into public.lessons(module_id,title,content,position)
  select id,'Historical testing & performance review','Apply fixed written rules to historical charts, record wins and losses, and review win rate, average win/loss, expectancy and rule-following.',1 from public.modules where course_id=c_id and title='Backtesting' and not exists(select 1 from public.lessons where module_id=public.modules.id);
  insert into public.lessons(module_id,title,content,position)
  select id,'Discipline, overtrading & journaling','Use checklists, daily loss and trade-count limits, avoid FOMO/revenge trading, and journal both results and rule-following.',1 from public.modules where course_id=c_id and title='Trading Psychology' and not exists(select 1 from public.lessons where module_id=public.modules.id);
end $$;

-- After creating the account you want to use as admin, run this once:
-- insert into public.admin_users(user_id) values('YOUR-AUTH-USER-UUID');
