"""Readable native SVG for Y/Delta: circuit topology, not a mechanical structure drawing."""
from pathlib import Path
import math
ROOT=Path(__file__).resolve().parents[1]
file=ROOT/'CraneExam/Resources/images/3-5_star_delta.svg'
backup=ROOT.parent/'tmp/glossary_revision_20261106/3-5_star_delta-before.svg'
if not backup.exists():backup.write_bytes(file.read_bytes())
s=['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 900 760" role="img" aria-labelledby="title desc">',
'<title id="title">スターデルタ始動の結線</title><desc id="desc">始動時は3本の巻線の一端を共通点へつなぐスター結線。通常運転は巻線を三角形につなぐデルタ結線。同じ電源でデルタで直接始動する場合と比べ、スター始動の電源電流と始動トルクは約3分の1。</desc>',
'<rect width="900" height="760" rx="18" fill="white"/>',
'<style>text{font-family:"Hiragino Kaku Gothic ProN","Yu Gothic",Meiryo,sans-serif;fill:#213b50}.heading{font-size:38px;font-weight:700}.sub{font-size:32px;font-weight:700}.label{font-size:28px}.note{font-size:26px;fill:#536776}.wire{fill:none;stroke:#324e60;stroke-width:4;stroke-linecap:round;stroke-linejoin:round}</style>',
'<text x="450" y="64" text-anchor="middle" class="heading">同じ3つの巻線を、つなぎ替える</text>',
'<text x="235" y="146" text-anchor="middle" class="sub">始動時：Y（スター）</text>',
'<text x="665" y="146" text-anchor="middle" class="sub">通常運転：Δ（デルタ）</text>']
def text(x,y,value,cls='label',anchor='middle'):
 s.append(f'<text x="{x}" y="{y}" text-anchor="{anchor}" class="{cls}">{value}</text>')
def line(a,b):s.append(f'<path class="wire" d="M{a[0]} {a[1]} L{b[0]} {b[1]}"/>')
def coil(a,b):
 # Four round coil humps along a local axis; leads remain continuous.
 dx,dy=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dy);theta=math.degrees(math.atan2(dy,dx))
 lead=(length-80)/2
 d=f'M0 0 H{lead}'
 for k in range(4):d+=' a10 10 0 0 1 20 0'
 d+=f' H{length}'
 s.append(f'<path class="wire" transform="translate({a[0]} {a[1]}) rotate({theta})" d="{d}"/>')
def terminal(x,y):s.append(f'<circle cx="{x}" cy="{y}" r="5" fill="#324e60"/>')
center=(235,340)
for a in [(125,230),(345,230),(235,460)]:coil(a,center);terminal(*a)
terminal(*center)
text(125,212,'L1');text(345,212,'L2');text(235,500,'L3')
line(center,(325,350));text(335,360,'共通点',anchor='start')
a,b,c=(665,224),(550,440),(780,440)
for p,q in [(a,b),(b,c),(c,a)]:coil(p,q)
for x,y in [a,b,c]:terminal(x,y)
line(a,(665,190));text(665,180,'L1')
line(b,(510,440));text(503,451,'L2',anchor='end')
line(c,(820,440));text(828,451,'L3',anchor='start')
text(235,555,'巻線の一端を、1か所に集める','note')
text(665,555,'巻線を、三角形につなぐ','note')
s.append('<path d="M434 325 H470 M460 314 L473 325 L460 336" class="wire"/>')
text(450,655,'Y始動では、電源電流・始動トルクは約1/3','sub')
text(450,705,'Δで直接始動する場合と比較。図は接続の原理。','note')
s.append('</svg>')
file.write_text('\n'.join(s)+'\n',encoding='utf-8',newline='\n')
print(file)
