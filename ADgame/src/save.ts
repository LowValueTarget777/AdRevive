import { updateCardHP, type World } from './world';
import { AD_SECONDS, ALLIES, ENEMIES, WEAPONS, BALLISTICS, FIRST_WAVE_AT, FIRST_BOSS_AT, enemyStats, isEnemy, rewardHP } from './rules';

export const SAVE_KEY='pozhen-endless-v1';
export type Progress={version:2; world:World; seconds:number; completed:number; deaths:number};
const positive=(x:unknown):x is number=>typeof x==='number'&&Number.isFinite(x)&&x>=0;
const integer=(x:unknown):x is number=>positive(x)&&Number.isSafeInteger(x);
const index=(x:unknown,length:number)=>integer(x)&&x<length;
const object=(x:unknown):x is Record<string,unknown>=>!!x&&typeof x==='object';
function fields(o:Record<string,unknown>,keys:string[]){return keys.every(k=>positive(o[k]));}
function valid(data:unknown):data is Progress{
  if(!object(data)||data.version!==2||!positive(data.seconds)||data.seconds>=AD_SECONDS||
    !integer(data.completed)||!integer(data.deaths)||!object(data.world))return false;
  const w=data.world;
  if(!fields(w,['seed','time','x','hp','kills','taken','nextId','nextMob','nextBoss','guard','fire']) ||
     !positive(w.hp)||w.hp>100||w.hp===0||!Array.isArray(w.weapons)||w.weapons.length!==WEAPONS.length||!w.weapons.every(integer))return false;
  return Array.isArray(w.cards)&&w.cards.length===2&&w.cards.every(c=>object(c)&&
    index(c.reward,ALLIES.length+WEAPONS.length)&&positive(c.max)&&c.max>0&&positive(c.hp)&&c.hp>0&&c.hp<=c.max)
    &&Array.isArray(w.allies)&&w.allies.every(a=>object(a)&&index(a.unit,ALLIES.length)&&positive(a.hp)&&a.hp>0&&positive(a.cool))
    &&Array.isArray(w.enemies)&&w.enemies.every(e=>object(e)&&typeof e.tribe==='string'&&Object.hasOwn(ENEMIES,e.tribe)&&
      index(e.unit,ENEMIES[e.tribe as keyof typeof ENEMIES].length)&&fields(e,['x','y','hp','max','attack','speed','id','reload']))
    &&Array.isArray(w.hostile)&&w.hostile.every(s=>object(s)&&fields(s,['x','y','attack'])&&Number.isFinite(s.vx)&&Number.isFinite(s.vy)&&typeof s.kind==='string'&&Object.hasOwn(BALLISTICS,s.kind))
    &&Array.isArray(w.shots)&&w.shots.every(s=>object(s)&&fields(s,['x','y','power','speed','size','pierce'])&&
      typeof s.friendly==='boolean'&&Array.isArray(s.touched)&&s.touched.every(integer));
}
export function loadProgress():Progress|null {
  const source=localStorage.getItem(SAVE_KEY);
  if(source===null)return null;
  const data:unknown=JSON.parse(source);
  if(object(data)&&data.version===1&&object(data.world)){
    const w=data.world;
    if(!Array.isArray(w.enemies)||!Array.isArray(w.shots)||!positive(w.time))throw Error('旧版战场无法读取');
    // Append-only roster IDs keep every existing character identity. Preserve damage ratios.
    for(const m of w.enemies){
      if(!object(m)||typeof m.tribe!=='string'||!Object.hasOwn(ENEMIES,m.tribe)||
        !integer(m.unit)||!positive(m.max)||m.max===0||!positive(m.y)||!positive(m.hp)||!integer(m.id))throw Error('旧版敌人数据错误');
      const stats=enemyStats(m.tribe as keyof typeof ENEMIES,w.time,m.unit);
      m.hp=Math.max(1,Math.ceil(stats.max*m.hp/m.max));
      Object.assign(m,stats,{y:m.y*1.5,reload:1+(m.id%13)/10});
    }
    for(const shot of w.shots){if(!object(shot)||!positive(shot.y))throw Error('旧版飞刀数据错误');shot.y*=1.5;}
    data.version=2;w.hostile=[];
  }
  if(!valid(data))throw Error('存档格式异常，无法续战');
  const cardMax=rewardHP(data.world.taken);
  for(const card of data.world.cards)updateCardHP(card,cardMax);
  data.world.nextMob=Math.max(data.world.nextMob,FIRST_WAVE_AT);
  data.world.nextBoss=Math.max(data.world.nextBoss,FIRST_BOSS_AT);
  data.world.enemies=data.world.enemies.filter(e=>isEnemy(e.tribe,e.unit));
  return data;
}
export function saveProgress(p:Progress){localStorage.setItem(SAVE_KEY,JSON.stringify(p));}
