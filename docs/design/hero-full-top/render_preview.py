"""Preview asset framing only. Does not run iOS or inspect build jobs."""
from pathlib import Path
import json
from playwright.sync_api import sync_playwright

OUT = Path(__file__).resolve().parent
checks = []
with sync_playwright() as pw:
    browser = pw.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe', headless=True)
    page = browser.new_page(viewport={'width': 900, 'height': 800}, device_scale_factor=1.5)
    errors = []
    page.on('pageerror', lambda e: errors.append(str(e)))
    page.goto((OUT/'preview.html').as_uri())
    page.wait_for_function('Array.from(document.images).every(i=>i.complete&&i.naturalWidth>0)')
    for dark in [False,True]:
        if dark: page.locator('#theme').click()
        page.locator('.comparison').screenshot(path=str(OUT/f'comparison-{"dark" if dark else "light"}.png'))
    for width,has_island in [(320,False),(375,False),(393,True),(430,True)]:
        page.locator('.column').evaluate_all('(els,w)=>els.forEach(e=>e.style.width=w+"px")',width)
        page.locator('.phone').evaluate_all('(els,se)=>els.forEach(e=>e.classList.toggle("se",se))',not has_island)
        layout = page.locator('.after').evaluate('''el=>{
            const box=el.getBoundingClientRect(), im=el.querySelector('img').getBoundingClientRect();
            return {top:im.top-box.top,width:im.width,height:im.height,scroll:el.scrollWidth,client:el.clientWidth};
        }''')
        assert abs(layout['top']-1)<0.1,layout
        assert abs(layout['height']/layout['width']-0.75)<0.01,layout
        assert layout['scroll']<=layout['client']+1,layout
        # Visually reviewed tip starts at y=212 in the 1448x1086 output; no app crop.
        tip_y=layout['width']*212/1448
        camera_bottom=45 if has_island else 20
        assert tip_y>camera_bottom,(width,tip_y,camera_bottom)
        checks.append({'width':width,'cameraBottom':camera_bottom,'tipY':round(tip_y,1),'imageStartsAtTop':True,'fullAspectRatio':True})
    assert not errors,errors
    browser.close()
(OUT/'preview-review.json').write_text(json.dumps({'kind':'HTML framing approximation','nativeAppViewed':False,'cases':checks,'javascriptErrors':errors},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'PASS: {len(checks)} image framing cases; native iOS layout remains unverified')
