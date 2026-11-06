"""Native calculation/concept diagrams; retain technical raster illustrations."""
from pathlib import Path
from html import escape
import math
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'crane-app/CraneExam/Resources/images'
NAVY='#203d53';BLUE='#2d769c';GOLD='#ba8033';GRAY='#718390';RED='#b74b42'
def text(x,y,s,size=32,color=NAVY,anchor='start',weight=500):
    return f'<text x="{x}" y="{y}" font-size="{size}" fill="{color}" text-anchor="{anchor}" font-weight="{weight}">{escape(s)}</text>'
def line(x1,y1,x2,y2,color=NAVY,width=4,arrow=False):
    return f'<path d="M{x1},{y1} L{x2},{y2}" fill="none" stroke="{color}" stroke-width="{width}"'+(f' marker-end="url(#{"red" if color==RED else "gold" if color==GOLD else "arrow"})"' if arrow else '')+'/>'
def box(x,y,w,h,fill='#f0f5f8',stroke='#d4dfe6'):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="{fill}" stroke="{stroke}" stroke-width="2"/>'
def dot(x,y,color=NAVY,r=6):return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{color}"/>'
def dim(x1,x2,y,label):
    return line(x1,y,x2,y,GRAY,2)+line(x1,y-9,x1,y+9,GRAY,2)+line(x2,y-9,x2,y+9,GRAY,2)+text((x1+x2)/2,y-16,label,30,anchor='middle')
def save(name,h,title,body):
    defs=''.join(f'<marker id="{id}" markerWidth="16" markerHeight="16" refX="13" refY="8" orient="auto" markerUnits="userSpaceOnUse"><path d="M0,0 L16,8 L0,16" fill="{color}"/></marker>' for id,color in [('arrow',BLUE),('red',RED),('gold',GOLD)])
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 {h}" role="img" aria-label="{escape(title)}"><title>{escape(title)}</title><defs>{defs}</defs><rect width="1000" height="{h}" fill="white"/><g font-family="Meiryo, sans-serif">{text(500,76,title,40,anchor="middle",weight=700)}{body}</g></svg>'
    (OUT/name).write_text(svg+'\n','utf-8')

# A 5-12-13 triangle drawn to scale; angle is explicitly at the horizontal side.
b=text(500,130,'辺の比は、三角形を大きくしても同じ',30,GRAY,'middle')
b+=line(160,460,820,460)+line(820,460,820,185,BLUE)+line(160,460,820,185,GOLD)
b+=line(790,460,790,430,GRAY,2)+line(790,430,820,430,GRAY,2)
b+=f'<path d="M255,460 A95,95 0 0 0 247.7,423.5" stroke="{BLUE}" fill="none" stroke-width="3"/>'
b+=text(280,438,'θ',35,BLUE)+text(490,505,'隣の辺 12',34,anchor='middle')+text(860,325,'5',36,BLUE)+text(860,368,'向かい',25,BLUE)
b+=text(440,280,'斜辺 13',34,GOLD)
b+=box(65,555,870,180)+text(500,610,'sinθ＝5/13　cosθ＝12/13',36,anchor='middle',weight=700)
b+=text(500,675,'tanθ＝5/12',36,anchor='middle',weight=700)
save('4-1_trig_ratios_20261106.svg',790,'sin・cos・tanは「辺の長さの比」',b)

# Book p154: A-C is 70 cm, not O-C. Dimensions share a consistent scale.
b=text(500,132,'長さは、すべて支点Oから読み直す',30,GRAY,'middle')
b+=dim(150,850,220,'A〜C：70cm')+dim(150,500,310,'35cm')+dim(500,850,310,'70−35＝35cm')+dim(500,700,395,'20cm')
b+=line(150,450,850,450,NAVY,10)
for x,label in [(150,'A'),(500,'O'),(700,'B'),(850,'C')]:b+=dot(x,450)+text(x,435 if label=='O' else 493,label,30,anchor='middle',weight=700)
b+='<path d="M500,455 L470,525 L530,525 Z" fill="#d8e4eb" stroke="#203d53" stroke-width="3"/>'
b+=text(500,565,'支点',30,anchor='middle')
for x,label,c in [(150,'30kg',BLUE),(700,'p kg',GOLD),(850,'10kg',BLUE)]:
    b+=line(x,510,x,615,c,5,True)+text(x,662,label,35,c,'middle',700)
