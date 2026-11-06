"""Create a live visual inventory; contact sheets are for QA, never production replacements."""
from pathlib import Path
from PIL import Image,ImageOps,ImageDraw,ImageFont
from playwright.sync_api import sync_playwright
import json,re,html,shutil
ROOT=Path(__file__).resolve().parents[1]
RES=ROOT/'CraneExam/Resources'
OUT=ROOT.parent/'tmp/figure_style_20261106'
OUT.mkdir(exist_ok=True)
for name in ['textbook.json','_manifest.json']:
    if not (OUT/name).exists():shutil.copyfile(RES/name,OUT/name)
data=json.loads((RES/'textbook.json').read_text(encoding='utf-8'))
records={}
def put(file,chapter,usage,caption):
    if not file:return
    x=records.setdefault(file,dict(file=file,chapter=chapter,uses=[],caption=caption))
    x['uses'].append(usage)
def assetfile(asset):
    return next((asset+ext for ext in ['.png','.jpg','.jpeg'] if (RES/'images'/(asset+ext)).exists()),None)
for chapter in data['chapters']:
    for section in chapter['sections']:
        for block in section['blocks']:
            if block['type']=='img':put(assetfile(block['asset']),chapter['id'],section['id']+'/'+block['id'],block.get('caption',''))
            elif block['type']=='svg':put(block['file'],chapter['id'],section['id']+'/'+block['id'],block.get('caption',''))
    for term in chapter.get('glossary',[]):
        fs=term.get('figures')
        if fs is None:fs=[dict(file=assetfile(term['img']))] if term.get('img') else []
        for figure in fs:put(figure['file'],chapter['id'],'glossary/'+term['term'],figure.get('caption',''))
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True)
    page=browser.new_page()
    for rec in records.values():
        src=RES/'images'/rec['file']
        assert src.exists(),src
        if src.suffix.lower()=='.svg':
            target=OUT/(src.name+'.png')
            if not target.exists():
                raw=src.read_text(encoding='utf-8')
                match=re.search(r'viewBox=["\']\s*[-\d.]+\s+[-\d.]+\s+([\d.]+)\s+([\d.]+)',raw)
                width,height=map(float,match.groups()) if match else (1600,900)
                h=round(1100*height/width)
                page.set_viewport_size(dict(width=1100,height=h))
                page.set_content('<!doctype html><meta charset="utf-8"><style>html,body{margin:0;background:white}svg{display:block;width:1100px;height:'+str(h)+'px}</style>'+raw)
                page.screenshot(path=str(target))
            rec['preview']=str(target.resolve())
        else:rec['preview']=str(src.resolve())
    browser.close()
font=ImageFont.truetype('C:/Windows/Fonts/meiryo.ttc',17)
for chapter in [1,2,3,4]:
    group=[r for r in records.values() if r['chapter']==chapter]
    for n in range(0,len(group),12):
        batch=group[n:n+12]
        sheet=Image.new('RGB',(1560,1940),'#e9edf2');d=ImageDraw.Draw(sheet)
        for i,r in enumerate(batch):
            x=(i%3)*520;y=(i//3)*485
            im=Image.open(r['preview']).convert('RGB')
            im.thumbnail((494,410))
            sheet.paste(im,(x+13+(494-im.width)//2,y+48+(410-im.height)//2))
            label=f'{chapter}:{n+i+1:02} '+r['file']
            d.text((x+12,y+4),label[:53],font=font,fill='#173353')
            d.text((x+12,y+25),r['uses'][0].split('/')[0]+' '+r['caption'][:27],font=font,fill='#53616e')
            r['auditID']=f'{chapter}:{n+i+1:02}'
        sheet.save(OUT/f'chapter{chapter}-sheet{n//12+1}.jpg',quality=88)
(OUT/'inventory.json').write_text(json.dumps(list(records.values()),ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Inventoried',len(records),'unique figures from textbook and glossary.')
