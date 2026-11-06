"""Render revised content at phone width, and export the same chapter to PDF.
This is a browser approximation for visual QA, not an iOS simulator.
"""
import html, json, pathlib, re, shutil
from playwright.sync_api import sync_playwright

ROOT=pathlib.Path(__file__).resolve().parents[2]
RES=ROOT/'crane-app/CraneExam/Resources'
OUT=ROOT/'tmp/ch1_revision_20261106';OUT.mkdir(exist_ok=True)
DOC=ROOT/'crane-app/docs/reviews'
chapter=json.loads((RES/'textbook.json').read_text('utf-8'))['chapters'][0]
esc=html.escape
def md(s):return re.sub(r'\*\*(.+?)\*\*',r'<strong>\1</strong>',esc(s)).replace('\n','<br>')
def asset(b):
    p=RES/'images'/(b.get('asset') or b['file'])
    if not p.suffix:
        p=next(p.with_suffix(x) for x in ['.png','.jpg','.jpeg'] if p.with_suffix(x).exists())
    assert p.exists(),p
    return p
def block(b,printmode=False):
    typ=b['type'];style=b.get('style','');bid=b['id'];a=f'id="{bid}"'
    if typ=='sub':return f'<h2 {a}>{md(b["text"])}</h2>'
    if typ=='p':
        if style=='answer':
            inner=md(b['text'])
            if printmode:return f'<div {a} class="answer printanswer"><b>答えと理由</b><p>{inner}</p></div>'
            return f'<details {a} class="answer"><summary>答えと理由を見る</summary><p>{inner}</p></details>'
        if style=='reference':return f'<p {a} class="reference">↗ {md(b["text"])}</p>'
        return f'<p {a} class="{style}">{md(b["text"])}</p>'
    if typ in ('img','svg'):
        return f'<figure {a}><a href="{asset(b).as_uri()}" target="_blank"><img src="{asset(b).as_uri()}" alt="{esc(b.get("caption", ""))}"></a><figcaption>{md(b.get("caption", ""))}</figcaption></figure>'
    if typ in ('point','ul'):
        return f'<div {a} class="{typ}">'+('<b>ここを覚える</b>' if typ=='point' else '')+'<ul>'+''.join('<li>'+md(t)+'</li>' for t in b['items'])+'</ul></div>'
    if typ=='table':
        return f'<div {a} class="tablewrap"><table><thead><tr>'+''.join('<th>'+md(h)+'</th>' for h in b['headers'])+'</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+md(c)+'</td>' for c in row)+'</tr>' for row in b['rows'])+'</tbody></table></div>'
    raise ValueError(typ)

