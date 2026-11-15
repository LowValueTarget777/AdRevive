import { ALLIES, WEAPONS, SPAWN_POOL, WIDTH, HEIGHT, FLOOR, CARD_X, CARD_Y, FIRST_WAVE_AT, FIRST_BOSS_AT, army, enemyStats, rewardHP, rewardInfo, weaponStats, missileType, BALLISTICS, type Missile, type Tribe } from './rules';

export type Friend = {unit:number; hp:number; cool:number};
export type Mob = {id:number; tribe:Tribe; unit:number; x:number; y:number; hp:number; max:number; attack:number; speed:number; reload:number};
export type Shot = {x:number; y:number; power:number; speed:number; size:number; pierce:number; touched:number[]; friendly:boolean};
export type EnemyShot = {x:number; y:number; vx:number; vy:number; attack:number; kind:Missile};
export type Card = {reward:number; max:number; hp:number};
export type World = {
  seed:number; time:number; x:number; hp:number; kills:number; taken:number; nextId:number;
  weapons:number[]; allies:Friend[]; cards:Card[]; enemies:Mob[]; shots:Shot[]; hostile:EnemyShot[];
  nextMob:number; nextBoss:number; guard:number; fire:number;
};
export type Cue='throw'|'hit'|'upgrade'|'hurt'|'win'|'lose';
export type Feedback=(cue:Cue,text?:string)=>void;
export function random(w:World){
  w.seed=(1664525*w.seed+1013904223)%4294967296;
  return w.seed/4294967296;
}
function rollCard(w:World):Card{
  const max=rewardHP(w.taken);
  return {reward:Math.floor(random(w)*(ALLIES.length+WEAPONS.length)),max,hp:max};
}
export function updateCardHP(card:Card,max:number){
  card.hp+=max-card.max;
  card.max=max;
}
export function newWorld(seed=Math.floor(Math.random()*4294967296)):World{
  const w:World={seed,time:0,x:WIDTH/2,hp:100,kills:0,taken:0,nextId:1,
    weapons:WEAPONS.map(()=>0),allies:[],cards:[],enemies:[],shots:[],hostile:[],nextMob:FIRST_WAVE_AT,nextBoss:FIRST_BOSS_AT,guard:0,fire:.10};
  w.cards=[rollCard(w),rollCard(w)];return w;
}
// A broken card rerolls its own slot. A boss draws independently from the full pool.
function grant(w:World,reward:number,slot:number|null,feedback:Feedback){
  if(reward<ALLIES.length)w.allies.push({unit:reward,hp:ALLIES[reward].hp,cool:.12});
  else w.weapons[reward-ALLIES.length]++;
  w.taken++;
  const max=rewardHP(w.taken);
  w.cards.forEach((card,i)=>{
    if(i===slot)w.cards[i]=rollCard(w);
    else updateCardHP(card,max);
  });
  const name=rewardInfo(reward).short;
  const stacks=reward>=ALLIES.length?' ×'+w.weapons[reward-ALLIES.length]:'';
  feedback('upgrade',(slot===null?'首领奖励 · ':'获得 ')+name+stacks);
}

export function formation(w:World,index:number){
  // The rear row has four places around the hero; subsequent rows have five.
  const slot=index<4?[1,3,0,4][index]:(index-4)%5;
  const row=index<4?0:1+Math.floor((index-4)/5);
  const width=58;
  const anchor=Math.min(WIDTH-width-20,Math.max(width+20,w.x));
  const stepY=Math.min(31,112/Math.max(1,Math.ceil((w.allies.length-4)/5)));
  return {x:anchor+(slot-2)*width/2,y:FLOOR-row*stepY};
}
export function spawn(w:World,tribe:Tribe){
  const pool=SPAWN_POOL[tribe];
  const unit=pool[Math.floor(random(w)*pool.length)];
  const stats=enemyStats(tribe,w.time,unit);
  w.enemies.push({id:w.nextId++,tribe,unit,x:WIDTH/2+32+random(w)*(WIDTH/2-66),
    y:tribe==='boss'?84:52,hp:stats.max,reload:1.05+random(w)*1.3,...stats});
}

