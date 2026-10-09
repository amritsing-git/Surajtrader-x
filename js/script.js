const CONFIG={
  // IMPORTANT: replace this with the client's VERIFIED UPI ID before publishing.
  upiId:"YOUR-UPI@BANK",
  merchantName:"SurajTraderX"
};

const page=document.body.dataset.page;
document.querySelectorAll(".side-nav a").forEach(a=>{
  if(a.dataset.page===page)a.classList.add("active");
});
const sidebar=document.getElementById("sidebar");
document.getElementById("openSide")?.addEventListener("click",()=>sidebar.classList.add("open"));
document.getElementById("closeSide")?.addEventListener("click",()=>sidebar.classList.remove("open"));

const toast=document.getElementById("toast");
function showToast(t){if(!toast)return;toast.textContent=t;toast.classList.add("show");setTimeout(()=>toast.classList.remove("show"),3000)}

const obs=new IntersectionObserver(es=>es.forEach(e=>{if(e.isIntersecting)e.target.classList.add("visible")}),{threshold:.08});
document.querySelectorAll(".reveal").forEach(x=>obs.observe(x));

function savePlan(plan,amount){
  localStorage.setItem("surajSelectedPlan",JSON.stringify({plan,amount}));
}
function getPlan(){
  try{return JSON.parse(localStorage.getItem("surajSelectedPlan"))||{plan:"Basic",amount:1499}}catch{return {plan:"Basic",amount:1499}}
}

document.querySelectorAll(".plan-btn").forEach(btn=>{
  btn.addEventListener("click",()=>{
    savePlan(btn.dataset.plan,Number(btn.dataset.amount));
    showToast(`${btn.dataset.plan} selected — opening application`);
    setTimeout(()=>location.href="apply.html",500);
  });
});

const applyForm=document.getElementById("applyForm");
if(applyForm){
  const saved=JSON.parse(localStorage.getItem("surajApplication")||"null");
  if(saved){
    for(const key of ["name","age","phone","telegram","email"]){
      if(saved[key]&&applyForm.elements[key])applyForm.elements[key].value=saved[key];
    }
    if(saved.plan){
      const radio=applyForm.querySelector(`input[name="plan"][value="${saved.plan}"]`);
      if(radio)radio.checked=true;
    }
  }
  applyForm.addEventListener("submit",e=>{
    e.preventDefault();
    if(!applyForm.checkValidity()){applyForm.reportValidity();return}
    const fd=new FormData(applyForm);
    const selected=applyForm.querySelector('input[name="plan"]:checked');
    const data={
      name:fd.get("name"),age:fd.get("age"),phone:fd.get("phone"),telegram:fd.get("telegram"),
      email:fd.get("email"),experience:fd.get("experience"),plan:selected?.value||"Basic",
      amount:Number(selected?.dataset.amount||1499)
    };
    savePlan(data.plan,data.amount);
    localStorage.setItem("surajApplication",JSON.stringify(data));
    document.getElementById("applyMessage").textContent="Application saved. Redirecting to secure payment…";
    showToast("Details saved");
    setTimeout(()=>location.href="payment.html",700);
  });
}

function renderPayment(){
  const selected=getPlan();
  const plan=selected.plan, amount=Number(selected.amount);
  const label=document.getElementById("payPlanLabel"), p=document.getElementById("payPlan"), a=document.getElementById("payAmount");
  if(!label)return;
  label.textContent=(plan==="Premium"?"COURSE + PREMIUM TELEGRAM":plan==="Renewal"?"TELEGRAM RENEWAL":"BASIC COURSE");
  p.textContent=plan;a.textContent="₹"+amount;
  document.getElementById("payAmountSmall").textContent="₹"+amount;
  document.getElementById("payTotal").textContent="₹"+amount;
  document.getElementById("payType").textContent=plan==="Renewal"?"Monthly":"One-time";
  document.getElementById("upiDisplay").textContent=CONFIG.upiId;
  const link=`upi://pay?pa=${encodeURIComponent(CONFIG.upiId)}&pn=${encodeURIComponent(CONFIG.merchantName)}&am=${amount.toFixed(2)}&cu=INR&tn=${encodeURIComponent(plan+" course enrollment")}`;
  const upi=document.getElementById("upiPay");upi.href=link;upi.textContent=`Pay ₹${amount} via UPI ↗`;
  const qr=document.getElementById("qr");qr.innerHTML="";
  if(window.QRCode && CONFIG.upiId!=="YOUR-UPI@BANK"){
    new QRCode(qr,{text:link,width:134,height:134,colorDark:"#111111",colorLight:"#ffffff",correctLevel:QRCode.CorrectLevel.M});
  }else{
    qr.innerHTML='<div style="font:8px JetBrains Mono;color:#555;text-align:center;line-height:1.5">QR READY<br>AFTER UPI ID<br>IS CONFIGURED</div>';
  }
  document.querySelectorAll(".plan-switch button").forEach(b=>{
    b.classList.toggle("active",b.dataset.plan===plan);
    b.onclick=()=>{savePlan(b.dataset.plan,Number(b.dataset.amount));renderPayment();showToast("Plan updated")};
  });
}
if(page==="payment"){
  renderPayment();
  document.getElementById("copyUpi")?.addEventListener("click",async()=>{
    try{await navigator.clipboard.writeText(CONFIG.upiId);showToast("UPI ID copied")}catch{showToast(CONFIG.upiId)}
  });
}

const finalForm=document.getElementById("contactForm");
if(finalForm){
  finalForm.addEventListener("submit",e=>{
    e.preventDefault();
    if(!finalForm.checkValidity()){finalForm.reportValidity();return}
    const fd=new FormData(finalForm);
    const name=fd.get("contactName")||"";
    const email=fd.get("contactEmail")||"";
    const phone=fd.get("contactPhone")||"Not provided";
    const subject=fd.get("contactSubject")||"SurajTraderX Website Enquiry";
    const message=fd.get("contactMessageText")||"";
    const body=`Hello SurajTraderX Team,%0A%0AName: ${encodeURIComponent(name)}%0AEmail: ${encodeURIComponent(email)}%0APhone/WhatsApp: ${encodeURIComponent(phone)}%0A%0AMessage:%0A${encodeURIComponent(message)}%0A%0AThank you.`;
    const mailto=`mailto:surajjawale942@gmail.com?subject=${encodeURIComponent(subject)}&body=${body}`;
    document.getElementById("contactMessage").textContent="Opening your email app…";
    showToast("Opening email");
    window.location.href=mailto;
  });
}