CSS='''
*{box-sizing:border-box}body{margin:0;background:#f8f9fb;color:#24364a;font-family:-apple-system,"Meiryo",sans-serif;line-height:1.7;font-size:16px}main{max-width:390px;margin:auto;padding:22px 20px 40px;background:#faf9f6}h1{font-size:21px;line-height:1.6;padding-left:14px;border-left:4px solid #c99432;margin:10px 0 24px}h2{font-size:19px;line-height:1.6;border-left:4px solid #2c719a;padding-left:12px;margin:36px 0 24px;break-after:avoid}p{margin:18px 0;line-height:1.85}strong{color:#21678d;background:#21678d12}p.lead{font-size:18px;font-weight:600;background:#eaf0f4;padding:18px;border-radius:14px}.tip,.caution,.point{padding:18px;background:#eaf1f5;border-radius:14px}.caution{background:#fff1dc}.question{font-size:17px;font-weight:500}.answer{padding:16px;background:#edf3f5;border-radius:12px;margin:18px 0}.answer summary{cursor:pointer;color:#226c92;font-weight:600;min-height:32px;line-height:32px}.answer p{margin:12px 0 0}.reference{background:#edf0f4;padding:14px;border-radius:12px;font-size:15px;color:#226c92;font-weight:600}figure{margin:22px 0}figure img{display:block;width:100%;height:auto;max-height:620px;object-fit:contain;background:white;border:1px solid #dce2e7;border-radius:10px}figcaption{font-size:13px;line-height:1.7;color:#53667a;margin-top:10px}table{border-collapse:separate;border-spacing:0;width:100%;table-layout:fixed;overflow:hidden;font-size:15px;border:1px solid #d8e1e8;border-radius:12px;margin:18px 0}th,td{text-align:left;vertical-align:top;padding:13px 15px;overflow-wrap:anywhere}th{font-size:13px;background:#eaf0f4;color:#53677a}tr:nth-child(even){background:#eef2f5}td:first-child{font-weight:600}ul{padding-left:22px}li{margin:12px 0}.tools{max-width:390px;margin:auto;padding:14px 20px;background:#e7edf2}.tools small{display:block;color:#53677a;font-size:12px;margin:6px 0}select,button{font:inherit;max-width:100%;padding:9px;border:1px solid #bacbd7;background:#fff;border-radius:8px}.contents{border-radius:12px;background:#edf0f4;padding:16px;margin:20px 0}.contents summary{font-size:15px;font-weight:bold;min-height:32px;line-height:32px;cursor:pointer}.contents a{display:block;padding:10px 0;font-size:15px;line-height:1.7;color:#226c92;text-decoration:none}section[hidden]{display:none}.dark{background:#101b25;color:#e4edf4}.dark main{background:#152330}.dark strong{color:#95cfea;background:#95cfea15}.dark .lead,.dark .tip,.dark .point,.dark .answer,.dark .contents,.dark .reference{background:#213749}.dark .caution{background:#493c24}.dark table{border-color:#395062}.dark th,.dark tr:nth-child(even){background:#213749}.dark th,.dark figcaption{color:#b2c3d0}.dark .answer summary,.dark .contents a{color:#95cfea}.printanswer{break-inside:avoid}.printanswer>b{color:#21678d;font-size:10pt}a{color:inherit}
'''
sections=[]
for i,s in enumerate(chapter['sections'],1):
    heads=[b for b in s['blocks'] if b['type']=='sub']
    toc='<details class="contents"><summary>この節の目次</summary>'+''.join(f'<a href="#{b["id"]}">{md(b["text"])}</a>' for b in heads)+'</details>' if len(heads)>4 else ''
    sections.append(f'<section data-section="{s["id"]}"'+(' hidden' if i>1 else '')+f'><h1>{i}. {md(s["title"])}</h1>'+toc+''.join(block(b) for b in s['blocks'])+'</section>')
