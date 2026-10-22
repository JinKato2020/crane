"""Generate chapters 2-4 using chapter one's approved mind-map design.
Run from any directory: python tools/chapter_relation_maps.py
Requires Pillow and Chrome for visual previews. Does not build iOS.
"""
from pathlib import Path
from html import escape
import json, subprocess, tempfile
from PIL import ImageFont
import xml.etree.ElementTree as ET
APP=Path(__file__).resolve().parents[1]
OUT=APP.parent/'教材画像/相関図_第2-4章_20261023'
OUT.mkdir(parents=True,exist_ok=True)
CONFIGS={2: {'title': '関係法令',
     'center': '関係法令',
     'core': ['安全に働くための', 'ルールをつなぐ'],
     'branches': [('設置する前に',
                   [('対象を分ける', ['つり上げ荷重・種類で区分', '区分ごとに必要な手続き'], ['2-1']),
                    ('許可・届出', ['製造許可＝作る前', '設置届＝据え付け工事の前'], ['2-1']),
                    ('使い始める前', ['落成検査 → 検査証', '建物・歩道との間隔も確保'], ['2-1'])]),
                  ('使うときに',
                   [('能力を守る', ['定格荷重・ジブの角度を確認', '安全装置を有効に保つ'], ['2-2']),
                    ('人を守る', ['合図を決め、危険な立入りを防ぐ', '荷をつったまま運転位置を離れない'], ['2-2']),
                    ('風・修理対策', ['強風時は作業中止・逸走防止', '修理中の運転を防ぐ'], ['2-2'])]),
                  ('点検を続ける',
                   [('いつ調べる？', ['作業開始前・月次・年次'], ['2-3']),
                    ('特別な点検', ['暴風・地震の後も状態を確認'], ['2-3']),
                    ('異常への対応', ['直ちに補修する', '検査・点検記録を保存'], ['2-3'])]),
                  ('変える・やめる',
                   [('検査証の更新', ['性能検査 → 有効期間を更新'], ['2-4']),
                    ('設備の変更', ['変更内容に応じた届出・検査'], ['2-4']),
                    ('休止から廃止へ', ['使用再開には必要な検査', '廃止などでは検査証を返還'], ['2-4'])]),
                  ('玉掛用具を選ぶ',
                   [('強さの余裕', ['安全係数＝切断荷重÷最大荷重'], ['2-5']),
                    ('使用禁止を知る', ['断線・摩耗・変形・き裂を確認', '用具ごとに限度が違う'], ['2-5']),
                    ('使用前に確認', ['荷に合う用具を選ぶ', '作業開始前に用具を点検'], ['2-5'])]),
                  ('資格と読み方',
                   [('運転の資格', ['つり上げ荷重＋操作方式で決まる'], ['2-6']),
                    ('玉掛けの資格', ['運転資格とは別に確認する'], ['2-6']),
                    ('法令の読み方', ['だれが・いつ・何をするか', '数字＋以上・未満＋例外条件'], ['2-0'])])]},
 3: {'title': '原動機及び電気に関する知識',
     'center': '電気と電動機',
     'core': ['電気を届けて', '動きを生み出す'],
     'branches': [('電気の基本',
                   [('流れと抵抗', ['電流＝流れる量 ／ 電圧＝押す力', '抵抗＝流れにくさ', '水の流れにたとえて考える'], ['3-0', '3-1']),
                    ('直流と交流', ['直流＝向きが一定', '交流＝向きが周期的に変わる'], ['3-1']),
                    ('三相と周波数', ['三相＝タイミングがずれた交流', '周波数＝1秒間の繰返し数'], ['3-1'])]),
                  ('回路と電力',
                   [('オームの法則', ['電圧＝電流×抵抗'], ['3-2']),
                    ('直列と並列', ['直列＝一本道 ／ 抵抗を足す', '並列＝枝分かれ ／ 通りやすい'], ['3-2']),
                    ('使う電気と熱', ['電力＝1秒あたりのエネルギー', '電力量＝電力×時間', 'ジュール熱＝電流が生む熱'], ['3-2'])]),
                  ('回るしくみ',
                   [('磁界と回転子', ['回る磁界 → 誘導電流 → 回す力'], ['3-3']),
                    ('かご形・巻線形', ['どちらも電気で軸を回す', '回転子の作りが違う'], ['3-3']),
                    ('磁界と回転の差', ['同期速度＝磁界が回る速さ', '回転子は磁界より少し遅れる'], ['3-3'])]),
                  ('動きを操る',
                   [('制御器', ['ハンドル・ボタンで運転を指令', '直接制御 ／ 接触器で間接制御'], ['3-4']),
                    ('速度の調整', ['インバーターで周波数を変える', '巻線形は二次抵抗でも調整'], ['3-6']),
                    ('回転方向', ['三相のうち2本を入れ替える'], ['3-6'])]),
                  ('電気を届ける',
                   [('トロリ線給電', ['集電子が電線に触れて受電'], ['3-5']),
                    ('ケーブル給電', ['動く本体へケーブルを追従'], ['3-5']),
                    ('回転部への給電', ['スリップリングで電気を渡す'], ['3-5'])]),
                  ('電気を守る',
                   [('絶縁と接地', ['絶縁＝電気を外へ漏らさない', '接地＝漏れた電気の逃げ道'], ['3-7']),
                    ('保護装置', ['過負荷・短絡などを検出', '異常時に回路を遮断'], ['3-4']),
                    ('測定と点検', ['電圧・電流・絶縁抵抗を測る', '異音・発熱・接点の状態を確認'], ['3-7'])])]},
 4: {'title': 'クレーンの運転のために必要な力学に関する知識',
     'center': '力学',
     'core': ['荷に働く力から', '動きと安全を考える'],
     'branches': [('重さと力',
                   [('質量と重量', ['質量kg × 重力加速度 → 重量N', '月でも質量は同じ、重量は違う'], ['4-0']),
                    ('体積から質量', ['形から体積 → 密度を掛ける', '中空なら外側の体積−内側の体積'], ['4-2']),
                    ('力の三要素', ['大きさ・向き・作用点'], ['4-1'])]),
                  ('つり合いと安定',
                   [('合力と分力', ['複数の力をまとめる＝合成', '1つの力を向き別に分ける＝分解'], ['4-1']),
                    ('モーメント', ['回す働き＝力×垂直な腕の長さ', '長いスパナほど小さな力で回る'], ['4-1']),
                    ('重心と安定', ['荷は重心の真上からつる', '重心の真下が支持範囲内なら安定'], ['4-3'])]),
                  ('動きの変化',
                   [('速度と加速度', ['速さ＋向き＝速度', '加速度＝速度の変わり方'], ['4-4']),
                    ('慣性と円運動', ['急発進 → 荷は元の状態を保つ', '円運動には中心向きの力'], ['4-4']),
                    ('摩擦', ['静止中＝押す力とつり合う', '動き出す限界が最大静止摩擦力', '動いた後は動摩擦力'], ['4-4'])]),
                  ('材料への負担',
                   [('荷重のかかり方', ['引張り・圧縮・曲げ・ねじりなど', '一定・繰返し・衝撃でも分類'], ['4-5']),
                    ('応力とひずみ', ['応力＝力÷断面積', 'ひずみ＝伸び÷もとの長さ'], ['4-5']),
                    ('変形と疲労', ['弾性＝戻る ／ 塑性＝変形が残る', '繰返す負担 → 疲労破壊'], ['4-5'])]),
                  ('ロープの選定',
                   [('つり角度と張力', ['開きが大きいほど張力が増える', '左右対称なら縦の分担は同じ'], ['4-6']),
                    ('張力・安全係数', ['張力係数＝縦の分力に対する倍率', '安全係数＝切断荷重÷最大荷重'], ['4-6']),
                    ('モード係数', ['つり方で、つれる質量が変わる', '基本安全荷重×係数＝つれる質量'], ['4-6'])]),
                  ('滑車と仕事',
                   [('定滑車・動滑車', ['定滑車＝引く向きを変える', '動滑車＝力を分担して支える'], ['4-7']),
                    ('ロープをたどる', ['組合せ＝荷を支える部分を数える', '段階式＝別ロープごとに半分'], ['4-7']),
                    ('仕事と動力', ['力を減らすほど、長く引く', '仕事＝力×力の向きの移動距離', '動力＝仕事÷時間'], ['4-7'])])]}}
