export const WIDTH = 620, HEIGHT = 765, FLOOR = 675, AD_SECONDS = 30;
export const FIRST_WAVE_AT = 3, FIRST_BOSS_AT = 52;
export const CARD_X = [76, 226] as const;
export const CARD_Y = 297;
export const HERO = '魂-背影';

export const ALLIES = [
  {name:'暗魔天堡之主：魔渊', short:'魔渊', text:'重击贯敌', hp:48, damage:16, interval:.66, size:7, speed:445, pierce:1},
  {name:'剑痴：花千笑', short:'花千笑', text:'快剑连发', hp:30, damage:6, interval:.25, size:4, speed:540, pierce:0},
  {name:'拳痴：铁狂', short:'铁狂', text:'厚血重拳', hp:72, damage:16, interval:.7, size:9, speed:380, pierce:0},
  {name:'双蛇夫人：白赤练', short:'白赤练', text:'蛇刃穿两敌', hp:34, damage:8, interval:.49, size:4, speed:510, pierce:2},
  {name:'天玄派：毕远掌门残躯', short:'毕远掌门', text:'宽刃剑气', hp:44, damage:12, interval:.54, size:10, speed:450, pierce:0},
  {name:'组织少主：沐小葵', short:'沐小葵', text:'轻刃疾射', hp:34, damage:7, interval:.29, size:5, speed:610, pierce:0},
  {name:'少主护卫：玉妖', short:'玉妖', text:'迅刃贯敌', hp:38, damage:8, interval:.38, size:4, speed:560, pierce:1},
  {name:'少主护卫：铁鬼', short:'铁鬼', text:'铁甲护阵', hp:94, damage:11, interval:.68, size:8, speed:395, pierce:0},
  {name:'雷枪：长鸿', short:'长鸿', text:'雷枪高速贯敌', hp:40, damage:11, interval:.53, size:4, speed:780, pierce:1},
  {name:'风雪刀客', short:'风雪刀客', text:'快刀横斩', hp:36, damage:8, interval:.37, size:8, speed:510, pierce:0},
  {name:'被面具控制的舞狮尊主：烈焰', short:'烈焰', text:'大范围烈刃', hp:54, damage:18, interval:.75, size:12, speed:415, pierce:0},
] as const;

export const WEAPONS = [
  {name:'黑伤', text:'刀伤 +5', damage:5},
  {name:'黑伤双刃', text:'双列飞刀 · 刀伤 +2', double:true, damage:2},
  {name:'圣母邪扇', text:'刃宽 +3 · 刀伤 +1', size:3, damage:1},
  {name:'白山风雷剑', text:'弹速 +80 · 射速 +12%', speed:80, rate:.12},
  {name:'妖锯', text:'刃宽 +2 · 刀伤 +3', size:2, damage:3},
  {name:'炽刃', text:'刀伤 +7', damage:7},
  {name:'破军', text:'穿透 +1 · 刀伤 +2', pierce:1, damage:2},
  {name:'乱莺剑', text:'射速 +28%', rate:.28},
  {name:'紫冥剑', text:'射速 +12% · 刀伤 +3', rate:.12, damage:3},
  {name:'木制黑伤', text:'移速 +40 · 刀伤 +2', move:40, damage:2},
  {name:'亡命斩马刀', text:'刀伤 +5 · 刃宽 +2', damage:5, size:2},
] satisfies {name:string; text:string; damage?:number; double?:boolean; size?:number; speed?:number; rate?:number; pierce?:number; move?:number}[];

