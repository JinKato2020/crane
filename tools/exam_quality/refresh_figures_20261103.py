"""Import editable exam SVGs and render a consistent textbook-style set.

The original artwork stays untouched. New names also avoid stale image caches.
Run from the repository; the original source archive is in ../模試画像.
"""
from pathlib import Path
import json, re, math, xml.etree.ElementTree as E

REPO = Path(__file__).resolve().parents[2]
WORK = REPO.parent
OUT = REPO / 'tools/exam_quality/figures_20261103'
OUT.mkdir(exist_ok=True)
NS = 'http://www.w3.org/2000/svg'
E.register_namespace('', NS)
NAVY = '#1F3A65'
RED = '#C82D2D'
FONT = 'Yu Gothic, Meiryo, sans-serif'
def tag(t): return '{'+NS+'}'+t
def node(root, kind, **attrs):
    return E.SubElement(root, tag(kind), {k.replace('_','-'):str(v) for k,v in attrs.items()})
def label(root,x,y,value,size=22,color=NAVY,anchor='middle'):
    n=node(root,'text',x=x,y=y,font_size=size,fill=color,text_anchor=anchor,font_family=FONT)
    n.text=value
def arrow(root,x,y,xx,yy,color=NAVY):
    node(root,'line',x1=x,y1=y,x2=xx,y2=yy,stroke=color,stroke_width=3)
    a=math.atan2(yy-y,xx-x);c=math.cos(a);s=math.sin(a)
    points=[(xx,yy),(xx-13*c+5*s,yy-13*s-5*c),(xx-13*c-5*s,yy-13*s+5*c)]
    node(root,'polygon',points=' '.join(f'{a},{b}' for a,b in points),fill=color)
def vector(key,explanation):
    # Each pair of force/velocity arrows has one common scale, not arbitrary lengths.
    settings={'1-31':(6,8,'kN',10),'1-37':(.8,.6,'m/s',1),
              '3-31':(5,12,'kN',13),'6-21':(12,5,'kN',13),
              '9-35':(24,18,'m/min',30),'7-21':(12,24,'kN',25)}
    vx,vy,unit,result=settings[key]
    root=E.Element(tag('svg'),{'viewBox':'0 0 800 520'})
    node(root,'rect',width=800,height=520,fill='white')
    scale=min(390/vx,300/vy);ox,oy=240,390;xx=ox+vx*scale;yy=oy-vy*scale
    arrow(root,ox,oy,xx,oy);arrow(root,ox,oy,ox,yy)
    label(root,(ox+xx)/2,oy+38,f'{vx:g} {unit}')
    label(root,ox-28,(oy+yy)/2,('F₂ = ?' if key=='3-31' else f'{vy:g} {unit}'),anchor='end')
    label(root,ox-22,oy+30,'P' if key=='9-35' else 'O')
    node(root,'path',d=f'M{ox} {oy-20}h20v20',fill='none',stroke='#71869A',stroke_width=2)
    if key=='7-21':
        arrow(root,ox,oy,ox-5*scale,oy,RED);label(root,ox-5*scale-12,oy-15,'5 kN',anchor='end')
    if explanation or key=='3-31':
        arrow(root,ox,oy,xx,yy,RED)
        result_label=f'合成速度 {result:g} {unit}' if key in ['1-37','9-35'] else f'合力 {result:g} {unit}'
        label(root,(ox+xx)/2+45,(oy+yy)/2+22,result_label,color=RED,anchor='start')
    if key=='3-31' and explanation:label(root,400,470,'鉛直方向：√(13² − 5²) = 12 kN',color=RED)
    if key=='1-37':label(root,610,65,'継続時間 10秒')
    if key=='1-37' and explanation:label(root,400,470,'移動距離：1.0 × 10 = 10 m',color=RED)
    return root

es=json.loads((REPO/'CraneExam/Resources/exams.json').read_text(encoding='utf-8'))
names=sorted({q[f].removesuffix('_v20261103') for e in es for q in e['questions'] for f in ['figImg','figImgExp'] if q.get(f)})
# Retain the reviewed technical 3D assets. Their old line-art explanation counterparts
# are replaced with those same assets in revise_20261103.py.
skip={'exam_9-3_q','exam_6-10_q','exam_4-8_q','exam_10-3_q','exam_9-5_q',
      'exam_10-5_q','exam_11-3_q','exam_12-3_q','exam_12-3_e',
      'exam_3-10_q','exam_3-10_e','exam_12-5_q','exam_12-5_e',
      'exam_4-8_e','exam_8-3_e','exam_8-5_e','exam_9-3_e','exam_9-5_e',
      'exam_10-3_e','exam_10-5_e','exam_11-3_e'}
