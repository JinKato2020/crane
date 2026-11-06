"""Package original image outputs and render a browser-based comparison board."""
from pathlib import Path
from PIL import Image
from playwright.sync_api import sync_playwright
import hashlib
import json
import zipfile

OUT = Path(__file__).resolve().parent
manifest = json.loads((OUT/'assets.json').read_text(encoding='utf-8'))
checks = []
for asset in manifest['assets']:
    target = OUT/asset['file']
    assert target.read_bytes() == Path(asset['source']).read_bytes()
    with Image.open(target) as im:
        checks.append({'file': asset['file'], 'dimensions': list(im.size), 'unchangedOriginal': True})
with zipfile.ZipFile(OUT/'hero-emotive-five.zip', 'w', compression=zipfile.ZIP_DEFLATED) as z:
    for asset in manifest['assets']:
        z.write(OUT/asset['file'], asset['file'])
    z.write(OUT/'prompts.json', 'prompts.json')
with sync_playwright() as pw:
    browser = pw.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe', headless=True)
    page = browser.new_page(viewport={'width': 1180, 'height': 1450}, device_scale_factor=2)
    page.goto((OUT/'index.html').as_uri())
    page.wait_for_function('Array.from(document.images).every(i=>i.complete&&i.naturalWidth>0)')
    page.evaluate('document.fonts.ready')
    page.locator('.board').screenshot(path=str(OUT/'comparison.png'))
    page.locator('#copytoggle').check()
    page.wait_for_timeout(200)
    page.locator('.board').screenshot(path=str(OUT/'comparison-with-copy.png'))
    browser.close()
root = OUT.parents[3]
baseline = json.loads((OUT.parent/'app-baseline-hashes.json').read_text(encoding='utf-8'))
now = {str(f.relative_to(root)).replace('\\','/'): hashlib.sha256(f.read_bytes()).hexdigest()
       for f in (root/'CraneExam').rglob('*') if f.is_file()}
assert now == baseline
report = {'status': 'additional-candidates-complete', 'generator': 'built-in image_gen',
          'images': checks, 'appFilesUnchanged': len(now), 'activeHeroOptionsChanged': False,
          'preview': 'index.html', 'comparison': 'comparison.png', 'zip': 'hero-emotive-five.zip'}
(OUT/'review.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps(report, ensure_ascii=False))