export const ENEMIES = {
  scout:['无面剑客队长','剑盾人偶','和事佬','机灵鬼','铁面','白山女探','水行钓者','活金人·刀','哇哇哇',
    '人屠子','冰封人屠','冰爆客','冰雪歌女','冰雪琴女','刀盾暴徒',
    '双斧暴徒','双镐疯妇','合金炮偶','吼吼吼','哈哈哈','哼哼哼',
    '嘿嘿嘿','大司乐','大娘亲','大盾暴徒','失心医者','山贼',
    '山贼高手','巨刃疯妇','幽怨女娃：呜呜呜','影魅杀手','憨哥哥','戎装疯妇',
    '投掷暴徒','无面剑客','无面枪兵','无面枪兵队长','无面枪骑兵','暴徒',
    '村中长老','村花姐','枪盾人偶','歌女人偶','毒爆客','水行弟子',
    '水行投者','水行潜者','活金人·拳','活金人·棍','活铁人·刀','活铁人·拳',
    '活铁人·棍','活铜人·拳','溺水贼','漂浮之头','火弓客','火蒺藜飞贼',
    '爆弹客','狂焰山贼','猎人','琴女人偶','画戟战偶','疯妇',
    '癫秀才','白山剑护法','白山双刺护法','白山女徒','白衣鬼差','紫衣刀卫',
    '紫衣双剑客','纵火疯妇','羽弓客','腐坏暴徒','腐坏疯妇','腐坏纵火狂',
    '荆棘暴徒','血剑客','重弩客','野火鬼差','金面','铁齿伞偶',
    '长刀水行潜者','长枪暴徒','阳体人偶','阳体人偶：上半身','阳体人偶：下半身','阴体人偶',
    '雪隐潜者','雷铳鬼差','飞刀疯妇','飞贼','马匪','驯犬客',
    '鬼差','鬼差火枪手','鬼差火枪骑兵','鬼差骑兵','鬼枪盾偶','黄袍暴徒',
    '黄金刺杀偶'
  ],
  elite:['追命：六绝凶镰','鬼差队长：火流星','堕落将军：武轩','癫狂暴徒：铁杀','力者和锯者','活人偶清道夫',
    '七星剑阵：大师兄','三号·乐师偶：玉瓒','亡命徒：荆野','力者：石破天惊之态','卅四号·混沌魔偶：玉琮','发狂的水行帮主：游龙',
    '吞噬尸体的小雪','大师兄的绝望剑意','女妖骨婉约','守门人拙壁','少年左殇','左殇：真龙之躯',
    '巨锤客：万钧','廿一号·剑偶：玉璧','悲痛欲绝的阿瑾','操偶师：荡秽','斧老大：彭猛','昆仑叛教者：荒行子',
    '横刀：毕峰','水行帮主：游龙','沐小葵：铁玉女王','火刀：祝原','火流星：磷火意识','灭法之法：寒岁',
    '灭法之法：炎茹','灭法之法：蛊鹤','灭法之法：雷婷','独眼弓客','玉琮：寒冰','玉琮：混沌',
    '玉琮：钢刃','玉面郎君','琴女烟千岁','疯婆子奎艳艳','痴狂暴徒：残钢','白赤练：献祭之蛇',
    '神医：谢秋冬','红衣女剑客','组织冥主：左殇（序章）','组织猎杀者：追命','舞狮尊主的最后一舞','苦叶寺：碧海大师残躯',
    '荒行子：撕裂锯轮','虎炮：雷当','赤影骨刃：囚锋','软剑：乌冷霜','金面具黑衣人','长鸿：雷电枪骑',
    '雷当：独臂虎','鬼差高手：勾魂','鬼差高手：斩骑','鬼差高手：断肠'
  ],
  boss:['组织冥主：左殇（终章）','救苦救难梦华圣母娘娘','十二号·偃月刀偶：玉鼎','新娘阿花','梦差：冷荼','三张脸的诡异魔偶'],
};
export type Tribe = keyof typeof ENEMIES;
// Keep catalog indices stable for saved battles. Allied identities never enter a spawn pool.
const alliedIdentities = new Set<string>([
  ...ALLIES.map(ally=>ally.name),
  '金面具黑衣人',       // 魔渊在龙柱中的身份
  '沐小葵：铁玉女王',
  '白赤练：献祭之蛇',
  '长鸿：雷电枪骑',
  '舞狮尊主的最后一舞', // 烈焰的后续形态
]);
function enemyPool(tribe:Tribe){
  return ENEMIES[tribe].flatMap((name,id)=>alliedIdentities.has(name)?[]:[id]);
}
export const SPAWN_POOL = {scout:enemyPool('scout'),elite:enemyPool('elite'),boss:enemyPool('boss')};
export function isEnemy(tribe:Tribe,id:number){return !alliedIdentities.has(ENEMIES[tribe][id]);}
export const ALL_ART = [HERO,...ALLIES.map(a=>a.name),...WEAPONS.map(w=>w.name),
  ...Object.values(ENEMIES).flat().filter(name=>!alliedIdentities.has(name))];
