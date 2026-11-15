import Phaser from 'phaser';
import { textures, type loadArt } from './art';
import { WIDTH, HEIGHT, FLOOR, CARD_X, CARD_Y, HERO, AD_SECONDS, ENEMIES, ALLIES, WEAPONS, rewardInfo, missileType, type Missile } from './rules';
import { formatNotice, type WorldNotice } from './worldNotice';
import { advance, formation, newWorld, type Cue } from './world';
import { loadProgress, saveProgress, SAVE_KEY, type Progress } from './save';
import { BattleGamepad, type VipKey } from './gamepad';

export type { Cue };
export type Mode='ready'|'playing'|'paused'|'success'|'complete'|'error';
export type Snapshot={mode:Mode; outcome?:Outcome; hp:number; left:number; kills:number; allies:number; weapons:number; error:string; vipKey:VipKey|null; vipPercent:number};
export type Outcome='completed'|'vip';
type UI={update:(s:Snapshot)=>void;notice:(s:string)=>void;sound:(cue:Cue)=>void;activateVip:()=>void;finish?:(outcome:Outcome)=>void};
const serif='"STKaiti","KaiTi","Microsoft YaHei",serif';
const battleWords={
  gain:'获得 {name}',bossGain:'首领奖励 · {name}',fallen:'{name} 已阵亡',allyHit:'{name} 承伤 −{n}',
  heroHit:'魂 · 气血 −{n}',drop:'掉落{name}',bossArrival:'首领来袭 · 击破得随机奖励',
  names:[...ALLIES.map(a=>a.short),...WEAPONS.map(w=>w.name)],
};

export class Battle extends Phaser.Scene {
  private mode:Mode='ready';
  private progress:Progress={version:2,world:newWorld(),seconds:0,completed:0,deaths:0};
  private error='';
  private aim:number|null=null;
  private keys=new Set<string>();
  private pointer:number|null=null;
  private gamepad=new BattleGamepad();
  private savedAt=0;
  private noticeUntil=0;
  private lastUI='';
  private previousTime=0;
  private outcome?:Outcome;
  private successElapsed=0;
  private releaseLock?:()=>void;
  private acquiring=false;
  private context!:CanvasRenderingContext2D;
  private layer!:Phaser.Textures.CanvasTexture;
  private images=new Map<string,HTMLImageElement>();

