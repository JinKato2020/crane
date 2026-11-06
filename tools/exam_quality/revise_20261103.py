"""Incremental reviewed corrections; stable question IDs and answer positions retained."""
from pathlib import Path
import copy, hashlib, json, re, shutil
REPO=Path(__file__).resolve().parents[2]
RES=REPO/'CraneExam/Resources'
path=RES/'exams.json'
es=json.loads(path.read_text(encoding='utf-8'))
qs={f"{e['round']}-{q['no']}":q for e in es for q in e['questions']}
before=copy.deepcopy(qs)
reasons={}
def edit(key,reason,**fields):
    qs[key].update(fields);reasons.setdefault(key,[]).append(reason)

edit('1-2','編集者向けの注意を学習者向けの説明に修正',explanation='[A]は天井クレーンの走行レール中心間の水平距離であるスパン。[B]は旋回中心からフック中心までの水平距離である作業半径。[C]は荷重によるたわみを見込んで設ける上向きの反りであるキャンバ。したがって(1)。揚程はフックを上下できる範囲を表す。')
edit('2-3','露骨な誤答を除き、公式書籍の開閉・昇降操作の区別を問う',
 text='複索式グラブバケット及びコンテナ用スプレッダに関する次の記述のうち、適切でないものはどれか。グラブバケットは、支持ロープと開閉ロープを用いる方式とする。',
 choices=['支持ロープを停止させたまま開閉ロープを巻き取ると、バケットは閉じる。',
 '支持ロープを停止させたまま開閉ロープを巻き戻すと、バケットは閉じる。',
 '支持ロープと開閉ロープを同時に巻き取ることにより、バケットの開閉状態を保って巻き上げることができる。',
 '複索式グラブバケットは、アンローダなどで鉄鉱石や石炭などの荷役に用いられる。',
 'コンテナ用スプレッダには、コンテナの隅金具にツイストロックを係合させて保持するものがある。'],answer=2,
 explanation='(2)が適切でない。支持ロープを止めて開閉ロープを巻き戻すと、バケットは開く。巻き取ると閉じるので、(1)は正しい。二つのロープを同時に巻き取る・巻き戻す操作は、開閉状態を保った昇降に使う。(3)〜(5)も適切である。')
edit('2-22','誤っている選択肢の理由を直接説明',explanation='(4)が適切でない。静止中の摩擦力は、加えた水平力につり合う値で、0から最大静止摩擦力まで変化する。μsNで求めるのは最大値であり、静止中にいつも働いている値ではない。(1)〜(3)、(5)は適切である。')
edit('3-30','時間を問う誤答に対して時間の比例関係を説明',explanation='(4)が適切でない。ジュール熱は Q＝I²Rt で求める。同じ電流I、同じ抵抗Rなら、通電時間tを2倍にすると発熱量も2倍になる。(2)は抵抗への比例、(3)は電流の2乗への比例を表す。(1)、(5)も適切である。')
q=qs['5-21'];exp=q['explanation'];cut=exp.find('二つの力の大きさをP、Q')
if cut>=0:edit('5-21','三角関数の追加学習を要求しない説明',explanation=exp[:cut]+'大きさが一定の二つの力では、同じ向きのときに合力が最大となり、開く角度を大きくすると合力は小さくなる。反対向きでは差の大きさとなる。')
edit('3-31','矢印を数値の比で描き直したため旧注記を除去',text=qs['3-31']['text'].replace('図は模式図であり、矢印の長さは力の大きさの縮尺を表していない。',''))
for key in ['3-37','5-26','8-25']:
    q=qs[key]
    if not q['text'].startswith('鉛直な1本'):
        edit(key,'ロープ張力の成立条件を問題文に明記',text='鉛直な1本のロープで荷をつり、荷には重力とロープの張力だけが作用しているものとする。'+q['text'])
