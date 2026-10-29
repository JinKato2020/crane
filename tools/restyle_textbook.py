"""教材の段落・強調を整理する。法令の数値・条件は既存本文を保持する。"""
import copy
import json
import re
import shutil
from collections import Counter
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / 'CraneExam/Resources/textbook.json'


def sentences(text):
    """括弧・引用・暗記マーカーの途中では分割しない。"""
    pairs = {'(': ')', '（': '）', '「': '」', '『': '』', '【': '】'}
    stack, start, result = [], 0, []
    for i, char in enumerate(text):
        if char in pairs:
            stack.append(pairs[char])
        elif stack and char == stack[-1]:
            stack.pop()
        if char == '。' and not stack and text[:i].count('{{') == text[:i].count('}}'):
            result.append(text[start:i + 1])
            start = i + 1
    if start < len(text):
        result.append(text[start:])
    return result or [text]


def chunks(text, limit=145):
    result, part = [], ''
    for sentence in sentences(text):
        if part and len(part) + len(sentence) > limit:
            result.append(part)
            part = ''
        part += sentence
    if part:
        result.append(part)
    assert ''.join(result) == text
    return result


def mark(text, terms):
    # 既に編集者が強調した段落は、その強弱を尊重する。
    if '**' in text or '{{' in text:
        return text
    candidates = [t for t in terms if 2 <= len(t) <= 22 and t in text]
    if candidates:
        term = max(candidates, key=len)
        text = text.replace(term, f'**{term}**', 1)
    return text


LEADS = {
    '1-0': '**クレーンの仕事は、荷を上げて、横へ運び、下ろすこと。** まず現場の動きを思い浮かべましょう。',
    '1-1': '**動力でつり上げる ＋ 水平に運ぶ。** クレーンを判断するときは、この二つを確かめます。',
    '1-3': '**走行は橋全体、横行は橋の上の台車、巻上げはフック。** どの部分が動くかで区別します。',
    '1-2': '**つり上げ荷重は機械の能力、定格荷重はその条件でつれる荷の上限。** 名前の似た二つを分けて覚えます。',
    '1-4': '**形・走る場所・荷のつかみ方** を見れば、種類を整理できます。まず図で違いをつかみましょう。',
    '1-5': '荷の重さは、ロープから骨組みへ伝わります。**どの部材が荷を支えているか** を追いかけましょう。',
    '1-6': 'モーターの回転を、歯車やドラムへ伝えて荷を動かします。**力が伝わる順番** を見るのがコツです。',
    '1-9': '**歯車は回転を伝え、軸は回り、軸受は軸を支える。** 部品の名前と役目を結びつけます。',
    '1-13': '**ドラムはロープを巻き取る。シーブはロープを案内する。** 似た丸い部品でも仕事が違います。',
    '1-7': '**細い素線 → 束にしたストランド → ワイヤロープ。** 二段階でより合わせた構造です。',
    '1-8': 'フック、つかみ具、電磁石などを、**荷の形や材質に合わせて使い分ける** のがつり具です。',
    '1-10': '**上げすぎ・積みすぎ・走りすぎを防ぐ。** 安全装置は、防ぐ危険とセットで覚えます。',
    '1-11': 'ブレーキの仕事は二つ。**動きを止めること** と、**止めた荷をその位置に保つこと** です。',
    '1-14': '**荷・玉掛け・通り道を、動かす前に確認する。** 運転の手順に沿って安全を考えます。',
    '1-12': '**給油は摩耗を抑えるため、点検は異常を見つけるため。** 部品の働きと結びつけて覚えます。',
    '2-0': '法令は、現場で守るルールです。覚える軸は **数字** と **手続き**。まず「だれが・いつ・だれに・何を」をつかみましょう。',
    '2-1': '最初に **つり上げ荷重3t以上（スタッカー式1t以上）** かを確認。次に、**作るとき** と **据え付けるとき** の手続きを分けます。',
    '2-2': '**巻き上げすぎない・積みすぎない・危険な場所に入らない。** 使う場面を思い浮かべて、守るルールを覚えます。',
    '2-3': '**作業開始前 → 月次 → 年次** の順に整理。検査・点検は、周期と記録の保存期間をセットで覚えます。',
    '2-4': '**使い始める検査** と **検査証を更新する検査** を区別。目的が分かると、試験荷重の違いも整理できます。',
    '2-5': '玉掛用具は、**必要な強さがあるか** と **傷んでいないか** を確認。安全係数と使用禁止の基準を分けて覚えます。',
    '2-6': '資格は **荷物の重さではなく、機械のつり上げ荷重** で判断。運転と玉掛けでは、境目の数字も違います。',
    '2-matome': '数字を思い出せますか？ **何の数字か・以上か超えるか・いつから数えるか** まで、セットで確認しましょう。',
    '3-1': '**電流は流れる量、電圧は流そうとする働き、抵抗は通りにくさ。** まず三つの役割を分けます。',
    '3-3': '電動機（モーター）は、**電気の力を回転に変える機械**。回る仕組みをつかんでから、種類の違いを見ます。',
    '4-0': '**質量は物そのものの量、重量は重力で引かれる力。** 質量が同じでも、重力が違えば重量は変わります。',
}

