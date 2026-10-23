"""Commercial Mac App Store screenshots, preserving real production UI and exact bilingual copy."""
from pathlib import Path
import json, argparse, shutil
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageCms
ROOT=Path(__file__).resolve().parents[1]
W,H=2880,1800
CAP=ROOT/'dist/1.5.0/captures'
OUT=ROOT/'dist/1.5.0/commercial-store'
ICC=ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()
CN='/System/Library/Fonts/Hiragino Sans GB.ttc'; EN='/System/Library/Fonts/Avenir Next.ttc'
COPY={
'zh-Hans':[
('让 PDF，井然有序。','查找书目、核对元数据、规范命名，在一处完成。'),
('成批导入，\n逐本整理。','多选 PDF 或文件夹。\n每份文件的进度，都在侧栏。'),
('比较来源，\n再做选择。','从公开书目中寻找线索。\n核对作者、ISBN 与出版信息。'),
('写入之前，\n变化先看清。','当前文件值，对比拟写入值。\n修改与清空，逐项确认。'),
('五项信息，\n命名一目了然。','标题、作者、出版社，\n年份与语言，\n一路分色，清楚对应。'),
('三种主题，\n一种清晰。','蓝白、暖绿与深色。\n简体中文与英文，随时切换。')],
'en-US':[
('A clearer home for every PDF.','Find bibliographic records. Review changes. Save with a clear name.'),
('Import more.\nKeep your place.','Select multiple PDFs or folders.\nResume each file from the sidebar.'),
('Compare first.\nChoose with care.','Review public catalog records.\nCompare authors, ISBNs and sources.'),
('See every change.\nBefore you write.','Current PDF values beside proposed values.\nReview changed and cleared fields.'),
('Five fields.\nOne clear name.','Title, authors and publisher.\nYear and language.\nFollow matching colors into the filename.'),
('Three themes.\nYour kind of calm.','Blue, warm sage or dark.\nSimplified Chinese and English.')]
}
COLORS=['#1769C2','#7E49B0','#24796D','#A35D12','#B54172']

def font(locale,size,bold=False):
 return ImageFont.truetype(CN if locale=='zh-Hans' else EN,round(size),index=(2 if bold else 0) if locale=='zh-Hans' else (0 if bold else 7))
def text(im,xy,lines,locale,size,color='#142D47',bold=False,spacing=1.25,maxwidth=None):
 d=ImageDraw.Draw(im); parts=lines.split('\n')
 if maxwidth:
  while max(d.textbbox((0,0),p,font=font(locale,size,bold))[2] for p in parts)>maxwidth:size-=1
 f=font(locale,size,bold)
 for i,line in enumerate(parts):d.text((xy[0],xy[1]+round(i*size*spacing)),line,font=f,fill=color,stroke_width=0)
 return size

def background(kind=0):
 palettes=[('#F5F9FF','#E1EEFE'),('#F6FAFF','#D9EAFF'),('#EEF6FF','#D9E9FF'),('#F4F8FF','#E1EBF8'),('#F7F5ED','#E4EDE7'),('#EAF1FA','#D5DFE9')]
 def rgb(s):return np.array([int(s[i:i+2],16) for i in (1,3,5)],dtype=np.float32)
 a,b=map(rgb,palettes[kind]);yy,xx=np.mgrid[0:H,0:W].astype(np.float32);mix=(0.52*yy/H+0.48*xx/W)[...,None]
 arr=a*(1-mix)+b*mix
 for cx,cy,r,tint,alpha in [(2380,300,980,'#A7D7FF',.28),(420,1420,850,'#FFFFFF',.72),(1800,1660,800,'#B2D9E6',.17)]:
  mask=np.maximum(0,1-((xx-cx)**2+(yy-cy)**2)/r**2)[...,None]*alpha
  arr=arr*(1-mask)+rgb(tint)*mask
 return Image.fromarray(np.uint8(np.clip(arr,0,255))).convert('RGBA')

def image(locale,name,crop=None):
 im=Image.open(CAP/locale/name).convert('RGBA');return im.crop(crop) if crop else im

