
function esc(v){return String(v??"").replace(/[&<>"']/g,m=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#039;"}[m]))}
function upiUri(amount){return `upi://pay?pa=${encodeURIComponent(SRTX_CONFIG.UPI_ID)}&pn=${encodeURIComponent(SRTX_CONFIG.UPI_NAME)}&am=${encodeURIComponent(amount)}&cu=INR`}
function copyText(t){navigator.clipboard?.writeText(t).then(()=>alert("UPI ID copied"))}
function siteNav(active){
  document.querySelectorAll("[data-nav]").forEach(a=>a.classList.toggle("active",a.dataset.nav===active));
  const nav=document.querySelector(".nav"),btn=document.querySelector(".hamb");
  if(btn)btn.addEventListener("click",()=>nav.classList.toggle("open"));
}
function footer(){
  const e=document.querySelector("[data-footer]");
  if(e)e.innerHTML=`<footer class="footer"><div class="container footer-in"><span>© 2026 SurajTraderX — Educational Purpose Only. Trading involves risk.</span><span>Support: ${esc(SRTX_CONFIG.SUPPORT_PHONE)}</span></div></footer>`;
}
document.addEventListener("DOMContentLoaded",()=>{siteNav(document.body.dataset.page||"");footer()});
