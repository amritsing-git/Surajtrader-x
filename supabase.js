
let sb=null;
async function initSB(){
  if(sb)return sb;
  if(!window.supabase||!window.SRTX_CONFIG||SRTX_CONFIG.SUPABASE_URL.includes("PASTE_"))return null;
  sb=window.supabase.createClient(SRTX_CONFIG.SUPABASE_URL,SRTX_CONFIG.SUPABASE_ANON_KEY);return sb;
}
async function requireUser(){
  const s=await initSB();if(!s)return null;
  const {data}=await s.auth.getSession();if(!data.session){location.href="login.html";return null}return data.session.user;
}
async function signOut(){const s=await initSB();if(s)await s.auth.signOut();location.href="index.html"}
