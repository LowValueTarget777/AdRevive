import Phaser from 'phaser';
import mountainUrl from './assets/mountains.jpg';

import { ALL_ART, WIDTH, HEIGHT } from './rules';
type Pen = CanvasRenderingContext2D;
const brush = '"STKaiti","KaiTi","Noto Serif CJK SC",serif';


function line(p: Pen, path: string, color: string, width = 1) {
  p.strokeStyle = color; p.lineWidth = width; p.stroke(new Path2D(path));
}
function lettering(p: Pen, value: string, x: number, y: number, font: string, color: string) {
  p.textAlign = 'center'; p.fillStyle = color; p.font = font; p.fillText(value, x, y);
}

function field(p: Pen, art: HTMLImageElement) {
  p.save(); p.scale(WIDTH/432,HEIGHT/512);
  p.fillStyle='#ded3b6';p.fillRect(0,0,432,512);
  p.save();p.globalAlpha=.52;p.drawImage(art,art.width*.24,0,art.width*.66,art.height,0,0,432,512);p.restore();
  const mist=p.createLinearGradient(0,0,0,512);
  mist.addColorStop(0,'#e2d4b22e');mist.addColorStop(.28,'#e5d8bbad');mist.addColorStop(.73,'#d9ceb3ca');mist.addColorStop(1,'#bcb39960');
  p.fillStyle=mist;p.fillRect(0,0,432,512);
  p.fillStyle='#caa66112';p.fillRect(0,0,216,512);p.fillStyle='#a4574510';p.fillRect(216,0,216,512);
  p.setLineDash([4,6]);line(p,'M216 35 V422','#675e488c',1);p.setLineDash([]);
  for (const [x,name,tone] of [[108,'强 化','#55513b'],[324,'迎 敌','#724235']] as const) {
    p.fillStyle='#e6dbbe';p.globalAlpha=.83;p.fillRect(x-38,12,76,25);p.globalAlpha=1;
    line(p,`M${x-38} 12 h76 M${x-38} 37 h76`,'#816e50',.8);
    lettering(p,name,x,29,'bold 15px '+brush,tone);
  }
  p.setLineDash([2,6]);line(p,'M13 428 H419','#63574168',1);p.setLineDash([]);p.restore();
}

function make(scene: Phaser.Scene, key: string, w: number, h: number, draw: (p: Pen)=>void) {
  const texture=scene.textures.createCanvas(key,w*2,h*2);
  if (!texture) throw new Error('无法创建纹理 '+key);
  const p=texture.getContext();p.scale(2,2);draw(p);texture.refresh();
}

export async function loadArt() {
  function image(url:string):Promise<HTMLImageElement> {
    return new Promise((resolve,reject)=>{
      const img=new Image();
      img.onload=()=>resolve(img);
      img.onerror=()=>reject(new Error('素材载入失败'));
      img.src=url;
    });
  }
  const files=import.meta.glob<string>('./assets/units/*.webp',{eager:true,import:'default',query:'?inline'});
  const sprites=await Promise.all(ALL_ART.map(async name=>{
    const src=files['./assets/units/'+name+'.webp'];
    if(!src)throw Error('缺少素材 '+name);
    return [name,await image(src)] as const;
  }));
  return {mountain:await image(mountainUrl),sprites};
}

export function textures(scene: Phaser.Scene, art: Awaited<ReturnType<typeof loadArt>>) {
  make(scene,'ground',WIDTH,HEIGHT,p=>field(p,art.mountain));
}
