"""Verify content integrity and cross-references for the chapter-1 revision.

Does not compile the iOS app or contact the OTA service.
"""
import collections
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
RES = ROOT / 'crane-app/CraneExam/Resources'
BASE = ROOT / 'tmp/ch1_revision_20261106'
read = lambda p: json.loads(p.read_text('utf-8'))
before, current = read(BASE/'textbook.json'), read(RES/'textbook.json')
exams = read(RES/'exams.json')
assert (BASE/'exams.json').read_bytes() == (RES/'exams.json').read_bytes(), 'Exam data changed'
assert before['chapters'][1:] == current['chapters'][1:], 'Other chapters changed'
assert [(s['id'],s['title']) for s in before['chapters'][0]['sections']] == [(s['id'],s['title']) for s in current['chapters'][0]['sections']]
old_glossary = {g['term']: g for g in before['chapters'][0]['glossary']}
allowed = {'剛脚／揺脚','クラブトロリ／ホイスト'}
changed_glossary = []
for g in current['chapters'][0]['glossary']:
    old = old_glossary[g['term']]
    if g != old:
        assert g['term'] in allowed, g['term']
        assert {k:v for k,v in old.items() if k != 'def'} == {k:v for k,v in g.items() if k != 'def'}
        changed_glossary.append(g['term'])
sections = {s['id']:s for c in current['chapters'] for s in c['sections']}
refs = [r for e in exams for q in e['questions'] for r in q.get('refs',[])]
for r in refs:
    assert r['section'] in sections, r
    if r.get('blockID'):
        assert r['blockID'] in {b['id'] for b in sections[r['section']]['blocks']}, r
counts, styles = collections.Counter(), collections.Counter()
for s in current['chapters'][0]['sections']:
    ids = [b['id'] for b in s['blocks']]
    assert len(ids) == len(set(ids)), s['id']
    for b in s['blocks']:
        counts[b['type']] += 1
        styles[b.get('style','normal')] += 1
        strings = [b.get('text',''),b.get('caption','')] + b.get('items',[]) + b.get('headers',[]) + sum(b.get('rows',[]),[])
        for text in strings:
            assert text.count('**') % 2 == 0, (b['id'],text)
            assert text.count('{{') == text.count('}}'), (b['id'],text)
        if b['type']=='table':
            assert all(len(r)==len(b['headers']) for r in b['rows']), b['id']
        if b['type']=='svg':
            ET.parse(RES/'images'/b['file'])
        if b['type']=='img':
            assert any((RES/'images'/(b['asset']+ext)).is_file() for ext in ('.png','.jpg','.jpeg')), b['id']
        if b.get('style')=='reference':
            assert b['file'] in sections, b['id']
    assert sum(b.get('style')=='question' for b in s['blocks']) == sum(b.get('style')=='answer' for b in s['blocks']), s['id']

visual = read(BASE/'visual-checks.json')
assert len(visual['sections']) == len(current['chapters'][0]['sections'])
assert not any(s['horizontal_overflow'] for s in visual['sections'])
assert not any(s['clipped_text'] for s in visual['svg'])
manifest = read(RES/'_manifest.json')['files']
assets = read(ROOT/'crane-app/docs/reviews/chapter1-revision-assets-20261106.json')
files = ['textbook.json']+['images/'+f for f in list(assets['generated'])+assets['svg_edited']+assets['svg_added']]
for f in files:
    raw=(RES/f).read_bytes(); entry=manifest['content/'+f]
    assert entry['sha256']==hashlib.sha256(raw).hexdigest() and entry['size']==len(raw), f
report = dict(questions=sum(len(e['questions']) for e in exams),valid_references=len(refs),
              other_chapters_unchanged=True,exam_questions_unchanged=True,section_ids_unchanged=True,
              glossary_definitions_aligned=changed_glossary,counts=dict(counts),styles=dict(styles),
              browser_preview_width=390,browser_sections_verified=len(visual['sections']),
              svg_clipping_checked=len(visual['svg']),manifest_fingerprints_verified=len(files),
              native_ios_compile_performed=False,ota_deployed=False)
(ROOT/'crane-app/docs/reviews/chapter1-revision-validation-20261106.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n','utf-8',newline='\n')
print(json.dumps(report,ensure_ascii=False))
