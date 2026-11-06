"""Verify real OTA resource dependencies and exercise the maintenance tool in isolation."""
from pathlib import Path
import hashlib
import importlib.util
import json
import tempfile
from manage_home_heroes import ROOT, RES, CATALOG, validate

catalog = json.loads(CATALOG.read_text(encoding='utf-8'))
validate(catalog)
manifest = json.loads((RES/'_manifest.json').read_text(encoding='utf-8'))
files = [CATALOG]
for hero in catalog['heroes']:
    matches = [p for p in (RES/'images').glob(hero['imageName']+'.*') if p.suffix in ['.jpg','.png']]
    assert len(matches) == 1
    files.extend(matches)
    data = matches[0].read_bytes()
    assert data.startswith(b'\x89PNG\r\n\x1a\n') or data.startswith(b'\xff\xd8\xff')
for path in files:
    key = 'content/'+path.relative_to(RES).as_posix()
    data = path.read_bytes()
    assert manifest['files'][key] == {'size':len(data),'sha256':hashlib.sha256(data).hexdigest()}, key

spec = importlib.util.spec_from_file_location('isolated_heroes', ROOT/'tools/manage_home_heroes.py')
module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
with tempfile.TemporaryDirectory() as temp:
    module.RES = Path(temp); (module.RES/'images').mkdir()
    test = {'schema':1,'defaultID':'test','heroes':[]}
    module.set_image(test,'test','試験','追加',files[1])
    first = test['heroes'][0]['imageName']
    # Use another actual bundled hero even when the live catalog has only one entry.
    second = next(p for p in (RES/'images').glob('home_hero_*.*') if p.read_bytes()!=files[1].read_bytes())
    module.set_image(test,'test','更新','差し替え',second)
    module.validate(test)
    assert len(test['heroes']) == 1 and test['heroes'][0]['id'] == 'test'
    assert test['heroes'][0]['imageName'] != first
    assert list((module.RES/'images').glob(first+'.*')), 'Old catalog image must remain usable'
print(f'PASS: {len(catalog["heroes"])} hero choices, {len(files)} verified OTA files; add/replace preserve IDs and old images')
