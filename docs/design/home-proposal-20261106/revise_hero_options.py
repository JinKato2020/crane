"""Apply the user's hero selection to design artifacts only."""
from pathlib import Path
import json

OUT = Path(__file__).resolve().parent

def revise(name, changes):
    path = OUT / name
    value = path.read_text(encoding='utf-8')
    for old, new in changes:
        if old in value:
            value = value.replace(old, new)
        else:
            assert new in value, (name, old)
    path.write_text(value, encoding='utf-8', newline='\n')

revise('proposal.js', [
    ("const styles={photo:{name:'現場の朝',label:'実写調',file:'hero-photo.png'},anime:{name:'未来の自分',label:'アニメ調',file:'hero-anime.png'},simple:{name:'静かな集中',label:'シンプル',file:'hero-simple.png'},none:{name:'画像なし',label:'学習に集中',file:''}};",
     "const styles={existing:{name:'いつもの景色',label:'既存の画像',file:'hero-existing.jpg'},anime:{name:'未来の自分',label:'アニメ調',file:'hero-anime.png'},cinematic:{name:'仕事の余韻',label:'シネマ調',file:'hero-cinematic.png'},none:{name:'画像なし',label:'学習に集中',file:''}};"),
    ("'photo'", "'existing'"),
    ("variant('ライト','実写調','existing')+variant('ダーク','実写調','existing',true)",
     "variant('ライト','既存の画像','existing')+variant('ダーク','既存の画像','existing',true)"),
    ("variant('A · 現場の朝','初期設定のおすすめ','existing')+variant('B · 未来の自分','落ち着いたアニメ調','anime')+variant('C · 静かな集中','シンプルなイラスト','simple')",
     "variant('A · いつもの景色','既存画像を採用','existing')+variant('B · 未来の自分','アニメ調を継続','anime')+variant('C · 仕事の余韻','新作 · 見上げる構図','cinematic')"),
])

revise('index.html', [
    ('おすすめ：Aを初期設定にし、B・C・画像なしを自由に選べる構成。',
     '既存のヒーローを初期設定に。アニメ調・新作のシネマ調も選べます。'),
    ('実写調「現場の朝」、落ち着いたアニメ調「未来の自分」、シンプルなイラスト「静かな集中」の3案。',
     '既存のヒーロー画像「いつもの景色」、落ち着いたアニメ調「未来の自分」、新作のシネマ調「仕事の余韻」の3案。前回の1枚目（現場の朝）と3枚目（静かな集中）は候補から外しました。新作は工場の床から天井クレーンを斜めに見上げ、夕方の光で静かな仕事の余韻を表しています。'),
    ('?view=full&hero=photo', '?view=full&hero=existing'),
    ('imagegenによるヒーロー生成記録・保存先・プロンプト', 'ヒーローの採用画像・生成記録・プロンプト'),
])

revise('render_proposal.py', [
    ("'recommendedDefault': 'photo'", "'recommendedDefault': 'existing'"),
    ("'heroOptions': {'photo': '現場の朝（実写調）', 'anime': '未来の自分（アニメ調）',\n                    'simple': '静かな集中（シンプル）', 'none': '画像なし'},",
     "'heroOptions': {'existing': 'いつもの景色（既存の画像）', 'anime': '未来の自分（アニメ調）',\n                    'cinematic': '仕事の余韻（シネマ調）', 'none': '画像なし'},\n    'rejectedHeroOptions': ['photo', 'simple'],\n    'heroRevision': 'User requested existing hero plus retained anime and a new emotional low-angle image',"),
    ("['photo','anime','simple']", "['existing','anime','cinematic']"),
    ('hero=photo', 'hero=existing'),
    ('home-photo-dark.png', 'home-existing-dark.png'),
    ("=='photo'", "=='existing'"),
])
revise('rating-flow.html', [('hero-photo.png', 'hero-existing.jpg'),
                           ('alt="朝の港とクレーン"', 'alt="既存のヒーロー画像：夕空とクレーン"')])

assets_path = OUT / 'generated-assets.json'
assets = json.loads(assets_path.read_text(encoding='utf-8'))
rejected = [dict(a, status='rejected-by-user', active=False) for a in assets if a['id'] in ['photo','simple']]
if rejected:
    (OUT / 'rejected-hero-candidates.json').write_text(
        json.dumps(rejected, ensure_ascii=False, indent=2)+'\n', encoding='utf-8', newline='\n')
anime = next(a for a in assets if a['id'] == 'anime')
existing = {'id': 'existing', 'file': 'hero-existing.jpg', 'name': 'いつもの景色', 'type': '既存の画像',
            'source': 'CraneExam/Assets.xcassets/Hero.imageset/hero.jpg',
            'generator': 'existing-app-asset-reused-without-modification', 'purpose': 'proposal-only'}
cinematic = json.loads((OUT / 'cinematic-generation.json').read_text(encoding='utf-8'))
current = [existing, anime, cinematic]
assets_path.write_text(json.dumps(current, ensure_ascii=False, indent=2)+'\n', encoding='utf-8', newline='\n')
(OUT / 'prompts.json').write_text(json.dumps([a for a in current if 'prompt' in a],
    ensure_ascii=False, indent=2)+'\n', encoding='utf-8', newline='\n')
assert (OUT / 'hero-existing.jpg').read_bytes() == (OUT.parents[2] / existing['source']).read_bytes()
print(json.dumps({'activeHeroOptions': [a['id'] for a in current], 'default': 'existing',
                  'excludedOptions': ['photo','simple'], 'existingImageUnmodified': True,
                  'appChanged': False}, ensure_ascii=False))
