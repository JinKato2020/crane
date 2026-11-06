"""Store the verified chapter-2 PDF and a review report, without publishing."""
from pathlib import Path
import hashlib, html, json, shutil
ROOT=Path(__file__).resolve().parents[2];TMP=ROOT/'tmp/ch2_revision_20261106'
DOC=ROOT/'crane-app/docs/reviews';RES=ROOT/'crane-app/CraneExam/Resources'
read=lambda p:json.loads(p.read_text('utf-8'))
validation=read(DOC/'chapter2-revision-validation-20261106.json')
assert validation['original_anchor_ids_retained']==184
assert validation['pdf']['text_preserved_after_compression']
dest=ROOT/'アプリ/教材/クレーン教材_第2章_関係法令.pdf'
if not (TMP/'original-chapter2.pdf').exists():shutil.copy2(dest,TMP/'original-chapter2.pdf')
shutil.copy2(TMP/'chapter2-optimized.pdf',dest)
book=read(RES/'textbook.json');legacy=ROOT/'アプリ/教材/textbook.json'
if not (TMP/'distribution-textbook.json').exists():shutil.copy2(legacy,TMP/'distribution-textbook.json')
distribution=read(legacy);prior_other=[c for c in distribution['chapters'] if str(c['id'])!='2']
for i,c in enumerate(distribution['chapters']):
    if str(c['id'])=='2':distribution['chapters'][i]=book['chapters'][1]
assert [c for c in distribution['chapters'] if str(c['id'])!='2']==prior_other
legacy.write_text(json.dumps(distribution,ensure_ascii=False,indent=2)+'\n','utf-8',newline='\n')
changes=[
 ('読み方の導入','「対象・期限・相手・行うこと」に分ける例を表に整理。「以上・超える」の説明の重複を削減。','書籍 pp.82–83／本文の編集'),
 ('製造と設置','製造許可・設置届・設置報告書を比較。製造と設置の図を導入直後へ移動。設計審査の原則・局長審査の書類を整理。','書籍 p.84／現行安全規則3条・3条の2'),
 ('落成検査','1.25倍・1.27倍・200t超の条件、準備・立会い・申請添付書類を短い表へ。','書籍 pp.85–86'),
 ('検査証と間隔','交付・再交付・書替えを場面別に整理。間隔の3D図を寸法の説明へ移し、「0.3m以下」の意味を説明。','書籍 pp.86–88'),
 ('作業の安全','巻過ぎ、過負荷特例、合図、搭乗、立入禁止、修理、強風、組立てを条件別の表に分割。請負人への周知、不良品除去を補足。','書籍 pp.89–96'),
 ('内角側の図','シーブで折れ曲がるロープの内側と、跳ねる危険の方向を概念図で追加。','書籍 p.93'),
 ('検査の時期','日次・月次・年次、暴風前後を区別。年次荷重試験の前後2か月は別の出来事を指すため時間軸の図を追加。','書籍 pp.96–98'),
 ('更新・変更・休止','4列表を2列表へ。変更届と構造部分の変更検査を区別。期限切れにわたる休止と自主検査を分ける。','書籍 pp.98–101'),
 ('玉掛用具','安全係数・材料の伸び・使用後の劣化を区別。ワイヤ、チェーン、金具の画像を説明の近くへ移動。','書籍 pp.102–106'),
 ('玉掛用具の境界値','断線10％以上、直径減少7％超、チェーン5％超・10％超を保持。チェーンのき裂と金具の変形・き裂を明示。アイスプライスの2通りを表に整理。','書籍 pp.103–106'),
 ('運転と玉掛けの資格','機械の能力→操作方式の順に説明。限定免許の取得経路、取消しと返還の相手、軽い荷の判断例を整理。','書籍 pp.107–111'),
 ('用語集との一致','変更届のスタッカー式、使用再開の期限切れ条件、床上操作式の資格等の8用語を本文と整合。','書籍 pp.93–110'),
 ('学習のレイアウト','比較表46個はすべて2列。確認問題19問、図16点（追加2点）。長い節には節内目次を適用するソース変更。','既存教材UI／表示検証'),
 ('配信・検証の範囲','第2章はローカル改訂版。模試の184既存教材アンカーを保持。第1・3・4章や模試本文に変更なし。','自動検証結果')
]
report=dict(date='2026-11-06',scope='第2章 全8節',changes=[dict(title=t,implementation=i,basis=b) for t,i,b in changes],verification=validation,
 pdf=dict(path=str(dest),pages=validation['pdf']['pages'],size_bytes=dest.stat().st_size,sha256=hashlib.sha256(dest.read_bytes()).hexdigest()),
 release=dict(ota_uploaded=False,build_requested=False,requires_new_build=['第2章の節内目次への適用'],
 ota_compatible=['本文・表・図・用語集'],note='第1章は公開済み。第2章は未配信。第2章の変更について追加ビルドは開始していない。'))
(DOC/'chapter2-revision-completed-20261106.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n','utf-8')
esc=html.escape
cards=''.join(f'<article><h2>{esc(t)}</h2><p>{esc(i)}</p><small>{esc(b)}</small></article>' for t,i,b in changes)
out='''<!doctype html><html lang="ja"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>第2章 改訂結果</title><style>body{max-width:880px;margin:32px auto;padding:0 24px;background:#f4f6f9;color:#213b4f;font:16px/1.9 Meiryo,sans-serif}h1{font-size:28px}h2{font-size:20px;margin:0}article{background:white;padding:24px;border-radius:14px;margin:20px 0}small{color:#607381}a{color:#246e95}.notice{padding:20px;border-radius:14px;background:#e8eff5}</style><h1>第2章 改訂結果</h1><p>2026年11月6日 / 全8節</p><p class="notice">第1章は公開済み。第2章は改訂・表示検証まで完了したローカル版で、未配信です。</p><p><a href="chapter2-revised-preview-20261106.html">スマホ幅プレビュー</a> · <a href="'''+dest.as_uri()+'''">改訂PDF</a></p><p>指定書籍の全章OCR（印刷ページ82〜111）を対照し、数値・条件・図表を中心に原本11ページを再確認しました。確認問題19問、比較表46個、図16点。模試480問の現行710参照と公開版スナップショット696参照が解決できます。</p><p>表示確認は390px幅のブラウザ再現です。iOS実機・コンパイルは未実施。第2章の節内目次は次回ビルドで有効になります。</p>'''+cards+'</html>'
(DOC/'chapter2-revision-completed-20261106.html').write_text(out,'utf-8',newline='\n')
print(json.dumps(report['pdf'],ensure_ascii=False))
