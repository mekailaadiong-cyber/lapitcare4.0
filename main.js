// Renders the right screen and starts the app
function draw(){const a=document.getElementById('app'),r=S.role;document.body.style.setProperty('--a',r&&S.v!='home'?COL[r]:'#f97316');
a.innerHTML=S.v=='home'?home():S.v=='login'?auth(0):S.v=='reg'?auth(1):app();
if(S.v=='app'&&S.tab=='map')initMap();window.scrollTo(0,0)}
draw();