options=''.join(f'<option value="{s["id"]}">{i}. {esc(s["title"])}</option>' for i,s in enumerate(chapter['sections'],1))
web='<!doctype html><html lang="ja"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>第1章 改訂プレビュー</title><style>'+CSS+'</style><div class="tools"><small>改訂プレビュー / iOS実機ではありません</small><select aria-label="節を選ぶ" id="sections">'+options+'</select><button id="theme">ライト / ダーク</button></div><main>'+''.join(sections)+'</main><script>document.querySelector("#sections").onchange=e=>{document.querySelectorAll("section").forEach(s=>s.hidden=s.dataset.section!==e.target.value);window.scrollTo(0,0)};document.querySelector("#theme").onclick=()=>document.body.classList.toggle("dark");</script></html>'
preview=DOC/'chapter1-revised-preview-20261106.html';preview.write_text(web,'utf-8',newline='\n')
PRINT='''@page{size:A4;margin:16mm 16mm 18mm}body{background:white;font-size:10.5pt}main{max-width:none;padding:0;background:white}h1{font-size:18pt;break-before:auto;break-after:avoid;margin-top:26px}.cover+.print-section{break-before:page}h1:has(+ .glossary){break-before:page}h2{font-size:12pt;margin:18px 0 10px}p{margin:10px 0;line-height:1.8}p.lead{font-size:12pt;padding:12px}.tip,.caution,.point{padding:12px}figure{break-inside:avoid;margin:14px 0}figure img{max-width:100%;max-height:135mm;width:auto;height:auto;max-width:155mm;margin:auto}figcaption{font-size:9pt}table{font-size:10pt;break-inside:avoid;margin:10px 0}th{font-size:9.5pt}th,td{padding:8px 10px}tr{break-inside:avoid}.answer{padding:10px;margin:10px 0}.question{font-size:11pt;break-after:avoid}section{display:block}.cover{height:220mm;display:flex;flex-direction:column;justify-content:center;align-items:center;text-align:center}.cover h1{border:0;padding:0;font-size:26pt;break-before:avoid}.cover p{color:#5b7080}.glossary{font-size:10pt;break-inside:auto}figure:has(+ .reference){break-after:avoid}.reference{break-before:avoid}.print-section>:nth-last-child(2){break-after:avoid}'''
printing='<!doctype html><html lang="ja"><meta charset="utf-8"><title>第1章 クレーンに関する知識</title><style>'+CSS+PRINT+'</style><main><div class="cover"><p>クレーン・デリック運転士〈クレーン限定〉</p><h1>第1章<br>クレーンに関する知識</h1><p>学習教材 / 2026年11月6日改訂</p><p>仕組みを理解する → 違いを見分ける → 自分で答える</p></div>'
for i,s in enumerate(chapter['sections'],1):printing+=f'<div class="print-section"><h1>{i}. {md(s["title"])}</h1>'+''.join(block(b,True) for b in s['blocks'])+'</div>'
printing+='<h1>用語の確認</h1><table class="glossary"><thead><tr><th>用語</th><th>意味</th></tr></thead><tbody>'+''.join('<tr><td>'+md(g['term'])+'</td><td>'+md(g['def'])+'</td></tr>' for g in chapter.get('glossary',[]))+'</tbody></table></main></html>'
printfile=OUT/'chapter1-print.html';printfile.write_text(printing,'utf-8',newline='\n')
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path='C:/Program Files/Google/Chrome/Application/chrome.exe',headless=True)
    page=browser.new_page(viewport={'width':390,'height':844},device_scale_factor=1)
    page.goto(preview.as_uri());page.evaluate('document.fonts.ready');page.evaluate('Promise.all(Array.from(document.images).map(i=>i.decode()))')
    print("Loaded phone preview",flush=True)
    checks=[]
    for sid in [s['id'] for s in chapter['sections']]:
        page.select_option('#sections',sid)
        assert not page.evaluate('document.documentElement.scrollWidth>innerWidth'),sid
        assert page.locator('section:not([hidden])').count()==1
        if sid in ['1-9','1-11','1-14','1-15','1-7']:
            page.screenshot(path=str(OUT/(sid+'-revised-mobile.png')),full_page=True)
        for sel in ['details.answer','details.contents']:
            entries=page.locator('section:not([hidden]) '+sel)
            if entries.count():
                item=entries.first;assert not item.evaluate('(e)=>e.open')
                item.locator('summary').click();assert item.evaluate('(e)=>e.open')
                item.locator('summary').click();assert not item.evaluate('(e)=>e.open')
        checks.append({'section':sid,'horizontal_overflow':False})
    page.select_option('#sections','1-9');page.locator('#theme').click();page.screenshot(path=str(OUT/'1-9-dark.png'))
    print("Phone checks complete; exporting PDF",flush=True)
    page.goto(printfile.as_uri());page.evaluate('document.fonts.ready');page.evaluate('Promise.all(Array.from(document.images).map(i=>i.decode()))')
    page.pdf(path=str(OUT/'chapter1-candidate.pdf'),format='A4',print_background=True,display_header_footer=True,header_template='<span></span>',footer_template='<div style="font-size:9px;width:100%;text-align:center;color:#667789">第1章 クレーンに関する知識　<span class="pageNumber"></span> / <span class="totalPages"></span></div>',prefer_css_page_size=True)
    print("PDF exported; rendering figures",flush=True)
    # Inspect the changed native diagrams independently of HTML layouts.
    assets=json.loads((DOC/'chapter1-revision-assets-20261106.json').read_text('utf-8'))
    svg_checks=[]
    for name in assets['svg_edited']+assets['svg_added']:
        page.goto((RES/'images'/name).as_uri());page.evaluate('document.fonts.ready')
        w,h=page.evaluate('(()=>{let v=document.documentElement.viewBox.baseVal;return [v.width,v.height]})()')
        page.set_viewport_size({'width':1000,'height':round(1000*h/w)})
        page.evaluate("document.documentElement.style.width='100vw';document.documentElement.style.height='100vh'")
        page.screenshot(path=str(OUT/(name+'.png')))
        bad=page.evaluate('''(()=>{const root=document.documentElement, vb=root.viewBox.baseVal;return [...document.querySelectorAll('text')].filter(t=>{const b=t.getBBox(),m=t.getCTM();let pts=[[b.x,b.y],[b.x+b.width,b.y+b.height]].map(([x,y])=>{let p=root.createSVGPoint();p.x=x;p.y=y;return p.matrixTransform(m)});return pts.some(p=>p.x < -1 || p.y < -1 || p.x>innerWidth+1 || p.y>innerHeight+1)}).map(t=>t.textContent)})()''')
        svg_checks.append({'file':name,'clipped_text':bad})
    browser.close()
(OUT/'visual-checks.json').write_text(json.dumps({'sections':checks,'svg':svg_checks},ensure_ascii=False,indent=2),'utf-8')
print(json.dumps({'preview':str(preview),'sections_checked':len(checks),'svg':svg_checks},ensure_ascii=False))
