"""Verify chapter 3 scope, anchors, assets, mobile checks and PDF integrity."""
from pathlib import Path
import collections,hashlib,json,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[2]
RES=ROOT/'crane-app/CraneExam/Resources';BASE=ROOT/'tmp/ch4_revision_20261106';DOC=ROOT/'crane-app/docs/reviews'
read=lambda p:json.loads(p.read_text('utf-8'))
before=read(BASE/'textbook.json');book=read(RES/'textbook.json');chapter=book['chapters'][3]
for i in (0,1,2):assert before['chapters'][i]==book['chapters'][i]
assert (RES/'exams.json').read_bytes()==(BASE/'exams.json').read_bytes()
assert [(s['id'],s['title']) for s in before['chapters'][3]['sections']]==[(s['id'],s['title']) for s in chapter['sections']]
available={(s['id'],b['id']) for c in book['chapters'] for s in c['sections'] for b in s['blocks']}
oldanchors={(s['id'],b['id']) for s in before['chapters'][3]['sections'] for b in s['blocks']}
assert oldanchors<=available
counts=collections.Counter();styles=collections.Counter()
for s in chapter['sections']:
    assert len(s['blocks'])==len({b['id'] for b in s['blocks']})
    for i,b in enumerate(s['blocks']):
        counts[b['type']]+=1;styles[b.get('style','normal')]+=1
        for t in [b.get('text',''),b.get('caption','')]+b.get('items',[])+b.get('headers',[])+sum(b.get('rows',[]),[]):assert t.count('**')%2==0,(b['id'],t)
        if b['type']=='table':assert len(b['headers']) in (2,4) and all(len(r)==len(b['headers']) for r in b['rows'])
        if b['type']=='svg':ET.parse(RES/'images'/b['file'])
        if b['type']=='img':assert any((RES/'images'/(b['asset']+x)).exists() for x in ['.png','.jpg','.jpeg'])
        if b.get('style')=='reference':assert any(t['id']==b['file'] for c in book['chapters'] for t in c['sections'])
        if b.get('style')=='question':assert s['blocks'][i+1].get('style')=='answer'
    assert sum(b.get('style')=='question' for b in s['blocks'])==sum(b.get('style')=='answer' for b in s['blocks'])
for g in chapter['glossary']:
    if g.get('img'):assert any((RES/'images'/(g['img']+x)).exists() for x in ['.png','.jpg','.jpeg','.svg'])
refchecks={}
for label,path in [('working',RES/'exams.json'),('published',ROOT/'tmp/ch3_release_20261106/remote_exams_before.json')]:
    exams=read(path);refs=[r for e in exams for q in e['questions'] for r in q['refs']]
    assert all((r['section'],r['blockID']) in available for r in refs)
    refchecks[label]={'questions':sum(len(e['questions']) for e in exams),'references':len(refs),'chapter4_references':sum(r['section'].startswith('4-') for r in refs)}
visual=read(BASE/'visual-checks.json')
assert len(visual['sections'])==8 and not any(s['horizontal_overflow'] for s in visual['sections'])
assert not any(s['clipped_text'] for s in visual['svg'])
pdf=read(BASE/'pdf-checks.json');assert pdf['text_preserved_after_compression'] and not pdf['sparse_pages'],pdf
manifest=read(RES/'_manifest.json');assets=read(DOC/'chapter4-revision-assets-20261106.json');fingerprints={}
for f in ['textbook.json']+['images/'+x for x in assets['svg_added']]:
    raw=(RES/f).read_bytes();meta={'sha256':hashlib.sha256(raw).hexdigest(),'size':len(raw)}
    manifest['files']['content/'+f]=meta;fingerprints[f]=meta
(RES/'_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,sort_keys=True,separators=(',',':'))+'\n','utf-8')
report=dict(scope='第4章 全8節',source_book='書籍/05_第4章_クレーンの運転のために必要な力学に関する知識.pdf',source_printed_pages='145–183',
 source_method='全章の既存OCRを対照し、数式・方式・数値・図表を中心に下記の原本ページ画像を確認。全ページを一文字ずつ再OCRする監査ではない。',
 source_pdf_pages_visually_reviewed=[145,154,160,166,173,175,176,177,182,183],
 sling_guidance_checked=['https://www.mhlw.go.jp/content/11300000/000627864.pdf','https://www.mhlw.go.jp/web/t_doc?dataId=74020000&dataType=0'],
 original_anchor_ids_retained=len(oldanchors),reference_checks=refchecks,other_chapters_unchanged=True,exam_questions_unchanged=True,
 counts=dict(counts),styles=dict(styles),mobile_browser_width=390,mobile_sections_checked=8,svg_clipping_checked=len(visual['svg']),pdf=pdf,fingerprints=fingerprints,
 native_ios_compile_performed=False,ota_deployed=False,
 ui_note='第4章の節内目次と、4列表をマトリクス形式で表示するソース変更あり。第3章公開後の変更で、まだビルド・配信していない。')
(DOC/'chapter4-revision-validation-20261106.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n','utf-8')
print(json.dumps({k:report[k] for k in ['original_anchor_ids_retained','reference_checks','counts','styles','mobile_sections_checked','svg_clipping_checked','ota_deployed']},ensure_ascii=False))
