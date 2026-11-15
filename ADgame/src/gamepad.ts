const DEADZONE=.18;
const HOLD_MS=800;
export type VipKey='B'|'○'|'右侧键';

function vipBinding(pad:Gamepad){
  const sony=/054c|sony|playstation|dual[ -]?(sense|shock)|\bps[345]\b/i.test(pad.id);
  if(sony){
    // Standard layouts normalize Circle to 1. Raw DS4 / DualSense put it after Cross.
    const rawIndex=/0268|playstation\(r\)3|dual[ -]?shock\s*3/i.test(pad.id)?13:2;
    return {key:'○' as const,index:pad.mapping==='standard'?1:rawIndex};
  }
  if(/xbox|xinput|045e/i.test(pad.id))return {key:'B' as const,index:1};
  return pad.mapping==='standard'?{key:'右侧键' as const,index:1}:null;
}

type PadSample={id:string;binding:ReturnType<typeof vipBinding>;buttons:number;axes:number[]};
export class BattleGamepad {
  private samples=new Map<number,PadSample>();
  private active:number|null=null;
  private holdStart:number|null=null;
  private fired=false;
  private available=true;
  key:VipKey|null=null;
  progress=0;

  cancel(){
    this.active=null;this.key=null;this.progress=0;this.holdStart=null;this.fired=false;
  }
  private read(){
    if(this.available && navigator.getGamepads){
      try{return navigator.getGamepads();}catch{this.available=false;}
    }
    return [];
  }
  poll(now:number):{axis:number;activate:boolean}{
    const pads=this.read();
    let activate=false;
    for(let i=0;i<pads.length;i++){
      const pad=pads[i];if(!pad?.connected)continue;
      let previous=this.samples.get(i);
      if(!previous||previous.id!==pad.id){
        if(this.active===i)this.cancel();
        previous={id:pad.id,binding:vipBinding(pad),buttons:0,axes:[]};this.samples.set(i,previous);
      }
      const buttons=pad.buttons.reduce((bits,b,j)=>b.pressed?bits|(1<<j):bits,0);
      let used=(buttons & ~previous.buttons)!==0;
      for(let j=0;j<Math.min(4,pad.axes.length);j++){
        const value=Math.abs(pad.axes[j])>DEADZONE?pad.axes[j]:0;
        if(value===0)previous.axes[j]=0;
        else if(Math.abs(value-(previous.axes[j]??0))>.08){previous.axes[j]=value;used=true;}
      }
      if(used){
        if(this.active!==i)this.cancel();
        this.active=i;
      }
      const binding=previous.binding;
      if(this.active===i && binding && (buttons & ~previous.buttons & (1<<binding.index))){
        this.holdStart=now;this.fired=false;
      }
      previous.buttons=buttons;
    }
    for(const i of this.samples.keys())if(!pads[i]?.connected)this.samples.delete(i);
    const pad=this.active===null?null:pads[this.active];
    if(!pad?.connected){this.cancel();return {axis:0,activate:false};}
    const binding=this.samples.get(this.active!)!.binding;
    this.key=binding?.key??null;
    if(!binding || !pad.buttons[binding.index]?.pressed){
      this.holdStart=null;this.fired=false;this.progress=0;
    }else if(this.holdStart!==null){
      this.progress=Math.min(1,(now-this.holdStart)/HOLD_MS);
      if(this.progress===1&&!this.fired){this.fired=true;activate=true;}
    }
    const x=pad.axes[0]??0;
    const axis=Math.abs(x)>DEADZONE?Math.sign(x)*(Math.min(1,Math.abs(x))-DEADZONE)/(1-DEADZONE):0;
    return {axis,activate};
  }
}