# 読み方の説明を何度も繰り返さず、短い言葉で学習の焦点を示す。
# 対象・期限・倍率・例外を定める詳細本文と表は削除しない。
REWRITES = {
    '「数字」とは、何トン以上なら': '覚える数字は、**何tから・何日前まで・何％で使用禁止か**。手続きは、**だれが・いつまでに・だれに・何をするか** で整理します。',
    'クレーン限定の学科試験では、この「関係法令」は': '関係法令は **10問・20点（1問2点）**。合格には、各科目 **40％以上**、全科目の合計 **60％以上** が必要です。法令の最低基準は **8点（4問）**。取り違えに備え、半分以上を確実に取れるようにしましょう。',
    '法令の文章は、一見むずかしそうに': '長い一文は、**だれが／どんな場合に／いつまでに／何をするか** に分けます。設置届なら、「設置する人が／対象のクレーンについて／工事開始の30日前までに／所轄の労働基準監督署長へ届け出る」です。',
    '法令には「原則」と「例外」があります。': '**原則は、基本のルール。例外は、条件付きの特別扱い。** 例外を覚えるときは「どんな条件なら使えるか」も一緒に。「いつでもできる」と読み替えないことが大切です。',
    '似た名前の手続きを区別することも': '**携帯＝仕事中に持つ。再交付＝なくした・壊した。書替え＝氏名が変わった。** 名前だけでなく、使う場面で区別しましょう。',
    'この科目で最初に固めてほしいのが': '**境目の数字を含むか** に注目します。たとえば「3t以上」と「3t未満」では、3tちょうどの扱いが逆になります。',
    '法令の問題文では、法律の名前が略語': '問題文に出る略語を確認しましょう。この章でよく使う **「安全規則」＝クレーン等安全規則** です。',
    '「製造」はクレーンを作ること、': '**製造＝作ること。設置＝使う場所へ据え付けること。** 製造許可は「作ってよいか」の確認、設置届は「据え付け工事の計画」の届出です。時期と提出先も分けて覚えます。',
    'まず、どのくらいの大きさで、どんな手続き': 'まず **対象となるつり上げ荷重**、次に **時期と提出先** を確認します。',
    '表の読み方を整理します。製造許可は': '**製造許可は作る前、設置届は据え付け工事の前。** 提出先は、製造許可が **都道府県労働局長**、設置届・設置報告書が **所轄の労働基準監督署長** です。「所轄」は、その場所を担当すること。設置届と設置報告書は、対象の荷重と提出時期が異なります。',
    '建物の中に据え付ける走行クレーンは': '建物の天井・柱・配管とぶつからないように、すき間を確保します。**測る場所・数字・以上か以下か** をセットで覚えましょう。',
    '安全装置は、危険を自動で防ぐ仕組みです。': '安全装置は、危険を自動で防ぐ仕組み。**効く状態を保つこと** が基本です。',
    '風は、クレーンにとって大きな危険です。': '風のルールは **三つの目的** に分けます。「逸走」は、風などで本体が意図せず走り出すことです。',
    '表の読み方を整理します。周期の短い順': '**作業開始前 → 月次 → 年次** の順に整理します。暴風後・地震後は、自然現象の後に行う臨時の点検です。年次の **荷重試験だけを省略する場合** と **検査そのものを省略する期間** は、条件を分けて確認します。',
    '検査・点検は、やりっぱなしでは意味': '作業開始前の点検を除き、自主検査・点検の結果は **記録して3年間保存**。異常があれば **直ちに補修** します。',
    '目的で見分けるのがコツです。': '**落成検査＝使い始める前。性能検査＝検査証の更新。** 目的を見分けてから、試験荷重を確認します。',
    'この「4以上を認めるための材料の強度': 'チェーンの **安全係数4以上を認める材料の条件** と、使用後の **劣化を判定する5％・10％** は、別の基準です。',
    '次は、使ってはいけない(不適格な)': 'ここからは **使用禁止の基準** です。用具ごとに、数字と傷み方を結びつけて覚えましょう。',
    'なお、ワイヤロープとチェーンの数字は': '**ワイヤ：断線10％以上・直径減少7％超。チェーン：伸び5％超・リンク径減少10％超。** 「以上」と「超える」も含めて区別します。',
    '運転資格は、つり上げ荷重と操作方式で': '運転資格は **つり上げ荷重と操作方式** で判断。大きな境目は **5t** です。',
    '玉掛けの資格の境目は': '**運転は5t、玉掛けは1t** が大きな境目。どちらも、荷物の重さではなく **機械のつり上げ荷重** で判断します。',
    '数字は、ただ一列に暗記するより': '**30日前＝工事開始より前。10日以内＝設置者の異動より後。** 数字だけでなく、数える出発点も思い出しましょう。',
    '覚え方のコツは、数字を': '似た数字は、**何が違うかを説明できるように** 比べましょう。「以上・超える」と、手続きの前後にも注目します。',
}


