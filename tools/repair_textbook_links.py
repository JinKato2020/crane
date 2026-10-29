"""480問の監査計画を反映。事前バックアップ必須。ネットワーク・配信・ビルドは行わない。"""
import hashlib
import json
import re
from collections import defaultdict
from pathlib import Path
from link_repair.lessons import LESSONS
from restyle_textbook import chunks

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / 'CraneExam/Resources'
PLAN = json.loads((ROOT / 'tools/link_repair/plan.json').read_text(encoding='utf-8'))


def flat(block):
    return '\n'.join([block.get('text', ''), block.get('caption', '')]
                     + block.get('items', []) + block.get('headers', []) + sum(block.get('rows', []), []))


def find(section, phrase):
    bs = section['blocks']
    for test in [lambda b: b['type'] == 'sub' and b.get('text') == phrase,
                 lambda b: b['type'] == 'sub' and phrase in b.get('text', ''),
                 lambda b: phrase in flat(b)]:
        idx = next((i for i, b in enumerate(bs) if test(b)), None)
        if idx is not None:
            return idx
    raise ValueError((section['id'], phrase))


def write_json(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')


def make_ref(section, phrase):
    i = find(section, phrase)
    b = section['blocks'][i]
    label = b.get('text', '') if b['type'] == 'sub' else phrase
    return {'section': section['id'], 'blockID': b['id'], 'anchor': phrase, 'label': label}


# 対比問題で必要な追加参照。語の部分一致から自動推定しない。
EXTRA = {}
def extra(ids, *targets):
    for key in ids.split():
        EXTRA.setdefault(key, []).extend(targets)

extra('1-2', ('1-2','作業半径とジブ傾斜角'), ('1-2','寄り・インチング・地切り・キャンバ'))
extra('1-6 3-6 9-4 10-4 11-4 12-4', ('1-10','巻過防止装置'), ('1-10','衝突防止・逸走防止・斜行防止'), ('1-8','フックブロック'))
extra('9-4 11-4', ('1-10','過負荷防止装置'), ('1-10','車輪止めと緩衝装置'))
extra('1-4 2-3 3-5', ('1-8','グラブバケット'), ('1-8','スプレッダ'), ('1-8','リフティングマグネット'), ('1-8','バキューム式つり具'))
extra('1-10 9-7', ('1-12','ワイヤロープはどこが傷みやすいか'), ('1-11','モーターを止めるだけ'))
extra('4-7 9-9 10-9', ('1-5','トロリとホイスト'), ('1-6','主巻と補巻'), ('1-4','ホイストの横行方式'))
extra('10-1 12-1', ('1-3','横行と走行'), ('1-3','起伏と旋回'), ('1-2','スパンと揚程'))
extra('9-2 11-2 12-2', ('1-5','構造部分とは'), ('1-5','ガーダの形が違う理由'))
extra('11-10', ('1-14','荷の振れを抑える'), ('1-14','行ってはいけない操作'))
extra('1-15 5-35 7-34', ('2-2','強風時の決まり'), ('2-3','暴風後・地震後の点検'))
extra('1-13 3-13 5-34 11-15', ('2-3','年次自主検査'), ('2-3','記録して3年間保存'))
extra('2-34 3-13 4-33 10-17', ('2-3','月次自主検査'), ('2-3','作業開始前の点検'))
extra('8-33 9-17 11-17', ('2-3','作業開始前の点検'), ('2-3','記録して3年間保存'))
extra('4-34 6-40 8-34', ('2-3','作業開始前の点検'), ('2-3','暴風後・地震後の点検'))
extra('6-40', ('2-2','使用の制限と検査証の備付け'), ('2-2','傾斜角の制限'))
extra('4-31 7-31 8-31', ('2-1','設置届'), ('2-1','落成検査'))
extra('1-12 2-32 9-15 11-15', ('2-1','落成検査'), ('2-4','性能検査(検査証の更新)'))
extra('5-33', ('2-4','変更の手続き'))
extra('1-16 2-37 4-35 5-36 6-34 9-18 11-18', ('2-6','操作方式と限定免許'), ('2-6','運転に必要な資格'))
extra('1-16 2-37 4-36 5-36 9-18 10-18', ('2-6','玉掛け業務の資格'))
extra('3-20 7-40 8-39 12-19', ('2-2','傾斜角の制限'), ('2-2','強風時の決まり'))
extra('5-39 7-39 9-19 11-19', ('2-2','巻過ぎの防止'), ('2-2','傾斜角の制限'))
extra('1-22', ('3-1','実効値のイメージ'), ('3-1','単相交流と三相交流'), ('3-1','周波数'))
extra('2-13 3-23 5-13 6-19 7-13 9-21 10-21 11-21', ('3-1','直流と交流'), ('3-1','実効値のイメージ'))
extra('9-21 11-21', ('3-1','単相交流と三相交流'), ('3-1','周波数'))
extra('2-15 3-25 4-15 5-14 6-20 12-23', ('3-3','同期速度――'), ('3-3','すべり――'))
extra('2-16', ('3-6','回転方向の変え方'))
extra('6-15 9-24 10-24 12-24', ('3-4','直接制御器（ドラム形）'), ('3-4','間接制御器'))
extra('2-20 9-24', ('3-4','操作ハンドル'))
extra('4-16 5-19 8-19', ('3-4','付属機器と保護装置'), ('3-7','接地（アース）'))
extra('1-29 2-18 9-30 11-30', ('3-7','感電'))
extra('3-27 5-18 8-18', ('3-7','絶縁・漏えい電流'))
extra('6-16 9-25 11-25', ('3-5','トロリ線給電'), ('3-5','キャブタイヤケーブル給電'), ('3-5','スリップリング給電'))
extra('10-25 12-25', ('3-7','電気装置の故障と原因'), ('3-2','ジュール熱：'))
extra('11-22 12-22', ('3-2','直列と並列が混ざった回路'), ('3-2','電力・電力量・ジュール熱'))
extra('7-29', ('4-0','単位をそろえる'), ('4-2','密度と比重'))
extra('4-28', ('4-5','時間や場所による分類'))
extra('5-28 10-39 11-39', ('4-5','応力：'), ('4-5','ひずみ：'), ('4-5','応力ひずみ曲線'))
extra('5-24 9-34 11-34 12-34', ('4-3','重心は'), ('4-3','安定：'))
extra('6-21 8-26 5-21', ('4-1','合力と分力'))
extra('4-27 7-27', ('4-1','tanとsin――'))
extra('6-24 8-23', ('4-6','荷を支える力'), ('4-6','補足：張力係数'))
extra('1-34 2-25 3-34 4-23 5-27 9-38 10-38 11-38 12-38', ('4-6','補足：張力係数'))
extra('6-23', ('4-7','組合せ滑車'), ('4-7','仕事：'))
extra('8-21', ('4-7','定滑車と動滑車'))
extra('10-40 11-40 12-40', ('4-7','組合せ滑車'), ('4-7','仕事：'))
extra('3-6', ('1-10','車輪止めと緩衝装置'))
extra('9-4', ('3-7','リミットスイッチ'))
extra('10-4 12-4', ('1-10','過負荷防止装置'))
for qid in ('9-4','10-4','11-4','12-4'):
    EXTRA[qid] = [t for t in EXTRA[qid] if t != ('1-8','フックブロック')]
for qid in ('9-4','11-4'):
    EXTRA[qid] = [t for t in EXTRA[qid] if t != ('1-10','車輪止めと緩衝装置')]
EXTRA['3-6'] = [t for t in EXTRA['3-6'] if t != ('1-10','衝突防止・逸走防止・斜行防止')]


def repair(book, exams):
    sections = {s['id']: s for c in book['chapters'] for s in c['sections']}
    assert not any(b.get('id', '').startswith('lesson-') for s in sections.values() for b in s['blocks']), '二重適用禁止'
    # 年次・月次・開始前・暴風地震後を別の見出しへ。元の文章は省略しない。
    sec = sections['2-3']
    rebuilt = []
    for b in sec['blocks']:
        if b['type'] == 'table' and b['headers'][0] == '検査・点検':
            for label, body in b['rows']:
                rebuilt.append({'type': 'sub', 'text': label})
                rebuilt.extend({'type': 'p', 'text': part, 'quizTerms': [t for t in b.get('quizTerms', []) if t in part]} for part in chunks(body))
        else:
            rebuilt.append(b)
    sec['blocks'] = rebuilt
    # 同じ既存見出しへの追記をまとめて挿入し、順番を保つ。
    additions = defaultdict(list)
    for lesson in LESSONS:
        s = sections[lesson['section']]
        i = find(s, lesson['after'])
        end = next((j for j in range(i + 1, len(s['blocks'])) if s['blocks'][j]['type'] == 'sub'), len(s['blocks']))
        additions[(s['id'], end)].append(lesson)
    for (sid, end), lessons in sorted(additions.items(), key=lambda item: (item[0][0], -item[0][1])):
        blocks = []
        for lesson in lessons:
            blocks.append({'type': 'sub', 'id': 'lesson-' + lesson['key'], 'text': lesson['title']})
            for block in lesson['blocks']:
                text = flat(block)
                terms = ['フランジ','ウェブ','キャンバ','シンブル','サドル','ツイストロック','支持ロープ','開閉ロープ',
                         '全波整流','平滑回路','脈流','巻数比','電圧比','周期','電磁誘導','起電力','回生','抵抗制動',
                         'V/f','1/√3','1/3','同期速度','すべり','二次抵抗','直巻直流電動機','効率','主幹制御器',
                         'サーマルリレー','バイメタル','電磁接触器','チャタリング','無電圧','残留電荷','放電','偶力',
                         'tanθ','cosθ','sinβ','20.6kN','10.2kN','75％','40V']
                block['quizTerms'] = [term for term in terms if term in text]
            blocks.extend(lesson['blocks'])
        sections[sid]['blocks'][end:end] = blocks
    # 全ブロックへ固定IDを付与。今後は文言を編集してもIDを維持する。
    for s in sections.values():
        used = set()
        for b in s['blocks']:
            if not b.get('id'):
                seed = json.dumps({k:v for k,v in b.items() if k not in ('quizTerms','style')}, ensure_ascii=False, sort_keys=True)
                base = s['id'] + '-' + hashlib.sha256(seed.encode()).hexdigest()[:12]
                candidate, index = base, 2
                while candidate in used:
                    candidate, index = base + '-' + str(index), index + 1
                b['id'] = candidate
            assert b['id'] not in used
            used.add(b['id'])
    plan = {r['id']: r for r in PLAN}
    lessons_by_question = defaultdict(list)
    for lesson in LESSONS:
        for qid in lesson['questions']:
            lessons_by_question[qid].append(make_ref(sections[lesson['section']], lesson['title']))
    for exam in exams:
        for q in exam['questions']:
            qid = f"{exam['round']}-{q['no']}"
            if qid in ('1-6','1-10','2-18'):
                assert len(q['choices']) == 6
                continuation = q['choices'].pop(0)
                body = continuation[re.search(r'A\s', continuation).start():]
                body = re.sub(r'\s+([B-E])\s', r'\n\n\1 ', body)
                body = re.sub(r'。(?=[B-E]\s)', '。\n\n', body)
                q['text'] = q['text'].split('組合せは')[0] + '組合せはどれか。\n\n' + body
            r = plan[qid]
            base_ref = make_ref(sections[r['recommended_section']], r['recommended_anchor'])
            added = lessons_by_question[qid]
            if r['coverage'] == '主根拠の説明不足':
                assert added, qid
                if qid == '8-16':
                    added.sort(key=lambda ref: ref['blockID'] != 'lesson-protection-roles')
                refs = added
            else:
                refs = [base_ref] + added
            refs += [make_ref(sections[sid], phrase) for sid, phrase in EXTRA.get(qid, [])]
            seen = set()
            refs = [ref for ref in refs if not ((ref['section'],ref['blockID']) in seen or seen.add((ref['section'],ref['blockID'])))]
            q['refs'] = refs
            q['ref'] = refs[0].copy()
    return book, exams


if __name__ == '__main__':
    for name in ['textbook.json','exams.json']:
        assert list(RES.glob(name+'.bak_pre_link_repair_*')), name+' のバックアップが必要'
    book, exams = repair(json.loads((RES/'textbook.json').read_text(encoding='utf-8')),
                         json.loads((RES/'exams.json').read_text(encoding='utf-8')))
    write_json(RES/'textbook.json', book)
    write_json(RES/'exams.json', exams)
    print('Repaired 480 question references and 3 malformed questions; added',len(LESSONS),'shared lessons')
