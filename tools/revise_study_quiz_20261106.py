"""Curate recall targets without changing textbook prose, illustrations or glossary data."""
import copy
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEXTBOOK = ROOT / 'CraneExam/Resources/textbook.json'
# Whole facts/quantities, never incidental values from worked examples.
TARGETS = {
    '1-1': '動力|水平|人力|つり上げ荷重|0.5 t未満',
    '1-3': 'ガーダ|サドル|トロリ|横行|走行|起伏|旋回|ドラム',
    '1-2': 'つり上げ荷重|定格荷重|定格速度|走行レールの中心間|揚程|作業半径|ジブ傾斜角|寄り|インチング|地切り|キャンバ|ランウェイ',
    '1-4': 'クラブトロリ式|ホイスト式|ロープトロリ式|レードルクレーン|マストクライミング方式|フロアクライミング方式|引込みクレーン|壁クレーン|カンチレバー|アンローダ|メインロープ|テルハ|スタッカークレーン|トップランニング式|サスペンション式',
    '1-5': 'ガーダ|サドル|主索|トラスガーダ|プレートガーダ|ボックスガーダ|フランジ|ウェブ|剛脚|揺脚|セミロープトロリ|マントロリ',
    '1-6': '減速機|トルク|保持|制動用ブレーキ|速度制御用ブレーキ|主巻|補巻|1電動機式|2電動機式|斜行防止装置|ピニオン',
    '1-9': '駆動歯車|従動歯車|減速比|平歯車|はすば歯車|スラスト|ウォーム歯車|かさ歯車|ラジアル荷重|スラスト荷重|高力ボルト|摩擦接合|リーマボルト|割りピン|たわみ軸継手|自在軸継手|こう配キー|平行キー',
    '1-13': 'ドラム|シーブ|ピッチ円直径|2巻以上|捨巻き|フックブロック|エコライザシーブ|駆動輪|遊動輪|フランジ',
    '1-7': 'ストランド|素線|心綱|フィラー線|繊維心|ラングより|普通より|実測直径|公称直径|末端加工効率|アイスプライス|ソケット止め|クリップ止め|くさび止め|シンブル|サドル',
    '1-8': '外れ止め|グラブバケット|支持ロープ|開閉ロープ|リフティングマグネット|停電保護装置|バキューム式|スプレッダ|クロー',
    '1-10': '巻過防止装置|直働式|間接式|0.25m以上|0.05m以上|過負荷防止装置|1/4以上|1/2以上|衝突防止装置|逸走防止装置|30m/sを超える風のおそれ|レールクランプ|アンカー|ゼロノッチインターロック',
    '1-11': '制動|保持|ライニング|ばね|無電圧作動型|バンドブレーキ|ブロックブレーキ|足踏み油圧式ディスクブレーキ|電動油圧押上機ブレーキ|1.5倍以上',
    '1-14': '重心|地切り|追いノッチ|発進時|停止時|インチング|作業半径が大きくなる',
    '1-12': '集中給油|ライニング|必要な場所へ届いたこと|油浴式|グリース|転がり軸受|平軸受',
    '2-0': '労働基準監督署長|以上・以下・以内|未満・超える|対象・期限・条件',
    '2-1': '3t以上|1t以上|30日前まで|0.5t以上3t未満|0.5t以上1t未満|設置報告書|都道府県労働局長|所轄の労働基準監督署長|1.25倍|1.27倍|1年以内|2年|再交付|10日以内|書替え|0.4m以上|1.8m以上|1.5m以上|0.6m以上|0.3m以下',
    '2-2': '作業場所に備え付ける|0.25m以上|0.05m以上|最大の定格荷重|あらかじめ事業者の許可|直ちに元に戻す|クレーン特例報告書|3年間保存|運転者と玉掛けをする者|動力下降|つり具の下|ケーブルクレーンのロープの内角側|作業指揮者|30m/s超の風のおそれ|ジブの位置を固定|離れない',
    '2-3': '作業開始前|1か月以内ごと|1年以内ごと|定格荷重|定格速度|2か月以内|再び使い始めるとき|30m/sを超える|中震以上（震度4以上）|屋内・屋外どちらも|3年間保存|直ちに補修',
    '2-4': '1.25倍|1.27倍|登録性能検査機関|定格荷重|定格速度|2年未満|2年を超え3年以内|変更届＋変更検査|30日前まで|有効期間中|所轄署長へ返還',
    '2-5': '6以上|4以上|5以上|0.5％以下|400N/mm²以上|1よりの間|10％以上|7％を超える|キンク|5%を超える|10%を超える|アイスプライス・圧縮止め|全ストランド3回以上|2回以上|全ストランド4回以上|1回以上',
    '2-6': 'つり上げ荷重|5t以上|床上操作式運転技能講習|床上運転式限定免許|5t未満|特別の教育|荷の移動とともに移動|クレーンの走行とともに移動|満18歳未満|1年未経過|携帯|住所を管轄する局長|6か月以内|1t以上|玉掛け技能講習|1t未満',
    '3-1': '自由電子|半導体|直流|交流|整流|脈流|全波整流|平滑化|変圧器|二次巻数 ÷ 一次巻数|三相|単相|周波数|ヘルツ|実効値|√2',
    '3-2': 'オームの法則|同じ電流|電圧が同じ|合成抵抗|電力|電力量|ジュール熱|V÷R|R₁＋R₂|1/R₁＋1/R₂|R₁×R₂÷（R₁＋R₂）|電力×時間|電圧V×電流I|I²Rt',
    '3-3': '電磁誘導|回転磁界|固定子|回転子|三相誘導電動機|かご形|巻線形|同期速度|周波数|極数|すべり|スリップリング|ブラシ|二次抵抗|電機子|界磁|整流子|直巻直流電動機',
    '3-4': '直接制御器|間接制御器|複合制御器|固定フィンガー|セグメント|エンコーダー|カム|電磁接触器|ノッチ|惰走|主幹制御器|サーマルリレー|バイメタル式|チャタリング',
    '3-5': '充電部|トロリ線|パンタグラフ|集電子|がいし|トロリバー|キャブタイヤケーブル|スリップリング給電|ブラシ',
    '3-6': '2線|相順|スターデルタ始動|1/√3|1/3|インバーター|コンバーター|VVVF|電源回生|抵抗制動|V/f|二次抵抗制御|巻線形|渦電流|可変電圧制御',
    '3-7': '絶縁抵抗計|メガー|無電圧|放電|接地|漏電遮断器|監視人|施錠|絶縁手袋|電流計|電圧計|計器用変圧器|変流器|分流器|短絡|過電流継電器|欠相',
    '4-0': '重力加速度|質量|重量|9.8m/s²',
    '4-1': '力〔N〕×腕の長さ〔m〕|作用点|作用線|合力|分力|平行四辺形|作用・反作用|力のモーメント|偶力',
    '4-2': '密度|比重|7.8t/m³|体積〔m³〕×密度〔t/m³〕',
    '4-3': '重心|真上|広い|モーメント',
    '4-4': '速さ|速度|加速度|三平方の定理|慣性|向心力|遠心力|静止摩擦力|最大静止摩擦力|動摩擦力|転がり摩擦|滑り摩擦|垂直抗力|摩擦係数',
    '4-5': '力〔N〕÷断面積〔mm²〕|衝撃荷重|静荷重|動荷重|繰返し荷重|片振り|両振り|疲労破壊|内力|応力|ひずみ|比例限度|塑性変形|弾性|許容応力',
    '4-6': '6以上|1.16|1.41|2.00|分力|合力|張力係数|安全係数|切断荷重|基本安全荷重|モード係数',
    '4-7': '荷の重量〔N〕÷支える本数|荷を上げる高さ×支える本数|仕事〔J〕÷時間〔s〕|有効な出力÷入力|定滑車|動滑車|2倍|半分|組合せ滑車|仕事|効率',
}

