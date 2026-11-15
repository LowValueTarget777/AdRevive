import Phaser from 'phaser';
import './style.css';
import { loadArt } from './art';
import { Battle, type Cue, type Snapshot, type Outcome } from './battle';
import { WIDTH, HEIGHT } from './rules';

function el<T extends HTMLElement=HTMLElement>(id:string){return document.getElementById(id) as T;}
const time=(s:number)=>'00:'+String(s).padStart(2,'0');
let arena:Battle;
type Host={postMessage:(message:string)=>void;addEventListener:(event:'message',handler:(event:MessageEvent)=>void)=>void};
const host=location.origin==='https://adgame.pbz.invalid'
  ? (window as Window & {chrome?:{webview?:Host}}).chrome?.webview : undefined;
const finish=host ? (result:Outcome)=>host.postMessage(result) : undefined;
function closeAd(){arena?.pauseRun();host?.postMessage('closed');}
host?.addEventListener('message',event=>{
  if(event.data==='close')closeAd();
});
let audio:AudioContext|undefined, muted=false, lastMode='';
try {muted=localStorage.getItem('pozhen-muted')==='yes';}catch{}
function unlock(){
  if(muted)return;
  try{audio??=new AudioContext();if(audio.state==='suspended')void audio.resume().catch(()=>{});}catch{}
}
function note(hz:number,to:number,length:number,gain:number,offset=0,type:OscillatorType='sine'){
  if(!audio || audio.state!=='running' || muted)return;
  const start=audio.currentTime+offset,osc=audio.createOscillator(),amp=audio.createGain();
  osc.type=type;osc.frequency.setValueAtTime(hz,start);osc.frequency.exponentialRampToValueAtTime(to,start+length);
  amp.gain.setValueAtTime(.0001,start);amp.gain.exponentialRampToValueAtTime(gain,start+.008);amp.gain.exponentialRampToValueAtTime(.0001,start+length);
  osc.connect(amp);amp.connect(audio.destination);osc.start(start);osc.stop(start+length+.01);
  osc.onended=()=>{osc.disconnect();amp.disconnect();};
}
function playCue(cue:Cue){
  switch(cue){
    case 'throw':note(650,320,.055,.012,0,'triangle');break;
    case 'hit':note(170,77,.105,.043,0,'triangle');break;
    case 'hurt':note(120,48,.22,.075,0,'sawtooth');break;
    case 'upgrade':note(392,392,.17,.07);note(587,587,.25,.065,.09);break;
    case 'win':[392,494,587,784].forEach((h,i)=>note(h,h,.28,.06,i*.09));break;
    case 'lose':note(196,155,.36,.06);note(130,98,.45,.05,.23);break;
  }
}
function render(s:Snapshot) {
  el('stage').dataset.mode=s.mode;
  const success=s.mode==='success';
  el('time').textContent=time(success||s.mode==='complete'?0:s.left);
  el('time').parentElement!.classList.toggle('urgent',s.left<=5);
  el('health').textContent=String(s.hp);el('allies').textContent=String(s.allies);
  el('gear').textContent=String(s.weapons);el('kills').textContent=String(s.kills);
  const overlay=el('overlay');
  if(host)el('close-ad').hidden=success||s.mode==='complete';
  overlay.hidden=s.mode==='ready'||s.mode==='playing';
  el('pause').hidden=s.mode!=='playing';
  const vip=el<HTMLButtonElement>('boss-vip'),hint=el('vip-hint');
  vip.hidden=s.mode!=='playing';
  hint.hidden=s.mode!=='playing'||s.vipKey===null;
  if(!hint.hidden){
    el('vip-key').textContent=s.vipKey;
    vip.setAttribute('aria-describedby','vip-hint');
  }else vip.removeAttribute('aria-describedby');
  vip.style.setProperty('--hold',s.vipPercent+'%');
  vip.classList.toggle('hold-complete',s.vipPercent===100);
  if(!overlay.hidden){
    el('result-title').textContent=success||s.mode==='complete'?(s.outcome==='vip'?'充值成功!':'复活成功!'):s.mode==='paused'?'暂歇':'存档异常';
    el('result-info').textContent=s.mode==='complete'?'已保存战场 · 本局击破 '+s.kills:s.mode==='paused'?'战场与倒计时已保存。':s.error;
    el('result-info').hidden=success;
    overlay.dataset.outcome=s.outcome??'';
    el('result-action').hidden=s.mode==='error'||success;el('result-action').textContent=s.mode==='complete'?'模拟下次广告':'继续试炼';
    if(host && s.mode==='complete'){
      el('result-info').textContent='战场已保存，正在返回游戏。';
      el('result-action').hidden=true;
    }
    if(lastMode!==s.mode && !el('result-action').hidden)el('result-action').focus({preventScroll:true});
  }else if(s.mode==='playing'&&lastMode!==s.mode)el('stage').focus({preventScroll:true});
  lastMode=s.mode;
}
el('pause').onclick=()=>arena?.pauseRun();
el('result-action').onclick=()=>arena?.action();
if(host){el('close-ad').hidden=false;el('close-ad').onclick=closeAd;}
el('boss-vip').onclick=()=>arena?.skipVip();
document.addEventListener('pointerdown',unlock,{once:true});document.addEventListener('keydown',unlock,{once:true});
async function boot(){
  const art=await loadArt();
  arena=new Battle(art,{update:render,sound:playCue,notice:text=>{el('notice').textContent=text;},
    activateVip:()=>el<HTMLButtonElement>('boss-vip').click(),finish});
  new Phaser.Game({
    type:Phaser.CANVAS,parent:'game',width:WIDTH,height:HEIGHT,scene:arena,
    backgroundColor:'#d5cbb2',banner:false,audio:{noAudio:true},
    render:{antialias:true,roundPixels:false},input:{keyboard:false,mouse:false,touch:false}
  });
}
boot().catch(err=>{el('notice').textContent='战场未能载入，请重新打开。';console.error(err);});
