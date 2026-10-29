"""現行教材データでスマートフォン幅のデザイン確認用HTMLを作る（iOS実機ではない）。"""
import html
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT.parent / '教材デザイン確認_20261029.html'
data = json.loads((ROOT / 'CraneExam/Resources/textbook.json').read_text(encoding='utf-8'))


def md(text):
    return re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', html.escape(text)).replace('\n', '<br>')


def block(b):
    t = b['type']
    if t == 'sub':
        return '<h2>' + md(b['text']) + '</h2>'
    if t == 'p':
        style = b.get('style', '')
        label = {'lead': 'まず、これだけ', 'tip': 'なるほど', 'caution': '取り違え注意'}.get(style, '')
        return f'<div class="{style}">' + (f'<small>{label}</small>' if label else '') + '<p>' + md(b['text']) + '</p></div>'
    if t in ('ul', 'point'):
        return ('<aside><b>ここを覚える</b>' if t == 'point' else '') + '<ul>' + ''.join('<li>' + md(s) + '</li>' for s in b['items']) + '</ul>' + ('</aside>' if t == 'point' else '')
    if t == 'table':
        if b.get('style') == 'numbers':
            return ''.join('<div class="number"><small>' + md(r[0]) + '</small><div style="font-size:' + ('16' if len(r[1]) > 36 else '22') + 'px">' + md(r[1]) + '</div></div>' for r in b['rows'])
        return '<div class="table">' + ''.join('<div class="row">' + ''.join('<div>' + md(c) + '</div>' for c in r) + '</div>' for r in [b['headers']] + b['rows']) + '</div>'
    if t in ('img', 'svg'):
        name = b.get('file') or b.get('asset')
        resource = ROOT / 'CraneExam/Resources/images' / name
        if not resource.suffix:
            resource = resource.with_suffix('.png')
        if not resource.exists():
            resource = ROOT / 'CraneExam/Resources' / resource.name
        return f'<figure><img loading="lazy" src="{resource.as_uri()}"><figcaption>{md(b.get("caption", ""))}</figcaption></figure>'
    return '<pre>' + md(b.get('text', '')) + '</pre>'


css = '''
*{box-sizing:border-box}body{margin:0;background:#f4f6f9;color:#1a1d22;font:16px/1.8 "Yu Gothic",Meiryo,sans-serif}
main{max-width:470px;margin:auto;padding:24px}header{font-size:12px;color:#5a6472;margin-bottom:16px}
h1{font-size:21px;line-height:1.6;border-left:4px solid #e08a00;padding-left:14px;margin:12px 0 24px}
h2{font-size:19px;line-height:1.6;border-left:4px solid #185a92;padding-left:12px;margin:38px 0 24px}
p{margin:0}section>div,section>ul{margin-bottom:18px}strong{color:#185a92;background:#185a9217;font-weight:700}
.lead{padding:18px;background:#185a9212;border-radius:14px;font-size:18px;font-weight:600;line-height:1.75}
small{display:block;color:#5a6472;font-size:14px;margin-bottom:9px}.lead small{font-size:13px;color:#185a92;font-weight:700}
.number{padding:18px;background:#185a9210;border-radius:12px;font-weight:bold;line-height:1.65}.number small{font-weight:600}
aside{padding:18px;background:#e08a001a;border:1px solid #e08a0059;border-radius:14px;margin:18px 0}
ul{padding-left:23px}li{padding-left:4px;margin:0 0 13px}.table{border:1px solid #d6dbe3;border-radius:12px;overflow:hidden}
.row{display:flex;gap:12px;padding:13px 15px;background:#fff;font-size:15px}.row>div{flex:1;min-width:0}.row:first-child{font-weight:bold;background:#e7ebf1}.row:nth-child(2n+1){background:#eff2f6}
figure{margin:20px 0}img{max-width:100%;border-radius:10px}figcaption{font-size:12px;color:#5a6472}
nav{margin:24px 0}select,button{max-width:100%;padding:10px;font:inherit}section{display:none}section.active{display:block}
body.dark{background:#0c0e12;color:#eef1f6}.dark strong{color:#8cc9ff;background:#8cc9ff17}.dark .lead,.dark .number{background:#8cc9ff12}.dark small,.dark header{color:#9aa4b4}.dark h2{border-color:#8cc9ff}.dark .lead small{color:#8cc9ff}.dark .row{background:#191d25}.dark .row:nth-child(2n+1){background:#1f242e}
'''
css += '.tip,.caution{padding:18px;border-radius:14px;background:#185a9212}.caution{background:#de432a12}.tip small{color:#185a92}.caution small{color:#de432a}.dark .tip{background:#8cc9ff12}.dark .caution{background:#ff6a5212}'
sections = [s for c in data['chapters'] for s in c['sections']]
doc = '<!doctype html><html lang="ja"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>教材デザイン確認</title><style>' + css + '</style><body><main><header>教材デザイン確認・スマホ幅のHTML見本<br>iOS実機のスクリーンショットではありません</header>'
for s in sections:
    doc += f'<section id="s{s["id"]}"><h1>{md(s["title"])}</h1>' + ''.join(map(block, s['blocks'])) + '</section>'
doc += '<nav><select onchange="show(this.value)">' + ''.join(f'<option value="{s["id"]}">{s["id"]} {html.escape(s["title"])}</option>' for s in sections) + '</select><button onclick="document.body.classList.toggle(\'dark\')">明暗を切替</button></nav></main><script>function show(id){document.querySelectorAll("section").forEach(s=>s.classList.toggle("active",s.id==="s"+id));document.querySelector("select").value=id;scrollTo(0,0)}show(location.hash.slice(1)||"2-0");if(location.search.includes("dark"))document.body.classList.add("dark");</script></body></html>'
doc = doc.replace('show(location.hash.slice(1)||"2-0");', 'addEventListener("hashchange",()=>show(location.hash.slice(1)||"2-0"));show(location.hash.slice(1)||"2-0");')
OUT.write_text(doc, encoding='utf-8', newline='\n')
print(OUT)
