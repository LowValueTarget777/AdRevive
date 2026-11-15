export type WorldNotice =
  | {key:'gain'|'bossGain'; id:number; copies?:number}
  | {key:'fallen'; id:number}
  | {key:'allyHit'; id:number; amount:number}
  | {key:'heroHit'; amount:number; lost?:number}
  | {key:'bossArrival'};

export type BattleWords = Record<WorldNotice['key']|'drop',string> & {names:readonly string[]};

export function formatNotice(event:WorldNotice,words:BattleWords){
  let text=words[event.key];
  if('id' in event)text=text.replace('{name}',words.names[event.id]);
  if('amount' in event)text=text.replace('{n}',String(event.amount));
  if('copies' in event && event.copies!==undefined)text+=' ×'+event.copies;
  if(event.key==='heroHit' && event.lost!==undefined){
    text+=' · '+words.drop.replace('{name}',words.names[event.lost]);
  }
  return text;
}
