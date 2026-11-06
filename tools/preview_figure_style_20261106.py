"""Produce a local before/after review and check phone-width image presentation."""
from pathlib import Path
import json, html, hashlib
from PIL import Image, ImageDraw, ImageFont
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT.parent/'tmp/figure_style_20261106'
DOCS = ROOT/'docs/reviews'
jobs = json.loads((DOCS/'figure-style-jobs-20261106.json').read_text(encoding='utf-8'))
report = json.loads((DOCS/'figure-style-review-20261106.json').read_text(encoding='utf-8'))
book = json.loads((ROOT/'CraneExam/Resources/textbook.json').read_text(encoding='utf-8'))
roles = {'climbing': '概念・動き / 2D', 'meggerreadings': '数値の意味 / 2D'}
titles = dict(overview='クレーンの種類', overhead='天井クレーンの使い分け', climbing='クライミング',
              jibtypes='ジブクレーンの形', stacker='スタッカークレーン', luffing='引込みクレーン',
              hoist='ホイストの支持方式', drum='ドラムとエコライザシーブ', oilbath='油浴式の給油',
              cabinet='共用保護盤', breaker='配線用遮断器', contactor='電磁接触器',
              meggerconnect='絶縁抵抗計の接続', meggerreadings='絶縁抵抗の数字')
order = list(titles)
jobs.sort(key=lambda j: order.index(j['id']))
cards = []
for j in jobs:
    uses = [x for x in report['changes'] if x['id'] == j['id'] and x['kind'] == 'textbook']
    sid, bid = uses[0]['location'].split('/')
    b = next(b for c in book['chapters'] for s in c['sections'] for b in s['blocks'] if b['id'] == bid)
    image_path = '../../CraneExam/Resources/images/'
    j.update(section=sid, caption=b['caption'], role=roles.get(j['id'], '外観・構造 / 3D'))
    title = html.escape(titles[j['id']])
    cards.append(f'''<article id="{j['id']}" data-section="{sid}"><div class="cardhead"><small>{sid} · {j['role']}</small><h2>{title}</h2></div>
<button class="figure" aria-label="{title}を拡大" data-src="{image_path+j['file']}" data-caption="{html.escape(j['caption'], quote=True)}"><img src="{image_path+j['file']}" alt="{html.escape(j['caption'], quote=True)}"></button>
<p class="caption">{html.escape(j['caption'])}</p><details><summary>修正前を見る</summary><img class="before" src="{image_path+j['old']}" alt="修正前の{title}"></details></article>''')
page = '''<!doctype html><html lang="ja"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>教材図の画風整理・修正前後</title><style>
:root{color-scheme:light;--bg:#f1f5f8;--card:#fff;--ink:#18374e;--muted:#506574;--line:#d7e1e8;--accent:#275f84}*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font-family:'Meiryo',sans-serif;line-height:1.75}body.dark{color-scheme:dark;--bg:#101b25;--card:#1a2b38;--ink:#e8f0f6;--muted:#b6cbd8;--line:#3a5263;--accent:#a4d6f4}
header,main,footer{max-width:1200px;margin:auto;padding:24px}h1{font-size:26px;line-height:1.45;margin:8px 0 14px}h2{font-size:18px;margin:4px 0}p{margin:8px 0}small,.caption{color:var(--muted)}.intro{max-width:900px}.policy{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin:20px 0}.policy div{border-left:3px solid var(--accent);padding:4px 14px}.policy b{display:block}
nav{display:flex;gap:10px;flex-wrap:wrap;margin-top:16px}button,summary{cursor:pointer;font:inherit}nav button{border:1px solid var(--line);border-radius:8px;color:var(--ink);background:var(--card);padding:8px 12px}button:focus-visible,summary:focus-visible{outline:3px solid #3890cb;outline-offset:3px}
main{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px;padding-top:0}article{min-width:0;border:1px solid var(--line);background:var(--card);border-radius:14px;overflow:hidden}.cardhead{padding:14px 18px 6px}.figure{display:block;padding:0;margin:8px 0 0;border:0;background:white;width:100%}.figure img,.before{display:block;width:100%;height:auto;background:white}.caption{padding:10px 18px;font-size:14px}details{padding:0 18px 14px;font-size:14px}details img{margin-top:12px}.hidden{display:none}
dialog{border:0;padding:0;border-radius:12px;max-width:96vw;width:1400px;max-height:94vh;background:var(--card);color:var(--ink)}dialog::backdrop{background:#071320d9}.viewerhead{display:flex;align-items:center;justify-content:space-between;padding:10px 16px;gap:20px}.close{border:0;border-radius:50%;width:44px;height:44px;background:var(--bg);color:var(--ink);font-size:28px}.zoomarea{overflow:auto;max-height:74vh;background:white}#large{display:block;width:100%;height:auto}#viewcaption{padding:8px 18px;font-size:14px}.viewerhead label{font-size:14px}.viewerhead input{width:110px;vertical-align:middle}a{color:var(--accent)}
@media(max-width:640px){header,main,footer{padding:16px}main{grid-template-columns:1fr;gap:20px;padding-top:0}h1{font-size:23px}.policy{grid-template-columns:1fr}.intro{font-size:15px}.cardhead{padding:12px 14px 4px}.caption{padding:8px 14px}.viewerhead{gap:8px;padding:8px}.viewerhead label{font-size:12px}.viewerhead input{width:74px}}
</style><body><header><small>ローカル修正済み · 2026年11月6日 · 未配信</small><h1>図の役割で、画風を使い分ける</h1>
<p class="intro">第1章4節の7図と、他の節で同じ懸念があった7図を整理。2Dと3Dを用途で分け、白背景・紺の文字・余白・簡潔な注釈を共通にしました。図を押すと拡大できます。</p>
<div class="policy"><div><b>形・構造は3D</b>機器の外観、部品の位置、支持・接続を見せる。</div><div><b>原理・変化は2D</b>何が変わるか、なぜそうなるかに絞る。</div><div><b>計算・寸法は正確な図</b>矢印や数値の関係を優先し、装飾を足さない。</div></div>
<p class="intro">全章の教材・用語集194図を一覧で視覚確認し、今回の14図は個別に再作成・確認しました。全図を公式書籍と照合した技術監査ではありません。このページはスマホ幅での図の確認用Webプレビューであり、iOS実機の画面ではありません。</p>
<nav><button data-filter="all">全14図</button><button data-filter="1-4">第1章4節</button><button data-filter="other">他の節</button><button id="theme">明るさを切り替える</button></nav></header><main>'''+''.join(cards)+'''</main>
<footer><p>本文・例題・教材リンク・クイズの出題語は維持。ドラム図で重複していたD/dは、専用図で説明しています。図の文字は最小限とし、詳しい説明は本文・図の下に置きます。</p><p><a href="figure-style-jobs-20261106.json">画像生成の記録・プロンプト</a> / <a href="figure-style-review-20261106.json">変更記録</a></p></footer>
<dialog><div class="viewerhead"><span>図をじっくり見る</span><label>拡大 <input id="zoom" type="range" min="100" max="250" value="100" step="25"></label><button class="close" aria-label="閉じる">×</button></div><div class="zoomarea"><img id="large" alt=""></div><p id="viewcaption"></p></dialog>
<script>const dialog=document.querySelector('dialog'),large=document.querySelector('#large'),zoom=document.querySelector('#zoom');document.querySelectorAll('.figure').forEach(b=>b.onclick=()=>{large.src=b.dataset.src;large.alt=b.dataset.caption;document.querySelector('#viewcaption').textContent=b.dataset.caption;zoom.value=100;large.style.width='100%';dialog.showModal()});document.querySelector('.close').onclick=()=>dialog.close();zoom.oninput=()=>large.style.width=zoom.value+'%';document.querySelector('#theme').onclick=()=>document.body.classList.toggle('dark');document.querySelectorAll('[data-filter]').forEach(b=>b.onclick=()=>{document.querySelectorAll('article').forEach(a=>a.classList.toggle('hidden',b.dataset.filter==='1-4'?a.dataset.section!=='1-4':b.dataset.filter==='other'?a.dataset.section==='1-4':false))});</script></body></html>'''
dest = DOCS/'figure-style-preview-20261106.html'
dest.write_text(page, encoding='utf-8', newline='\n')

