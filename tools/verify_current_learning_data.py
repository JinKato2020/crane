"""Current-release checks, independent of historical one-task migration snapshots."""
from pathlib import Path
import collections
import hashlib
import json
from verify_study_quiz import TARGETS, candidates, selection, pattern, re

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT/'CraneExam/Resources'
book = json.loads((RES/'textbook.json').read_text(encoding='utf-8'))
canonical = ROOT.parent/'アプリ/教材/textbook.json'
if canonical.exists(): assert (RES/'textbook.json').read_bytes() == canonical.read_bytes()
sections = {s['id']:s for c in book['chapters'] for s in c['sections']}
pool_count = 0
rounds = 0
for section in sections.values():
    pool = candidates(section)
    expected = set(TARGETS.get(section['id'],'').split('|'))-{''}
    assert {p['answer'] for p in pool} == expected, section['id']
    covered = set()
    for category in ['all','key','num']:
        count = len([p for p in pool if category=='all' or p['category']==category])
        for rotation in range(max(1,count)):
            chosen = selection(pool,category,rotation)
            assert bool(chosen)==bool(count) and len(chosen)<=10
            assert len({p['answer'] for p in chosen})==len(chosen)
            assert all(n<=2 for n in collections.Counter(p['fieldID'] for p in chosen).values())
            assert all(n<=1 for n in collections.Counter(p['fieldID'].rsplit(':',1)[0] for p in chosen if '/rows:' in p['fieldID']).values())
            assert all(category=='all' or p['category']==category for p in chosen)
            covered.update(p['id'] for p in chosen); rounds += 1
    assert covered=={p['id'] for p in pool}
    pool_count += len(pool)
for term,text in [('速度','加速度'),('導体','半導体'),('静止摩擦力','最大静止摩擦力'),('7.8','7.8t/m³'),('5t','15t')]:
    assert not re.search(pattern(term),text)

terms = 0
references = 0
for chapter in book['chapters']:
    glossary = chapter.get('glossary',[])
    assert len({t['term'] for t in glossary})==len(glossary)
    figures = []
    for term in glossary:
        assert all(term.get(key) for key in ['summary','reading','category','def','points','references']), term['term']
        assert '**' not in term['def']
        for text in [term['summary']]+term['points']+[term.get('example','')]: assert text.count('**')%2==0
        if term.get('comparison'):
            assert len(term['comparison']['headers'])==2
            assert all(len(row)==2 for row in term['comparison']['rows'])
        for ref in term['references']:
            assert ref['section'] in sections
            assert sum(b['id']==ref['blockID'] for b in sections[ref['section']]['blocks'])==1
            references += 1
        for figure in term.get('figures',[]):
            assert (RES/'images'/figure['file']).is_file() and figure['caption']
            figures.append(figure['file'])
        if term.get('img'): assert (RES/'images'/(term['img']+'.png')).exists()
    assert len(figures)==len(set(figures)), chapter['id']
    terms += len(glossary)
manifest = json.loads((RES/'_manifest.json').read_text(encoding='utf-8'))
for key,entry in manifest['files'].items():
    path = RES/key.removeprefix('content/')
    data = path.read_bytes()
    assert len(data)==entry['size'] and hashlib.sha256(data).hexdigest()==entry['sha256'], key
print(f'PASS: {pool_count} recall answers, {rounds} category/rotation cases, {terms} terms, {references} glossary references, {len(manifest["files"])} resource hashes')