def panel(canvas,source,xy,width,radius=32):
 height=round(source.height*width/source.width);size=(round(width),height);source=source.resize(size,Image.Resampling.LANCZOS)
 x,y=map(round,xy);shadow=Image.new('RGBA',(W,H));sd=ImageDraw.Draw(shadow)
 sd.rounded_rectangle((x,y+28,x+size[0],y+height+28),radius=radius,fill=(30,59,94,45));shadow=shadow.filter(ImageFilter.GaussianBlur(45));canvas.alpha_composite(shadow)
 mask=Image.new('L',size);ImageDraw.Draw(mask).rounded_rectangle((0,0,size[0]-1,height-1),radius=radius,fill=255)
 canvas.paste(source,(x,y),mask)
 ImageDraw.Draw(canvas).rounded_rectangle((x,y,x+size[0]-1,y+height-1),radius=radius,outline=(255,255,255,210),width=3)
 return (x,y,size[0],height)

def brand(canvas,locale):
 icon=Image.open(ROOT/'docs/assets/icon.png').convert('RGBA').resize((70,70),Image.Resampling.LANCZOS);canvas.alpha_composite(icon,(2655,91))
 text(canvas,(2360,103),'PDF Librarian','en-US',31,'#4C667C',True)

def footer(canvas,locale):
 value='真实应用界面 · 演示书目数据' if locale=='zh-Hans' else 'Actual application views · Demo bibliographic data'
 text(canvas,(150,1738),value,locale,25,'#687D90')

def file_art(canvas):
 for x,y,angle in [(195,1090,-9),(425,1040,0),(650,1100,9)]:
  card=Image.new('RGBA',(240,300));d=ImageDraw.Draw(card);d.rounded_rectangle((4,4,235,295),radius=28,fill=(255,255,255,200),outline=(255,255,255,250),width=3)
  d.polygon([(165,5),(235,75),(165,75)],fill=(191,217,245,255));d.text((53,140),'PDF',font=font('en-US',50,True),fill='#2D72BD')
  card=card.rotate(angle,Image.Resampling.BICUBIC,expand=True);canvas.alpha_composite(card,(x,y))