# Contact sheets are inspection aids, never edited production assets.
font = ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',20)
for offset in range(0,14,7):
    sheet = Image.new('RGB', (1500,1700), '#eef2f5'); draw=ImageDraw.Draw(sheet)
    for i,j in enumerate(jobs[offset:offset+7]):
        x=(i%2)*750; y=(i//2)*425
        im=Image.open(ROOT/'CraneExam/Resources/images'/j['file']);im.thumbnail((714,370))
        sheet.paste(im,(x+18+(714-im.width)//2,y+42))
        draw.text((x+18,y+8),j['section']+' '+titles[j['id']]+' / '+('2D' if j['id'] in roles else '3D'),font=font,fill='#17384e')
    sheet.save(OUT/f'updated-{offset//7+1}.jpg',quality=90)

with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True)
    page=browser.new_page()
    checks=[]
    for width in [320,390]:
        page.set_viewport_size({'width':width,'height':844})
        page.goto(dest.as_uri());page.wait_for_load_state('load')
        page.wait_for_function("Array.from(document.querySelectorAll('img[src]')).every(i=>i.complete && i.naturalWidth>0)")
        assert page.evaluate('document.documentElement.scrollWidth<=innerWidth'),width
        for theme in ['light','dark']:
            page.evaluate("document.body.classList.toggle('dark',"+str(theme=='dark').lower()+")")
            for key in ['climbing','hoist','contactor','meggerreadings']:
                page.locator('#'+key).screenshot(path=str(OUT/f'phone-{width}-{theme}-{key}.png'))
            checks.append({'width':width,'theme':theme,'horizontalOverflow':False,'allImagesLoaded':True})
        page.locator('#hoist .figure').click();assert page.locator('dialog').is_visible()
        page.locator('#zoom').fill('200');page.locator('#zoom').dispatch_event('input')
        assert page.locator('#large').evaluate("e=>e.style.width")=='200%'
        page.locator('.close').click();assert not page.locator('dialog').is_visible()
    browser.close()
report['webPreviewQA']={'phoneConditions':checks,'zoomAndClose':True,'nativeAppTest':False}
(DOCS/'figure-style-review-20261106.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print('PASS: 14 before/after figures loaded; 320/390px light/dark preview; zoom/close. No native-device test.')
