"""教材参照・5択・追記の網羅性と、解説の代表計算を検証する（配信しない）。"""
import collections
import hashlib
import json
import math
import re
from pathlib import Path
from link_repair.lessons import LESSONS

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / 'CraneExam/Resources'
book = json.loads((RES/'textbook.json').read_text(encoding='utf-8'))
exams = json.loads((RES/'exams.json').read_text(encoding='utf-8'))
plan = json.loads((ROOT/'tools/link_repair/plan.json').read_text(encoding='utf-8'))
sections = {s['id']: s for c in book['chapters'] for s in c['sections']}
by_id = {}
for sid, section in sections.items():
    ids = [b.get('id') for b in section['blocks']]
    assert all(ids) and len(ids) == len(set(ids)), sid
    for b in section['blocks']:
        by_id[(sid,b['id'])] = b
        for text in [b.get('text','')] + b.get('items',[]) + sum(b.get('rows',[]),[]):
            assert text.count('**') % 2 == 0, (sid,text)
            assert text.count('{{') == text.count('}}'), (sid,text)
        if b['type'] == 'table':
            assert all(len(row) == len(b['headers']) for row in b['rows']), sid
questions = {f"{e['round']}-{q['no']}":q for e in exams for q in e['questions']}
assert len(exams) == 12 and len(questions) == len(plan) == 480
for exam in exams:
    assert {q['no'] for q in exam['questions']} == set(range(1,41))
    assert all(n == 10 for n in collections.Counter(q['subject'] for q in exam['questions']).values())
reference_count = 0
for key,q in questions.items():
    assert len(q['choices']) == 5 and 1 <= q['answer'] <= 5, key
    assert all(q['choices']) and len(set(q['choices'])) == 5, key
    assert q['refs'] and q['ref'] == q['refs'][0], key
    ids = [(r['section'],r['blockID']) for r in q['refs']]
    assert len(ids) == len(set(ids)), key
    for ref in q['refs']:
        assert (ref['section'],ref['blockID']) in by_id, (key,ref)
        assert ref['anchor'] and ref['label']
        reference_count += 1
for key,choice in {'1-6':'C, D','1-10':'A, D','2-18':'C, D'}.items():
    q=questions[key]
    assert q['choices'][q['answer']-1] == choice, key
    assert '\n\nA ' in q['text'] and '\n\nD ' in q['text'], key
    assert all(len(c) < 35 for c in q['choices']), key
for expected,section in [('1-22','3-1'),('6-8','3-3'),('10-3','1-7'),('2-24','4-1'),('2-29','4-5'),('3-33','4-7'),('7-39','2-2')]:
    assert questions[expected]['ref']['section'] == section, expected
assert questions['1-22']['ref']['blockID'] == 'lesson-rectify-smooth'
assert questions['8-23']['ref']['blockID'] == 'lesson-force-direction'
assert questions['8-16']['ref']['blockID'] == 'lesson-protection-roles'
assert all(any(r['section']=='3-1' and r['blockID']=='lesson-transformer-ratio' for r in questions[k]['refs']) for k in ['1-22','7-20'])
for record in plan:
    if record['gap']:
        applicable = {l['key'] for l in LESSONS if record['id'] in l['questions']}
        actual = {r['blockID'].removeprefix('lesson-') for r in questions[record['id']]['refs']}
        assert applicable and applicable <= actual, record['id']
for lesson in LESSONS:
    assert by_id[(lesson['section'],'lesson-'+lesson['key'])]['text'] == lesson['title']
# 代表数値を本文とは独立に計算し、桁・角度・入力/出力の向きを検算。
checks = {
    '梁の中央曲げ': (40*4*4/8,80), '梁の端寄り曲げ': (40*2*6/8,60),
    '作業半径': (2+10*math.cos(math.radians(60)),7),
    'ロープ巻取り速度': (3.14*.4*(1200/40),37.68),
    'フック上昇速度': (3.14*.4*(1200/40)/4,9.42),
    '変圧器': (200*200/1000,40), '50Hzの半周期': (1/50/2,.01),
    '効率': (6/8,.75), '120度二力合成': (math.sqrt(100+100+200*math.cos(math.radians(120))),10),
    '転倒tan': (.30/.80,.375), '加速距離': ((0+1.5)/2*3,2.25),
    '制動距離': ((1.2+0)/2*(1.2/.3),2.4), '上向き加速張力': (2000*(9.8+.5)/1000,20.6),
    '下向き加速度': (18600/2000-9.8,-.5), '加速する動滑車': (2000*(9.8+.4)/2/1000,10.2),
    '軸出力': (2000*9.8*.3/.75/1000,7.84), '滑車入力の仕事': (1200*9.8*.5/.8,7350),
    '滑車の平均引く力': (1200*9.8*.5/.8/2,3675), '張力水平成分': (39.2*.866,33.9472),
}
for name,(actual,expected) in checks.items():
    assert math.isclose(actual,expected,rel_tol=1e-10,abs_tol=1e-10), name
print(f'PASS: 480 questions, {reference_count} references, {len(LESSONS)} lessons, 3 choice repairs, {len(checks)} numeric checks')

# ローカルにバックアップがあれば、今回触る必要のない図・用語集・問題本文等の保持も確認。
backups = sorted(RES.glob('textbook.json.bak_pre_link_repair_*'))
if backups:
    before = json.loads(backups[-1].read_text(encoding='utf-8'))
    for old,new in zip(before['chapters'],book['chapters']):
        assert old['glossary'] == new['glossary']
        for os,ns in zip(old['sections'],new['sections']):
            assert (os['id'],os['title']) == (ns['id'],ns['title'])
            assert [b for b in os['blocks'] if b['type'] in ('img','svg')] == [{k:v for k,v in b.items() if k!='id'} for b in ns['blocks'] if b['type'] in ('img','svg')]
    before_exams = json.loads(sorted(RES.glob('exams.json.bak_pre_link_repair_*'))[-1].read_text(encoding='utf-8'))
    for oe,ne in zip(before_exams,exams):
        for oq,nq in zip(oe['questions'],ne['questions']):
            key=f"{oe['round']}-{oq['no']}"
            ignored={'ref','refs'}|({'text','choices'} if key in ('1-6','1-10','2-18') else set())
            assert {k:v for k,v in oq.items() if k not in ignored} == {k:v for k,v in nq.items() if k not in ignored},key
    print('PASS: figures, glossary, section identities, 477 stems/choices and all answers/explanations preserved')
