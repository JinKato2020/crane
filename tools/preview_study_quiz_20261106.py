"""Browser interaction/layout approximation; not a screenshot of the native iOS app."""
import json
import re
from PIL import Image
from pathlib import Path
from verify_study_quiz import ROOT, fields, candidates, selection

def main():
    data=json.loads((ROOT/'CraneExam/Resources/textbook.json').read_text(encoding='utf-8'))
    sections=[]
    for ch in data['chapters']:
        for s in ch['sections']:
            for b in s['blocks']:
                if b['type'] not in ('img', 'svg'): continue
                file=b.get('file')
                if not file:
                    file=next((b['asset']+ext for ext in ('.png','.jpg','.jpeg') if (ROOT/'CraneExam/Resources/images'/(b['asset']+ext)).exists()), b['asset']+'.png')
                b['_previewFile']=file
                path=ROOT/'CraneExam/Resources/images'/file
                if path.exists() and path.suffix!='.svg':
                    with Image.open(path) as img: b['_width'],b['_height']=img.size
                elif path.exists():
                    match=re.search(r'viewBox=["\\\']0 0 ([\\d.]+) ([\\d.]+)',path.read_text(encoding='utf-8'))
                    if match:b['_width'],b['_height']=map(float,match.groups())
            pool=candidates(s)
            if not pool: continue
            fs=fields(s)
            for f in fs:
                for b in pool:
                    if b['fieldID']==f['id']:
                        b['start16']=len(f['text'][:b['start']].encode('utf-16-le'))//2
                        b['end16']=len(f['text'][:b['end']].encode('utf-16-le'))//2
            rounds={}
            for cat in ['all','key','num']:
                n=sum(cat=='all' or b['category']==cat for b in pool)
                rounds[cat]=[[b['id'] for b in selection(pool,cat,r)] for r in range(max(1,n))]
            sections.append(dict(**s, chapter=ch['id'], fields=fs, candidates=pool, rounds=rounds))
    html=HTML.replace('__DATA__',json.dumps(sections,ensure_ascii=False).replace('</','<\\/'))
    dest=ROOT/'docs/reviews/study-quiz-preview-20261106.html'
    dest.write_text(html,encoding='utf-8',newline='\n')
    print(dest)