  constructor(private art:Awaited<ReturnType<typeof loadArt>>,private ui:UI){super('battle');}
  create(){
    textures(this,this.art);
    this.add.image(0,0,'ground').setOrigin(0).setDisplaySize(WIDTH,HEIGHT);
    this.layer=this.textures.createCanvas('combat-layer',WIDTH*2,HEIGHT*2)!;
    this.add.image(0,0,'combat-layer').setOrigin(0).setDisplaySize(WIDTH,HEIGHT);
    this.context=this.layer.getContext();this.context.scale(2,2);
    for(const [name,img] of this.art.sprites)this.images.set(name,img);
    this.installInput();this.restore();this.draw();this.sync();
    this.autoStart();
  }
  private autoStart(){
    if(this.mode==='ready'&&!document.hidden&&(!this.ui.finish||document.hasFocus()))this.action();
  }
  private restore(){
    try{
      const p=loadProgress();
      if(p){this.progress=p;}
    }catch(e){this.fail('存档读取失败，请在允许本地存储的浏览器中重试。');}
  }
  private fail(message:string){
    this.error=message;this.mode='error';this.releaseLock?.();this.sync();
  }
  private save(){
    try{saveProgress(this.progress);this.savedAt=this.progress.world.time;return true;}
    catch{this.fail('进度未能写入。请检查浏览器存储空间，保留此页后重试。');return false;}
  }
  private installInput(){
    const canvas=this.game.canvas;
    const usePointer=()=>this.gamepad.cancel();
    window.addEventListener('pointerdown',usePointer,true);
    window.addEventListener('pointermove',usePointer,true);
    const move=(e:PointerEvent)=>{
      const r=canvas.getBoundingClientRect();this.aim=(e.clientX-r.left)*WIDTH/r.width;
    };
    canvas.addEventListener('pointerdown',e=>{
      if(this.mode!=='playing'||e.button!==0||this.pointer!==null)return;
      if(e.pointerType!=='mouse'){
        this.pointer=e.pointerId;canvas.setPointerCapture(e.pointerId);
      }
      move(e);e.preventDefault();
    });
    canvas.addEventListener('pointermove',e=>{
      if(this.mode!=='playing')return;
      if(this.pointer===null ? e.pointerType==='mouse' : e.pointerId===this.pointer)move(e);
    });
    canvas.addEventListener('lostpointercapture',e=>{
      if(this.pointer===e.pointerId)this.pointer=null;
    });
    const controls=['a','d','arrowleft','arrowright'];
    window.addEventListener('keydown',e=>{
      if(this.mode!=='playing')return;
      this.gamepad.cancel();
      const k=e.key.toLowerCase();if(controls.includes(k)){this.keys.add(k);this.aim=null;e.preventDefault();}
      if(k==='escape'&&!e.repeat)this.pauseRun();
    });
    window.addEventListener('keyup',e=>{
      this.keys.delete(e.key.toLowerCase());
    });
    window.addEventListener('blur',()=>this.pauseRun());
    window.addEventListener('focus',()=>this.autoStart());
    document.addEventListener('visibilitychange',()=>{if(document.hidden)this.pauseRun();else this.autoStart();});
    window.addEventListener('pagehide',()=>{this.pauseRun();this.releaseLock?.();});
    window.addEventListener('storage',e=>{
      if(e.key===SAVE_KEY&&this.mode!=='playing'&&!this.releaseLock){this.restore();this.draw();this.sync();}
    });
  }
  private start(){
    if(this.mode==='error')return;
    this.keys.clear();this.pointer=null;this.aim=null;this.gamepad.cancel();this.previousTime=performance.now();
    this.mode='playing';this.ui.notice('');this.sync();
  }
  action(){
    if(this.mode==='success' || (this.ui.finish && this.mode==='complete'))return;
    if(this.mode==='playing'){this.pauseRun();return;}
    if(this.mode==='error'||this.acquiring)return;
    if(this.releaseLock || !navigator.locks){this.start();return;}
    this.acquiring=true;
    void navigator.locks.request(SAVE_KEY,{ifAvailable:true},async lock=>{
      this.acquiring=false;
      if(!lock){this.mode='paused';this.sync();this.ui.notice('另一窗口正在试炼，请先暂停该窗口。');return;}
      if(document.hidden || (this.ui.finish && !document.hasFocus()))return;
      this.restore();
      if(this.mode==='error')return;
      await new Promise<void>(resolve=>{
        this.releaseLock=()=>{this.releaseLock=undefined;resolve();};
        this.start();
      });
    }).catch(()=>{this.acquiring=false;this.fail('浏览器未能打开存档，请重新打开试玩页。');});
  }
  pauseRun(){
    if(this.mode!=='playing')return;
    this.mode='paused';this.keys.clear();this.pointer=null;this.save();this.releaseLock?.();this.sync();
  }
  skipVip(){
    if(this.mode==='playing' && document.hasFocus() && !document.hidden)this.finishSegment('vip');
  }
  private finishSegment(outcome:Outcome){
    this.progress.seconds=0;this.progress.completed++;
    this.ui.notice('');
    if(this.save()){
      this.ui.sound('win');
      this.mode='success';this.outcome=outcome;this.successElapsed=0;this.previousTime=performance.now();
    }
    this.releaseLock?.();this.sync();
  }
  private feedback=(cue:Cue,message?:string)=>{
    this.ui.sound(cue);
    if(message){this.ui.notice(message);this.noticeUntil=performance.now()+1650;}
  };
  private combatFeedback=(cue:Cue,event?:WorldNotice)=>this.feedback(cue,event && formatNotice(event,battleWords));
  private sync(){
    const w=this.progress.world;
    const s:Snapshot={mode:this.mode,outcome:this.outcome,hp:Math.ceil(w.hp),left:Math.ceil(AD_SECONDS-this.progress.seconds),
      kills:w.kills,allies:w.allies.length,weapons:w.weapons.reduce((a,b)=>a+b,0),error:this.error,
      vipKey:this.gamepad.key,vipPercent:Math.floor(100*this.gamepad.progress)};
    const json=JSON.stringify(s);if(json!==this.lastUI){this.lastUI=json;this.ui.update(s);}
  }
  private image(name:string,x:number,y:number,width:number,height=width){
    const img=this.images.get(name)!;
    const scale=Math.min(width/img.width,height/img.height);
    this.context.drawImage(img,x-img.width*scale/2,y-img.height*scale/2,img.width*scale,img.height*scale);
  }
  private text(value:string,x:number,y:number,size:number,color:string,family=serif){
    const c=this.context;c.font='bold '+size+'px '+family;c.fillStyle=color;c.textAlign='center';c.textBaseline='middle';c.fillText(value,x,y);
  }
  private bar(x:number,y:number,length:number,ratio:number,color:string){
    const c=this.context;c.fillStyle='#51453588';c.fillRect(x-length/2,y,length,3);
    c.fillStyle=color;c.fillRect(x-length/2,y,length*Math.min(1,Math.max(0,ratio)),3);
  }
  private unit(name:string,x:number,y:number,kind:'scout'|'elite'|'boss',hp:number){
    const size={scout:56,elite:80,boss:103}[kind];
    this.image(name,x,y,size);
    this.bar(x,y-size/2-4,size*.56,hp,kind==='scout'?'#9e5a40':'#9f3024');
    if(kind!=='scout')this.text(kind==='boss'?'首领':'◆',x,y-size/2-14,kind==='boss'?14:11,'#873a29');
  }
  private enemyShot(x:number,y:number,vx:number,vy:number,kind:Missile){
    const c=this.context;c.save();c.translate(x,y);c.rotate(Math.atan2(vy,vx));
    c.lineWidth=2.3;c.strokeStyle=kind==='music'?'#6c345b':'#8e3021';
    c.fillStyle=kind==='music'?'#ecd2e8':'#ffb765';c.beginPath();
    if(kind==='music'){
      c.arc(-3,0,8,-1.13,1.13);c.stroke();c.beginPath();c.arc(0,0,3,0,Math.PI*2);
    }else{
      c.moveTo(7,0);c.lineTo(-5,-3);c.lineTo(kind==='gun'?-12:-9,0);c.lineTo(-5,3);c.closePath();
    }
    c.fill();c.stroke();c.restore();
  }
  private draw(){
    const c=this.context,w=this.progress.world;c.clearRect(0,0,WIDTH,HEIGHT);
    w.cards.forEach((card,i)=>{
      const x=CARD_X[i],y=CARD_Y,a=rewardInfo(card.reward),ally=card.reward<ALLIES.length;
      c.fillStyle=ally?'#343e34':'#3c352c';c.strokeStyle=ally?'#899578':'#b49864';c.lineWidth=2;
      c.beginPath();c.roundRect(x-52,y-65,104,123,5);c.fill();c.stroke();
      const count=ally?0:w.weapons[card.reward-ALLIES.length];
      this.text(a.kind+(count?' · 持有 '+count:''),x,y-49,13,ally?'#c8dbb2':'#e4c68d');
      this.image(a.name,x,y-9,78,62);this.text(a.short,x,y+37,16,'#f1dfbb');
      this.text(String(Math.ceil(card.hp)),x,y+74,18,'#433829','Consolas,monospace');
      this.bar(x,y+88,66,card.hp/card.max,'#9c7138');
    });
    for(const shot of w.shots){
      const radius=Math.min(24,shot.size);
      c.fillStyle=shot.friendly?'#697f6c':'#7b432f';c.strokeStyle='#e5cb8c';c.lineWidth=1;
      c.beginPath();c.moveTo(shot.x,shot.y-10);c.lineTo(shot.x+radius,shot.y+3);
      c.lineTo(shot.x,shot.y+10);c.lineTo(shot.x-radius,shot.y+3);c.closePath();c.fill();c.stroke();
    }
    for(const e of w.enemies){
      this.unit(ENEMIES[e.tribe][e.unit],e.x,e.y,e.tribe,e.hp/e.max);
      const kind=missileType(e.tribe,e.unit);
      if(kind && e.y>=HEIGHT*.26 && e.reload<.55){
        c.strokeStyle=kind==='music'?'#7e426f':'#b23d24';c.lineWidth=2;c.beginPath();
        c.arc(e.x,e.y+5,8+13*e.reload/.55,0,Math.PI*2);c.stroke();
      }
    }
    for(const shot of w.hostile)this.enemyShot(shot.x,shot.y,shot.vx,shot.vy,shot.kind);
    for(let i=w.allies.length-1;i>=0;i--){
      const a=w.allies[i],p=formation(w,i),info=ALLIES[a.unit];this.image(info.name,p.x,p.y,42);
      this.bar(p.x,p.y+21,22,a.hp/info.hp,'#607651');
    }
    c.save();if(w.guard>0)c.globalAlpha=.64+.3*Math.abs(Math.sin(w.guard*16));
    this.image(HERO,w.x,FLOOR,68,72);c.restore();
    this.bar(w.x,FLOOR+36,43,w.hp/100,'#973f2c');
    this.layer.refresh();
  }
  update(){
    if(this.mode==='success'){
      const now=performance.now();
      if(!document.hidden && document.hasFocus())this.successElapsed+=Math.min(.25,(now-this.previousTime)/1000);
      this.previousTime=now;
      if(this.successElapsed>=1.5){
        this.mode='complete';this.sync();this.ui.finish?.(this.outcome!);
      }
      return;
    }
    if(this.mode!=='playing')return;
    if(this.ui.finish && (document.hidden||!document.hasFocus())){this.pauseRun();return;}
    const now=performance.now();
    const passed=Math.max(0,(now-this.previousTime)/1000);this.previousTime=now;
    const remaining=AD_SECONDS-this.progress.seconds;
    const credited=Math.min(remaining,passed,.25);
    const pad=this.gamepad.poll(now);
    if(pad.activate && credited<remaining){this.ui.activateVip();if(this.mode!=='playing')return;}
    const left=this.keys.has('a')||this.keys.has('arrowleft'),right=this.keys.has('d')||this.keys.has('arrowright');
    const axis=this.keys.size?Number(right)-Number(left):pad.axis;
    if(axis!==0||this.keys.size)this.aim=null;
    // Substeps keep fast blades and collisions stable across normal rendering rates.
    let todo=Math.min(.25,credited);
    while(todo>1e-8){
      const dt=Math.min(1/60,todo);todo-=dt;
      advance(this.progress.world,dt,this.aim,this.combatFeedback,axis);
      if(this.progress.world.hp<=0){
        this.progress.deaths++;this.progress.world=newWorld();this.aim=null;this.savedAt=-1;
        this.feedback('lose','魂已倒下 · 重开试炼，本次广告继续计时');
      }
    }
    this.progress.seconds+=credited;
    if(now>=this.noticeUntil&&this.noticeUntil){this.noticeUntil=0;this.ui.notice('');}
    if(credited>=remaining){
      this.finishSegment('completed');
    }else if(this.progress.world.time-this.savedAt>=1)this.save();
    this.draw();this.sync();
  }
}