edit('3-10','3D図とネイティブ選択肢表に合わせ重複見出しを除去',text=qs['3-10']['text'].split('選択肢')[0].replace('図中の歯車の歯数は問題文の値を用いる。','').rstrip()+'図中の歯車の歯数は問題文の値を用いる。')
edit('3-33','表の見出しの本文への重複を除去',text=qs['3-33']['text'].split('選択肢')[0].rstrip())
edit('12-5','二段歯車を教材と同じ3D図へ変更',text=qs['12-5']['text'].replace('図の破線はBとCの同軸関係を示し、実際の歯車の大きさや配置を示すものではない。','図中の歯車の歯数は問題文の値を用いる。'))
edit('12-3','より方向の抽象的な斜線を技術系3D図に変更',
 text='図A、Bは、ワイヤロープと、そのストランドの一部を拡大して示したものである。ロープを構成するストランドのより方向と、ストランドを構成する素線のより方向に着目したとき、A、Bのより方の組合せとして適切なものはどれか。Zより・Sよりの区別は問わない。',
 explanation='(2)が適切。普通よりは、ロープを構成するストランドと、ストランドを構成する素線のより方向が逆である。ラングよりは両者が同じ方向である。Aでは逆、Bでは同じ関係を示す。拡大図の素線の傾きと、ロープ全体のストランドの傾きを区別して見る。',
 figImg='exam_wire_lay_3d_20261103',figImgExp='exam_wire_lay_3d_20261103')
for key in ['5-23','6-24','7-23','7-24','8-21','8-22','8-30']:
    if '9.8' not in qs[key]['text']:
        edit(key,'数値計算に必要な重力加速度を明記',text=qs[key]['text']+'重力加速度は9.8m/s²とする。')
edit('6-24','鉛直成分を問う問題に不要な三角関数を除去',explanation='鉛直成分は左右で等しく、2本の合計で荷の重量2,000×9.8＝19,600Nを支える。したがって1本の鉛直成分は19.6÷2＝9.8kNで(2)。斜めのロープに沿う張力そのものと、荷を支える鉛直成分は区別する。')
if '張力係数' not in qs['9-38']['text']:
    edit('9-38','他のつり角度問題と同じく張力係数を与える',text=qs['9-38']['text']+'つり角度120°の張力係数は2.00とする。')
edit('9-38','張力係数で解ける説明に統一',explanation='(3)が正しい。荷の重さは750×9.8＝7,350N。1本のロープが受け持つ上向きの力は7,350÷2＝3,675Nである。斜めの張力は、この値に張力係数2.00を掛け、3,675×2.00＝7,350N＝7.350kNとなる。(1)は角度を考えずに二等分した値、(5)は2本で分担することを考えずに荷の重さ全体へ係数を掛けた値である。')
for key in ['3-10','12-5']:
    edit(key,'問題図と解説図を教材由来の同じ中立3D図に統一',figImg='exam_quality_gears_20261101',figImgExp='exam_quality_gears_20261101')
for key,name in {'4-8':'exam_4-8_q','8-3':'1-7_rope_diameter','8-5':'1-10_overwind',
                 '9-3':'exam_9-3_q','9-5':'exam_9-5_q','10-3':'exam_10-3_q',
                 '10-5':'exam_10-5_q','11-3':'exam_11-3_q'}.items():
    edit(key,'古い技術系線画の解説図を教材と同じ3D図に統一',figImgExp=name)

# True tables, rather than spacing characters inside one long choice string.
def table(key,headers,rows):
    assert len(rows)==5 and all(len(r)==len(headers) for r in rows),(key,rows)
    assert all(all(c.replace(' ','') in choice.replace(' ','') for c in row) for row,choice in zip(rows,qs[key]['choices'])),key
    edit(key,'対応関係を選択肢表として整列',choiceHeaders=headers,choiceRows=rows)
for key in ['1-2','9-3','9-5','9-20','9-33','9-34','10-20','11-20','12-20','12-3']:
    headers=['A','B'] if key=='12-3' else ['A','B','C']
    rows=[re.split(r'\[?[ABC]\]?[：:]?\s*',s)[1:] for s in qs[key]['choices']]
    table(key,headers,[[c.strip() for c in row] for row in rows])
