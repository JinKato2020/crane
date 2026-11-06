"""Editable conceptual diagrams. Native SVG, not replacement technical renders."""
from pathlib import Path
from html import escape
import math
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'crane-app/CraneExam/Resources/images'
NAVY='#203d53';BLUE='#2d769c';GOLD='#ba8033';GRAY='#718390'
def text(x,y,s,size=32,color=NAVY,anchor='start',weight=500):
    return f'<text x="{x}" y="{y}" font-size="{size}" fill="{color}" text-anchor="{anchor}" font-weight="{weight}">{escape(s)}</text>'
def line(x1,y1,x2,y2,color=NAVY,width=4,arrow=False):
    return f'<path d="M{x1},{y1} L{x2},{y2}" fill="none" stroke="{color}" stroke-width="{width}"'+(' marker-end="url(#arrow)"' if arrow else '')+'/>'
def box(x,y,w,h,fill='#f0f5f8',stroke='#d4dfe6'):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="{fill}" stroke="{stroke}" stroke-width="2"/>'
def save(name,h,title,body):
    svg=f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 {h}" role="img" aria-label="{escape(title)}"><title>{escape(title)}</title><defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="5" orient="auto" markerUnits="userSpaceOnUse"><path d="M0,0 L10,5 L0,10" fill="{BLUE}"/></marker></defs><rect width="1000" height="{h}" fill="white"/><g font-family="Meiryo, sans-serif">{text(500,76,title,40,anchor='middle',weight=700)}{body}</g></svg>'''
    (OUT/name).write_text(svg+'\n','utf-8')

b=text(500,122,'電気の向きをそろえ、でこぼこをならす',28,GRAY,'middle')
for n,(label,desc,base) in enumerate([('交流','＋と−が交互',300),('整流した後','一方向の脈流',555),('平滑化した後','脈打ちを小さく',810)]):
    b+=text(75,base-57,label,34,weight=700)+text(75,base-8,desc,28,GRAY)
    b+=line(365,base,920,base,'#a7b6bf',2)+text(345,base+10,'0',24,GRAY,'end')
    b+=line(375,base-105,375,base+95,'#a7b6bf',2)
    pts=[]
    for j in range(251):
        x=380+j*2.08;t=j/250*4*math.pi
        v=math.sin(t) if n==0 else abs(math.sin(t)) if n==1 else .86+.10*math.cos(2*t)
        pts.append(f'{x:.1f},{base-78*v:.1f}')
    b+=f'<polyline points="{" ".join(pts)}" fill="none" stroke="{BLUE}" stroke-width="5"/>'
    if n<2:b+=line(610,base+125,610,base+150,BLUE,4,True)
b+=text(915,930,'時間 →',26,GRAY,'end')
save('3-1_rectify_smooth_20261106.svg',980,'整流と平滑化は、別の働き',b)

b=text(500,130,'まず、枝分かれしている部分をまとめる',30,GRAY,'middle')
# Ordinary circuit schematic: 100 ohms in series with two parallel branches.
b+=text(90,365,'A',36,weight=700)+text(910,365,'B',36,weight=700)
b+=line(100,405,190,405)+line(320,405,440,405)+line(440,270,440,540)+line(800,270,800,540)+line(800,405,915,405)
for y in [270,540]:
    b+=line(440,y,550,y)+line(680,y,800,y)
    b+=f'<rect x="550" y="{y-24}" width="130" height="48" fill="#edf2f5" stroke="{NAVY}" stroke-width="3"/>'
b+='<rect x="190" y="381" width="130" height="48" fill="#edf2f5" stroke="'+NAVY+'" stroke-width="3"/>'
for x,y in [(100,405),(440,405),(800,405),(915,405)]:b+=f'<circle cx="{x}" cy="{y}" r="6" fill="{NAVY}"/>'
b+=text(255,355,'100Ω',36,anchor='middle',weight=700)+text(615,220,'200Ω',36,anchor='middle',weight=700)+text(615,605,'600Ω',36,anchor='middle',weight=700)
b+=box(70,685,860,100)+text(500,746,'200Ω と 600Ω は並列。100Ω はその外側。',30,anchor='middle')
save('3-2_mixed_practice_20261106.svg',840,'合成抵抗を、自分で求めよう',b)

b=text(500,135,'全部が軸の仕事になるわけではない',30,GRAY,'middle')
b+=text(100,240,'入力 8kW',38,weight=700)+box(100,270,800,95,'#e4eff5',BLUE)+text(500,331,'電気で受け取る',32,BLUE,'middle')
b+=line(500,390,500,440,BLUE,5,True)
b+=box(100,480,600,120,'#e4eff5',BLUE)+box(700,480,200,120,'#faf0df',GOLD)
b+=text(400,530,'出力 6kW',36,BLUE,'middle',700)+text(400,575,'軸を回す仕事',30,BLUE,'middle')
b+=text(800,530,'損失',32,GOLD,'middle',700)+text(800,575,'2kW',34,GOLD,'middle',700)
b+=text(800,655,'熱などへ',28,GOLD,'middle')
b+=text(500,754,'効率 ＝ 6 ÷ 8 × 100 ＝ 75％',38,anchor='middle',weight=700)
save('3-3_motor_efficiency_20261106.svg',820,'入った電力を、仕事と損失に分ける',b)

b=text(500,130,'コースチングを備えた横行・走行の例',29,GRAY,'middle')
rows=[(190,'動かしている','モーター：通電','ブレーキ：緩む','駆動する力で進む'),(430,'1ノッチへ戻す','モーター：無通電','ブレーキ：緩む','惰走し、少しずつ減速'),(670,'0ノッチへ戻す','モーター：無通電','ブレーキ：かかる','ブレーキで停止する')]
for i,(y,head,motor,brake,desc) in enumerate(rows):
    b+=box(65,y,870,190,fill='#f1f6f8' if i==1 else '#fafbfc')
    b+=text(95,y+50,head,35,weight=700)+text(95,y+103,motor,31,BLUE)+text(505,y+103,brake,31,GOLD)
    b+=text(95,y+155,desc,31)
    if i<2:b+=line(500,y+205,500,y+225,BLUE,4,True)
b+=text(500,925,'1ノッチでは、ブレーキだけ通電して緩める。',31,BLUE,'middle',700)
save('3-4_coasting_20261106.svg',980,'惰走して減速 → ブレーキで停止',b)
print('Created 4 chapter 3 conceptual SVG diagrams.')
