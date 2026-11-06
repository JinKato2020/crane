"""Verify chapter 3 scope, anchors, assets, mobile checks and PDF integrity."""
from pathlib import Path
import collections,hashlib,json,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[2]
RES=ROOT/'crane-app/CraneExam/Resources';BASE=ROOT/'tmp/ch3_revision_20261106';DOC=ROOT/'crane-app/docs/reviews'
read=lambda p:json.loads(p.read_text('utf-8'))
before=read(BASE/'textbook.json');book=read(RES/'textbook.json');chapter=book['chapters'][2]
for i in (0,1,3):assert before['chapters'][i]==book['chapters'][i]
assert (RES/'exams.json').read_bytes()==(BASE/'exams.json').read_bytes()
assert [(s['id'],s['title']) for s in before['chapters'][2]['sections']]==[(s['id'],s['title']) for s in chapter['sections']]
available={(s['id'],b['id']) for c in book['chapters'] for s in c['sections'] for b in s['blocks']}
oldanchors={(s['id'],b['id']) for s in before['chapters'][2]['sections'] for b in s['blocks']}
assert oldanchors<=available
counts=collections.Counter();styles=collections.Counter()
for s in chapter['sections']:
    assert len(s['blocks'])==len({b['id'] for b in s['blocks']})
    for i,b in enumerate(s['blocks']):
        counts[b['type']]+=1;styles[b.get('style','normal')]+=1
        for t in [b.get('text',''),b.get('caption','')]+b.get('items',[])+b.get('headers',[])+sum(b.get('rows',[]),[]):assert t.count('**')%2==0,(b['id'],t)
        if b['type']=='table':assert len(b['headers'])==2 and all(len(r)==2 for r in b['rows'])
        if b['type']=='svg':ET.parse(RES/'images'/b['file'])
        if b['type']=='img':assert any((RES/'images'/(b['asset']+x)).exists() for x in ['.png','.jpg','.jpeg'])
        if b.get('style')=='reference':assert any(t['id']==b['file'] for c in book['chapters'] for t in c['sections'])
        if b.get('style')=='question':assert s['blocks'][i+1].get('style')=='answer'
    assert sum(b.get('style')=='question' for b in s['blocks'])==sum(b.get('style')=='answer' for b in s['blocks'])
for g in chapter['glossary']:
    if g.get('img'):assert any((RES/'images'/(g['img']+x)).exists() for x in ['.png','.jpg','.jpeg','.svg'])
refchecks={}
for label,path in [('working',RES/'exams.json'),('published',ROOT/'tmp/ch2_release_20261106/remote_exams_before.json')]:
    exams=read(path);refs=[r for e in exams for q in e['questions'] for r in q['refs']]
    assert all((r['section'],r['blockID']) in available for r in refs)
    refchecks[label]={'questions':sum(len(e['questions']) for e in exams),'references':len(refs),'chapter3_references':sum(r['section'].startswith('3-') for r in refs)}
visual=read(BASE/'visual-checks.json')
assert len(visual['sections'])==9 and not any(s['horizontal_overflow'] for s in visual['sections'])
assert not any(s['clipped_text'] for s in visual['svg'])
pdf=read(BASE/'pdf-checks.json');assert pdf['text_preserved_after_compression'] and not pdf['sparse_pages'],pdf
manifest=read(RES/'_manifest.json');assets=read(DOC/'chapter3-revision-assets-20261106.json');fingerprints={}
for f in ['textbook.json']+['images/'+x for x in assets['svg_added']]:
    raw=(RES/f).read_bytes();meta={'sha256':hashlib.sha256(raw).hexdigest(),'size':len(raw)}
    manifest['files']['content/'+f]=meta;fingerprints[f]=meta
(RES/'_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,sort_keys=True,separators=(',',':'))+'\n','utf-8')
report=dict(scope='第3章 全9節',source_book='書籍/04_第3章_原動機及び電気に関する知識.pdf',source_printed_pages='112–144',
 source_method='全章の既存OCRを対照し、数式・方式・数値・図表を中心に下記の原本ページ画像を確認。全ページを一文字ずつ再OCRする監査ではない。',
 source_pdf_pages_visually_reviewed=[112,116,119,125,129,131,133,135,140,141,144],
 rescue_guidance_checked=['https://www.fdma.go.jp/relocation/e-college/cat65/cat65/cat44/1-15.html','https://internal.fdma.go.jp/hiyarihatto/juyo/anzenkanri_h28/html/23a00.html'],
 original_anchor_ids_retained=len(oldanchors),reference_checks=refchecks,other_chapters_unchanged=True,exam_questions_unchanged=True,
 counts=dict(counts),styles=dict(styles),mobile_browser_width=390,mobile_sections_checked=9,svg_clipping_checked=len(visual['svg']),pdf=pdf,fingerprints=fingerprints,
 native_ios_compile_performed=False,ota_deployed=False,
 ui_note='第3章にも節内目次を適用するソース変更あり。第2章の公開後に行った変更で、まだビルド・配信していない。')
(DOC/'chapter3-revision-validation-20261106.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n','utf-8')
print(json.dumps({k:report[k] for k in ['original_anchor_ids_retained','reference_checks','counts','styles','mobile_sections_checked','svg_clipping_checked','ota_deployed']},ensure_ascii=False))
