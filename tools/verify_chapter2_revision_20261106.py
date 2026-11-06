"""Check chapter 2 integrity, source coverage, reference anchors and rendering."""
from pathlib import Path
import collections, hashlib, json, re, xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[2]
RES=ROOT/'crane-app/CraneExam/Resources';BASE=ROOT/'tmp/ch2_revision_20261106'
DOC=ROOT/'crane-app/docs/reviews'
read=lambda p:json.loads(p.read_text('utf-8'))
before=read(BASE/'textbook.json');book=read(RES/'textbook.json');chapter=book['chapters'][1]
for index in (0,2,3):assert before['chapters'][index]==book['chapters'][index]
assert (RES/'exams.json').read_bytes()==(BASE/'exams.json').read_bytes()
assert [(s['id'],s['title']) for s in before['chapters'][1]['sections']]==[(s['id'],s['title']) for s in chapter['sections']]
available={(s['id'],b['id']) for c in book['chapters'] for s in c['sections'] for b in s['blocks']}
oldanchors={(s['id'],b['id']) for s in before['chapters'][1]['sections'] for b in s['blocks']}
assert oldanchors<=available
counts=collections.Counter();styles=collections.Counter()
for s in chapter['sections']:
    assert len(s['blocks'])==len({b['id'] for b in s['blocks']})
    for b in s['blocks']:
        counts[b['type']]+=1;styles[b.get('style','normal')]+=1
        for t in [b.get('text',''),b.get('caption','')]+b.get('items',[])+b.get('headers',[])+sum(b.get('rows',[]),[]):
            assert t.count('**')%2==0,(b['id'],t)
            assert not re.search(r'(?<=[0-9０-９])月',t),(b['id'],t)
        if b['type']=='table':
            assert len(b['headers'])==2,b['id']
            assert all(len(r)==2 for r in b['rows'])
        if b['type']=='svg':ET.parse(RES/'images'/b['file'])
        if b['type']=='img':assert any((RES/'images'/(b['asset']+x)).exists() for x in ['.png','.jpg','.jpeg'])
        if b.get('style')=='reference':assert any(t['id']==b['file'] for c in book['chapters'] for t in c['sections'])
    assert sum(b.get('style')=='question' for b in s['blocks'])==sum(b.get('style')=='answer' for b in s['blocks'])
refchecks={}
for label,path in [('working',RES/'exams.json'),('published_snapshot',ROOT/'tmp/ch1_release_20261106/remote_exams_before.json')]:
    exams=read(path);refs=[r for e in exams for q in e['questions'] for r in q['refs']]
    assert all((r['section'],r['blockID']) in available for r in refs)
    refchecks[label]={'questions':sum(len(e['questions']) for e in exams),'references':len(refs),'chapter2_references':sum(r['section'].startswith('2-') for r in refs)}
visual=read(BASE/'visual-checks.json')
assert len(visual['sections'])==8
assert not any(s['horizontal_overflow'] for s in visual['sections'])
assert not any(s['clipped_text'] for s in visual['svg'])
pdf=read(BASE/'pdf-checks.json');assert pdf['text_preserved_after_compression'] and not pdf['sparse_pages']
# Update only this task's resource fingerprints, not pending exam/image changes.
manifest=read(RES/'_manifest.json')
assets=read(DOC/'chapter2-revision-assets-20261106.json')
fingerprints={}
for f in ['textbook.json']+['images/'+x for x in assets['svg_added']]:
    raw=(RES/f).read_bytes();meta={'sha256':hashlib.sha256(raw).hexdigest(),'size':len(raw)}
    manifest['files']['content/'+f]=meta;fingerprints[f]=meta
(RES/'_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,sort_keys=True,separators=(',',':'))+'\n','utf-8')
report=dict(scope='第2章 全8節',source_book='書籍/03_第2章_関係法令.pdf',source_printed_pages='82–111',
 source_method='全章の既存OCRを対照し、条件・数値・図表は下記ページをPDF原本のページ画像で再確認。全ページの文字単位の再OCR監査ではない。',
 source_pdf_pages_visually_reviewed=[84,85,88,92,93,96,104,105,108,109,110],
 current_law_checked='https://laws.e-gov.go.jp/law/347M50002000034',
 original_anchor_ids_retained=len(oldanchors),reference_checks=refchecks,
 other_chapters_unchanged=True,exam_questions_unchanged=True,counts=dict(counts),styles=dict(styles),
 mobile_browser_width=390,mobile_sections_checked=8,svg_clipping_checked=len(visual['svg']),
 pdf=pdf,fingerprints=fingerprints,native_ios_compile_performed=False,ota_deployed=False,
 ui_note='第2章にも節内目次を適用するソース変更あり。第1章のPush後の変更であり、まだビルド・配信していない。')
(DOC/'chapter2-revision-validation-20261106.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n','utf-8')
print(json.dumps({k:report[k] for k in ['original_anchor_ids_retained','reference_checks','counts','styles','mobile_sections_checked','svg_clipping_checked','ota_deployed']},ensure_ascii=False))