function shoot(w:World,x:number,y:number,power:number,speed:number,size:number,pierce:number,friendly:boolean){
  w.shots.push({x,y,power,speed,size,pierce,friendly,touched:[]});
}
function fire(w:World,dt:number,stats:ReturnType<typeof weaponStats>,feedback:Feedback){
  w.fire-=dt;
  if(w.fire<=0){
    // Fold extremely high theoretical rates into damage so stacks keep their value.
    const rate=Math.min(15,stats.rate),power=stats.damage*stats.rate/rate;
    w.fire+=1/rate;
    for(const dx of stats.double?[-11,11]:[0])shoot(w,w.x+dx,FLOOR-27,power,stats.speed,stats.size,stats.pierce,false);
    feedback('throw');
  }
  w.allies.forEach((a,i)=>{
    a.cool-=dt;if(a.cool>0)return;
    const p=formation(w,i), ally=ALLIES[a.unit];
    shoot(w,p.x,p.y-19,ally.damage,ally.speed,ally.size,ally.pierce,true);a.cool+=ally.interval;
  });
}
function resolveShots(w:World,dt:number,feedback:Feedback){
  for(let i=w.shots.length-1;i>=0;i--){
    const shot=w.shots[i],oldY=shot.y;
    shot.y-=shot.speed*dt;
    const hits:{y:number; mob?:Mob; slot?:number}[]=[];
    for(const mob of w.enemies){
      const r=mob.tribe==='boss'?31:mob.tribe==='elite'?23:16;
      if(Math.abs(mob.x-shot.x)<=r+shot.size && shot.y<=mob.y+r && oldY>=mob.y-r && !shot.touched.includes(mob.id))
        hits.push({y:mob.y+r,mob});
    }
    for(let c=0;c<2;c++){
      if(Math.abs(shot.x-CARD_X[c])<46+shot.size && shot.y<=CARD_Y+45 && oldY>=CARD_Y-45)hits.push({y:CARD_Y+45,slot:c});
    }
    hits.sort((a,b)=>b.y-a.y);
    let consumed=false;
    for(const hit of hits){
      if(hit.slot!==undefined){
        const card=w.cards[hit.slot];card.hp-=shot.power;
        if(card.hp<=0)grant(w,card.reward,hit.slot,feedback);
        consumed=true;break;
      }
      const mob=hit.mob!;
      mob.hp-=shot.power;shot.touched.push(mob.id);
      if(mob.hp<=0){
        w.enemies.splice(w.enemies.indexOf(mob),1);w.kills++;feedback('hit');
        if(mob.tribe==='boss')grant(w,Math.floor(random(w)*(ALLIES.length+WEAPONS.length)),null,feedback);
      }
      if(shot.pierce<=0){consumed=true;break;}
      shot.pierce--;
    }
    if(consumed || shot.y<0)w.shots.splice(i,1);
  }
}
function damage(w:World,victim:number,amount:number,feedback:Feedback){
  if(w.guard>0)return;
    if(victim>=0){
      const a=w.allies[victim];a.hp-=amount;
      if(a.hp<=0){w.allies.splice(victim,1);feedback('hurt',ALLIES[a.unit].short+' 已阵亡');}
      else feedback('hurt',ALLIES[a.unit].short+' 承伤 −'+amount);
    }else{
      w.hp=Math.max(0,w.hp-amount);
      const owned=w.weapons.reduce((sum,n)=>sum+n,0);
      let lost='';
      if(owned>0){
        let ticket=Math.floor(random(w)*owned);
        for(let i=0;i<w.weapons.length;i++){
          if(ticket<w.weapons[i]){w.weapons[i]--;lost=' · 掉落'+WEAPONS[i].name;break;}
          ticket-=w.weapons[i];
        }
      }
      feedback('hurt','魂 · 气血 −'+amount+lost);
    }
  // Enough protection to survive a fan of shots, short enough for a crowd to matter.
  w.guard=.48;
}
function frontTarget(w:World,from:{x:number;y:number}){
  let closest=Infinity,index=-1,point={x:w.x,y:FLOOR};
  for(let i=0;i<w.allies.length;i++){
    const p=formation(w,i),d=(p.x-from.x)**2+(p.y-from.y)**2;
    if(d<closest){closest=d;point=p;index=i;}
  }
  return {...point,index};
}
function rangedAttack(w:World,m:Mob,kind:Missile,dt:number){
  m.reload-=dt;
  if(m.reload>0)return;
  const target=frontTarget(w,m),angle=Math.atan2(target.y-m.y,target.x-m.x),spec=BALLISTICS[kind];
  for(const offset of spec.spread){
    w.hostile.push({x:m.x,y:m.y+7,vx:Math.cos(angle+offset)*spec.speed,vy:Math.sin(angle+offset)*spec.speed,
      kind,attack:Math.ceil(m.attack*spec.damage)});
  }
  m.reload=spec.delay*(.9+.22*random(w));
}
function march(w:World,dt:number,feedback:Feedback){
  w.guard=Math.max(0,w.guard-dt);
  for(const mob of w.enemies){
    const ranged=missileType(mob.tribe,mob.unit);
    if(ranged && mob.y>=HEIGHT*.26){
      rangedAttack(w,mob,ranged,dt);
      // Spread firing positions in depth so the volley can be read and dodged.
      if(mob.y>=HEIGHT*(.38+.035*(mob.id%8)))continue;
    }
    if(mob.y<FLOOR-160){mob.y+=mob.speed*dt;continue;}
    const target=frontTarget(w,mob);
    const dx=target.x-mob.x,dy=target.y-mob.y,dist=Math.sqrt(dx*dx+dy*dy);
    if(dist>1){
      const travel=Math.min(dist,dt*mob.speed*1.55);
      mob.x+=travel*dx/dist;mob.y+=travel*dy/dist;
    }
    if(dist>24 || w.guard>0)continue;
    damage(w,target.index,mob.attack,feedback);mob.y-=55;
    if(w.hp===0)return;
  }
}
function enemyBullets(w:World,dt:number,feedback:Feedback){
  for(let i=w.hostile.length-1;i>=0;i--){
    const shot=w.hostile[i];
    shot.x+=shot.vx*dt;shot.y+=shot.vy*dt;
    let spent=shot.x<0||shot.x>WIDTH||shot.y<0||shot.y>HEIGHT;
    if(!spent && shot.y>FLOOR-155){
      const target=frontTarget(w,shot);
      const radius=(target.index<0?17:13)+BALLISTICS[shot.kind].radius;
      if((target.x-shot.x)**2+(target.y-shot.y)**2<=radius**2){
        damage(w,target.index,shot.attack,feedback);spent=true;
      }
    }
    if(spent)w.hostile.splice(i,1);
    if(w.hp===0)return;
  }
}
export function advance(w:World,dt:number,aim:number|null,feedback:Feedback,axis=0){
  const stats=weaponStats(w.weapons);
  const travel=stats.move*dt;
  const displacement=aim===null?axis*travel:aim-w.x;
  w.x=Math.max(21,Math.min(WIDTH-21,w.x+Math.max(-travel,Math.min(travel,displacement))));
  w.time+=dt;
  if(w.time>=w.nextMob){
    const wave=army(w.time);
    for(let i=0;i<wave.count;i++)spawn(w,random(w)<wave.eliteChance?'elite':'scout');
    w.nextMob+=wave.interval;
  }
  if(w.time>=w.nextBoss){spawn(w,'boss');w.nextBoss+=32;feedback('hit','首领来袭 · 击破得随机奖励');}
  fire(w,dt,stats,feedback);resolveShots(w,dt,feedback);march(w,dt,feedback);if(w.hp>0)enemyBullets(w,dt,feedback);
}
