"""Synchronize the verified local PDF and record the chapter-1 changes.

No deployment, commit, push, or build is performed.
"""
from pathlib import Path
import hashlib
import html
import json
import shutil

ROOT=Path(__file__).resolve().parents[2]
TMP=ROOT/'tmp/ch1_revision_20261106'
DOC=ROOT/'crane-app/docs/reviews'
RES=ROOT/'crane-app/CraneExam/Resources'
read=lambda p:json.loads(p.read_text('utf-8'))
checks=read(TMP/'pdf-checks.json')
assert checks['text_preserved_after_compression'] and not checks['sparse_pages']
dest=ROOT/'アプリ/教材/クレーン教材_第1章_クレーンに関する知識.pdf'
backup=TMP/'original-chapter1.pdf'
if dest.exists() and not backup.exists():shutil.copy2(dest,backup)
shutil.copy2(TMP/'chapter1-optimized.pdf',dest)
data=read(RES/'textbook.json')
legacy=ROOT/'アプリ/教材/textbook.json'
backup=TMP/'distribution-textbook.json'
if not backup.exists():shutil.copy2(legacy,backup)
distribution=read(legacy)
prior_other=[c for c in distribution['chapters'] if str(c['id'])!='1']
for i,c in enumerate(distribution['chapters']):
    if str(c['id'])=='1':distribution['chapters'][i]=data['chapters'][0]
assert prior_other==[c for c in distribution['chapters'] if str(c['id'])!='1']
legacy.write_text(json.dumps(distribution,ensure_ascii=False,indent=2)+'\n','utf-8',newline='\n')

implemented={
 'A01':'ばね鋼を2～3巻きしたばねナットへ描き直し、六角ナットの上に取り付ける位置を明示。',
 'A02':'バンドの調整用ボルトと解放時のすき間を図解。本文・確認問題も追加。',
 'A03':'発進時・停止時を独立した3コマに整理。荷が振り切れる前の再操作を明示。',
 'A04':'揺脚・ホイスト・はすば歯車の説明を指定書籍の基本事項が先に伝わる順へ変更。用語集の関連2定義も整合。',
 'A05':'図・本文を20歯→60歯の2段、減速比9、900→300→100rpmで統一。中間軸から考える確認問題を追加。',
 'A06':'巻上げ・巻下げの上下矢印を追加。5種類の運動を比較表で整理。',
 'A07':'主要図のラベル・余白・矢印位置を調整。軸継手は2×2、末端処理は2列へ。第1章の図の通常表示の高さ制限を緩和。',
 'B01':'荷重図と本文を10.0−0.5＝9.5tで統一。補足の重複を整理。',
 'B02':'水平基準と角度弧を強調。cosの計算は応用として節末へ移し、2m・10m・60°の対応図を追加。',
 'B03':'図の名称を低床ジブクレーンへ統一。引込み4方式を比較表へ整理。',
 'B04':'スタッカー、アンローダ、サドル、橋形の脚、起伏するカンチレバーの識別点を追加。',
 'B05':'制動・保持と下降速度の調整を、目的で区別して説明。',
 'B06':'捨巻・エコライザ・D/dの共通図を説明の前へ移動。本文とキャプションで位置を対応付け。',
 'B07':'末端処理5方式と効率を比較表へ。アイスプライスの編込みを描き直し、クリップの本体側・端末側を拡大図で説明。',
 'B08':'引込み、グラブ、ブレーキ分類、荷振れ操作、クライミング、給油の近接する重複説明を統合。',
 'B09':'油浴式の3D図と、密閉減速機箱でも油の点検・交換が必要な理由を追加。給脂周期表は保持。',
 'B10':'比較表を1個から13個へ整理。導入・結論・理由・図の役割を分け、全段落を枠で囲わない構成。',
 'B11':'章末12問＋途中2問。図の識別・用語の対比・数値計算・操作のタイミングを確認し、答えと理由を開いて読めるUIを追加。',
 'C01':'割形の着脱、チェーン式の構成、キー板の役割を補強。長い節には見出しへ移動する目次を追加。',
 'C02':'巻過防止と点検から第2章への参照ボタンを追加。改訂と同じデータからPDFを作成し、改訂日を明示。'
}
audit=read(DOC/'chapter1-review-20261106.json')
assert set(implemented)=={f['id'] for f in audit['findings']}
report=dict(date='2026-11-06',scope='第1章 全16節',
            changes=[dict(id=f['id'],title=f['title'],implementation=implemented[f['id']],basis=f['evidence']) for f in audit['findings']],
            verification=read(DOC/'chapter1-revision-validation-20261106.json'),
            pdf=dict(path=str(dest),pages=checks['pages'],size_bytes=dest.stat().st_size,sha256=hashlib.sha256(dest.read_bytes()).hexdigest()),
            release=dict(ota_uploaded=False,build_started=False,native_ios_compile_performed=False,
                         requires_new_build=['節内目次','答えと理由の開閉','教材内の参照ボタン','図の表示サイズ・余白'],
                         ota_compatible=['本文','比較表','図の追加・差し替え'],
                         old_client='新しいstyleは既存のpブロックとして読める。目次・開閉・参照ボタン等は新ビルドで有効になる。'))
(DOC/'chapter1-revision-completed-20261106.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n','utf-8',newline='\n')
esc=html.escape
cards=''.join(f'<article><small>{c["id"]}</small><h2>{esc(c["title"])}</h2><p>{esc(c["implementation"])}</p><details><summary>照合根拠</summary><p>{esc(c["basis"])}</p></details></article>' for c in report['changes'])
document='''<!doctype html><html lang="ja"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>第1章 改訂結果</title><style>body{max-width:900px;margin:30px auto;padding:0 22px;background:#f5f7fa;color:#22394b;font:16px/1.9 -apple-system,Meiryo,sans-serif}h1{font-size:28px}h2{font-size:19px;margin:6px 0}article{background:white;border-radius:14px;padding:22px;margin:18px 0}small{color:#2b728f;font-weight:bold}a{color:#246a8a}summary{cursor:pointer;color:#58748b;font-size:14px}.note{padding:20px;background:#e6eef3;border-radius:14px}</style><h1>第1章 改訂結果</h1><p>2026年11月6日 / 全16節</p><p class="note">指定書籍の試験上の整理を優先し、20件の提案に対応。比較表13個、確認問題14問。模試480問の710件の教材参照は解決可能で、問題データおよび第2～4章本文は変更していません。</p><p><a href="chapter1-revised-preview-20261106.html">スマホ幅の改訂プレビュー</a> · <a href="'''+dest.as_uri()+'''">改訂PDF</a></p><p>表示検証は390px幅のブラウザ再現です。iOS実機・コンパイルは未実施。配信・ビルドは行っていません。本文・図はOTA対応、節内目次・答えの開閉・表示サイズ等のUI変更は次回ビルドで有効になります。</p>'''+cards+'</html>'
(DOC/'chapter1-revision-completed-20261106.html').write_text(document,'utf-8',newline='\n')
print(json.dumps({'pdf':str(dest),'pages':checks['pages'],'MB':round(dest.stat().st_size/1e6,1),'review_items':len(implemented)},ensure_ascii=False))
