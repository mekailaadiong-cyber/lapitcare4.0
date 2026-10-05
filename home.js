// Landing page (three role cards)
function home(){return `<div class=w style="text-align:center"><span class=pill>● Real-Time Clinic Availability</span>
<h1>Find clinics. Book appointments.<br><span style="color:var(--g)">All in one place.</span></h1>
<p class=mu style="max-width:560px;margin:0 auto 28px">LapitCARE connects residents of Pagadian City with private outpatient clinics — check availability, locate on a map, and book instantly.</p>
<div class=grid style="text-align:left">${[['patient','PATIENT PORTAL',"I'm a Patient",'Search clinics, check availability, and book appointments online.',1],['staff','CLINIC STAFF PORTAL',"I'm Clinic Staff",'Manage schedules, appointment slots, and patient bookings.',1],['admin','SYSTEM ADMINISTRATOR',"I'm an Admin",'Manage clinic accounts, monitor citywide availability, and generate reports.',0]].map(([r,k,t,d,reg])=>`<div class="card rc" style="--c:${COL[r]};--a:${COL[r]};background:linear-gradient(${BG[r]}33,var(--card))"><small>${k}</small><h2 style="margin-top:8px">${t}</h2><p class=mu>${d}</p>
<div style="display:flex;gap:8px"><button class=btn style="flex:1" onclick="go({v:'login',role:'${r}'})">${r=='admin'?'Administrator Log In':'Log In'}</button>${reg?`<button class="btn o" style="flex:1" onclick="go({v:'reg',role:'${r}'})">Register</button>`:''}</div></div>`).join('')}</div>
</div>`}
