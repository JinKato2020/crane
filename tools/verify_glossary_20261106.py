"""Glossary data regression checks and browser-based mobile interaction checks.
The browser checks are a layout approximation, not an iOS compile or simulator.
"""
from pathlib import Path
from collections import Counter
import hashlib,json,re,sys,unicodedata
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; WORK=ROOT.parent/'tmp/glossary_revision_20261106'
RES=ROOT/'CraneExam/Resources'; DOC=ROOT/'docs/reviews'
book=json.loads((RES/'textbook.json').read_text(encoding='utf-8'))
old=json.loads((WORK/'textbook.json').read_text(encoding='utf-8'))
canonical=json.loads((ROOT.parent/'アプリ/教材/textbook.json').read_text(encoding='utf-8'))
sections={s['id']:s for c in book['chapters'] for s in c['sections']}
refs=0;assets=set();counts=[]
for c,o,canonical_c in zip(book['chapters'],old['chapters'],canonical['chapters']):
 assert c['sections']==o['sections'],c['id']
 assert c['glossary']==canonical_c['glossary']
 assert [x['term'] for x in c['glossary'][:len(o['glossary'])]]==[x['term'] for x in o['glossary']]
 assert [x['term'] for x in c['glossary'][:10]]==[x['term'] for x in o['glossary'][:10]]
 assert len(set(t['term'] for t in c['glossary']))==len(c['glossary'])
 figures=[]
 for t in c['glossary']:
  assert all(t.get(k) for k in ['summary','reading','category','def','points','references']),t['term']
  assert '**' not in t['def'],t['term']
  for p in [t['summary']]+t['points']+[t.get('example','')]:assert p.count('**')%2==0,(t['term'],p)
  if t.get('comparison'):
   comp=t['comparison'];assert len(comp['headers'])==2
   assert all(len(row)==2 for row in comp['rows'])
  for ref in t['references']:
   assert ref['section'] in sections,ref
   assert len([b for b in sections[ref['section']]['blocks'] if b['id']==ref['blockID']])==1,ref
   refs+=1
  for fig in t.get('figures',[]):
   assert (RES/'images'/fig['file']).is_file(),fig
   assert fig['caption'],fig
   figures.append(fig['file']);assets.add(fig['file'])
  if t.get('img'):assert (RES/'images'/(t['img']+'.png')).exists()
 assert len(figures)==len(set(figures)),Counter(figures)
 counts.append({'chapter':c['id'],'before':len(o['glossary']),'after':len(c['glossary']),'figures':len(figures)})
assert (RES/'exams.json').read_bytes()==(WORK/'exams.json').read_bytes(),'Unrelated exams changed'
# Boundary words, applied conditions and useful formulas remain part of the actual content.
def t(c,i):return book['chapters'][c-1]['glossary'][i]['def']
for token in ['1/2','0.5％以下','400','630','1000','20％','17％','15％']:
 assert token in t(2,33).replace(',',''),(token,t(2,33))
