"""Render review-only home proposals. Does not write application files."""
from pathlib import Path
from playwright.sync_api import sync_playwright
import hashlib, json

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]
URL = (OUT/'index.html').as_uri()

review = {
    'date': '2026-11-06', 'status': 'proposal-only-awaiting-user-review',
    'reviewBasis': ['CraneExam/Views/HomeView.swift', 'CraneExam/Theme.swift', 'CraneExam/Store.swift',
                    'CraneExam/Views/RootView.swift', 'CraneExam/Views/FeedbackView.swift',
                    'CraneExam/Assets.xcassets/Hero.imageset/hero.jpg'],
    'nativeAppViewed': False, 'imageGenerator': 'built-in image_gen',
    'findings': [
        {'finding': '学習開始カードの前に、試験日と分野別成績が配置されている', 'source': 'HomeView.swift:14-28',
         'proposal': '最初の画面に学習再開の主ボタンを置く。試験日は小さな上部表示へ'},
        {'finding': '継続日数は模試の解答数だけが対象。教材・用語の閲覧は反映されない', 'source': 'Store.swift:142-169',
         'proposal': '教材・用語・模試を30秒以上見て離れた学習も記録。理解度・合格可能性とは区別する'},
        {'finding': '模試を受けていない人には成績欄が空欄になり、教材中心の学習者を評価しにくい', 'source': 'HomeView.swift:180-209',
         'proposal': 'ホームでは今週の学習日を表示し、詳細成績は模試・成績へ'},
        {'finding': '主な操作と補助機能が6枚のほぼ同じカードで並ぶ', 'source': 'HomeView.swift:305-317',
         'proposal': '主入口4つと、保存・総合解説などの補助機能を整理する'},
        {'finding': '現在のヒーローは単一の暗い画像。外観に関わらず白文字が重なる', 'source': 'HomeView.swift:78-106',
         'proposal': '3種の画像と画像なしを選択可能に。文字はUIで描画し、必要なコントラストを保つ'}
    ],
    'recommendedDefault': 'existing',
    'heroOptions': {'existing': 'いつもの景色（既存の画像）', 'anime': '未来の自分（アニメ調）',
                    'cinematic': '仕事の余韻（シネマ調）', 'none': '画像なし'},
    'rejectedHeroOptions': ['photo', 'simple'],
    'heroRevision': 'User requested existing hero plus retained anime and a new emotional low-angle image',
    'implementationAfterApproval': ['ホームのレイアウト', '学習再開位置の保存', '教材・用語を含む学習日の記録',
                                    'ヒーロー選択の保存', 'Dynamic Type・VoiceOver・実機でのタップ領域確認'],
    'sampleDataOnly': True, 'appImplementationChanged': False, 'published': False, 'buildStarted': False,
    'screenshots': [], 'previewQA': []
}

with sync_playwright() as pw:
    browser = pw.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True)
    page = browser.new_page(viewport={'width':1380,'height':1180},device_scale_factor=2)
    def load(query=''):
        page.goto(URL+query)
        page.wait_for_load_state('load')
        page.wait_for_function("Array.from(document.querySelectorAll('img[src]')).every(i=>i.complete&&i.naturalWidth>0)")
        page.evaluate('document.fonts.ready')
    for query,name in [('', '01-home-styles.png'),('?board=theme','02-dark-and-theme-picker.png'),('?board=states','03-learning-states.png')]:
        load(query)
        page.locator('.board').screenshot(path=str(OUT/name))
        review['screenshots'].append(name)
    for hero in ['existing','anime','cinematic']:
        load('?view=screen&hero='+hero)
        page.locator('.device').screenshot(path=str(OUT/f'home-{hero}-light.png'))
    for query,name in [('?view=screen&hero=existing&dark=1','home-existing-dark.png'),
                       ('?view=screen&hero=anime&sheet=1','hero-picker.png'),
                       ('?view=full&hero=existing','04-home-full-layout.png')]:
        load(query);page.locator('.device').screenshot(path=str(OUT/name))
        review['screenshots'].append(name)
    load('?view=screen&hero=existing')
    button=page.locator('.start').bounding_box();nav=page.locator('.navbottom').bounding_box()
    assert button['y']+button['height'] < nav['y'],(button,nav)
    review['previewQA'].append({'primaryActionVisibleWithoutScroll': True,'width':390,'height':844})
    page.locator('.changehero').click()
    assert page.locator('.chooser').is_visible()
    page.locator('[data-choice="anime"]').click()
    assert page.locator('.device').get_attribute('data-style')=='anime'
    page.locator('.close').click()
    assert page.locator('.device').get_attribute('data-style')=='existing'
    page.locator('.changehero').click();page.locator('[data-choice="none"]').click();page.locator('.confirm').click()
    assert not page.locator('.chooser').is_visible()
    assert page.locator('.hero').evaluate("e=>e.classList.contains('none')")
    review['previewQA'].append({'selectionPreview':True,'cancelRestoresPrevious':True,'imageNoneOption':True})
    browser.close()

baseline=json.loads((OUT/'app-baseline-hashes.json').read_text(encoding='utf-8'))
now={str(f.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(f.read_bytes()).hexdigest() for f in (ROOT/'CraneExam').rglob('*') if f.is_file()}
assert now==baseline, 'Application files changed during proposal work'
review['appFilesUnchanged']=len(now)
(OUT/'review.json').write_text(json.dumps(review,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps({'rendered':review['screenshots'],'appFilesUnchanged':len(now),'status':'proposal-only'},ensure_ascii=False))
