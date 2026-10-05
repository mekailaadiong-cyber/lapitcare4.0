// Dashboard shell: top bar, tabs, emergency banner, tab router
function app(){const r=S.role,T={patient:[['clinics','Clinics'],['book','Book Appointment'],['map','Map'],['appts','My Appointments'],['fb','Feedback'],['notif','Notifications'],['prof','My Profile']],staff:[['ov','📊 Overview'],['appts','📋 Appointments'],['sl','🔢 Slots'],['fb','⭐ Feedback'],['notif','🔔 Notifications'],['cp','🏥 Clinic Profile']],admin:[['ov','Overview'],['clinics','Clinics'],['users','Users'],['rep','Reports'],['notif','Notifications'],['prof','My Profile']]}[r];
const al=r!='patient'?'':C.filter(c=>c.v&&c.st=='Emergency'&&c.al).map(c=>`<div style="background:#dc2626;color:#fff;border-radius:16px;padding:16px 22px;margin-top:16px">🚨 <b>Emergency Status Alert</b><br><b>${e(c.n)}:</b> ${e(c.al)}</div>`).join('');
return `<div class=bar><div class=w><b style="font-size:1.2rem">LapitCARE · ${NM[r]}</b><span>${e(P[r].name)}</span></div></div>
<div class=w>${al}<div class=tabs>${T.map(([k,l])=>`<button class="${S.tab==k?'on':''}" onclick="go({tab:'${k}'})">${l}${k=='notif'&&unread(r)?`<span class=bd>${unread(r)}</span>`:''}</button>`).join('')}</div>${tabHtml()}</div>`}

function tabHtml(){const r=S.role,t=S.tab;
if(t=='notif')return r=='patient'?patNotif():plainN(r);
if(t=='prof')return profileTab();
if(t=='map')return mapTab();
if(r=='patient')return patientTab(t);
return r=='staff'?stTab(t):adTab(t)}