COLORS=['#326F9B', '#527D94', '#398574', '#AF792D', '#B46758', '#7D8951']
book=json.loads((APP/'CraneExam/Resources/textbook.json').read_bytes())
for number,config in CONFIGS.items():
 branches=[(title,color,subs) for (title,subs),color in zip(config['branches'],COLORS)]
 ch=next(c for c in book['chapters'] if c['id']==number)
 refs={ref for _,_,subs in branches for _,_,ids in subs for ref in ids}
 all_ids={s['id'] for s in ch['sections']}
 core_ids=all_ids-{f'{number}-0',f'{number}-matome'}
 assert refs<=all_ids and core_ids<=refs, (number,core_ids-refs,refs-all_ids)
 W,H=3400,2200
 svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" aria-labelledby="title desc">',
  '<title id="title">'+escape(f'第{number}章 {config["title"]}のマインドマップ')+'</title>',
  '<desc id="desc">'+escape('中心から6本の枝が伸び、'+ '、'.join(b[0] for b in branches)+'へ分かれます。')+'</desc>',
  '<metadata>'+escape(json.dumps({'chapter':number,'sectionReferences':sorted(refs)},ensure_ascii=False))+'</metadata>',
  f'<rect width="{W}" height="{H}" fill="white"/>',
  '<g font-family="Meiryo, sans-serif" fill="#233C50" stroke-linecap="round" stroke-linejoin="round">']
 boxes=[]
 def text(x,y,label,size=34,weight=500,anchor='start',color='#233C50'):
  width=ImageFont.truetype('C:/Windows/Fonts/meiryob.ttc' if weight>=600 else 'C:/Windows/Fonts/meiryo.ttc',size).getlength(label)
  assert width <= (590 if size==32 else 260 if size==36 else 365 if size==48 else W-90), (label,width)
  left=x if anchor=='start' else x-width if anchor=='end' else x-width/2
  assert 45<=left and left+width<=W-45,(label,left,width)
  boxes.append((left,y-size,left+width,y+8,label))
  svg.append(f'<text x="{x}" y="{y}" text-anchor="{anchor}" font-size="{size}" font-weight="{weight}" fill="{color}">{escape(label)}</text>')
 def path(d,color,width,opacity=1):
  svg.append(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}" opacity="{opacity}"/>')
 text(1700,78,f'第{number}章  {config["title"]}',44,700,'middle')
 text(1700,128,'中心から外へ、役割としくみのつながりをたどる',30,500,'middle','#647B8C')
 for i,(main,color,subs) in enumerate(branches):
  right=i>=3; row=i%3; my=[430,1090,1750][row]
  def X(x):return W-x if right else x
  anchor='end' if right else 'start'
  # Thick trunk, thinner topic branches, fine keyword twigs.
  path(f'M {X(1510)} 1100 C {X(1440)} 1100 {X(1450)} {my} {X(1390)} {my} L {X(1080)} {my}',color,17)
  text(X(1090),my-28,main,48,700,'start' if not right else 'end',color)
  for j,(topic,leaves,_) in enumerate(subs):
   sy=[220,440,660][j]+row*660
   path(f'M {X(1080)} {my} C {X(1025)} {my} {X(1040)} {sy} {X(990)} {sy} L {X(740)} {sy}',color,7,.85)
   text(X(755),sy-18,topic,36,700,anchor,color)
   n=len(leaves)
   for k,label in enumerate(leaves):
    ly=sy+(k-(n-1)/2)*64
    path(f'M {X(740)} {sy} C {X(690)} {sy} {X(695)} {ly} {X(640)} {ly} L {X(90)} {ly}',color,3,.55)
    text(X(108),ly-14,label,32,500,anchor)
 svg.append('<ellipse cx="1700" cy="1100" rx="199" ry="177" fill="#F1F6FA" stroke="#D0DEE9" stroke-width="3"/>')
 text(1700,1029,config['center'],54,700,'middle')
 text(1700,1080,config['core'][0],30,600,'middle')
 text(1700,1123,config['core'][1],30,600,'middle')
 if number==2:
  svg.append('<path d="M1655 1152H1730L1753 1175V1240H1655Z" fill="white" stroke="#355972" stroke-width="5"/>')
  path('M1730 1152V1175H1753 M1673 1182H1715 M1673 1200H1734','#355972',4)
  path('M1684 1220L1696 1231L1720 1209','#398574',5)
 elif number==3:
  path('M1610 1202H1660 M1740 1202H1790','#355972',5)
  svg.append('<circle cx="1700" cy="1202" r="39" fill="white" stroke="#355972" stroke-width="5"/>')
  text(1700,1217,'M',40,700,'middle')
 else:
  path('M1620 1210H1780 M1700 1166V1210 M1650 1210L1632 1241H1668Z','#355972',5)
  svg.append('<rect x="1730" y="1175" width="33" height="35" rx="3" fill="#E8B965" stroke="#355972" stroke-width="4"/>')
 # Check labels, including fonts, before writing the production SVG.
 for a in range(len(boxes)):
  for b in range(a+1,len(boxes)):
   x1,y1,x2,y2,t1=boxes[a];u1,v1,u2,v2,t2=boxes[b]
   assert min(x2,u2)-max(x1,u1)<0 or min(y2,v2)-max(y1,v1)<0,('Label overlap',t1,t2)
 svg.extend(['</g>','</svg>'])
 raw='\n'.join(svg)+'\n';ET.fromstring(raw)
 for dest in [OUT/f'chapter{number}_relation_map.svg',APP/f'CraneExam/Resources/images/chapter{number}_relation_map.svg']:
  dest.write_text(raw,encoding='utf-8',newline='\n')
 html=OUT/f'chapter{number}_preview.html'
 html.write_text('<!doctype html><meta charset="utf-8"><style>html,body{margin:0;background:white;overflow:hidden}svg{display:block}</style>'+raw,encoding='utf-8')
 with tempfile.TemporaryDirectory(prefix='crane_mindmap_') as profile:
  r=subprocess.run(['C:/Program Files/Google/Chrome/Application/chrome.exe','--headless=new','--disable-gpu','--hide-scrollbars','--no-first-run','--user-data-dir='+profile,f'--window-size={W},{H}','--force-device-scale-factor=1','--screenshot='+str(OUT/f'chapter{number}_relation_map.png'),html.as_uri()],capture_output=True,timeout=60)
  assert r.returncode==0 and (OUT/f'chapter{number}_relation_map.png').exists()
 print(f'Chapter {number}: six branches, 18 topics; {len(refs)} section references. Labels validated; rendered PNG.')
 
