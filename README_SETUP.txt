SURAJTRADERX FINAL PREMIUM BUILD

STRUCTURE
- All HTML/CSS/JS/config files stay at the root.
- Only assets/ contains the supplied logo, payment QR and course PDFs.
- No unnecessary backend/server folders.

CURRENT FEATURES
- Premium light UI with navy/blue/cyan/purple accents
- Supplied SURAJTRADERX logo used across the site and as favicon
- Responsive 3-line mobile menu
- Basic ₹1,499: Weekly live doubt solving
- Premium ₹2,499: Daily live doubt solving + mentorship
- Renewal ₹699/month
- Supplied UPI QR + UPI deep link
- UTR submission flow
- Admin payment approval/rejection flow
- Course access after admin approval
- Admin course/module/lesson management
- Student dashboard
- Single login page: authorised admin accounts automatically open admin.html; students open student.html
- Forgot/reset password flow
- Admin password change
- Student profile fields

SUPABASE SETUP (WHEN READY)
1. Create a Supabase project.
2. Run supabase-schema.sql in Supabase SQL Editor.
3. Create a student/admin Auth account using register.html.
4. Copy the Auth user UUID and run:
   insert into public.admin_users(user_id) values('YOUR-UUID');
5. Put the Supabase project URL and anon/publishable key in config.js.
6. Upload the complete folder to GitHub Pages.
7. Students use login.html. There is no separate admin login option.

PAYMENT
UPI: 9421460322@ybl
UPI Name: SURAJ BHAGWAN JAWALE
Support: 9421460322
Telegram: https://t.me/surajtraderx

IMPORTANT
- A UTR must be checked against the actual incoming UPI/bank transaction before approval.
- Do not unlock access just because a UTR has the right format.
- Never put a Supabase service-role/secret key in config.js.
- GitHub Pages hosts the frontend; Supabase provides authentication/database when configured.


COURSE ACCESS / RESOURCES
- PDF 1: assets/course-material-1.pdf — available to ₹1,499 and ₹2,499 students.
- PDF 2: assets/premium-material-2.pdf — available only to ₹2,499 Premium students.
- ₹1,499 and ₹2,499: https://t.me/+8Vj_UMez_XA5NWQ1
- ₹2,499 and ₹699 renewal: https://t.me/+Yw3zM7d5CpYzZTM1
- The unlocked course page shows resources according to the approved enrollment plan.
- Renewal keeps an existing Premium enrollment as Premium; it does not downgrade access.
- Telegram is used for live videos, live doubt solving and ongoing updates as provided by the course owner.
- PDFs are in public GitHub Pages assets for V1 convenience. For stronger premium content protection, move them to private authenticated storage later.