parser=argparse.ArgumentParser();parser.add_argument('--install',action='store_true',help='Copy reviewed commercial assets into the canonical release media tree');ARGS=parser.parse_args()
manifest=[]
for locale in COPY:
 (OUT/locale).mkdir(parents=True,exist_ok=True)
 for index,(headline,body) in enumerate(COPY[locale],1):
  canvas=background(index-1);brand(canvas,locale)
  native=[]
  if index==1:
   text(canvas,(150,106),headline,locale,158 if locale=='zh-Hans' else 130,bold=True,maxwidth=2440)
   text(canvas,(158,308),body,locale,46,'#49677E',maxwidth=2480)
   native.append(panel(canvas,image(locale,'02.png'),(390,423),2100))
  elif index==2:
   text(canvas,(150,245),headline,locale,156 if locale=='zh-Hans' else 122,bold=True,maxwidth=1030)
   text(canvas,(158,722),body,locale,47,'#49677E',spacing=1.6,maxwidth=1030)
   file_art(canvas)
   native.append(panel(canvas,image(locale,'01.png',(0,152,1290,1710)),(1545,205),1140))
  elif index==3:
   text(canvas,(150,238),headline,locale,150 if locale=='zh-Hans' else 116,bold=True,maxwidth=970)
   text(canvas,(158,706),body,locale,45,'#49677E',spacing=1.6,maxwidth=980)
   for i,source in enumerate(['Google Books','Open Library','Douban','Library of Congress']):
    ImageDraw.Draw(canvas).ellipse((164,1080+i*100,178,1094+i*100),fill='#5993C2');text(canvas,(204,1060+i*100),source,'en-US',39,'#49677E')
   native.append(panel(canvas,image(locale,'02.png',(1292,152,2880,1710)),(1225,210),1500))
  elif index==4:
   text(canvas,(150,238),headline,locale,150 if locale=='zh-Hans' else 116,bold=True,maxwidth=990)
   text(canvas,(158,715),body,locale,45,'#49677E',spacing=1.6,maxwidth=990)
   labels=['当前文件','准备写入','更改高亮'] if locale=='zh-Hans' else ['Current PDF','Proposed values','Changes highlighted']
   for i,label in enumerate(labels):
    ImageDraw.Draw(canvas).rounded_rectangle((158,1050+i*130,169,1120+i*130),radius=5,fill=['#8C9AAB','#236BC1','#5A9CD9'][i]);text(canvas,(204,1055+i*130),label,locale,42,'#315A7F',i==2,maxwidth=900)
   native.append(panel(canvas,image(locale,'confirmation.png'),(1150,315),1550))
  elif index==5:
   text(canvas,(150,242),headline,locale,140 if locale=='zh-Hans' else 118,bold=True,maxwidth=950)
   text(canvas,(158,695),body,locale,44,'#556F6C',spacing=1.6,maxwidth=950)
   labels=['标题','作者','出版社','年份','语言'] if locale=='zh-Hans' else ['Title','Authors','Publisher','Year','Language']
   for i,(label,color) in enumerate(zip(labels,COLORS)):
    ImageDraw.Draw(canvas).ellipse((164,1088+i*98,186,1110+i*98),fill=color);text(canvas,(220,1067+i*98),label,locale,43,color,True)
   native.append(panel(canvas,image(locale,'04.png',(1292,152,2880,1710)),(1160,200),1550))
  else:
   text(canvas,(150,120),headline,locale,150 if locale=='zh-Hans' else 124,bold=True,maxwidth=2250)
   text(canvas,(163,535),body,locale,47,'#49677E',spacing=1.5,maxwidth=1170)
   native.append(panel(canvas,image(locale,'03.png'),(150,855),1330))
   native.append(panel(canvas,image(locale,'05.png'),(790,695),1430))
   native.append(panel(canvas,image(locale,'06.png'),(1310,835),1440))
   for xy,label,col in [((162,795),'蓝白' if locale=='zh-Hans' else 'Blue','#3276B2'),((802,635),'暖绿' if locale=='zh-Hans' else 'Warm sage','#4E8176'),((2510,775),'深色' if locale=='zh-Hans' else 'Dark','#344653')]:text(canvas,xy,label,locale,34,col,True)
  footer(canvas,locale)
  path=OUT/locale/f'{index:02d}.png';canvas.convert('RGB').save(path,icc_profile=ICC,optimize=True)
  manifest.append({'locale':locale,'file':str(path.relative_to(ROOT)),'headline':headline,'body':body,'native_regions':native,'size':[W,H],'source':'Production SwiftUI native view captures; demo data; original UI preserved','alpha':False})
(OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
# A contact sheet is for QA only; each delivered store image is its own commercial composition.
for locale in COPY:
 board=Image.new('RGB',(1920,800),'#DFE7EF')
 for i in range(6):board.paste(Image.open(OUT/locale/f'{i+1:02d}.png').resize((640,400)),((i%3)*640,(i//3)*400))
 board.save(OUT/f'contact-{locale}.jpg',quality=95)
print('Created 12 commercial App Store images at 2880x1800, RGB/sRGB, exact native UI preserved')

if ARGS.install:
 target=ROOT/'docs/app-store/1.5.0'
 for locale in COPY:
  (target/'screenshots'/locale).mkdir(parents=True,exist_ok=True)
  for number in range(1,7):shutil.copy2(OUT/locale/f'{number:02d}.png',target/'screenshots'/locale/f'{number:02d}.png')
  (target/'promotional').mkdir(exist_ok=True)
  shutil.copy2(OUT/locale/'01.png',target/'promotional'/f'{locale}-workspace.png')
  shutil.copy2(OUT/f'contact-{locale}.jpg',target/'promotional'/f'contact-{locale}.jpg')
 public_manifest=[dict(item,file=f"screenshots/{item['locale']}/{Path(item['file']).name}") for item in manifest]
 (target/'commercial-manifest.json').write_text(json.dumps(public_manifest,ensure_ascii=False,indent=2))
 print('Installed the 12 commercial store images and two hero posters')
