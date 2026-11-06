"""Save reviewed chapter 4 locally, without publishing unfinished next-chapter work."""
from pathlib import Path
import hashlib,html,json,shutil
from pypdf import PdfReader
ROOT=Path(__file__).resolve().parents[2];TMP=ROOT/'tmp/ch4_revision_20261106'
DOC=ROOT/'crane-app/docs/reviews';RES=ROOT/'crane-app/CraneExam/Resources'
read=lambda p:json.loads(p.read_text('utf-8'))
validation=read(DOC/'chapter4-revision-validation-20261106.json')
assert validation['original_anchor_ids_retained']==339
assert validation['pdf']['text_preserved_after_compression']
assert len(PdfReader(TMP/'chapter4-optimized.pdf',strict=True).pages)==60
dest=ROOT/'アプリ/教材/クレーン教材_第4章_クレーンの運転のために必要な力学に関する知識.pdf'
if not (TMP/'original-chapter4.pdf').exists():shutil.copy2(dest,TMP/'original-chapter4.pdf')
shutil.copy2(TMP/'chapter4-optimized.pdf',dest)
book=read(RES/'textbook.json');legacy=ROOT/'アプリ/教材/textbook.json'
if not (TMP/'distribution-textbook.json').exists():shutil.copy2(legacy,TMP/'distribution-textbook.json')
distribution=read(legacy);other=[c for c in distribution['chapters'] if str(c['id'])!='4']
for i,c in enumerate(distribution['chapters']):
    if str(c['id'])=='4':distribution['chapters'][i]=book['chapters'][3]
assert [c for c in distribution['chapters'] if str(c['id'])!='4']==other
legacy.write_text(json.dumps(distribution,ensure_ascii=False,indent=2)+'\n','utf-8',newline='\n')
changes=[
 ('導入と単位','質量×重力加速度→重量の順を維持し、kg・tとN・kNを表で区別。地表・月面の既存図を保持。','書籍 pp.145–146'),
 ('力とモーメント','支点反力の例題が曲げモーメントの説明で中断されていたため順序を整理。三角比は基本例題の後へ移動し、5・12・13の三角形と比の表を追加。偶力はハンドルで図示。','書籍 pp.146–155／既存模試対応の補足'),
 ('例題5の条件','書籍の70cmは棒全長。旧教材では支点〜右端を70cmとして17.5kgだった条件を、書籍と同じ支点〜右端35cmにそろえ、図・問題文・計算結果35kgを一体で修正。旧条件での計算ミスと判定したものではない。','原本 p.154 の図と解答'),
 ('質量・体積','密度と材料表を計算例の前へ移動。鋼7.8、コンクリート2.3、水1.0を強調。中空体積と直径倍率を自習問題で確認。','書籍 pp.156–158'),
 ('重心・安定','重心の鉛直線と支点の関係を、直立した箱と傾けた箱で比較。転倒限界tanθ＝0.3÷0.8を図で読めるように追加。','書籍 pp.159–161／既存模試対応の補足'),
 ('運動・摩擦','基準による動きの違い、F＝ma、旋回中の作業半径増大、接線方向を補足。張力を加速度の向きで3比較。静止摩擦の現在値・最大値・動摩擦を分ける表を追加。','書籍 pp.162–168'),
 ('荷重・応力','荷重のかけ方を短い比較表へ。集中・分布荷重、たるんだロープの急巻上げによる衝撃を補足。比例限度・引張強さ・破断点の基本を優先。用語集の応力／曲線に対応する画像を修正。','書籍 pp.169–174'),
 ('ロープと係数','必要切断荷重746.172kNで終わっていた例題に直径別の選択肢と答え40mmを追加。モード係数の範囲を2行に整理し、4本掛けは原則3本用という書籍の扱いを明記。cos35°＝0.82の書籍例を図と3段階で追加。','原本 pp.175–177／厚生労働省'),
 ('滑車・仕事','定滑車と動滑車の設置場所・方向の役割を補足。階段式は下のロープ端が上の滑車の軸を引く関係を明記。巻上げ機構の効率を入力・有効出力・損失の図で示す。','書籍 pp.178–183／既存模試対応の補足'),
 ('学習と表示','全8節に計18問の回答開閉式の確認問題。図55点（新規7点のうち1点は旧図を差替え）、比較表15個。技術系3D画像と既存の良い模式図は保持。節内目次と4列マトリクス表のネイティブUIを実装。','本文・図・SwiftUIソース'),
 ('確認範囲','既存339アンカーを保持し、作業版710参照・公開版696参照を確認。390px幅の全8節、320px幅の係数表、SVG14点の文字切れ、最終PDF60ページを一覧と主要ページの拡大で点検。','ブラウザ再現とPDF。iOS実機・コンパイルは未実施')
]
report=dict(date='2026-11-06',scope='第4章 全8節',changes=[dict(title=t,implementation=i,basis=b) for t,i,b in changes],verification=validation,
 pdf=dict(path=str(dest),pages=60,size_bytes=dest.stat().st_size,sha256=hashlib.sha256(dest.read_bytes()).hexdigest()),
 visual_review=dict(contact_sheets=[1,2,3],phone_section_openings=8,new_svg_figures=7,detail_pdf_pages=[47],native_ios=False),
 release=dict(ota_uploaded=False,source_pushed=False,build_requested=False,requires_new_build=['第4章の節内目次','4列のマトリクス表表示'],ota_compatible=['本文・図・用語集'],note='第3章はOTAとPDF公開、ソースPush済み（7f94684）。第4章はローカル改訂版で未公開。ビルド状態照会は行っていない。'))
