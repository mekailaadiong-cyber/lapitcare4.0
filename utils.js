// Shared helpers and constants used by every page
const e=s=>String(s??'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const COL={patient:'#f97316',staff:'#3b82f6',admin:'#0d9488'},NM={patient:'Patient',staff:'Clinic Staff',admin:'Administrator'};
const BG={patient:'#fff4ea',staff:'#eaf3ff',admin:'#e8faf6'};
const stars=n=>'★'.repeat(n)+'☆'.repeat(5-n);
const chips=a=>a.map(x=>`<span class=ch>${e(x)}</span>`).join('');
const pn=a=>a.me?P.patient.name:a.pt;
const fs=(c,d)=>c.dr!='Available'?[]:c.sl.filter(t=>!c.bl.includes(t)&&!taken(c.id,t,d));
const fd=d=>new Date(d+'T00:00').toLocaleDateString('en-US',{month:'short',day:'numeric',year:'numeric'});
const cs=x=>x=='Approved'?'Confirmed':x;
const sc={Confirmed:['#dcfce7','#16a34a'],Verified:['#dcfce7','#16a34a'],Pending:['#fef3c7','#b45309'],Completed:['#f1f5f9','#64748b'],Cancelled:['#f1f5f9','#64748b'],'No-show':['#f1f5f9','#64748b'],Rejected:['#fee2e2','#dc2626'],Suspended:['#fee2e2','#dc2626']};
const pill=x=>`<span class=pl style="background:${sc[cs(x)][0]};color:${sc[cs(x)][1]}">${cs(x)}</span>`;
const stat=(n,l,sub,c)=>`<div class=card><h1 style="margin:0;color:${c}">${n}</h1><b>${l}</b><div class=mu>${sub}</div></div>`;
const live=a=>!['Cancelled','Rejected'].includes(a.s);
const bar=(l,v,mx,c='#0d9488',x='')=>`<div style="margin-bottom:12px"><div class=row style="border:0;padding:0 0 4px;font-size:.9rem"><span>${e(l)}</span><span class=mu>${v}${x}</span></div><div class=bt><i style="width:${mx?v/mx*100:0}%;background:${c}"></i></div></div>`;