export function rewardInfo(id:number) {
  if(id<ALLIES.length) return {...ALLIES[id],kind:'队友'};
  const w=WEAPONS[id-ALLIES.length];return {name:w.name,short:w.name,text:w.text,kind:'武器'};
}
export function weaponStats(stacks:number[]) {
  const s={damage:10,rate:4,speed:480,move:390,size:4,pierce:0,double:false};
  WEAPONS.forEach((w,i)=>{
    const n=stacks[i];
    s.damage+=(w.damage??0)*n;s.rate+=4*(w.rate??0)*n;s.speed+=(w.speed??0)*n;
    s.move+=(w.move??0)*n;s.size+=(w.size??0)*n;s.pierce+=(w.pierce??0)*n;
    if(w.double && n>0)s.double=true;
  });
  return s;
}
export function rewardHP(taken:number){
  return 100+2*Math.ceil(22*taken+1.8*taken*taken);
}
function growthSquared(minutes:number){
  const afterOpening=Math.max(0,minutes-AD_SECONDS/60);
  return minutes**2+.16*afterOpening**2;
}
export function enemyStats(tribe:Tribe,time:number,variant:number){
  const boss=tribe==='boss';
  const [hp,attack,speed]={scout:[15,4,50],elite:[70,12,47],boss:[235,19,39]}[tribe];
  const minutes=time/60;
  const squared=growthSquared(minutes);
  const hpGrowth=boss ? 1+.16*minutes+1.5*squared : 1+.12*minutes+.52*squared;
  const attackGrowth=boss ? 1+.10*minutes+.38*squared : 1+.14*minutes+.20*squared;
  return {
    max:Math.ceil(hp*hpGrowth*(1+.055*(variant%4))),
    attack:Math.ceil(attack*attackGrowth),
    speed:speed*(1+.78*time/(time+70)),
  };
}
export function army(time:number){
  const minutes=time/60;
  const baseRate=.20+.07*minutes+.46*growthSquared(minutes);
  // Add pressure to the opening; the extra rate and its slope reach zero at three minutes.
  const openingWeight=Math.max(0,1-minutes/3)**2;
  const enemiesPerSecond=baseRate+(.20+.40*minutes)*openingWeight;
  // Start with individual enemies, then group arrivals without a sudden jump in throughput.
  const count=Math.max(1,Math.round(.85*enemiesPerSecond));
  const eliteMinutes=Math.max(0,(time-AD_SECONDS)/60);
  const eliteWeight=eliteMinutes**2;
  return {count,interval:count/enemiesPerSecond,eliteChance:.70*eliteWeight/(5+eliteWeight)};
}

export type Missile = 'music'|'gun'|'bow';
const rangedProfiles:Record<string,Missile> = {};
for(const name of ['琴女烟千岁','三号·乐师偶：玉瓒','琴女人偶','冰雪琴女','冰雪歌女','歌女人偶','大司乐'])rangedProfiles[name]='music';
for(const name of ['鬼差火枪手','鬼差火枪骑兵','雷铳鬼差','合金炮偶','虎炮：雷当','雷当：独臂虎'])rangedProfiles[name]='gun';
for(const name of ['火弓客','羽弓客','重弩客','独眼弓客','猎人'])rangedProfiles[name]='bow';
export function missileType(tribe:Tribe,unit:number):Missile|undefined{return rangedProfiles[ENEMIES[tribe][unit]];}
export const BALLISTICS = {
  music:{speed:155,delay:3.8,spread:[-.12,0,.12],damage:.53,radius:7},
  gun:{speed:315,delay:3.1,spread:[0],damage:.87,radius:5},
  bow:{speed:232,delay:3.5,spread:[0],damage:.65,radius:4},
};
