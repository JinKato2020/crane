"""Seed the accepted hero collection from the reviewed, original image assets."""
import json
from manage_home_heroes import ROOT, CATALOG, set_image, save

design = ROOT/'docs/design/home-proposal-20261106'
catalog = {'schema':1,'defaultID':'existing','heroes':[]}
sources = [
    ('existing','いつもの景色','これまでのヒーロー',ROOT/'CraneExam/Assets.xcassets/Hero.imageset/hero.jpg'),
    ('anime','未来の自分','アニメ調',design/'hero-anime.png'),
    ('cinematic','仕事の余韻','シネマ調',design/'hero-cinematic.png'),
]
additional = json.loads((design/'emotive-five/assets.json').read_text(encoding='utf-8'))['assets']
sources += [(x['id'],x['name'],x['style'],design/'emotive-five'/x['file']) for x in additional]
for hero_id,title,subtitle,image in sources: set_image(catalog,hero_id,title,subtitle,image)
save(catalog)
print(f'Created {CATALOG.name}: {len(catalog["heroes"])} images plus the local no-image option')
