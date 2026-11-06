"""Install inspected imagegen assets and update textbook/glossary references only."""
from pathlib import Path
import copy, hashlib, json, shutil

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / 'CraneExam/Resources'
BASE = ROOT.parent / 'tmp/figure_style_20261106'
JOBS = ROOT / 'docs/reviews/figure-style-jobs-20261106.json'
CAPTIONS = {
    'overview': 'クレーンの代表的な7種類。外観と荷を運ぶ仕組みを比べる。機種ごとに能力や設置方法は異なる。',
    'overhead': '普通形はフックで荷をつり上げる。レードル形は主巻で容器を支え、補巻で傾ける。',
    'jibtypes': 'ジブクレーンの代表的な形。高脚・低床・ポスト形・つち形・壁クレーンを、支持部分とジブの形で見分ける。',
    'climbing': '上昇方法の模式図。左はマストを継ぎ足す方式。右は建物の床を支えに、マスト全体を上へ移す方式。',
    'luffing': '引込みクレーンの4方式。ジブの連結やロープの使い方を変え、荷の高さの変化を抑える。赤い部分に注目して比べる。',
    'stacker': 'スタッカークレーンの3形式。上部で支えるか床上で支えるかを比べる。フォークを昇降させて荷を出し入れする。',
    'hoist': 'サスペンション形は桁の下フランジで車輪を支える。トップランニング形は2本の上部レールで車輪を支える。',
    'oilbath': '油浴式は、歯車の一部を油に浸して回転させ、油をはね上げて潤滑する。密閉された装置でも、油の点検・交換が必要。',
    'drum': '左：取付部に力が集中しないよう、ドラムに捨巻きを2巻以上残す。右：エコライザシーブが左右のロープの張力をそろえる。',
    'cabinet': '共用保護盤の配置例。主配線用遮断器・主電磁接触器などを収め、電力を分配し、回路を保護する。内部の配線は省略。',
    'breaker': '配線用遮断器の外観例。連動する操作ハンドルで回路を開閉し、過負荷や短絡では自動で遮断する。',
    'contactor': '電磁接触器の内部構造の模式的な3D図。コイルの磁力で鉄片を動かし、主接点を操作する。',
    'meggerconnect': '絶縁抵抗計の接続例。LINEは巻線端子、EARTHは金属フレームへ。電源遮断・無電圧確認後に測定する。100 MΩは表示例。',
    'meggerreadings': '同じ測定電圧なら、絶縁抵抗が大きいほど電気は漏れにくい。100 MΩと0.1 MΩは比較例であり、良否基準ではない。測定電圧・端子名は取扱説明書で確認し、測定後は所定の方法で放電する。',
}

def digest(path):
    raw = path.read_bytes()
    return {'sha256': hashlib.sha256(raw).hexdigest(), 'size': len(raw)}

def save(path, value, compact=False):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=None if compact else 2,
                              separators=(',', ':') if compact else None) + ('\n' if not compact else ''),
                    encoding='utf-8', newline='\n')

def main():
    jobs = json.loads(JOBS.read_text(encoding='utf-8'))
    assert len(jobs) == len({j['old'] for j in jobs}) == 14
    by_file = {j['old']: j for j in jobs}
    by_stem = {Path(j['old']).stem: j for j in jobs}
    book = json.loads((RES/'textbook.json').read_text(encoding='utf-8'))
    baseline = json.loads((BASE/'textbook.json').read_text(encoding='utf-8'))
    manifest = json.loads((RES/'_manifest.json').read_text(encoding='utf-8'))
    changes = []
    for j in jobs:
        assert j['status'] == 'accepted'
        source, target = Path(j['source']), RES/'images'/j['file']
        assert source.is_file() and target.resolve().is_relative_to(RES.resolve())
        shutil.copyfile(source, target)
        manifest['files']['content/images/'+j['file']] = digest(target)
    dd_figure = next(copy.deepcopy(b) for c in book['chapters'] for s in c['sections'] for b in s['blocks']
                     if b.get('file') == '1-13_supplement_f22_20261023.svg')
    for chapter in book['chapters']:
        for section in chapter['sections']:
            for block in section['blocks']:
                j = by_file.get(block.get('file')) or by_stem.get(block.get('asset'))
                if j and block['type'] in ['img', 'svg']:
                    block.pop('file', None)
                    block['type'] = 'img'
                    block['asset'] = Path(j['file']).stem
                    block['caption'] = CAPTIONS[j['id']]
                    changes.append({'location': section['id']+'/'+block['id'], 'id': j['id'], 'kind': 'textbook'})
        for term in chapter.get('glossary', []):
            for figure in term.get('figures', []):
                j = by_file.get(figure['file'])
                if j:
                    figure['file'] = j['file']
                    figure['caption'] = CAPTIONS[j['id']]
                    changes.append({'location': str(chapter['id'])+'/'+term['term'], 'id': j['id'], 'kind': 'glossary'})
            j = by_stem.get(term.get('img'))
            if j:
                term['img'] = Path(j['file']).stem
            if any(f['file'] == '1-13_drum_equalizer_style26.png' for f in term.get('figures', [])):
                if not any(f['file'] == dd_figure['file'] for f in term['figures']):
                    term['figures'].append({'file': dd_figure['file'], 'caption': dd_figure['caption']})
    # Keep all non-figure teaching content, all quiz terms, anchors, and glossary prose intact.
    def nonfigure_content(value):
        value = copy.deepcopy(value)
        for c in value['chapters']:
            for s in c['sections']:
                s['blocks'] = [({'id': b['id'], 'type': 'figure'} if b['type'] in ['img', 'svg'] else b) for b in s['blocks']]
            for t in c.get('glossary', []):
                t.pop('figures', None); t.pop('img', None)
        return value
    assert nonfigure_content(book) == nonfigure_content(baseline), 'Unrelated teaching text changed'
    assert len([x for x in changes if x['kind'] == 'textbook']) == 14
    save(RES/'textbook.json', book)
    shutil.copyfile(RES/'textbook.json', ROOT.parent/'アプリ/教材/textbook.json')
    manifest['files']['content/textbook.json'] = digest(RES/'textbook.json')
    save(RES/'_manifest.json', manifest, compact=True)
    report = {'status': 'integrated-locally', 'generator': 'built-in image_gen', 'auditUniqueFigures': 194,
              'auditScope': '全章の教材・用語集の図を一覧で視覚確認。今回の14図は個別に確認・再作成。全図の公式書籍との内容照合を意味しない。',
              'replacementCount': 14, 'changes': changes,
              'rolePolicy': {'technical': '形状・構造・接続位置は清潔なリアル3D',
                             'concept': '変化・原理・比較は簡潔な2D',
                             'calculation': '計算・力・寸法関係は正確な2D/SVG'},
              'preserved': ['本文', '例題', 'クイズの出題語', '教材参照アンカー', '用語の解説'],
              'distribution': 'not-published', 'nativeDeviceQA': 'not-performed',
              'manifestTextbook': manifest['files']['content/textbook.json']}
    save(ROOT/'docs/reviews/figure-style-review-20261106.json', report)
    print(json.dumps({'installed': len(jobs), 'updatedReferences': len(changes),
                      'quizAndProsePreserved': True}, ensure_ascii=False))

if __name__ == '__main__':
    main()
