"""整理前バックアップと比較し、図・用語・法令の詳細が欠けていないことを検証。"""
import json
import re
from pathlib import Path
from restyle_textbook import PATH, REWRITES


def plain(text):
    return re.sub(r'\s+|\*\*', '', text)


def text(block):
    return ''.join([block.get('text', '')] + block.get('items', []) + sum(block.get('rows', []), []))


backup = sorted(PATH.parent.glob('textbook.json.bak_pre_study_layout_*'))[-1]
before = json.loads(backup.read_text(encoding='utf-8'))
after = json.loads(PATH.read_text(encoding='utf-8'))
assert len(before['chapters']) == len(after['chapters']) == 4
for oc, nc in zip(before['chapters'], after['chapters']):
    assert oc['glossary'] == nc['glossary']
    assert len(oc['sections']) == len(nc['sections'])
    for os, ns in zip(oc['sections'], nc['sections']):
        assert (os['id'], os['title']) == (ns['id'], ns['title'])
        assert [b for b in os['blocks'] if b['type'] in ('img', 'svg')] == [b for b in ns['blocks'] if b['type'] in ('img', 'svg')]
        assert sum(b.get('style') == 'lead' for b in ns['blocks']) == 1
        full = plain(''.join(map(text, ns['blocks'])))
        for i, b in enumerate(os['blocks']):
            # 法令の短文化は明示した導入・学習案内のみを許す。
            edited = oc['id'] == 2 and b['type'] == 'p' and (i == 0 or any(b['text'].startswith(p) for p in REWRITES))
            if not edited:
                for phrase in [b.get('text', '')] + b.get('items', []) + sum(b.get('rows', []), []):
                    assert plain(phrase) in full, (os['id'], phrase[:50])
        for b in ns['blocks']:
            for phrase in [b.get('text', '')] + b.get('items', []) + sum(b.get('rows', []), []):
                assert phrase.count('**') % 2 == 0, (ns['id'], phrase)
                assert phrase.count('{{') == phrase.count('}}'), ns['id']
    old_lengths = [len(b['text']) for s in oc['sections'] for b in s['blocks'] if b['type'] == 'p']
    new_lengths = [len(b['text']) for s in nc['sections'] for b in s['blocks'] if b['type'] == 'p']
    print(f"Chapter {nc['id']}: details/figures/glossary preserved; paragraphs >180 chars {sum(n > 180 for n in old_lengths)} -> {sum(n > 180 for n in new_lengths)}")
print('PASS: all 41 sections, existing detail facts and quiz markup checked')