HTML=r"""<!doctype html><html lang="ja"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>教材の暗記クイズ・表示確認</title>
<style>
*{box-sizing:border-box} :root{--bg:#f4f6f9;--card:#fff;--fg:#1a1d22;--muted:#5a6472;--line:#d6dbe3;--key:#185a92;--pale:#e5edf4;--hole:#d1e0ec;--size:16px}
body{margin:0;background:var(--bg);color:var(--fg);font:var(--size)/1.8 -apple-system,BlinkMacSystemFont,"Yu Gothic UI",sans-serif}
body.dark{--bg:#0c0e12;--card:#191d25;--fg:#eef1f6;--muted:#9aa4b4;--line:#2a303c;--key:#8cc9ff;--pale:#172534;--hole:#203c56}
body.large{--size:25px} button,select{font:inherit;color:inherit}button{cursor:pointer}button:focus-visible,select:focus-visible{outline:3px solid var(--key);outline-offset:3px}
.lab{max-width:640px;margin:auto;padding:12px 16px;font-size:14px;background:var(--card);border-bottom:1px solid var(--line)}
.lab p{font-size:12px;color:var(--muted);margin:0}.lab select{width:100%;padding:8px;border:1px solid var(--line);border-radius:8px;background:var(--card)}
.lab .options{display:flex;gap:14px;flex-wrap:wrap}.lab label{min-height:44px;display:flex;align-items:center;gap:5px}
main{max-width:640px;margin:auto;padding:22px 20px 32px}h1{font-size:1.3em;line-height:1.65;padding-left:14px;border-left:4px solid #e08a00;margin:10px 0 20px}
h2{font-size:1.18em;border-left:4px solid var(--key);padding-left:12px;margin:32px 0 14px;line-height:1.6}
.card{border:1px solid var(--line);border-radius:14px;padding:18px;margin:18px 0;background:var(--card)}
.quiz-card{border-color:color-mix(in srgb,var(--key) 22%,var(--bg));background:var(--pale)}
.toggle-row{display:flex;align-items:center;gap:12px;justify-content:space-between}.toggle-row strong{display:block;font-size:1.06em}.muted{color:var(--muted)}
.sub{font-size:.94em;line-height:1.6}.hint{font-size:.81em;color:var(--muted);margin-bottom:0}.category{display:flex;justify-content:space-between;align-items:center;gap:8px;flex-wrap:wrap;margin-top:12px}
.category select{color:var(--key);background:var(--card);border:1px solid var(--line);padding:6px;min-height:44px;max-width:100%;border-radius:8px}
.switch{appearance:none;min-width:52px;width:52px;height:32px;border-radius:20px;background:var(--line);position:relative;margin:0;cursor:pointer}
.switch:before{content:"";position:absolute;left:3px;top:3px;border-radius:100%;width:26px;height:26px;background:white;box-shadow:0 1px 4px #0002}
.switch:checked{background:var(--key)}.switch:checked:before{left:23px}.switch-label{min-height:44px;display:flex;align-items:center}
.text{white-space:pre-wrap;overflow-wrap:anywhere;line-height:1.9}.paragraph{margin:16px 0}strong{color:var(--key)}
.blank{display:inline;padding:2px 3px;border:0;border-radius:4px;background:var(--hole);color:var(--key);font-weight:700;font-size:inherit;line-height:inherit;white-space:normal;text-decoration:underline;text-underline-offset:3px}
.blank.revealed{background:var(--pale);text-decoration:none}
table{width:100%;border-spacing:0;border:1px solid var(--line);border-radius:12px;overflow:hidden;background:var(--card);margin:18px 0;table-layout:fixed}
th,td{text-align:left;vertical-align:top;padding:13px 14px;overflow-wrap:anywhere}th{background:var(--pale);font-size:.84em;color:var(--muted)}td{font-size:.94em;border-top:1px solid var(--line)}tr:nth-child(even){background:color-mix(in srgb,var(--pale) 40%,var(--card))}
.number{background:var(--pale);border:0}.number .label{color:var(--muted);font-weight:600;font-size:.88em}.number .value{font-size:1.35em;font-weight:700;margin-top:9px}
.figure img{display:block;width:100%;height:auto;max-height:620px;object-fit:contain;background:white;border-radius:10px}.figure small{display:block;color:var(--muted);font-size:.81em;line-height:1.6;margin-top:8px}
ul{padding-left:22px}li{margin-bottom:12px}.point{background:var(--pale)}.tip,.caution,.lead{background:var(--pale);border:0}.lead .text{font-size:1.12em;font-weight:600}.tag{font-size:.81em;font-weight:bold;color:var(--key);margin-bottom:10px}
details{padding:16px;background:var(--pale);border-radius:12px;margin:18px 0}summary{min-height:44px;align-content:center;color:var(--key);font-weight:600;cursor:pointer}details[open] summary{margin-bottom:12px}
#toolbar{position:fixed;bottom:0;left:50%;transform:translateX(-50%);width:min(640px,100%);padding:4px 16px 12px;background:var(--card);border-top:1px solid var(--line);z-index:10}
.toolbar-top{display:flex;align-items:center;justify-content:space-between;gap:8px;min-height:44px}.count{color:var(--key);font-size:.94em;font-weight:600;font-variant-numeric:tabular-nums}
.end{background:none;color:var(--muted);border:0;min-height:44px;min-width:44px;padding:0}
.actions{display:flex;gap:10px}.actions button{border:0;border-radius:12px;min-height:48px;padding:8px 10px;line-height:1.5;font-weight:600}.primary{flex:1;background:var(--key);color:var(--bg)}.secondary{background:var(--pale);color:var(--key);font-size:.94em}
.large table{display:block;border:0;background:none}.large thead{display:none}.large tbody{display:block}.large tr{display:block;background:var(--card);border:1px solid var(--line);border-radius:12px;margin:14px 0;padding:4px}.large td{display:block;border:0;padding:14px}.large td+td{border-top:1px solid var(--line)}.large td:before{content:attr(data-label);display:block;font-size:.78em;color:var(--muted);margin-bottom:6px}.large .actions{flex-direction:column}.large .number .value{font-size:1.1em}
.foot{color:var(--muted);text-align:center;margin:30px 0;font-size:.85em}
</style>
<body>
<div class="lab"><p>表示と操作の確認用プレビュー（iOS実画面ではありません）</p>
<select id="section" aria-label="表示する節"></select><div class="options">
<label><input type="checkbox" id="dark">ダーク</label><label><input type="checkbox" id="large">文字を大きく</label>
<button id="jump" class="end">最初の空欄へ ↓</button></div></div>
<main><h1 id="title"></h1><section id="quiz"></section><article id="content"></article><p class="foot">この節の学習はここまで</p></main>
<div id="toolbar"></div>
<script>
const sections=__DATA__;
const params=new URLSearchParams(location.search);
let current=sections.find(s=>s.id===(params.get('section')||'2-1'))||sections[0];
let on=params.get('quiz')!=='off', category=params.get('cat')||'all', round=0, revealed=new Set();
const $=id=>document.getElementById(id);
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const field=(i,name)=>current.id+'/'+i+'/'+name;
const text=(raw,id,cl='')=>'<div class="text '+cl+'"'+(id?' data-field="'+esc(id)+'"':'')+' data-raw="'+esc(raw)+'">'+rich(raw)+'</div>';
function rich(raw){return esc(raw).replace(/\*\*(.*?)\*\*/gs,'<strong>$1</strong>')}
function chosen(){return current.rounds[category]?.[round%current.rounds[category].length]||[]}
function selected(){const ids=chosen();return current.candidates.filter(b=>ids.includes(b.id))}
function render(){
 $('title').textContent=current.title;
 $('quiz').innerHTML='<div class="card quiz-card"><div class="toggle-row"><div><strong>暗記クイズ</strong><div class="sub muted">本文の空欄を、頭の中で答える</div></div><label class="switch-label"><input id="quizToggle" type="checkbox" role="switch" class="switch" aria-label="暗記クイズ" '+(on?'checked':'')+'></label></div>'+
 (on?((current.candidates.some(b=>b.category==='num')&&current.candidates.some(b=>b.category==='key'))?'<div class="category"><span class="sub muted">出題する内容</span><select id="category" aria-label="出題する内容"><option value="all">すべて</option><option value="key">用語・式</option><option value="num">数値</option></select></div>':'')+
 '<p class="sub">空欄をタップすると答えを確認できます。もう一度タップで隠せます。</p><p class="hint">1回に最大10か所。見出しや図はヒントに使えます。</p>':'')+'</div>';
 if($('category')) $('category').value=category;
 $('content').innerHTML=current.blocks.map((b,i)=>{
  if(b.type==='sub')return '<h2>'+rich(b.text)+'</h2>';
  if(b.type==='p'){
   if(b.style==='answer')return '<details><summary>答えと理由を見る</summary>'+text(b.text)+'</details>';
   if(b.style==='reference')return '<div class="card muted">'+rich(b.text)+'</div>';
   let name=['question','lead'].includes(b.style)?null:field(i,'text');
   if(['lead','tip','caution'].includes(b.style))return '<div class="card '+b.style+'"><div class="tag">'+({lead:'まず、これだけ',tip:'なるほど',caution:'取り違え注意'}[b.style])+'</div>'+text(b.text,name)+'</div>';
   return text(b.text,name,'paragraph');
  }
  if(['ul','point'].includes(b.type))return '<div class="'+(b.type==='point'?'card point':'')+'">'+(b.type==='point'?'<div class="tag">ここを覚える</div>':'')+'<ul>'+b.items.map((t,j)=>'<li>'+text(t,field(i,'items:'+j))+'</li>').join('')+'</ul></div>';
  if(b.type==='table'){
   if(b.style==='numbers')return b.rows.map((r,j)=>'<div class="card number">'+text(r[0],null,'label')+text(r.slice(1).join(' ／ '),field(i,'rows:'+j+':value'),'value')+'</div>').join('');
   if(b.headers.length<=2||b.style==='matrix')return '<table><thead><tr>'+b.headers.map(h=>'<th>'+rich(h)+'</th>').join('')+'</tr></thead><tbody>'+b.rows.map((r,j)=>'<tr>'+r.map((v,k)=>'<td data-label="'+esc(b.headers[k])+'">'+text(v,field(i,'rows:'+j+':'+k))+'</td>').join('')+'</tr>').join('')+'</tbody></table>';
   return b.rows.map((r,j)=>'<div class="card">'+text(r[0],field(i,'rows:'+j+':0'))+r.slice(1).map((v,k)=>'<div class="hint">'+rich(b.headers[k+1])+'</div>'+text(v,field(i,'rows:'+j+':'+(k+1)))).join('')+'</div>').join('');
  }
  if(['img','svg'].includes(b.type)){
   let file=b._previewFile;
   return '<figure class="figure" style="margin:18px 0"><img width="\'+(b._width||1536)+\'" height="\'+(b._height||1024)+\'" loading="lazy" src="../../CraneExam/Resources/images/'+encodeURIComponent(file)+'" alt="'+esc(b.caption||'教材の図')+'">'+(b.caption?'<small>図：'+esc(b.caption)+'</small>':'')+'</figure>';
  }
  return '';
 }).join('');
 paint();
}
function paint(){
 document.querySelectorAll('[data-field]').forEach(node=>{
  const id=node.dataset.field, source=current.fields.find(f=>f.id===id);
  if(!on||!source){node.innerHTML=rich(node.dataset.raw);return;}
  const blanks=selected().filter(b=>b.fieldID===id).sort((a,b)=>a.start16-b.start16);
  if(!blanks.length){node.innerHTML=rich(node.dataset.raw);return;}
  let pos=0,out='';
  blanks.forEach(b=>{
   out+=esc(source.text.slice(pos,b.start16));
   const yes=revealed.has(b.id), label=yes?b.answer:b.prompt;
   out+='<button class="blank '+(yes?'revealed':'')+'" data-answer="'+esc(b.id)+'" aria-pressed="'+yes+'" aria-label="'+esc(label+(yes?'。タップで隠す':'。タップで答えを表示'))+'">'+esc(label)+'</button>';
   pos=b.end16;
  });
  node.innerHTML=out+esc(source.text.slice(pos));
 });
 const all=chosen().length>0&&revealed.size===chosen().length;
 const available=current.candidates.filter(b=>category==='all'||b.category===category).length;
 $('toolbar').hidden=!on;
 $('toolbar').innerHTML='<div class="toolbar-top"><span class="count">答えを確認 '+revealed.size+' / '+chosen().length+'</span><button class="end" id="end">終了</button></div><div class="actions"><button class="primary" id="answers">'+(all?'もう一度隠す':revealed.size?'残りの答えを表示':'答えを表示')+'</button>'+(available>chosen().length?'<button class="secondary" id="next">別の出題</button>':'')+'</div>';
 document.querySelector('main').style.paddingBottom=(on?$('toolbar').offsetHeight+24:32)+'px';
 window.quizState={section:current.id,on,category,round,chosen:chosen(),revealed:[...revealed]};
}
$('section').innerHTML=sections.map(s=>'<option value="'+s.id+'">第'+s.chapter+'章 '+esc(s.title)+'</option>').join('');
$('section').value=current.id;
document.addEventListener('change',e=>{
 if(e.target.id==='section'){current=sections.find(s=>s.id===e.target.value);round=0;category='all';revealed.clear();render();window.scrollTo(0,0)}
 if(e.target.id==='category'){category=e.target.value;round=0;revealed.clear();paint()}
 if(e.target.id==='quizToggle'){on=e.target.checked;revealed.clear();render()}
 if(e.target.id==='dark'){document.body.classList.toggle('dark',e.target.checked);paint()}
 if(e.target.id==='large'){document.body.classList.toggle('large',e.target.checked);paint()}
});
document.addEventListener('click',e=>{
 const answer=e.target.closest('[data-answer]');
 if(answer){let id=answer.dataset.answer;revealed.has(id)?revealed.delete(id):revealed.add(id);paint()}
 if(e.target.id==='answers'){revealed=revealed.size===chosen().length?new Set():new Set(chosen());paint()}
 if(e.target.id==='end'){on=false;revealed.clear();render()}
 if(e.target.id==='next'){
  const before=[...chosen()].sort().join('|');
  for(let i=0;i<current.candidates.length;i++){round++;if([...chosen()].sort().join('|')!==before)break;}
  revealed.clear();paint();
 }
 if(e.target.id==='jump')document.querySelector('.blank')?.scrollIntoView({block:'center',behavior:'instant'});
});
if(params.get('theme')==='dark'){$('dark').checked=true;document.body.classList.add('dark')}
if(params.get('large')==='1'){$('large').checked=true;document.body.classList.add('large')}
window.addEventListener('resize',paint);
render();
</script></body></html>"""
if __name__=='__main__':main()
