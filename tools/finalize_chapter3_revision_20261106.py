"""Save reviewed chapter-3 output and record what is, and is not, published."""
from pathlib import Path
import hashlib,html,json,shutil
ROOT=Path(__file__).resolve().parents[2];TMP=ROOT/'tmp/ch3_revision_20261106'
DOC=ROOT/'crane-app/docs/reviews';RES=ROOT/'crane-app/CraneExam/Resources'
read=lambda p:json.loads(p.read_text('utf-8'))
validation=read(DOC/'chapter3-revision-validation-20261106.json')
assert validation['original_anchor_ids_retained']==334
assert validation['pdf']['text_preserved_after_compression']
dest=ROOT/'アプリ/教材/クレーン教材_第3章_原動機及び電気に関する知識.pdf'
if not (TMP/'original-chapter3.pdf').exists():shutil.copy2(dest,TMP/'original-chapter3.pdf')
shutil.copy2(TMP/'chapter3-optimized.pdf',dest)
book=read(RES/'textbook.json');legacy=ROOT/'アプリ/教材/textbook.json'
if not (TMP/'distribution-textbook.json').exists():shutil.copy2(legacy,TMP/'distribution-textbook.json')
distribution=read(legacy);other=[c for c in distribution['chapters'] if str(c['id'])!='3']
for i,c in enumerate(distribution['chapters']):
    if str(c['id'])=='3':distribution['chapters'][i]=book['chapters'][2]
assert [c for c in distribution['chapters'] if str(c['id'])!='3']==other
legacy.write_text(json.dumps(distribution,ensure_ascii=False,indent=2)+'\n','utf-8',newline='\n')
changes=[
 ('基礎の順序','電流・電圧・抵抗を先にまとめ、直流・交流→整流→変圧器→三相・周波数へ。電線の長さ・直径・温度、実効値を短い文で区別。','書籍 pp.112–115'),
 ('整流と平滑化','交流・脈流・平滑化後を、同じ時間軸の3段の図で比較。波の形と説明を対応させる。','既存教材の補足／回路の基本'),
 ('計算','直列・並列の公式を図だけでなく本文にも記載。混合回路を3段階で解き、電圧・電流の検算を表に整理。100Ω＋（200Ωと600Ωの並列）の自習図を追加。','書籍 pp.115–117'),
 ('電動機','一次・二次、界磁・電機子を役割で比較。入力8kW→出力6kW＋損失2kWを図示。かご形の従来の特徴とインバーター普及、動作別の電動機を補足。','書籍 pp.118–121'),
 ('制御器','方式名を繰り返す表を、主回路をどう操作するかの比較へ。直接・間接・半間接、無線から機上運転への切替えを整理。','書籍 pp.121–125'),
 ('惰走・保護','長い箇条書きを操作・電源順序・保護の表へ。コースチングのモーター無通電／ブレーキ開放／0ノッチで制動を図示。','書籍 pp.125–127'),
 ('図と項目の誤対応','共用保護盤の図に付いていた「継電器」の説明を修正。用語集のスリップリング給電に付いていたトロリ給電図を正しい図へ差替え。','掲載画像と書籍 pp.126・131'),
 ('給電','支持方式を4つに分け、特殊チェーン式とケーブルキャリア式の違いを明記。集電子の2方式、リング側・ブラシ側の回転の両配置を説明。図を該当箇所へ移動。','書籍 pp.128–131'),
 ('速度制御','書籍の「巻上げは通常全電圧始動」を基本として説明。緩始動の部品、極数比2：1、巻下げと二次抵抗、軽荷重・重荷重の渦電流制御を補足。方式と数値の表を分割。','書籍 pp.131–136'),
 ('電気保守','絶縁と漏れ電流、絶縁抵抗と接地抵抗を区別。感電の数値は指定書籍の扱いで記載。救助の記述は消防庁の安全確保・119番・AEDの案内と照合。故障表を症状別に3分割。','書籍 pp.137–144／消防庁'),
 ('学習と表示','技術系3D図を保持。重複する一般的な電動機図1点は参照リンクへ。合計56図、29比較表、21問の回答開閉式の確認問題。第3章の節内目次をソースへ追加。','教材UIの既存部品'),
 ('検証','334既存アンカーを保持。現行710参照・公開版696参照を検証。390px幅の全9節、SVG9図の文字切れ、PDF67ページの一覧を確認。','自動検証・ブラウザ表示・PDF目視')
]
report=dict(date='2026-11-06',scope='第3章 全9節',changes=[dict(title=t,implementation=i,basis=b) for t,i,b in changes],verification=validation,
 pdf=dict(path=str(dest),pages=validation['pdf']['pages'],size_bytes=dest.stat().st_size,sha256=hashlib.sha256(dest.read_bytes()).hexdigest()),
 visual_review=dict(contact_sheets=[1,2,3,4],phone_section_openings=9,new_svg_figures=4,detail_pdf_pages=[52],native_ios=False),
 release=dict(ota_uploaded=False,build_requested=False,requires_new_build=['第3章の節内目次への適用'],ota_compatible=['本文・表・図・用語集'],
 note='第2章はOTA・PDF公開、ソースPush済み（1976215）。第3章は改訂済みのローカル版。第3章の追加ビルド・OTA・Pushは行っていない。ビルド状態の照会・監視は行わない。'))
(DOC/'chapter3-revision-completed-20261106.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n','utf-8',newline='\n')
esc=html.escape
cards=''.join(f'<article><h2>{esc(t)}</h2><p>{esc(i)}</p><small>{esc(b)}</small></article>' for t,i,b in changes)
out='''<!doctype html><html lang="ja"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>第3章 改訂結果</title><style>body{max-width:880px;margin:32px auto;padding:0 24px;background:#f4f6f9;color:#213b4f;font:16px/1.9 Meiryo,sans-serif}h1{font-size:28px}h2{font-size:20px;margin:0}article{background:white;padding:24px;border-radius:14px;margin:20px 0}small{color:#607381}a{color:#246e95}.notice{padding:20px;border-radius:14px;background:#e8eff5}</style><h1>第3章 改訂結果</h1><p>2026年11月6日 / 全9節</p><p class="notice">第2章はOTA・PDF公開、ソースPush済み（1976215）。第3章は改訂・表示確認済みのローカル版で、未配信です。</p><p><a href="chapter3-revised-preview-20261106.html">スマホ幅プレビュー</a> · <a href="'''+dest.as_uri()+'''">改訂PDF</a></p><p>指定書籍の全章OCR（印刷ページ112〜144）を対照し、数式・方式・数値・図表を中心に原本11ページを再確認しました。元の書籍を全ページ一文字ずつ再OCRした監査ではありません。</p><p>確認問題21問、比較表29個、図56点（追加4点）。教材アンカー334か所を保持し、模試480問の現行710参照・公開版696参照が解決することを確認しています。</p><p>表示確認は390px幅のブラウザ再現です。iOS実機・コンパイルは未実施。第3章の節内目次は次回ビルドで有効になります。</p>'''+cards+'''<p>救助の記述の照合先：<a href="https://www.fdma.go.jp/relocation/e-college/cat65/cat65/cat44/1-15.html">消防庁：一次救命処置</a>、<a href="https://internal.fdma.go.jp/hiyarihatto/juyo/anzenkanri_h28/html/23a00.html">消防庁：感電事故での安全管理</a>。</p></html>'''
(DOC/'chapter3-revision-completed-20261106.html').write_text(out,'utf-8',newline='\n')
print(json.dumps(report['pdf'],ensure_ascii=False))