for token in ['10％以上','7％を超えて減少']:assert token in t(2,31)
assert '＋50t' in t(2,27) and '1.27倍' in t(2,27)
assert '3年間' in t(2,23) and '作業開始前' in t(2,23)
assert 'I²Rt' in t(3,14) and '1/3' in t(3,35)
assert all(x in t(4,9) for x in ['29.4','68.6','98'])
assert '同じ断面を3方向' in t(1,47)
checks=[]
with sync_playwright() as pw:
 browser=pw.chromium.launch(executable_path='C:/Program Files/Google/Chrome/Application/chrome.exe',headless=True)
 page=browser.new_page(viewport={'width':390,'height':844},device_scale_factor=1)
 errors=[];page.on('pageerror',lambda error:errors.append(str(error)))
 page.goto((DOC/'glossary-preview-20261106.html').as_uri());page.evaluate('document.fonts.ready')
 assert page.locator('.row').count()==4
 page.screenshot(path=str(WORK/'overview-light.png'),full_page=True)
 # Data-driven browser search across reading variants, aliases and multiple keywords.
 results=page.evaluate('''()=>{const cases=[['かごがた','かご形'],['ｶｺﾞｶﾞﾀ','かご形'],['カゴガタ','かご形'],['巻線型','かご形'],['巻線形　すべり','かご形'],['ＶＶＶＦ','インバーター'],['さんようそ','三要素'],['すてまき','すて巻']];return cases.map(([q,expected])=>({q,ok:book.chapters.flatMap(c=>c.glossary).filter(t=>match(t,q)).some(t=>t.term.includes(expected))}))}''')
 assert all(r['ok'] for r in results),results
 # Exact glossary destinations all exist in the preview document's live data too.
 assert page.evaluate('''()=>book.chapters.every(c=>c.glossary.every(t=>t.references.every(r=>book.chapters.flatMap(c=>c.sections).some(s=>s.id===r.section&&s.blocks.some(b=>b.id===r.blockID)))))''')
 for width in [390,320]:
  page.set_viewport_size({'width':width,'height':844})
  for dark,large in [(False,False),(True,False),(False,True),(True,True)]:
   page.evaluate('([d,l])=>{document.body.classList.toggle("dark",d);document.body.classList.toggle("large",l)}',[dark,large])
   for c in book['chapters']:
    page.evaluate('(id)=>{chapter=id;query="";category="";favMode=false;render()}',c['id'])
    assert page.locator('.card').count()==len(c['glossary'])
    page.evaluate('document.querySelectorAll("details").forEach(d=>d.open=true)')
    assert not page.evaluate('document.documentElement.scrollWidth>innerWidth'),(width,dark,large,c['id'])
    checks.append({'width':width,'dark':dark,'large_text':large,'chapter':c['id'],'overflow':False})
 print('32 phone-layout combinations passed',flush=True)
 page.set_viewport_size({'width':390,'height':844});page.evaluate('document.body.className=""')
 # Filtering and clearing really update visible cards.
 page.evaluate('chapter=3;query="";category="";favMode=false;render()')
 page.select_option('#category','モーターのしくみ');assert page.locator('.card').count()>0
 assert page.evaluate('Array.from(document.querySelectorAll(".card")).every(e=>termAt(e.dataset.key).category==="モーターのしくみ")')
 page.locator('#search').fill('存在しない語句');assert page.locator('.card').count()==0
 page.locator('#reset').click();assert page.locator('.card').count()==53
 page.locator('#search').fill('かご型');assert page.locator('.card').count()==1
 card=page.locator('.card').first
 assert not card.locator('details').evaluate('d=>d.open')
 card.locator('summary').click();assert card.locator('details').evaluate('d=>d.open')
 card.locator('.heart').click();assert card.locator('.heart').inner_text()=='♥'
 page.screenshot(path=str(WORK/'motor-open.png'),full_page=True)
 card.locator('.imagebutton').first.click();assert page.locator('#modal').evaluate('d=>d.open')
 page.locator('#close').click();assert not page.locator('#modal').evaluate('d=>d.open')
 card.locator('.ref').first.click();assert page.locator('#modal .target').count()==1
 assert 'かご形' in page.locator('#modal .target').inner_text()
 page.keyboard.press('Escape');assert not page.locator('#modal').evaluate('d=>d.open')
 page.locator('#favorites').click();assert page.locator('.card').count()==1
 page.reload();page.locator('#favorites').click();assert page.locator('.card').count()==1
 page.locator('.heart').click();assert page.locator('.card').count()==0
 # Representative content screenshots, and every displayed image decodes.
 for cid,query,name in [(1,'ロープ径','rope'),(2,'つりチェーンの安全係数','law'),(3,'電力／電力量','power'),(4,'張力係数・モード','coefficients'),(4,'摩擦力と静止','friction')]:
  page.evaluate('([c,q])=>{chapter=c;query=q;category="";favMode=false;render()}',[cid,query])
  page.evaluate('document.querySelectorAll("details").forEach(d=>d.open=true)')
  page.evaluate('Promise.all(Array.from(document.querySelectorAll(".card img")).map(i=>{i.loading="eager";return i.decode()}))')
  page.screenshot(path=str(WORK/(name+'-open.png')),full_page=True)
  if name=='law':
   assert page.locator('.compare tbody tr').count()==3
   page.evaluate('document.body.classList.add("dark")');page.screenshot(path=str(WORK/'law-dark.png'),full_page=True)
   page.evaluate('document.body.classList.remove("dark")')
   page.set_viewport_size({'width':320,'height':844});page.evaluate('document.body.classList.add("large")')
   page.screenshot(path=str(WORK/'law-large-320.png'),full_page=True)
   page.evaluate('document.body.classList.remove("large")');page.set_viewport_size({'width':390,'height':844})
 # Raster/SVG contact sheets: same local files the app will load.
 names=sorted(assets);rendered=WORK/'figures';rendered.mkdir(exist_ok=True)
 for name in names:
  p=RES/'images'/name
  if p.suffix=='.svg':
   page.set_viewport_size({'width':900,'height':650});page.goto(p.as_uri());page.evaluate('document.fonts.ready')
   w,h=page.evaluate('(()=>{const v=document.documentElement.viewBox.baseVal;return [v.width,v.height]})()')
   page.set_viewport_size({'width':900,'height':round(900*h/w)})
   page.evaluate("document.documentElement.style.width='100vw';document.documentElement.style.height='100vh'")
   page.screenshot(path=str(rendered/(name+'.png')))
   if name=='3-5_star_delta.svg':
    clipped=page.evaluate('''()=>[...document.querySelectorAll('text')].filter(t=>{const b=t.getBBox();return b.x<0||b.y<0||b.x+b.width>900||b.y+b.height>760}).map(t=>t.textContent)''')
    assert not clipped,clipped
 assert not errors,errors
 browser.close()
from PIL import Image,ImageOps,ImageDraw,ImageFont
font=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',14)
for page_no in range((len(names)+8)//9):
 sheet=Image.new('RGB',(1200,1020),'#eef2f6');draw=ImageDraw.Draw(sheet)
 for slot,name in enumerate(names[page_no*9:page_no*9+9]):
  im=Image.open(rendered/(name+'.png') if name.endswith('.svg') else RES/'images'/name).convert('RGB')
  im.thumbnail((388,298))
  x=(slot%3)*400;y=(slot//3)*340
  sheet.paste(im,(x+(400-im.width)//2,y+4+(298-im.height)//2))
  draw.text((x+8,y+304),name[:43],font=font,fill='#1a1d22')
 sheet.save(WORK/f'figures-contact-{page_no+1:02d}.jpg',quality=92)
result={'chapters':counts,'original_terms_preserved':198,'terms':207,'figures':sum(c['figures'] for c in counts),'unique_files':len(assets),'references':refs,'textbook_sections_unchanged':True,'exams_unchanged':True,'search_tests':results,'phone_layouts':checks,'browser_errors':errors,'native_build':'not run (Windows; no iOS SDK)','published':False}
(DOC/'glossary-review-checks-20261106.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k not in ['phone_layouts','search_tests']},ensure_ascii=False))
