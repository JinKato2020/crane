"""Code-native conceptual diagrams; existing technical 3D images are retained."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'crane-app/CraneExam/Resources/images'
def svg(h,body):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 {h}" role="img">
<style>text{{font-family:Meiryo,'Noto Sans JP',sans-serif;fill:#19354a;font-size:38px}}.title{{font-size:46px;font-weight:700}}.label{{font-weight:700}}.muted{{fill:#586c7a;font-size:32px}}.blue{{fill:#216b9a}}.red{{fill:#ad4338}}</style>
<defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="4" orient="auto"><path d="M0 0L8 4L0 8Z" fill="#216b9a"/></marker><marker id="redarrow" markerWidth="10" markerHeight="10" refX="8" refY="4" orient="auto"><path d="M0 0L8 4L0 8Z" fill="#ad4338"/></marker></defs>
<rect width="1000" height="{h}" rx="20" fill="#fff"/>{body}</svg>'''
files={
'2-3_annual_exception_20261106.svg':svg(880,'''
<text x="500" y="80" class="title" text-anchor="middle">年次の荷重試験を省略できる時期</text>
<text x="500" y="135" text-anchor="middle" class="muted">見るのは「自主検査の日」から前と後</text>
<rect x="50" y="185" width="900" height="270" rx="18" fill="#f0f5f8"/>
<text x="85" y="245" class="label">① 前の２月以内に、試験を済ませた</text>
<path d="M130 350H850" stroke="#b4c3cd" stroke-width="5"/>
<path d="M160 350H530" stroke="#216b9a" stroke-width="9"/>
<circle cx="160" cy="350" r="12" fill="#216b9a"/><circle cx="530" cy="350" r="12" fill="#19354a"/>
<text x="155" y="310" class="blue label">荷重試験</text>
<text x="530" y="310" class="label" text-anchor="middle">自主検査</text>
<text x="345" y="410" class="blue" text-anchor="middle">２月以内</text>
<text x="700" y="410" class="muted">性能検査で実施</text>
<rect x="50" y="485" width="900" height="270" rx="18" fill="#f0f5f8"/>
<text x="85" y="545" class="label">② 後の２月以内に、検査証が満了</text>
<path d="M130 650H850" stroke="#b4c3cd" stroke-width="5"/>
<path d="M460 650H830" stroke="#216b9a" stroke-width="9"/>
<circle cx="460" cy="650" r="12" fill="#19354a"/><circle cx="830" cy="650" r="12" fill="#216b9a"/>
<text x="460" y="610" class="label" text-anchor="middle">自主検査</text>
<text x="830" y="610" class="blue label" text-anchor="middle">満了日</text>
<text x="645" y="710" class="blue" text-anchor="middle">２月以内</text>
<text x="500" y="825" text-anchor="middle" class="label">①・②の、どちらかに当てはまればよい</text>
'''),
'2-2_inner_angle_20261106.svg':svg(900,'''
<text x="500" y="80" class="title" text-anchor="middle">ロープの「内角側」はどちら？</text>
<text x="500" y="135" text-anchor="middle" class="muted">上から見た概念図</text>
<path d="M130 595L500 280L870 595Z" fill="#f9e9e4"/>
<path d="M130 595L478 280Q500 260 522 280L870 595" stroke="#385565" stroke-width="15" fill="none"/>
<circle cx="500" cy="300" r="37" fill="#d5e0e6" stroke="#19354a" stroke-width="5"/>
<circle cx="500" cy="300" r="9" fill="#19354a"/>
<path d="M500 260V190H650" stroke="#526b7a" stroke-width="4" fill="none"/>
<text x="670" y="205">シーブ</text>
<text x="160" y="330" transform="rotate(-41 160 330)" class="muted">張ったロープ</text>
<text x="500" y="460" text-anchor="middle" class="red label">内角側</text>
<path d="M500 485V570" stroke="#ad4338" stroke-width="7" marker-end="url(#redarrow)"/>
<path d="M130 595H870" stroke="#ad4338" stroke-width="4" stroke-dasharray="14 12"/>
<circle cx="130" cy="595" r="12" fill="#19354a"/><circle cx="870" cy="595" r="12" fill="#19354a"/>
<text x="500" y="690" text-anchor="middle">シーブ等が壊れると、</text>
<text x="500" y="745" text-anchor="middle">ロープが内角側へ跳ねるおそれ</text>
<text x="500" y="835" text-anchor="middle" class="red label">危険のおそれのある箇所は立入禁止</text>
''')}
for name,body in files.items():
    body=body.replace('２月','２か月')
    (OUT/name).write_text(body,'utf-8',newline='\n')
doc=ROOT/'crane-app/docs/reviews/chapter2-revision-assets-20261106.json'
doc.write_text(json.dumps(dict(generated={},svg_edited=[],svg_added=list(files)),ensure_ascii=False,indent=2)+'\n','utf-8')
print('Created 2 conceptual SVG diagrams; retained all existing technical images.')