jobs=[]
for name in names:
    if name in skip or name.startswith('exam_quality_'):continue
    match=re.fullmatch(r'exam_(\d+)-(\d+)_([qe])',name)
    if not match:continue  # Textbook reuse and the separately generated 3D lay image.
    r,n,kind=match.groups();key=f'{r}-{n}'
    source=WORK/f'模試画像/第{r}回/SVG/{"回答前" if kind=="q" else "回答後"}/{key}.svg'
    root=E.parse(source).getroot()
    if key in ['1-31','1-37','3-31','6-21','7-21','9-35']:root=vector(key,kind=='e')
    if key=='5-9':
        # Radius identification does not need the old numerical/trigonometric guides.
        for el in list(root):
            if el.tag==tag('line'):
                x1,y1,x2,y2=[float(el.get(a,'0')) for a in ['x1','y1','x2','y2']]
                if min(y1,y2)>350 or (300<x1<345 and 250<y1<=315):root.remove(el)
    for el in root.iter():
        kind_name=el.tag.split('}')[-1]
        if key=='1-36' and kind_name=='text' and el.text and el.text.startswith('鋼'):
            el.set('y','240')  # Put material identification inside the solid, away from its outline.
        if key=='4-25' and kind_name=='text' and el.text=='1.0 m' and float(el.get('y','0'))<300:
            el.set('x','500');el.set('text-anchor','start')
        if key=='12-32':
            if kind_name=='line' and el.get('x1')=='460' and el.get('y2')=='186':el.set('y1','133')
            if kind_name=='text' and el.text=='6 kN':el.set('y','108')
        if key=='1-32' and kind=='e':
            if kind_name=='line' and el.get('x1')=='680' and el.get('y2')=='100':el.set('y2','160')
            if kind_name=='polygon' and el.get('points','').startswith('680,100'):el.set('points','680,160 675,172 685,172')
            if kind_name=='text' and el.text=='4 kN':el.set('y','175')
        if key=='4-26' and kind=='e':
            if kind_name=='line' and el.get('x1')=='240' and el.get('x2')=='110':el.set('x2','40')
            if kind_name=='polygon' and el.get('points','').startswith('110,285'):el.set('points','40,285 52,290 52,280')
    x,y,w,h=map(float,root.get('viewBox').split())
    pad=w*.035
    root.set('viewBox',f'{x-pad:g} {y-pad:g} {w+2*pad:g} {h+2*pad:g}')
    root.set('width','1600');root.set('height',str(round(1600*(h+2*pad)/(w+2*pad))))
    for el in root.iter():
        for attr in ['fill','stroke']:
            if el.get(attr) in ['black','#000','#000000']:el.set(attr,NAVY)
        if el.get('stroke-width') and float(el.get('stroke-width'))>0:
            el.set('stroke-width',str(max(float(el.get('stroke-width')),w*.0035)))
        if el.tag in [tag('text'),tag('g')] and (el.tag==tag('text') or el.get('font-family')):
            el.set('font-family',FONT)
            el.set('font-weight','600')
            if el.get('font-size'):el.set('font-size',str(max(float(el.get('font-size')),w*.026)))
        if el.tag==tag('text') and el.text:
            el.text=el.text.replace('A: length L, diameter d','A：長さ L、直径 d').replace('B: length 2L, diameter d/2','B：長さ 2L、直径 d/2')
            el.text=el.text.replace('10 kN (total)','合計 10 kN').replace('mu_k','μk').replace('R_B / R_A','抵抗B ÷ 抵抗A').replace('Req','合成抵抗')
            if key=='5-9' and el.text in ['ジブ10 m','60°','2 m','R = ?']:el.text=''
            if '°' in el.text:
                el.set('paint-order','stroke');el.set('stroke','white');el.set('stroke-width',str(w*.005));el.set('stroke-linejoin','round')
    target=OUT/(name+'_v20261103.svg')
    E.ElementTree(root).write(target,encoding='utf-8')
    jobs.append({'before':name,'after':target.stem,'source':str(source.relative_to(WORK)),'svg':target.name})
(OUT/'manifest.json').write_text(json.dumps(jobs,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Prepared',len(jobs),'editable diagrams')

if __name__=='__main__':
    from playwright.sync_api import sync_playwright
    with sync_playwright() as pw:
        browser=pw.chromium.launch(executable_path='C:/Program Files/Google/Chrome/Application/chrome.exe',headless=True)
        page=browser.new_page()
        clipped=[]
        for job in jobs:
            p=OUT/job['svg'];root=E.parse(p).getroot()
            page.set_viewport_size({'width':1600,'height':int(root.get('height'))})
            page.goto(p.as_uri());page.evaluate('document.fonts.ready')
            issues=page.evaluate('''() => Array.from(document.querySelectorAll('text')).filter(t=>t.textContent.trim()).flatMap(t=>{
                const b=t.getBoundingClientRect();
                return b.left<0 || b.top<0 || b.right>innerWidth+1 || b.bottom>innerHeight+1 ? [t.textContent] : [];
            })''')
            if issues:clipped.append({'figure':job['after'],'text':issues})
            page.screenshot(path=str(REPO/'CraneExam/Resources/images'/(job['after']+'.png')))
        browser.close()
    (OUT/'layout_check.json').write_text(json.dumps({'checked':len(jobs),'clippedText':clipped},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    assert not clipped,clipped
    print('Rendered',len(jobs),'diagrams')
