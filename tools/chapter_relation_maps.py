"""Generate all four relationship maps, with labelled edges and source checks.

python tools/chapter_relation_maps.py          # generate and validate SVGs
python tools/chapter_relation_maps.py --render # also render local PNG previews
Does not build iOS or publish content. Requires Pillow; --render needs Playwright/Chrome.
"""
from __future__ import annotations
import argparse
from dataclasses import dataclass, asdict
from html import escape
import json
from pathlib import Path
import xml.etree.ElementTree as ET
from PIL import ImageFont

APP = Path(__file__).resolve().parents[1]
OUT = APP / 'docs/design/relation-maps-20261107'
IMAGES = APP / 'CraneExam/Resources/images'
BLUE, TEAL, GOLD = '#286897', '#287E70', '#9B6B27'
INK, MUTED, LINE = '#19374C', '#506777', '#D8E3E9'
TINTS = {BLUE: '#F0F6FB', TEAL: '#EEF7F4', GOLD: '#FBF6EB'}
FONTS = {b: {s: ImageFont.truetype(f'C:/Windows/Fonts/{"meiryob" if b else "meiryo"}.ttc', s)
             for s in [22,24,26,28,30,32,46]} for b in [False,True]}

@dataclass
class Node:
    id: str
    x: int
    y: int
    w: int
    h: int
    title: str
    lines: list[str]
    color: str
    refs: list[str]