(DOC/'chapter4-revision-completed-20261106.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n','utf-8',newline='\n')
esc=html.escape
cards=''.join(f'<article><h2>{esc(t)}</h2><p>{esc(i)}</p><small>{esc(b)}</small></article>' for t,i,b in changes)
out='''<!doctype html><html lang="ja"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>第4章 改訂結果</title><style>body{max-width:880px;margin:32px auto;padding:0 24px;background:#f4f6f9;color:#213b4f;font:16px/1.9 Meiryo,sans-serif}h1{font-size:28px}h2{font-size:20px;margin:0}article{background:white;padding:24px;border-radius:14px;margin:20px 0}small{color:#607381}a{color:#246e95}.notice{padding:20px;border-radius:14px;background:#e8eff5}</style><h1>第4章 改訂結果</h1><p>2026年11月6日 / 全8節</p><p class="notice">第3章はOTA・PDF公開、ソースPush済み（7f94684）。第4章は改訂・表示確認済みのローカル版で、未配信です。</p><p><a href="chapter4-revised-preview-20261106.html">スマホ幅プレビュー</a> · <a href="'''+dest.as_uri()+'''">改訂PDF</a></p><p>指定書籍の全章OCR（印刷ページ145〜183）を対照し、数式・数値・図表を中心に原本10ページを再確認しました。全ページを一文字ずつ再OCRした監査ではありません。</p><p>確認問題18問・比較表15個・図55点。既存339アンカーを保持。表示確認はブラウザ再現で、iOS実機・コンパイルは未実施です。</p>'''+cards+'''<p>玉掛けの補足照合先：<a href="https://www.mhlw.go.jp/content/11300000/000627864.pdf">厚生労働省の玉掛け教材</a>、<a href="https://www.mhlw.go.jp/web/t_doc?dataId=74020000&amp;dataType=0">クレーン等安全規則</a>。</p></html>'''
(DOC/'chapter4-revision-completed-20261106.html').write_text(out,'utf-8',newline='\n')
# The chapter-3 receipt was saved before the authorized source push. Record it now.
p=DOC/'chapter3-revision-completed-20261106.json';r=read(p)
r['release'].update(source_pushed=True,source_commit='7f94684',build_requested=True,build_trigger='git push origin main',build_status_queried=False,note='第3章の本文・図・PDFを公開し公開URLとのSHA-256一致を確認。UI変更を含むソースを7f94684でPush済み。ビルド状態は照会していない。')
p.write_text(json.dumps(r,ensure_ascii=False,indent=2)+'\n','utf-8',newline='\n')
print(json.dumps(report['pdf'],ensure_ascii=False))
