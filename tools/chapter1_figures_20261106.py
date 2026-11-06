"""Install reviewed image_gen assets and edit the existing SVG annotations.
Native concept diagrams keep their geometry and text editable.
"""
import base64, html, json, pathlib, shutil, xml.etree.ElementTree as E
from PIL import Image
ROOT=pathlib.Path(__file__).resolve().parents[2]
IM=ROOT/'crane-app/CraneExam/Resources/images'
BACK=ROOT/'tmp/ch1_revision_20261106/images';BACK.mkdir(exist_ok=True)
GEN=pathlib.Path('C:/Users/jwpsa/.codex/generated_images/01a14a5b-6e30-70c2-86f9-e75dbf7b4cda')
NS='http://www.w3.org/2000/svg';XL='http://www.w3.org/1999/xlink'
E.register_namespace('',NS);E.register_namespace('xlink',XL)
def backup(name):
    p=IM/name; dest=BACK/name
    if p.exists() and not dest.exists():shutil.copy2(p,dest)
    return dest
def install(src,dest):
    backup(dest);shutil.copy2(GEN/src,IM/dest)

installed={
 '1-7_end_fittings_20261106.png':'exec-5960f6cc-efa0-4a5b-b6dd-6dd1334dcddb.png',
 '1-9_supplement_f17_20261023.png':'exec-f47f21fe-604d-429d-a131-f413b37663cc.png',
 '1-11_supplement_f30_20261023.png':'exec-d9affba8-9467-4250-be68-bf38ebbc20ff.png',
 '1-4_supplement_f05_20261023.png':'exec-8c05647f-2cae-40e3-ad9c-89b24b472d08.png',
 '1-5_rigid_pin_legs_readable21.png':'exec-fa45c59a-07bb-4c14-a76e-36dddcc65675.png',
 '1-12_oil_bath_20261106.png':'exec-de4b6119-c45b-4ed6-ae4a-19548ecb2760.png',
 '1-15_fastener_check_20261106.png':'exec-e0aaaa03-f68c-416c-bf2d-cd315dc140cb.png',
 '1-9_couplings_20261106.png':'exec-184800b8-23dc-4ad4-a8c2-824ea429f1dd.png'}
for dest,src in installed.items():install(src,dest)

def local(tag):return tag.split('}')[-1]
def sub(root,tag,attrs=None,text=None):
    n=E.SubElement(root,'{'+NS+'}'+tag,{k:str(v) for k,v in (attrs or {}).items()})
    if text is not None:n.text=text
    return n
def label(root,x,y,text,size=52,color='#173650',anchor='middle'):
    return sub(root,'text',{'x':x,'y':y,'font-size':size,'font-weight':600,'fill':color,'text-anchor':anchor,'font-family':'-apple-system, Hiragino Sans, Meiryo, sans-serif'},text)
def read(name):
    r=E.parse(backup(name)).getroot()
    for n in list(r):
        if local(n.tag)=='style':r.remove(n)
    return r
def save(name,root):E.ElementTree(root).write(IM/name,encoding='utf-8',xml_declaration=False)
def root_svg(w,h,title):
    r=E.Element('{'+NS+'}svg',{'viewBox':f'0 0 {w} {h}','width':str(w),'height':str(h),'role':'img','aria-label':title})
    sub(r,'title',text=title);sub(r,'rect',dict(width=w,height=h,fill='white'))
    return r

# Keep the SVG entry point used by the glossary, embed the selected raster intact.
r=root_svg(1254,1254,'軸継手の種類')
raw=(IM/'1-9_couplings_20261106.png').read_bytes()
sub(r,'image',{'width':1254,'height':1254,'{'+XL+'}href':'data:image/png;base64,'+base64.b64encode(raw).decode()})
backup('1-9_couplings.svg');save('1-9_couplings.svg',r)

# Preserve the endpoint shared by lesson and glossary while improving the splice.
with Image.open(IM/'1-7_end_fittings_20261106.png') as im:w,h=im.size
r=root_svg(w,h,'ワイヤロープの末端処理')
raw=(IM/'1-7_end_fittings_20261106.png').read_bytes()
sub(r,'image',{'width':w,'height':h,'{'+XL+'}href':'data:image/png;base64,'+base64.b64encode(raw).decode()})
backup('1-7_end_fittings.svg');save('1-7_end_fittings.svg',r)