class Map:
    def __init__(self, chapter, height, title, subtitle, legend):
        self.chapter, self.height = chapter, height
        self.nodes, self.edges, self.labels = [], [], []
        self.connections, self.content = [], []
        self.refs = set()
        self.title, self.subtitle = title, subtitle
        self.text(64,72,f'第{chapter}章  /  全体のつながり',24,BLUE,True)
        self.text(64,139,title,46,INK,True)
        self.text(64,188,subtitle,26,MUTED)
        self.text(64,height-38,legend,22,MUTED)

    def text(self,x,y,value,size=24,color=INK,bold=False,anchor='start',layer=None,max_width=None):
        width=FONTS[bold][size].getlength(value)
        left=x if anchor=='start' else x-width/2 if anchor=='middle' else x-width
        top,bottom=y-size,y+size*.24
        assert 26<=left and left+width<=1654, ('Text outside canvas',value,left,width)
        assert 20<=top and bottom<self.height-10, ('Vertical overflow',value)
        if max_width:
            assert width<=max_width, ('Text too wide',value,width,max_width)
        self.labels.append((left,top,left+width,bottom,value))
        (self.content if layer is None else layer).append(f'<text x="{x}" y="{y}" text-anchor="{anchor}" font-size="{size}" font-weight="{700 if bold else 400}" fill="{color}">{escape(value)}</text>')

    def rect(self,x,y,w,h,fill,stroke=LINE,radius=20,layer=None):
        (self.content if layer is None else layer).append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}" fill="{fill}" stroke="{stroke}" stroke-width="2"/>')

    def node(self,id,x,y,w,h,title,lines,color=BLUE,refs=(),size=30):
        assert all(n.id!=id for n in self.nodes), id
        n=Node(id,x,y,w,h,title,lines,color,list(refs))
        self.nodes.append(n)
        self.refs.update(refs)
        self.rect(x,y,w,h,TINTS[color])
        self.content.append(f'<path d="M{x+24} {y+24}H{x+65}" stroke="{color}" stroke-width="5"/>')
        self.text(x+24,y+67,title,size,color,True,max_width=w-48)
        for i,line in enumerate(lines):
            self.text(x+24,y+108+i*35,line,24,max_width=w-48)
        assert y+108+(len(lines)-1)*35+12<=y+h-18, ('Node too short',id)

    def edge(self,source,target,points,label,at,color=BLUE,dashed=False,size=22):
        self.edges.append(dict(source=source,target=target,relation=label,points=points,dashed=dashed))
        color_id={BLUE:'blue',TEAL:'teal',GOLD:'gold'}[color]
        d='M'+' L'.join(f'{x},{y}' for x,y in points)
        dash=' stroke-dasharray="9 8"' if dashed else ''
        self.connections.append(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{3 if dashed else 4}"{dash} marker-end="url(#{color_id})"/>')
        x,y=at
        width=FONTS[True][size].getlength(label)
        self.rect(x-width/2-10,y-size-6,width+20,size+16,'white','white',8,self.connections)
        self.text(x,y,label,size,color,True,'middle',self.connections)

    def heading(self,y,title,color=BLUE):
        self.text(64,y,title,28,color,True)

    def save(self,book):
        ch=next(c for c in book['chapters'] if c['id']==self.chapter)
        valid={s['id'] for s in ch['sections']}
        core=valid-{f'{self.chapter}-0',f'{self.chapter}-matome'}
        assert self.refs<=valid and core<=self.refs, ('References',core-self.refs,self.refs-valid)
        ids={n.id for n in self.nodes}
        assert all(e['source'] in ids and e['target'] in ids for e in self.edges)
        assert ids<={e[k] for e in self.edges for k in ['source','target']}, 'Disconnected node'
        for i,a in enumerate(self.labels):
            for b in self.labels[i+1:]:
                assert min(a[2],b[2])<=max(a[0],b[0]) or min(a[3],b[3])<=max(a[1],b[1]), ('Text overlap',a[4],b[4])
        for i,a in enumerate(self.nodes):
            for b in self.nodes[i+1:]:
                assert min(a.x+a.w,b.x+b.w)<=max(a.x,b.x) or min(a.y+a.h,b.y+b.h)<=max(a.y,b.y), ('Node overlap',a.id,b.id)
        for e in self.edges:
            for a,b in zip(e['points'],e['points'][1:]):
                assert a[0]==b[0] or a[1]==b[1], ('Non-orthogonal edge',e)
                for n in self.nodes:
                    crosses=(a[0]==b[0] and n.x<a[0]<n.x+n.w and max(min(a[1],b[1]),n.y)<min(max(a[1],b[1]),n.y+n.h)) or (a[1]==b[1] and n.y<a[1]<n.y+n.h and max(min(a[0],b[0]),n.x)<min(max(a[0],b[0]),n.x+n.w))
                    assert not crosses, ('Edge passes through node',e['relation'],n.id)
        metadata={'chapter':self.chapter,'design':'labelled-relationships-v2','sectionReferences':sorted(self.refs),
                  'nodes':[asdict(n) for n in self.nodes],'relationships':self.edges}
        defs=''.join(f'<marker id="{i}" viewBox="0 0 12 12" refX="11" refY="6" markerWidth="16" markerHeight="16" orient="auto-start-reverse" markerUnits="userSpaceOnUse"><path d="M1 1L11 6L1 11Z" fill="{c}"/></marker>' for i,c in [('blue',BLUE),('teal',TEAL),('gold',GOLD)])
        desc=self.subtitle+'。'+'。'.join(e['relation'] for e in self.edges)
        raw='\n'.join([f'<svg xmlns="http://www.w3.org/2000/svg" width="1680" height="{self.height}" viewBox="0 0 1680 {self.height}" role="img" aria-labelledby="title desc">',
            f'<title id="title">第{self.chapter}章 {escape(self.title)}</title>',f'<desc id="desc">{escape(desc)}</desc>',
            '<metadata>'+escape(json.dumps(metadata,ensure_ascii=False))+'</metadata>','<defs>'+defs+'</defs>',
            f'<rect width="1680" height="{self.height}" fill="white"/>',"<g font-family=\"'Hiragino Sans', Meiryo, sans-serif\" stroke-linecap=\"round\" stroke-linejoin=\"round\">",
            *self.connections,*self.content,'</g></svg>',''])
        ET.fromstring(raw)
        (IMAGES/f'chapter{self.chapter}_relation_map.svg').write_text(raw,encoding='utf-8',newline='\n')
        return dict(chapter=self.chapter,nodes=len(self.nodes),relationships=len(self.edges),sectionReferences=sorted(self.refs),size=[1680,self.height],minimumFontSize=22,geometryChecks='passed')

def chapter1():
    m=Map(1,1550,'クレーンは、どうやって荷を動かす？',
          '青は「動かす道」、緑は「重さを支える道」。同じ装置を、2つの役割から見る。',
          '実線＝動き・力が伝わる道　／　破線＝安全を保つ働き・しくみの補足')
    m.node('before',64,250,420,175,'運転前の確認',['荷・作業範囲・合図を確認','定格荷重などの能力を守る'],GOLD,['1-2','1-14'])
    m.node('safety',620,250,440,175,'ブレーキ・安全装置',['停止・保持／巻過ぎの防止など','それぞれが違う危険を防ぐ'],GOLD,['1-10','1-11'])
    m.node('care',1196,250,420,175,'点検・給油',['摩耗・断線・ゆるみを見つける','動く部分の状態を保つ'],GOLD,['1-12'])
    m.node('motor',64,570,300,180,'電動機',['回転を生む'],BLUE,['1-6'])
    m.node('gears',482,570,300,180,'歯車・軸',['回転を伝える','回転速度を変える'],BLUE,['1-9'])
    m.node('drum',900,570,300,180,'ドラム',['ロープを巻き取る'],BLUE,['1-13'])
    m.node('load',1318,570,298,180,'荷',['ロープ・つり具を介し','荷が上がる・下がる'],BLUE,['1-7','1-8'])
    m.edge('motor','gears',[(364,655),(482,655)],'回転',(423,624))
    m.edge('gears','drum',[(782,655),(900,655)],'回転',(841,624))
    m.edge('drum','load',[(1200,655),(1318,655)],'巻取り',(1259,624))
    m.edge('before','motor',[(274,425),(274,455),(214,455),(214,570)],'巻上げ前に確認',(274,475),GOLD,True)
    m.edge('safety','drum',[(840,425),(840,450),(1050,450),(1050,570)],'停止・保持・制限',(1050,458),GOLD,True)
    m.edge('care','load',[(1406,425),(1406,450),(1467,450),(1467,570)],'状態を確認',(1467,458),GOLD,True)
    m.heading(898,'荷の重さは、ロープから骨組み、建物や地盤へ伝わる',TEAL)
    m.node('ground',64,970,300,207,'建物・地盤へ',['車輪・走路・支柱など','を介して支える'],TEAL,['1-5'])
    m.node('frame',482,970,300,207,'骨組み',['ガーダ・ジブなど','荷重を支える構造'],TEAL,['1-5'])
    m.node('support',900,970,300,207,'機械の支持部',['ドラム・シーブなどの','軸や支持部で受ける'],TEAL,['1-9','1-13'])
    m.node('rope',1318,970,298,207,'ロープ・シーブ',['ロープに張力が働く','シーブで向きを変える'],TEAL,['1-7','1-13'])
    m.edge('load','rope',[(1467,750),(1467,970)],'荷重を伝える',(1467,821),TEAL)
    for a,b,x1,x2 in [('rope','support',1318,1200),('support','frame',900,782),('frame','ground',482,364)]:
        m.edge(a,b,[(x1,1074),(x2,1074)],'荷重',((x1+x2)//2,1043),TEAL)
    m.node('types',64,1315,1552,150,'形が変わると、支え方と動ける方向が変わる',
           ['天井クレーン・橋形クレーン・ジブクレーンなどを、この2つの道で見比べよう。'],TEAL,['1-0','1-1','1-3','1-4','1-15'],32)
    m.edge('types','frame',[(632,1315),(632,1177)],'機種ごとに形が変わる',(632,1252),TEAL,True)
    return m

def chapter2():
    m=Map(2,1670,'法令は「いつ、何をするか」でつなぐ',
          '準備して使い始め、点検しながら使い続ける。異常や変更があれば、対応が必要。',
          '具体的な数字は「対象・条件・以上／未満」と一緒に本文で確認。図は手続きの関係を示す。')
    m.node('classify',64,270,400,207,'クレーンを区分する',['つり上げ荷重・種類を確認','操作方式も資格の区分に関係'],BLUE,['2-0','2-1','2-6'])
    m.node('install',620,270,420,207,'製造・設置の手続き',['対象に応じた許可・届出','使い始める前に所定の検査'],BLUE,['2-1'])
    m.node('ready',1196,270,420,244,'使用開始の条件を整える',['検査証の対象なら取得','設備・設置場所の基準も確認','作業開始前の点検も実施'],BLUE,['2-1','2-3'],28)
    m.edge('classify','install',[(464,374),(620,374)],'対象で決まる',(542,338))
    m.edge('install','ready',[(1040,374),(1196,374)],'準備を整える',(1118,338))
    m.node('people',64,690,420,244,'資格と用具を確認',['運転と玉掛けの資格は別','荷に合う玉掛用具を選ぶ','損傷・強度などの基準を守る'],GOLD,['2-5','2-6'])
    m.node('use',1196,690,420,244,'安全に使う',['定格荷重などの能力を守る','合図・立入禁止・運転位置','強風などで危険なら作業中止'],TEAL,['2-2'])
    m.edge('classify','people',[(264,477),(264,690)],'運転資格の区分も確認',(264,592),GOLD)
    m.edge('people','use',[(484,812),(1196,812)],'人と用具の条件も満たす',(840,798),GOLD)
    m.edge('ready','use',[(1406,514),(1406,690)],'条件が整ってから使用',(1406,592),TEAL)
    m.node('inspect',1196,1190,420,281,'点検・検査を繰り返す',['作業開始前・月次・年次','暴風・地震の後も条件に応じ実施','定期検査・暴風後等の記録は3年','作業開始前点検は保存規定外'],TEAL,['2-3'],28)
    m.node('repair',650,1190,370,207,'直ちに補修',['異常を放置しない','補修して安全を確かめる'],GOLD,['2-3'])
    m.edge('use','inspect',[(1406,934),(1406,1190)],'使い続ける間も確認',(1406,1070),TEAL)
    m.edge('inspect','repair',[(1196,1294),(1020,1294)],'異常あり',(1108,1257),GOLD)
    m.edge('repair','use',[(835,1190),(835,1005),(1140,1005),(1140,875),(1196,875)],'補修・安全確認後に使用',(902,1037),GOLD)
    m.node('change',64,1190,420,318,'更新・変更・休止・廃止',['検査証の更新には性能検査','設備の変更 → 所定の手続き','検査証の期限を超える休止','→ 再開時に使用再開検査','廃止など → 検査証を返還'],BLUE,['2-4'],28)
    m.edge('use','change',[(1616,812),(1640,812),(1640,1565),(274,1565),(274,1508)],'設備や使用状況が変わる',(835,1550))
    return m

def chapter3():
    m=Map(3,1900,'電気が届く → 回る → 荷が動く',
          '電気の公式も、回転子も、制御も。「荷を動かす流れ」のどこに関わるかで整理する。',
          '実線＝電気・動き・しくみのつながり　／　破線＝安全を保つための働き')
    m.node('basics',64,270,700,281,'電流は、電圧と抵抗で決まる',[
        '電圧は押し流す働き、抵抗は流れにくさ','I＝V÷R：他の条件が同じなら',
        '電圧を上げると電流↑／抵抗を増やすと電流↓','直列：抵抗を足す　並列：全体の抵抗は小さくなる'],BLUE,['3-0','3-1','3-2'],32)
    m.node('energy',1090,270,526,281,'電力と電力量',['電力：電気を使う勢い〔W〕','直流では P＝V×I','電力量＝電力×時間〔Whなど〕','ジュール熱：電流が流れて生じる熱'],BLUE,['3-2'],32)
    m.edge('basics','energy',[(764,411),(1090,411)],'電圧と電流から求める',(927,394))
    m.node('supply',64,775,300,244,'電源・給電',['トロリ線やケーブル','などで、動く本体や','回転部へ電気を渡す'],BLUE,['3-5'])
    m.node('control',482,775,300,244,'制御器',['操作の指令に合わせ','電動機を運転する','直接制御／間接制御'],BLUE,['3-4'])
    m.node('motor',900,775,300,244,'電動機',['電気を使って','軸を回す'],TEAL,['3-3'])
    m.node('load',1318,775,298,244,'巻上げ装置・荷',['機械に回転を伝え','荷を動かす'],TEAL,['3-3'],28)
    m.edge('basics','supply',[(214,551),(214,775)],'流れる電気の基本',(214,637))
    m.edge('supply','control',[(364,897),(482,897)],'電気',(423,859))
    m.edge('control','motor',[(782,897),(900,897)],'電気',(841,859))
    m.edge('motor','load',[(1200,897),(1318,897)],'回転',(1259,859),TEAL)
    m.node('speed',64,1215,500,244,'速さ・回転方向を変える',['インバーター：周波数を変える','巻線形：二次抵抗でも調整','回転方向：三相のうち2本を入替え'],BLUE,['3-6'])
    m.node('inside',760,1215,856,281,'電動機の中では、何が起きる？',[
        '三相交流が、回転する磁界をつくる','回転子に誘導電流 → 磁界との作用で回す力が生まれる',
        'かご形・巻線形：回転子の構造が違う','通常の電動運転では、回転子は磁界より少し遅く回る'],TEAL,['3-1','3-3'],32)
    m.edge('control','speed',[(632,1019),(632,1120),(314,1120),(314,1215)],'動きの調整につながる',(390,1104))
    m.edge('motor','inside',[(1050,1019),(1050,1215)],'回転を生むしくみ',(1050,1120),TEAL)
    m.node('protect',64,1650,1552,150,'この流れを、安全に保つ',[
        '絶縁で漏電を防ぐ。接地や保護装置で異常に備える。測定・点検で劣化や異常を見つける。'],GOLD,['3-4','3-7'],32)
    m.edge('protect','supply',[(314,1650),(314,1530),(34,1530),(34,1080),(115,1080),(115,1019)],'給電から電動機までを保護',(314,1580),GOLD,True)
    return m

def chapter4():
    m=Map(4,1900,'重さが分かると、支え方と負担が分かる',
          '荷の重さを「力」に直して考える。つり合い、動き、ロープ、部材の強さはつながっている。',
          'まず働く力を描く。その後に「静かに支えるか」「動かすか」「何が力を受けるか」を考える。')
    m.node('volume',64,270,400,207,'形から、体積を求める',['中空なら「外側－内側」','形に合った体積の式を使う'],BLUE,['4-2'],28)
    m.node('mass',640,270,400,207,'質量 m〔kg〕',['物そのものの量','地球でも月でも同じ'],BLUE,['4-0','4-2'],32)
    m.node('weight',1216,270,400,207,'重量 W〔N〕',['重力によって下向きに働く力','W＝m×g'],BLUE,['4-0'],32)
    m.edge('volume','mass',[(464,374),(640,374)],'× 密度',(552,338))
    m.edge('mass','weight',[(1040,374),(1216,374)],'× 重力加速度 g',(1128,338))
    m.node('force',600,640,480,244,'働く力を描く',['大きさ・向き・作用点を確かめる','複数の力 → 1つの合力にまとめる','1つの力 → 向き別の分力に分ける'],BLUE,['4-1'],32)
    m.edge('weight','force',[(1416,477),(1416,555),(840,555),(840,640)],'荷に働く、下向きの力',(1128,539))
    m.node('motion',64,1050,440,281,'動きと抵抗',['加速度＝速度の変化÷時間','慣性：元の運動状態を保つ性質','円運動には中心向きの力が必要','摩擦は滑る動きを妨げる'],BLUE,['4-4'],32)
    m.node('balance',1176,1050,440,281,'静かに支える',['合力もモーメントの合計も0','モーメント＝力×垂直な腕の長さ','荷は重心の真上からつる','置いた物は重心と支持面で安定'],TEAL,['4-1','4-3'],32)
    m.edge('force','motion',[(600,762),(284,762),(284,1050)],'つり合わない力が動きを変える',(284,946))
    m.edge('force','balance',[(1080,762),(1396,762),(1396,1050)],'力と、回す働きがつり合う',(1396,946),TEAL)
    m.node('stress',64,1505,440,281,'部材が受ける負担',['引張り・圧縮・曲げ・ねじりなど','引張応力＝引張荷重÷断面積','縦ひずみ＝伸び÷もとの長さ','弾性：戻る／塑性：変形が残る','繰返す負担で疲労が進む'],GOLD,['4-5'])
    m.node('pulley',620,1505,440,281,'滑車・仕事',['定滑車は引く向きを変える','動滑車はロープで力を分担する','小さい力で長く引く（理想条件）','仕事＝力×その向きの移動距離','動力＝仕事÷時間'],BLUE,['4-7'],32)
    m.node('sling',1176,1505,440,281,'玉掛けロープ',['左右対称の2本で静かにつると','縦の分力＝片側で荷の重さの半分','同じ荷なら開くほど張力が増す','張力・モード係数で荷重を計算','安全係数で強さの余裕を確認'],TEAL,['4-6'],32)
    m.edge('motion','stress',[(284,1331),(284,1505)],'衝撃・繰返しも負担になる',(284,1425),GOLD)
    m.edge('force','pulley',[(840,884),(840,1505)],'必要な力と引く距離を考える',(840,1243))
    m.edge('balance','sling',[(1396,1331),(1396,1505)],'張力を分力に分けて考える',(1396,1425),TEAL)
    m.edge('sling','stress',[(1396,1786),(1396,1820),(284,1820),(284,1786)],'ロープや部材に働く力を、強さと照らす',(840,1828),GOLD)
    return m

def render(maps):
    from playwright.sync_api import sync_playwright
    with sync_playwright() as pw:
        browser=pw.chromium.launch(executable_path='C:/Program Files/Google/Chrome/Application/chrome.exe',headless=True)
        for m in maps:
            page=browser.new_page(viewport={'width':1680,'height':m.height},device_scale_factor=1)
            svg=(IMAGES/f'chapter{m.chapter}_relation_map.svg').read_text(encoding='utf-8')
            page.set_content('<!doctype html><meta charset="utf-8"><style>html,body{margin:0;background:white}svg{display:block}</style>'+svg)
            page.evaluate('document.fonts.ready')
            page.screenshot(path=str(OUT/f'chapter{m.chapter}.png'))
            page.set_viewport_size({'width':390,'height':900})
            page.add_style_tag(content='svg{max-width:100%;height:auto}')
            page.locator('svg').screenshot(path=str(OUT/f'chapter{m.chapter}-phone.png'))
            page.close()
        browser.close()

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--render',action='store_true')
    args=parser.parse_args()
    OUT.mkdir(parents=True,exist_ok=True)
    book=json.loads((APP/'CraneExam/Resources/textbook.json').read_bytes())
    maps=[chapter1(),chapter2(),chapter3(),chapter4()]
    report=[m.save(book) for m in maps]
    (OUT/'validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    if args.render:
        render(maps)
    print(json.dumps(report,ensure_ascii=False,indent=2))

if __name__=='__main__':
    main()