def plain(raw):
    return raw.replace('**', '').replace('__', '')

def fields(block):
    kind = block['type']
    if kind == 'p' and block.get('style') not in ('lead', 'question', 'answer', 'reference'):
        return [plain(block.get('text', ''))]
    if kind in ('ul', 'point'):
        return [plain(x) for x in block.get('items', [])]
    if kind == 'table':
        if block.get('style') == 'numbers':
            return [plain(' ／ '.join(row[1:])) for row in block.get('rows', [])]
        count = len(block.get('headers', []))
        return [plain(x) for row in block.get('rows', []) for x in row[:(2 if count <= 2 else count)]]
    return []

def pattern(term):
    p = re.escape(term)
    kanji = r'[\u3400-\u9fff\u30a1-\u30f6ー]'
    if re.search(r'\d', term):
        p = rf'(?<![0-9０-９.．])(?:{p})(?![0-9０-９.．])'
        if re.search(r'\d$',term): p += r'(?![A-Za-z％%])'
    if re.match(kanji, term[0]): p = rf'(?<!{kanji})' + p
    if re.match(kanji, term[-1]): p += rf'(?!{kanji})'
    return p

def content_only(data):
    result = copy.deepcopy(data)
    for chapter in result['chapters']:
        for section in chapter['sections']:
            for block in section['blocks']:
                block.pop('quizTerms', None)
    return result