# Five motions: reuse the 3D illustration and add a visible vertical movement.
r=read('1-3.svg');r.set('viewBox','0 0 1440 1020');r.set('height','1020')
for n in list(r):
    if local(n.tag)!='text':continue
    t=n.text or ''
    if '４運動' in t or t.startswith(('青：','赤：')):r.remove(n);continue
    n.set('font-size','52');n.set('font-family','-apple-system, Hiragino Sans, Meiryo, sans-serif')
    if t=='クレーンの運動':n.text='クレーンの5つの基本運動';n.set('font-size','62')
    if t in ['走行','横行','起伏','旋回']:
        n.set('paint-order','stroke');n.set('stroke','white');n.set('stroke-width','8')
sub(r,'line',{'x1':680,'y1':445,'x2':680,'y2':620,'stroke':'#5360a4','stroke-width':9})
sub(r,'path',{'d':'M664 467 L680 443 L696 467 M664 598 L680 622 L696 598','fill':'none','stroke':'#5360a4','stroke-width':9,'stroke-linejoin':'round'})
for y,t in [(535,'巻上げ'),(596,'巻下げ')]:
    n=label(r,720,y,t,50,'#5360a4','start')
    n.set('paint-order','stroke');n.set('stroke','white');n.set('stroke-width','10')
save('1-3.svg',r)

# Lifting load: a readable numeric equation tied to the paragraph.
r=read('1-2_lifting_load.svg')
for n in list(r):
    if local(n.tag)!='text':continue
    t=n.text or ''; y=float(n.get('y','0'))
    if y>=950 or t in ['ジブを持たないクレーンでの関係','荷とつり具','荷重の内訳']:r.remove(n);continue
    n.set('font-size','48');n.set('font-family','-apple-system, Hiragino Sans, Meiryo, sans-serif')
    if t=='つり具（フックブロック）':n.text='つり具 0.5t';n.set('font-size','50')
    if t=='荷（定格荷重）':n.text='定格荷重 9.5t'
    if t=='定格荷重（荷）':n.text='9.5t'
    if t=='つり具':n.text='0.5t'
    if t=='つり上げ荷重':n.text='つり上げ荷重 10.0t';n.set('y','815')
label(r,720,1020,'10.0t − 0.5t ＝ 9.5t',68)
label(r,720,1110,'つり上げ荷重 − つり具分 ＝ 定格荷重',45)
save('1-2_lifting_load.svg',r)

# Existing angular arcs were present but faint; thicken them and shorten labels.
r=read('1-2_jib_radius.svg')
for n in list(r):
    tag=local(n.tag)
    if tag=='text':
        t=n.text or '';y=float(n.get('y','0'))
        if y>=1000 or t=='同じジブ長・同じ旋回中心で比較する':r.remove(n);continue
        n.set('font-size','50');n.set('font-family','-apple-system, Hiragino Sans, Meiryo, sans-serif')
        if t=='起伏角':n.text='傾斜角';n.set('font-size','46')
        if t=='高く起こした状態':n.text='起こす：半径は小さい';n.set('x','360');n.set('y','900')
        if t=='低く倒した状態':n.text='伏せる：半径は大きい';n.set('x','1035');n.set('y','900')
    if tag in ('path','line'):n.set('stroke-width','6')
label(r,720,1130,'傾斜角は、水平面から測る',60)
save('1-2_jib_radius.svg',r)

# Gear labels directly carry the same tooth counts used in the lesson.
r=read('1-9_two_stage_gear.svg');r.set('viewBox','0 0 2000 1500');r.set('height','1500')
for n in list(r):
    if local(n.tag)!='text':continue
    t=n.text or ''
    if t.startswith(('AがB','A：20歯','BとCは同軸')):r.remove(n);continue
    replacements={'A：入力ピニオン':'A：20歯','B：1段目ギヤ':'B：60歯','C：2段目ピニオン':'C：20歯','D：出力ギヤ':'D：60歯','B・Cは同じ軸':'BとCは同じ回転数'}
    n.text=replacements.get(t,t);n.set('font-size','80');n.set('font-family','-apple-system, Hiragino Sans, Meiryo, sans-serif')
    n.set('paint-order','stroke');n.set('stroke','white');n.set('stroke-width','10')
    if t=='D：出力ギヤ':n.set('x','1470')
label(r,1000,1435,'減速比 ＝ 3 × 3 ＝ 9',78)
save('1-9_two_stage_gear.svg',r)

# Minimal conceptual diagrams: exact editable vectors, not realism.
def line(r,x1,y1,x2,y2,color='#38546b',width=5,dash=None):
    a=dict(x1=x1,y1=y1,x2=x2,y2=y2,stroke=color,**{'stroke-width':width,'stroke-linecap':'round'})
    if dash:a['stroke-dasharray']=dash
    sub(r,'line',a)
