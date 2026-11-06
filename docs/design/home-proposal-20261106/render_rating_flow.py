"""Render the review-only campaign journey; never changes app sources."""
from pathlib import Path
from playwright.sync_api import sync_playwright
import hashlib
import json

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]
with sync_playwright() as pw:
    browser = pw.chromium.launch(
        executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe', headless=True)
    page = browser.new_page(viewport={'width': 1380, 'height': 1300}, device_scale_factor=2)
    url = (OUT / 'rating-flow.html').as_uri()
    page.goto(url)
    page.wait_for_function("Array.from(document.images).every(i=>i.complete&&i.naturalWidth>0)")
    page.evaluate('document.fonts.ready')
    page.locator('.board').screenshot(path=str(OUT / '05-campaign-review-flow.png'))
    qa = []
    for view in ['campaign', 'settings']:
        page.goto(url + '?view=' + view)
        page.wait_for_function("Array.from(document.images).every(i=>i.complete&&i.naturalWidth>0)")
        page.evaluate('document.fonts.ready')
        screen = page.locator(f'[data-screen="{view}"]')
        screen.locator('.device').screenshot(path=str(OUT / f'rating-{view}.png'))
        button = screen.locator('.primary').bounding_box()
        nav = screen.locator('.navbottom').bounding_box()
        assert button['y'] + button['height'] < nav['y'], (view, button, nav)
        assert screen.locator('.screen-scroll').evaluate('e=>e.scrollWidth<=e.clientWidth'), view
        screen.locator('.primary').click()
        assert page.locator('.notice').is_visible()
        qa.append({'screen': view, 'primaryVisibleWithoutScroll': True,
                   'noHorizontalOverflow': True, 'demoHasNoExternalAction': True})
    browser.close()

baseline = json.loads((OUT / 'app-baseline-hashes.json').read_text(encoding='utf-8'))
now = {str(f.relative_to(ROOT)).replace('\\', '/'): hashlib.sha256(f.read_bytes()).hexdigest()
       for f in (ROOT / 'CraneExam').rglob('*') if f.is_file()}
assert now == baseline, 'Application files changed since the home design baseline'
report = {'status': 'proposal-only-awaiting-user-review', 'date': '2026-11-06',
          'appFilesUnchanged': len(now), 'qa': qa, 'published': False, 'buildStarted': False,
          'existingSchedulePreserved': {'firstDay': 3, 'repeatMinimumDays': 7, 'studySeconds': 30},
          'screenshots': ['05-campaign-review-flow.png', 'rating-campaign.png', 'rating-settings.png'],
          'reviewSubmissionObservable': False, 'nativeAppViewed': False}
(OUT / 'rating-flow-review.json').write_text(
    json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
print(json.dumps(report, ensure_ascii=False))