def main():
    data = json.loads(TEXTBOOK.read_text(encoding='utf-8'))
    before = content_only(data)
    audit = []
    for chapter in data['chapters']:
        for section in chapter['sections']:
            for block in section['blocks']:
                block.pop('quizTerms', None)
            for term in TARGETS.get(section['id'], '').split('|'):
                if not term:
                    continue
                choices = []
                for index, block in enumerate(section['blocks']):
                    preferred = {
                        ('4-2', '密度'): '4-2-98e5ddeb4bfa',
                        ('4-6', '分力'): '4-6-c120d4e0573e',
                        ('1-2', '作業半径'): '1-2-4cddf2f6fd21',
                    }.get((section['id'], term))
                    if preferred and block['id'] != preferred:
                        continue
                    for text in fields(block):
                        if not re.search(pattern(term), text):
                            continue
                        score = {'point': 10, 'p': 30, 'ul': 20, 'table': 40}.get(block['type'], 0)
                        if block.get('style') == 'tip': score -= 15
                        if block.get('style') == 'numbers': score += 15
                        if text.startswith('例題') or text.startswith('例：'): score -= 100
                        # Keep full numbers/units: 7.8 (specific gravity) must not match 7.8t.
                        if term == '7.8' and not ('比重' in text or block.get('headers', []) == ['材料', '比重']):
                            continue
                        choices.append((score, -index, block, text))
                if not choices:
                    raise ValueError(f'No eligible source: {section["id"]} {term}')
                _, _, block, text = max(choices, key=lambda row: row[:2])
                block.setdefault('quizTerms', []).append(term)
                audit.append({'section': section['id'], 'block': block['id'], 'answer': term, 'context': text})
    assert content_only(data) == before
    payload = json.dumps(data, ensure_ascii=False, indent=2) + '\n'
    TEXTBOOK.write_text(payload, encoding='utf-8', newline='\n')
    canonical = ROOT.parent / 'アプリ/教材/textbook.json'
    canonical_data = json.loads(canonical.read_text(encoding='utf-8'))
    assert content_only(canonical_data) == before, 'Canonical copy has other changes; do not overwrite'
    canonical.write_text(payload, encoding='utf-8', newline='\n')
    manifest_path = ROOT / 'CraneExam/Resources/_manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    # Updated below by the established manifest format; no unrelated entry changes.
    entry = manifest['files']['content/textbook.json']
    entry['sha256'] = hashlib.sha256(TEXTBOOK.read_bytes()).hexdigest()
    entry['size'] = TEXTBOOK.stat().st_size
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, separators=(',', ':')), encoding='utf-8', newline='\n')
    path = ROOT / 'docs/reviews/study-quiz-targets-20261106.json'
    path.write_text(json.dumps(audit, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
    print(f'Curated {len(audit)} answers in {len(TARGETS)} sections; prose, glossary and figures unchanged.')

if __name__ == '__main__':
    main()