b+=text(500,745,'右端の10kgの腕は、70cmではなく35cm。',31,anchor='middle')
save('4-1_balance_example5_20261106.svg',810,'例題5：支点からの距離で比べる',b)

# Equal and opposite forces acting at distinct lines of action create a couple.
b=text(500,130,'左右の力が、どちらも時計回りに働く',30,GRAY,'middle')
b+=f'<circle cx="500" cy="400" r="185" fill="#f8fafb" stroke="{NAVY}" stroke-width="13"/>'
b+=line(315,400,685,400,GRAY,10)+line(500,400,500,570,GRAY,10)+dot(500,400,NAVY,22)
b+=line(285,430,285,230,BLUE,7,True)+text(190,350,'同じ力',32,BLUE,'middle')
b+=line(715,370,715,570,BLUE,7,True)+text(815,460,'同じ力',32,BLUE,'middle')
b+=f'<path d="M444,305 A110,110 0 0 1 603,365" stroke="{GOLD}" stroke-width="6" fill="none" marker-end="url(#gold)"/>'
b+=text(500,700,'合力は0。でも、回す働きは残る。',35,anchor='middle',weight=700)
save('4-1_couple_20261106.svg',770,'偶力：2つの力でハンドルを回す',b)

# Tipping: rectangle 0.6 x 1.6 m. Rotate clockwise about its lower right corner.
b=text(500,132,'重心から下ろした線が、底面の端へ来るとき',29,GRAY,'middle')
b+=text(250,195,'直立しているとき',32,anchor='middle',weight=700)+text(750,195,'転倒し始める境目',32,anchor='middle',weight=700)
for offset,angle in [(0,0),(500,math.atan(.3/.8))]:
    px=310+offset;py=630;scale=220
    def tr(x,y):return (px+scale*(x*math.cos(angle)-y*math.sin(angle)),py+scale*(x*math.sin(angle)+y*math.cos(angle)))
    corners=[tr(-.6,0),tr(0,0),tr(0,-1.6),tr(-.6,-1.6)]
    b+=f'<polygon points="{" ".join(f"{x:.1f},{y:.1f}" for x,y in corners)}" fill="#eaf1f5" stroke="{NAVY}" stroke-width="3"/>'
    gx,gy=tr(-.3,-.8);b+=dot(gx,gy,GOLD,8)+text(gx-15,gy-18,'G',32,GOLD,'end')+dot(px,py,NAVY,7)+text(px+14,py+30,'P',30)
    b+=line(100+offset,py,440+offset,py,GRAY,3)
    b+=f'<path d="M{gx},{gy+14} V{py}" stroke="{BLUE}" stroke-width="3" stroke-dasharray="8 7"/>'
    if angle==0:
        b+=line(gx,gy,px,py,GOLD,3)+text(155,gy+100,'0.8m',27,BLUE,'end')+text((gx+px)/2,py+51,'0.3m',27,BLUE,'middle')
        b+=f'<path d="M{gx},{gy+70} A70,70 0 0 0 {gx+24.58},{gy+65.55}" stroke="{GOLD}" fill="none" stroke-width="3"/>'
        b+=text(gx+21,gy+130,'θ',26,GOLD,'middle')
    else:b+=text(750,730,'GがPの真上に来る',30,BLUE,'middle')
b+=text(250,730,'幅0.6m・高さ1.6m',28,GRAY,'middle')
b+=box(65,785,870,110)+text(500,853,'tanθ＝0.3÷0.8＝0.375',37,anchor='middle',weight=700)
save('4-3_tipping_triangle_20261106.svg',950,'倒れる角度は、重心と支点で考える',b)

