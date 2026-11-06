import json
from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT.parent/'tmp/study_quiz_20261106'
URL=(ROOT/'docs/reviews/study-quiz-preview-20261106.html').as_uri()
cases=[]
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe',headless=True)
    page=browser.new_page(viewport={'width':390,'height':844},device_scale_factor=1)
    errors=[]
    page.on('pageerror',lambda e:errors.append(str(e)))
    for section in ['1-10','2-1','3-2','4-6']:
        for width in [320,390]:
            for dark in [False,True]:
                for large in [False,True]:
                    page.set_viewport_size({'width':width,'height':844})
                    page.goto(URL+f'?section={section}&theme={"dark" if dark else "light"}&large={int(large)}')
                    page.wait_for_function('window.quizState && window.quizState.chosen.length>0')
                    state=page.evaluate('window.quizState')
                    assert page.locator('.blank').count()==len(state['chosen']), (section,'missing rendered blanks')
                    overflow=page.evaluate('({scroll:document.documentElement.scrollWidth, width:innerWidth})')
                    assert overflow['scroll']<=overflow['width']+1,(section,width,dark,large,overflow)
                    first=page.locator('.blank').first
                    first.evaluate("e=>e.scrollIntoView({block:'center'})")
                    first.click()
                    assert len(page.evaluate('window.quizState.revealed'))==1
                    first.click()
                    assert len(page.evaluate('window.quizState.revealed'))==0
                    # Save actual interaction states, including revealed ones.
                    if (section,width,dark,large) in [('2-1',390,False,False),('2-1',390,True,False),('2-1',320,False,True),('3-2',390,False,False),('4-6',390,False,False)]:
                        name=f'{section}-{width}-{"dark" if dark else "light"}-{"large" if large else "normal"}.png'
                        page.screenshot(path=str(OUT/name))
                    page.locator('#answers').click()
                    assert len(page.evaluate('window.quizState.revealed'))==len(state['chosen'])
                    assert page.locator('.blank.revealed').count()==len(state['chosen'])
                    page.locator('#answers').click()
                    assert not page.evaluate('window.quizState.revealed')
                    if page.locator('#next').count():
                        old=set(page.evaluate('window.quizState.chosen'))
                        page.locator('#next').click()
                        assert set(page.evaluate('window.quizState.chosen'))!=old
                        assert not page.evaluate('window.quizState.revealed')
                    if page.locator('#category').count():
                        page.locator('#category').select_option('num')
                        assert not page.evaluate('window.quizState.revealed')
                        assert page.locator('.blank').count()>0
                        assert all('数値' in s for s in page.locator('.blank').all_text_contents())
                    page.evaluate("document.activeElement.blur();window.scrollTo({top:document.documentElement.scrollHeight,behavior:'instant'})")
                    page.wait_for_timeout(300)  # Lazy image decode may extend the page after the first scroll.
                    page.evaluate("window.scrollTo({top:document.documentElement.scrollHeight,behavior:'instant'})")
                    layout=page.evaluate("({foot:document.querySelector('.foot').getBoundingClientRect().bottom,bar:document.getElementById('toolbar').getBoundingClientRect().top})")
                    assert layout['foot']<=layout['bar'],('bottom covered',section,width,dark,large,layout)
                    page.locator('#end').click()
                    assert not page.locator('.blank').count()
                    assert page.locator('#toolbar').is_hidden()
                    page.locator('#quizToggle').check()
                    assert page.locator('.blank').count()>0
                    assert not page.evaluate('window.quizState.revealed')
                    cases.append(dict(section=section,width=width,theme='dark' if dark else 'light',large=large,status='PASS'))
    # The three-column row-card path and single-category small pool.
    for section in ['2-6','4-2']:
        page.goto(URL+'?section='+section)
        page.wait_for_function('window.quizState')
        assert page.locator('.blank').count()==len(page.evaluate('window.quizState.chosen'))
    browser.close()
assert not errors,errors
report={'status':'PASS','type':'browser approximation (not native iOS)','cases':cases,'consoleErrors':errors,
        'interactions':['individual reveal/hide','show/hide all','different selection','numeric category','exit/restart','footer clearance','no horizontal overflow']}
(ROOT/'docs/reviews/study-quiz-preview-checks-20261106.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print(f'PASS: {len(cases)} mobile/theme/font combinations and quiz interactions; no script errors or horizontal overflow.')
