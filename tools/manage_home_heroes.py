"""Manage the OTA hero catalog without editing Swift. Run --help for commands."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT/'CraneExam/Resources'
CATALOG = RES/'home_heroes.json'

def validate(catalog):
    assert catalog.get('schema') == 1, 'Unsupported schema'
    items = catalog['heroes']
    ids = [item['id'] for item in items]
    assert 1 <= len(items) <= 100 and len(ids) == len(set(ids)), 'Empty or duplicate IDs'
    assert catalog['defaultID'] in ids, 'Default must be an existing hero'
    for item in items:
        assert re.fullmatch(r'[A-Za-z0-9_-]{1,100}', item['id']) and item['id'] != 'none', item
        assert re.fullmatch(r'home_hero_[A-Za-z0-9_-]+', item['imageName']) and len(item['imageName']) <= 100, item
        assert item['title'].strip() and len(item['title']) <= 60 and len(item['subtitle']) <= 120, item
        assert any((RES/'images'/f"{item['imageName']}{ext}").is_file() for ext in ['.jpg','.png']), item

def set_image(catalog, hero_id, title, subtitle, image):
    assert re.fullmatch(r'[A-Za-z0-9_-]{1,70}', hero_id) and hero_id != 'none'
    source = Path(image).resolve()
    data = source.read_bytes()
    if data.startswith(b'\x89PNG\r\n\x1a\n'): ext = '.png'
    elif data.startswith(b'\xff\xd8\xff'): ext = '.jpg'
    else: raise ValueError('Only PNG/JPEG images are supported')
    # Versioned names keep the old catalog usable if a later OTA download is interrupted.
    name = f"home_hero_{hero_id.replace('-', '_')}_{hashlib.sha256(data).hexdigest()[:12]}"
    target = RES/'images'/f'{name}{ext}'
    if source != target.resolve(): shutil.copy2(source, target)
    item = {'id':hero_id, 'title':title, 'subtitle':subtitle, 'imageName':name}
    index = next((i for i,v in enumerate(catalog['heroes']) if v['id']==hero_id), None)
    if index is None: catalog['heroes'].append(item)
    else: catalog['heroes'][index] = item

def save(catalog):
    validate(catalog)
    CATALOG.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    subprocess.run([sys.executable,str(ROOT/'tools/content_manifest.py')],cwd=ROOT,check=True)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    commands.add_parser('list')
    setter = commands.add_parser('set',help='Add a hero or replace one while preserving its selected ID')
    for field in ['id','title','subtitle','image']: setter.add_argument('--'+field,required=True)
    order = commands.add_parser('order'); order.add_argument('ids',nargs='+')
    remove = commands.add_parser('remove'); remove.add_argument('id')
    default = commands.add_parser('default'); default.add_argument('id')
    args = parser.parse_args()
    catalog = json.loads(CATALOG.read_text(encoding='utf-8'))
    if args.command == 'list':
        validate(catalog)
        for hero in catalog['heroes']: print(f"{hero['id']}\t{hero['title']}\t{hero['imageName']}")
        return
    if args.command == 'set': set_image(catalog,args.id,args.title,args.subtitle,args.image)
    elif args.command == 'order':
        mapping = {v['id']:v for v in catalog['heroes']}
        assert len(args.ids)==len(mapping) and set(args.ids)==set(mapping), 'Include every ID once'
        catalog['heroes'] = [mapping[x] for x in args.ids]
    elif args.command == 'default': catalog['defaultID'] = args.id
    elif args.command == 'remove':
        assert any(v['id']==args.id for v in catalog['heroes']), 'Unknown ID'
        catalog['heroes'] = [v for v in catalog['heroes'] if v['id']!=args.id]
        assert catalog['heroes'], 'Keep at least one image'
        if catalog['defaultID']==args.id: catalog['defaultID']=catalog['heroes'][0]['id']
    save(catalog)
    print('Catalog ready. Commit/push and run the existing content OTA workflow to publish.')

if __name__=='__main__': main()