def restyle(data):
    for chapter in data['chapters']:
        for section in chapter['sections']:
            sid = section['id']
            old = section['blocks']
            # 法令の導入を短い結論に置き換える。詳細の条件は後続の本文に残す。
            if sid in LEADS:
                lead = {'type': 'p', 'style': 'lead', 'text': LEADS[sid]}
                lead['quizTerms'] = list(dict.fromkeys(t for b in old for t in b.get('quizTerms', []) if t in lead['text']))
                if chapter['id'] == 2:
                    old = [lead] + old[1:]
                else:
                    old = [lead] + old
            elif old and old[0]['type'] == 'p' and len(old[0].get('text', '')) <= 180:
                old[0]['style'] = 'lead'
            result = []
            for block in old:
                b = copy.deepcopy(block)
                terms = b.get('quizTerms', [])
                if b['type'] == 'p':
                    if chapter['id'] == 2 and b.get('style') != 'lead':
                        for prefix, replacement in REWRITES.items():
                            if b.get('text', '').startswith(prefix):
                                b['text'] = replacement
                                break
                        if b['text'].startswith(('**原則は、基本', '**落成検査＝')):
                            b['style'] = 'tip'
                        elif b['text'].startswith(('チェーンの **安全係数', '**ワイヤ：断線', '**30日前＝')):
                            b['style'] = 'caution'
                    # 一文は壊さず、意味の切れ目で段落を分ける。
                    for text in chunks(b.get('text', '')):
                        part = copy.deepcopy(b)
                        part['text'] = mark(text, terms)
                        if terms:
                            part['quizTerms'] = [t for t in terms if t in text]
                        result.append(part)
                elif b['type'] == 'table' and chapter['id'] == 2 and any(len(cell) > 260 for row in b['rows'] for cell in row):
                    # 長い条文を狭い表のセルに押し込めない。原文の情報は全文残す。
                    for row in b['rows']:
                        result.append({'type': 'sub', 'text': row[0]})
                        for text in chunks('。'.join(row[1:]), 135):
                            result.append({'type': 'p', 'text': mark(text, terms),
                                           'quizTerms': [t for t in terms if t in text]})
                else:
                    if b['type'] in ('ul', 'point'):
                        b['items'] = ['\n\n'.join(mark(part, terms) for part in chunks(t)) for t in b['items']]
                    if b['type'] == 'table' and chapter['id'] == 2:
                        b['rows'] = [[mark(cell, terms) for cell in row] for row in b['rows']]
                        if b['headers'][-1] == '必要な安全係数':
                            b['style'] = 'numbers'
                    result.append(b)
            # 19項目の数値表を、意味のまとまりで小分けにする。行の情報は不変。
            if sid == '2-matome':
                grouped = []
                labels = [(0, 4, '手続き ―― 対象と期限'), (4, 8, '装置・検査 ―― 間隔と試験荷重'),
                          (8, 13, '点検 ―― 周期と保存'), (13, 16, '玉掛用具 ―― 強さと使用禁止'),
                          (16, 19, '資格 ―― 運転と玉掛け')]
                for b in result:
                    if b['type'] == 'table':
                        for start, end, label in labels:
                            grouped.extend([{'type': 'sub', 'text': label},
                                            dict(b, rows=b['rows'][start:end], style='numbers')])
                    else:
                        grouped.append(b)
                result = grouped
            section['blocks'] = result
    return data


if __name__ == '__main__':
    before = json.loads(PATH.read_text(encoding='utf-8'))
    if any(b.get('style') == 'lead' for c in before['chapters'] for s in c['sections'] for b in s['blocks']):
        raise SystemExit('既に整理済みです。二重適用しません。')
    backup = PATH.with_name(PATH.name + '.bak_pre_study_layout_' + datetime.now().strftime('%Y%m%d_%H%M%S'))
    shutil.copy2(PATH, backup)
    after = restyle(copy.deepcopy(before))
    PATH.write_text(json.dumps(after, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
    for c in after['chapters']:
        print(c['id'], Counter(b['type'] for s in c['sections'] for b in s['blocks']))
    print('Backup:', backup)