# All three have equal downward gravity; upward arrow length encodes tension.
b=text(500,132,'同じ荷をつる。下向きの重力は変わらない',29,GRAY,'middle')
for x,label,L,caption in [(190,'上向きに加速',150,'張力 ＞ 重量'),(500,'加速度0',100,'張力 ＝ 重量'),(810,'下向きに加速',50,'張力 ＜ 重量')]:
    b+=text(x,205,label,31,anchor='middle',weight=700)+box(x-80,390,160,100)
    b+=line(x,375,x,375-L,BLUE,6,True)+text(x+28,320,'張力',27,BLUE)
    b+=line(x,505,x,605,RED,6,True)+text(x+28,565,'重量',27,RED)
    b+=text(x,685,caption,31,anchor='middle',weight=700)
b+=text(500,775,'巻下げを減速するときも、加速度は上向き。',31,anchor='middle')
save('4-4_tension_acceleration_20261106.svg',840,'ロープの負担は「加速度」で変わる',b)

# 70 degree sling on the left; 35 degree vector triangle at right.
b=text(500,132,'cos35°＝0.82なら、張力の82％が上向き',30,GRAY,'middle')
hx=265;hy=220;v=245;dx=v*math.tan(math.radians(35))
b+=line(hx-dx,hy+v,hx,hy,NAVY,5)+line(hx,hy,hx+dx,hy+v,NAVY,5)
b+=box(70,hy+v+5,390,90)+text(265,hy+v+62,'荷の重量 W',30,anchor='middle')
b+=f'<path d="M{hx},{hy} V{hy+v}" stroke="{GRAY}" stroke-width="2" stroke-dasharray="8 7"/>'
b+=f'<path d="M{hx-57.36},{hy+81.92} A100,100 0 0 0 {hx+57.36},{hy+81.92}" stroke="{GOLD}" fill="none" stroke-width="3"/>'
b+=text(hx,hy+133,'70°',31,GOLD,'middle')
b+=text(265,615,'片側は35°',32,anchor='middle',weight=700)
ox=610;oy=520;vx=250*math.tan(math.radians(35));vy=250
b+=line(ox,oy,ox+vx,oy-vy,GOLD,6,True)+line(ox,oy,ox,oy-vy,BLUE,5,True)
b+=f'<path d="M{ox},{oy-vy} H{ox+vx}" stroke="{GRAY}" stroke-width="2" stroke-dasharray="8 7"/>'
b+=f'<path d="M{ox},{oy-85} A85,85 0 0 1 {ox+48.75},{oy-69.63}" stroke="{GRAY}" fill="none" stroke-width="2"/>'
b+=text(650,390,'35°',28,anchor='middle')+text(700,235,'張力 T',32,GOLD)+text(590,340,'上向き',28,BLUE,'end')
b+=text(590,382,'0.82T',32,BLUE,'end')+text(750,615,'上向きの力＝W÷2',30,BLUE,'middle')
b+=box(65,680,870,145)+text(500,737,'必要な上向きの力を0.82で割る',33,anchor='middle',weight=700)+text(500,788,'T＝（W÷2）÷0.82',35,anchor='middle')
save('4-6_cos35_20261106.svg',885,'cosは「上向きに働く割合」',b)

b=text(500,132,'荷へ伝える仕事に、損失の分を足して入れる',30,GRAY,'middle')
b+=box(65,205,250,180)+text(190,265,'軸から入る',30,anchor='middle')+text(190,330,'7.84kW',40,BLUE,'middle',700)
b+=line(333,295,390,295,BLUE,6,True)+box(410,205,220,180)+text(520,265,'巻上げ機構',30,anchor='middle')+text(520,330,'効率75％',32,anchor='middle',weight=700)
b+=line(648,295,705,295,BLUE,6,True)+box(725,205,215,180)+text(832,265,'荷へ伝わる',29,anchor='middle')+text(832,330,'5.88kW',36,BLUE,'middle',700)
b+=line(520,405,520,470,GOLD,6,True)+text(520,530,'損失 1.96kW',35,GOLD,'middle',700)
b+=text(500,635,'必要な軸動力＝5.88÷0.75＝7.84kW',34,anchor='middle',weight=700)
save('4-7_efficiency_20261106.svg',705,'効率75％：入る動力の4分の3が届く',b)
print('Created 7 chapter 4 conceptual SVG diagrams.')