def arrow(r,x1,y1,x2,y2,color='#257dae'):
    import math
    line(r,x1,y1,x2,y2,color,6);a=math.atan2(y2-y1,x2-x1)
    points=[(x2,y2),(x2-18*math.cos(a-.45),y2-18*math.sin(a-.45)),(x2-18*math.cos(a+.45),y2-18*math.sin(a+.45))]
    sub(r,'polygon',{'points':' '.join(f'{x},{y}' for x,y in points),'fill':color})

r=root_svg(1000,1040,'作業半径を水平な長さで求める')
label(r,500,70,'作業半径は、水平な長さを足す',43)
line(r,100,760,870,760,'#a4b4bf',3)
line(r,160,730,160,870,'#7e8f9b',3,'8 8');line(r,300,760,300,870,'#7e8f9b',3,'8 8')
# 70 drawing units / metre: offset=140, horizontal=350, jib=700.
tip_y=760-350*(3**0.5)
line(r,300,760,650,tip_y,'#38546b',10)
line(r,650,tip_y,650,870,'#a4b4bf',3,'8 8')
sub(r,'path',{'d':'M380 760 A80 80 0 0 0 340 690.718','fill':'none','stroke':'#d88932','stroke-width':6})
label(r,415,720,'60°',44,'#a45b1c');label(r,330,400,'ジブ 10m',44)
label(r,150,935,'旋回中心',36);label(r,300,810,'支点',36)
arrow(r,160,865,300,865);label(r,230,850,'2m',40)
arrow(r,300,865,650,865);label(r,475,850,'5m',40)
label(r,500,1000,'2 ＋ 10 × 0.5 ＝ 7m',46)
label(r,800,400,'cos60°',40);label(r,800,455,'＝ 0.5',40)
save('1-2_radius_projection_20261106.svg',r)

def notch(name,title,states,footer):
    r=root_svg(1000,1120,title);label(r,500,75,title,47)
    for k,(heading,tx,lx,action,desc) in enumerate(states):
        y=130+k*290
        sub(r,'rect',dict(x=30,y=y,width=940,height=260,rx=18,fill='#f3f7fa'))
        label(r,65,y+48,f'{k+1}  {heading}',38,anchor='start')
        line(r,110,y+100,550,y+100,'#a2b6c6',7)
        sub(r,'rect',dict(x=tx-48,y=y+60,width=96,height=48,rx=7,fill='#c9dce8',stroke='#38546b',**{'stroke-width':4}))
        sub(r,'circle',dict(cx=tx-27,cy=y+105,r=9,fill='#38546b'));sub(r,'circle',dict(cx=tx+27,cy=y+105,r=9,fill='#38546b'))
        line(r,tx,y+112,lx,y+215,'#38546b',5)
        sub(r,'rect',dict(x=lx-37,y=y+215,width=74,height=38,rx=4,fill='#e9c48f',stroke='#6e5840',**{'stroke-width':3}))
        line(r,tx,y+120,tx,y+210,'#a2b6c6',2,'7 7')
        label(r,620,y+110,action,42,'#257dae',anchor='start')
        for j,t in enumerate(desc):label(r,620,y+164+j*48,t,35,anchor='start')
        if k in (0,2):arrow(r,490,y+70,570,y+70)
        if k==1:arrow(r,lx+45,y+232,lx+125,y+232,'#c96534')
    label(r,500,1060,footer,40)
    save(name,r)

notch('1-14_notch_start_20261106.svg','発進時：遅れた荷を待つ',[
 ('動き始め',350,265,'運転する',['台車が先に動く','荷は後ろに残る']),
 ('いったん待つ',350,320,'停止・減速',['荷が追いつく','鉛直になる前…']),
 ('荷に合わせる',410,410,'再び運転',['進行方向へ動かし','振れを抑える'])], '青：台車の操作　橙：荷の動き')
notch('1-14_notch_stop_20261106.svg','停止時：前へ進む荷に合わせる',[
 ('目標の少し手前',300,300,'いったん切る',['台車を止める','荷は進み続ける']),
 ('荷が前へ進む',300,370,'振り切れる前',['荷が戻るまで','待たない']),
 ('少し追いかける',360,360,'入れて、すぐ切る',['進行方向へ短く','動かして止める'])], '荷が振り切れる前に、短く入れる')

record={'generated':installed,'svg_edited':['1-3.svg','1-2_lifting_load.svg','1-2_jib_radius.svg','1-9_two_stage_gear.svg','1-9_couplings.svg','1-7_end_fittings.svg'],'svg_added':['1-2_radius_projection_20261106.svg','1-14_notch_start_20261106.svg','1-14_notch_stop_20261106.svg']}
(ROOT/'crane-app/docs/reviews/chapter1-revision-assets-20261106.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),'utf-8')
print(json.dumps({'generated':len(installed),'edited_svg':len(record['svg_edited']),'new_svg':len(record['svg_added'])}))