for key,headers,pattern in [
 ('1-33',['引く力','引く距離'],r'([\d,]+N).*?([\d.]+m)'),
 ('3-33',['引く力','引く距離'],r'([\d.]+kN)\s+([\d.]+m)'),
 ('4-22',['荷の上昇速度','自由端の仕事率'],r'([\d.]+m/s).*?([\d.]+kW)'),
 ('5-14',['同期速度','すべり'],r'([\d,]+min⁻¹).*?(約?[\d.]+%)'),
 ('6-23',['引く力','引く距離'],r'([\d.]+kN)、([\d.]+m)'),
 ('7-24',['左の張力','右の張力'],r'左([\d.]+kN)、右([\d.]+kN)'),
 ('8-30',['引く距離','仕事'],r'([\d.]+m)、([\d.]+kJ)'),
 ('1-24',['導体','絶縁体'],r'導体:(.*?) — 絶縁体:(.*)'),
 ('8-1',['A','B'],r'A(.*?)、B(.*)'),
 ('12-33',['円柱Aの体積','円錐Bの体積'],r'VA＝(.*?)\s+VB＝(.*)'),
 ('10-3',['Aの部品','取付け'],r'A：(.*?)\s+取付け：(.*)'),
 ('3-11',['期限','提出先'],r'(.*?) (.*)'),
 ('5-6',['Aの部品','取り付ける側'],r'(.*?)／(.*)')]:
    matches=[re.search(pattern+'$',s) for s in qs[key]['choices']]
    assert all(matches),(key,qs[key]['choices'],pattern)
    table(key,headers,[list(m.groups()) for m in matches])

jobs=json.loads((REPO/'tools/exam_quality/figures_20261103/manifest.json').read_text(encoding='utf-8'))
mapping={j['before']:j['after'] for j in jobs}
for key,q in qs.items():
    for field in ['figImg','figImgExp']:
        if q.get(field) in mapping:edit(key,'図の文字・線・余白・日本語注記を教材規格に統一',**{field:mapping[q[field]]})

def digest(q):return hashlib.sha256(json.dumps(q,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
ledger_path=REPO/'tools/exam_quality/changes.json'
ledger=json.loads(ledger_path.read_text(encoding='utf-8'))
records={r['id']:r for r in ledger['changes']}
changes=[]
for key,q in qs.items():
    fields=sorted(k for k in set(before[key])|set(q) if before[key].get(k)!=q.get(k))
    if not fields:continue
    changes.append({'id':key,'displayNo':q['displayNo'],'fields':fields,'reason':'／'.join(dict.fromkeys(reasons[key])),
                    'beforeSHA256':digest(before[key]),'afterSHA256':digest(q)})
    record=records[key]
    record['fields']=sorted(set(record['fields'])|set(fields));record['afterSHA256']=digest(q)
    record['followup20261103']='／'.join(dict.fromkeys(reasons[key]))
if '2-3' in ledger['truthChecks']:
    ledger['truthChecks']['2-3']={'combination':False,'asksFalse':True,'falseIndices':[2]}
ledger_path.write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
path.write_text(json.dumps(es,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
if changes:
    audit_path=REPO/'tools/exam_quality/changes_20261103.json'
    previous={r['id']:r for r in json.loads(audit_path.read_text(encoding='utf-8'))['changes']} if audit_path.exists() else {}
    for r in changes:
        old=previous.get(r['id'])
        if old:
            r['beforeSHA256']=old['beforeSHA256'];r['fields']=sorted(set(old['fields'])|set(r['fields']))
            r['reason']='／'.join(dict.fromkeys((old['reason']+'／'+r['reason']).split('／')))
        previous[r['id']]=r
    audit_path.write_text(json.dumps({'date':'2026-11-03','changes':list(previous.values())},ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Updated',len(changes),'questions; tables',sum(bool(q.get('choiceRows')) for q in qs.values()))
