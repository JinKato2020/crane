"""Data/selection-model checks runnable without Xcode. Native engine tests live in verify_study_quiz.swift."""
import collections
import hashlib
import json
import re
import unicodedata
from pathlib import Path
from revise_study_quiz_20261106 import ROOT, TARGETS, content_only, pattern, plain

def fields(section):
    result = []
    for i, b in enumerate(section['blocks']):
        base = f'{section["id"]}/{i}'
        def add(name, raw):
            result.append(dict(id=f'{base}/{name}', raw=raw, text=plain(raw), terms=b.get('quizTerms', []), block=b['id']))
        if b['type'] == 'p' and b.get('style') not in ('lead', 'question', 'answer', 'reference'):
            add('text', b.get('text', ''))
        elif b['type'] in ('ul', 'point'):
            for j, raw in enumerate(b.get('items', [])): add(f'items:{j}', raw)
        elif b['type'] == 'table':
            for r, row in enumerate(b.get('rows', [])):
                if b.get('style') == 'numbers':
                    add(f'rows:{r}:value', ' ／ '.join(row[1:]))
                else:
                    count = len(b.get('headers', []))
                    for c, raw in enumerate(row[:2 if count <= 2 else count]): add(f'rows:{r}:{c}', raw)
    return result

def is_formula(answer):
    return any(ch in answer for ch in '×÷＝') or bool(re.search(r'[A-Z][₀-₉²³]|^[A-Z]/[a-zA-Z]$',answer))

def candidates(section):
    result, seen = [], set()
    for f in fields(section):
        terms = sorted(set(f['terms']), key=lambda t: (-len(t), t))
        if not terms: continue
        for match in re.finditer('|'.join(map(pattern, terms)), f['text']):
            answer = match[0]
            key = ''.join(unicodedata.normalize('NFKC', answer).lower().split())
            if key in seen: continue
            seen.add(key)
            offset = len(f['text'][:match.start()].encode('utf-16-le')) // 2
            result.append(dict(id=f'{f["id"]}#{offset}', fieldID=f['id'], block=f['block'],
                               answer=answer, category='num' if re.search(r'\d', answer) and not is_formula(answer) else 'key',
                               prompt='［式？］' if is_formula(answer) else ('［数値？］' if re.search(r'\d', answer) else '［用語？］'),
                               start=match.start(), end=match.end(), context=f['text']))
    return result

def stable_hash(value):
    h = 14695981039346656037
    for v in value.encode(): h = ((h ^ v) * 1099511628211) & ((1 << 64) - 1)
    return h

def selection(pool, category='all', round=0):
    pool = sorted((p for p in pool if category == 'all' or p['category'] == category), key=lambda x: (stable_hash(x['id']), x['id']))
    if not pool: return []
    start = max(0, round) % len(pool)
    result, counts, rows = [], collections.Counter(), set()
    for item in pool[start:] + pool[:start]:
        f = item['fieldID']
        if counts[f] >= 2: continue
        if '/rows:' in f:
            row = f.rsplit(':', 1)[0]
            if row in rows: continue
            rows.add(row)
        result.append(item)
        counts[f] += 1
        if len(result) == 10: break
    return result

def main():
    resources = ROOT / 'CraneExam/Resources'
    data = json.loads((resources / 'textbook.json').read_text(encoding='utf-8'))
    baseline = ROOT.parent / 'tmp/study_quiz_20261106'
    if (baseline / 'textbook.json').exists():
        old = json.loads((baseline / 'textbook.json').read_text(encoding='utf-8'))
        assert content_only(data) == content_only(old), 'Prose, figures or glossary changed'
        assert (resources / 'exams.json').read_bytes() == (baseline / 'exams.json').read_bytes(), 'Exam changes outside scope'
        before = json.loads((baseline / '_manifest.json').read_text(encoding='utf-8'))
        after = json.loads((resources / '_manifest.json').read_text(encoding='utf-8'))
        before['files'].pop('content/textbook.json'); after['files'].pop('content/textbook.json')
        assert before == after, 'Unrelated manifest entry changed'
    assert (resources / 'textbook.json').read_bytes() == (ROOT.parent / 'アプリ/教材/textbook.json').read_bytes()
    manifest = json.loads((resources / '_manifest.json').read_text(encoding='utf-8'))['files']['content/textbook.json']
    assert manifest['sha256'] == hashlib.sha256((resources / 'textbook.json').read_bytes()).hexdigest()
    assert manifest['size'] == (resources / 'textbook.json').stat().st_size
    audit, total, checks = [], 0, 0
    for ch in data['chapters']:
        for section in ch['sections']:
            pool = candidates(section)
            expected = set(TARGETS.get(section['id'], '').split('|')) - {''}
            actual = {item['answer'] for item in pool}
            assert actual == expected, (section['id'], 'missing', expected - actual, 'extra', actual - expected)
            covered = set()
            for category in ['all', 'key', 'num']:
                count = len([p for p in pool if category == 'all' or p['category'] == category])
                for r in range(max(1, count)):
                    chosen = selection(pool, category, r)
                    assert bool(chosen) == bool(count)
                    assert len(chosen) <= 10
                    assert len({p['answer'] for p in chosen}) == len(chosen)
                    assert all(n <= 2 for n in collections.Counter(p['fieldID'] for p in chosen).values())
                    assert all(n <= 1 for n in collections.Counter(p['fieldID'].rsplit(':',1)[0] for p in chosen if '/rows:' in p['fieldID']).values())
                    assert all(category == 'all' or p['category'] == category for p in chosen)
                    covered.update(p['id'] for p in chosen)
                    checks += 1
            assert covered == {p['id'] for p in pool}, 'Candidate unreachable in later rounds'
            total += len(pool)
            audit.append(dict(section=section['id'], title=section['title'], candidates=len(pool),
                              firstRound=len(selection(pool)), numbers=sum(p['category']=='num' for p in pool)))
    # These regressions used to hide part of another term or only the digits of a quantity.
    for term, text in [('速度','加速度'), ('導体','半導体'), ('静止摩擦力','最大静止摩擦力'), ('7.8','7.8t/m³'), ('5t','15t'), ('1','10')]:
        assert not re.search(pattern(term), text), (term,text)
    assert re.search(pattern('定格速度'), '定格荷重・定格速度')
    report = dict(status='PASS', nativeSwiftExecuted=False, selectionModelChecks=checks, candidateCount=total,
                  sections=audit, preserved=['textbook prose', 'glossary', 'figures', 'exam data', 'unrelated manifest entries'])
    (ROOT / 'docs/reviews/study-quiz-checks-20261106.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n',encoding='utf-8',newline='\n')
    print(f'PASS: {total} distinct answers, {checks} category/round cases; original content and manifests preserved.')
    for row in audit:
        print(row['section'], f"pool={row['candidates']} first={row['firstRound']} numeric={row['numbers']}")

if __name__ == '__main__': main()
