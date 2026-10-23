from pathlib import Path
import shutil,json
repo=Path(__file__).resolve().parents[2]
root=Path(__file__).resolve().parent;(root/'assets').mkdir(exist_ok=True);(root/'compositions').mkdir(exist_ok=True)
# Two language editions share the same shot structure and real product states.
shots=[('import',0,4,'video-1.png',1.0,50,50),('lookup',4,5,'video-2.png',1.2,70,41),('edit',9,4,'video-3.png',1.12,58,45),('compare',13,5,'confirmation.png',1.0,50,50),('rename',18,5,'video-4.png',1.17,72,52),('warm',23,3,'05.png',1.0,50,50),('dark',26,3,'06.png',1.0,50,50)]
(root/'SPEC.md').write_text('''GOAL: Show a PDF moving through the actual four-step workspace, with current-versus-proposed metadata review and a readable filename as the payoff.
OUTPUT: Two App Store previews, zh-Hans and en-US, 1920x1080, 30 fps, H.264; 29 seconds (870 frames).
LOOK: Actual production SwiftUI views, no invented controls. Neutral #eef2f6 only outside the native comparison sheet. Product UI fills the canvas; no added slogans or mock devices.
SOURCE: Native NSHostingView captures of production views and controlled demo data. These are application-view captures, not a desktop screen recording. No book body pages included.
MOTION: Adapt registry ui-focus-zoom camera law; one anchored move at 0.7 seconds, power2.inOut, 0.6 seconds, then a still reading hold. No halo, drift, or animated fake clicks.
SHOTS: 0-4 import; 4-9 candidate record; 9-13 fields; 13-18 actual confirmation sheet; 18-23 filename; 23-26 warm theme; 26-29 dark theme.
SOUND: Deliberately silent; designed for muted App Store autoplay. No voiceover, unlicensed music, or synthesized effects.
BANNED: Fake product UI, fake cursor interactions, claims of a completed external search, logo end cards replacing functionality, decorative motion, tiny centered windows.
QA: Inspect every shot midpoint, before/after each cut, and full file duration/codec/resolution. Still holds are intentional reading time.
''')
(root/'STORYBOARD.md').write_text('\n'.join(f'## Frame {i+1}: {name}\n- {start}-{start+duration}s\n- Actual production view: {file}\n- Camera: ui-focus-zoom registry component, halo/drift removed\n' for i,(name,start,duration,file,*_) in enumerate(shots)))
for locale in ['en-US','zh-Hans']:
 d=root/'assets'/locale;d.mkdir(exist_ok=True)
 for f in ['video-1.png','video-2.png','video-3.png','video-4.png','05.png','06.png','confirmation.png']:shutil.copy2(repo/'dist/1.5.0/captures'/locale/f,d/f)
 hosts=[]
 for name,start,duration,file,zoom,ax,ay in shots:
  id=f'{locale.lower()}-{name}';hosts.append(f'<div id="{id}" class="clip" data-composition-id="{id}" data-composition-src="compositions/{id}.html" data-start="{start}" data-duration="{duration}" data-track-index="1" data-track-kind="graphics" data-width="1920" data-height="1080"></div>')
  fit='contain' if name in ['compare','warm','dark'] else 'cover'
  tx=max(-50*(zoom-1),min(50*(zoom-1),-(ax-50)*zoom));ty=max(-50*(zoom-1),min(50*(zoom-1),-(ay-50)*zoom))
  # Source identity and camera transform come from ui-focus-zoom. All skeleton UI is removed.
  html=f'''<template><style>#root{{position:absolute;inset:0;overflow:hidden;background:#eef2f6}}.world{{position:absolute;inset:0;transform-origin:50% 50%}}.screen{{display:block;width:100%;height:100%;object-fit:{fit}}}</style>
<div id="root" data-composition-id="{id}" data-duration="{duration}" data-width="1920" data-height="1080"><div id="{id}-surface" class="clip" data-start="0" data-duration="{duration}" data-track-index="0" data-hold="true" data-beat="Actual app: {name}"><div class="world"><img id="{id}-screen" class="screen" src="assets/{locale}/{file}" alt="Actual PDF Librarian {name} view, demonstration library" data-var-src="{id}-source"></div></div></div>
<script>const tl=gsap.timeline({{paused:true}});tl.fromTo('.world',{{scale:1,xPercent:0,yPercent:0}},{{scale:{zoom},xPercent:{tx},yPercent:{ty},duration:0.6,ease:'power2.inOut'}},0.7);window.__timelines['{id}']=tl;</script></template>'''
  (root/'compositions'/f'{id}.html').write_text(html)
 html='''<!doctype html><html lang="'''+('en' if locale=='en-US' else 'zh-CN')+'''"><head><meta charset="UTF-8"><script src="assets/gsap.min.js"></script><style>*{box-sizing:border-box;margin:0}html,body{width:1920px;height:1080px;overflow:hidden;background:#eef2f6}#root{width:100%;height:100%;position:relative}</style></head><body><div id="root" data-composition-id="main" data-start="0" data-duration="29" data-fps="30" data-width="1920" data-height="1080">'''+''.join(hosts)+'''</div><script>window.__timelines['main']=gsap.timeline({paused:true});</script></body></html>'''
 (root/f'{locale}.html.template').write_text(html)
shutil.copy2(root/'en-US.html.template',root/'index.html')
