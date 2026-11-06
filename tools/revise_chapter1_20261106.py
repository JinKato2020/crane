"""Apply the reviewed chapter-1 revision, keeping all mock-exam anchor IDs.

The immutable source snapshot is created before editing in tmp/ch1_revision_20261106.
Other chapters, exam questions and unrelated pending changes are not rewritten.
"""
import copy
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
RES = ROOT / 'crane-app/CraneExam/Resources'
BASE = ROOT / 'tmp/ch1_revision_20261106/textbook.json'
original = json.loads(BASE.read_text('utf-8'))
data = copy.deepcopy(original)
chapter = data['chapters'][0]
sections = {s['id']: s for s in chapter['sections']}
olds = {s['id']: copy.deepcopy(s['blocks']) for s in chapter['sections']}
exam = json.loads((RES/'exams.json').read_text('utf-8'))
protected = {(r['section'], r['blockID']) for e in exam for q in e['questions'] for r in q.get('refs', [])}

def old(s, i): return olds[s][i]['id']
def get(s, i): return next(b for b in sections[s]['blocks'] if b['id']==old(s,i))
def patch(s, i, text=None, **attrs):
    b=get(s,i)
    if text is not None: b['text']=text
    b.update(attrs)
    return b
def drop(s, *idx):
    ids={old(s,i) for i in idx}
    assert all((s,x) not in protected for x in ids), (s,ids)
    sections[s]['blocks']=[b for b in sections[s]['blocks'] if b['id'] not in ids]
def replace(s, i, typ, **attrs):
    b=get(s,i); bid=b['id']; b.clear(); b.update(id=bid,type=typ,**attrs); return b
def new(s, key, typ='p', **attrs): return dict(id=s+'-rev26-'+key, type=typ, **attrs)
def add_after(s, i, *blocks):
    seq=sections[s]['blocks']; at=seq.index(get(s,i)); seq[at+1:at+1]=blocks
def move_before(s, i, target):
    seq=sections[s]['blocks'];b=get(s,i);seq.remove(b);seq.insert(seq.index(get(s,target)),b)
def table(s,key,headers,rows): return new(s,key,'table',headers=headers,rows=rows)
def point(s,key,*items): return new(s,key,'point',items=list(items))
def figure(s,key,file,caption): return new(s,key,'svg',file=file,caption=caption,style='figure')
def check(s,key,question,answer):
    return [new(s,key+'-q',text=question,style='question'),new(s,key+'-a',text=answer,style='answer')]

# Definition and five motions: keep the good opening, add a compact comparison.
patch('1-3',4,caption='上下・横行・走行・起伏・旋回。矢印の向きと、動く部分を対応させる。')
add_after('1-3',4,table('1-3','motions',['運動','どこが動く？'],[
 ['**巻上げ・巻下げ**','フックや荷が上下する'],['**横行**','トロリがガーダなどに沿って動く'],
 ['**走行**','クレーン全体が走行レールに沿って動く'],['**起伏**','ジブを起こす・伏せる'],['**旋回**','ジブなどが旋回中心のまわりに回る']]))

# Same numeric example in the text and diagram; move the unillustrated trig aside.
patch('1-2',6,'ジブを持たないクレーンで、つり上げ荷重が**10.0 t**、つり具分が**0.5 t**なら、定格荷重は10.0−0.5＝**9.5 t**です。図と同じ数値で、つり具分を引いて確かめます。')
drop('1-2',7,8)
patch('1-2',9,'この9.5 tには、荷物のほかに玉掛け用ロープや補助つり具の負担も数えます。能力を確認するときは、**荷物だけの重さで判断しない**ことが大切です。')
patch('1-2',29,'同じジブ長さなら、**起こすと半径が小さくなり、伏せると大きくなります**。まずこの関係を図でつかみましょう。')
patch('1-2',30,'応用：ジブの長さから作業半径を求める')
patch('1-2',31,'斜めの長さから水平の長さを求める割合が**cos（コサイン）**です。ここでは、問題で与えられたcos60°＝0.5を使います。10mのジブの水平分は、10×0.5＝5mです。')
patch('1-2',32,'**作業半径＝支点までの水平距離＋ジブの水平分**。旋回中心とジブの付け根がずれていれば、その距離も足します。')
patch('1-2',33,'図では、旋回中心から支点まで2m、ジブ長10m、傾斜角60°です。作業半径は2＋10×0.5＝**7m**。角度は水平面から測ります。')
add_after('1-2',30,figure('1-2','projection','1-2_radius_projection_20261106.svg','2mと、ジブの水平分5mを足す。角度は水平面から測る。'))
# Keep this exam-linked lesson, but place it after the basic vocabulary.
group=[get('1-2',i) for i in (30,31,32,33)]
projection=next(b for b in sections['1-2']['blocks'] if b['id']=='1-2-rev26-projection')
seq=sections['1-2']['blocks']; seq[:]=[b for b in seq if b not in group and b is not projection];seq.extend([group[0],projection,*group[1:]])

# Types: a single level-luffing explanation; add tested distinguishing features.
patch('1-4',15,'**引込みクレーン**は、ジブを動かしても荷がほぼ水平に移動する形式です。仕組みは、この節の「引込みクレーン」で比べます。')
patch('1-4',17,caption='高脚・低床・ポスト形・つち形・壁クレーン。ジブを下から支える構造を見る。')
patch('1-4',20,'脚の外へ張り出したガーダを**カンチレバー**といいます。走行レールの外側にも荷を運べます。船の出入りを妨げないよう、カンチレバーを起こせる形式もあります。')
patch('1-4',23,'多くのアンローダでは、すくったばら物を**ホッパ（受入れ容器）**へ落とし、**コンベヤ**で運びます。「船→グラブ→ホッパ→コンベヤ」の順に荷を追うと、役割が分かります。')
patch('1-4',32,'**スタッカー式**には運転室がフォークなどと一緒に昇降するものがあり、**荷昇降式**では荷を載せる部分が昇降します。名前だけでなく、何が上下するかを見分けます。')
add_after('1-4',37,table('1-4','luffing-types',['方式','水平を保つ仕組みの目印'],[
 ['**ダブルリンク式**','3つのジブを組み合わせたリンクの動き'],['**スイングレバー式**','起伏に合わせてレバーが回り、ロープを繰り出す'],['**ロープバランス式**','起伏に合わせた巻上げロープの繰出し'],['**テンションロープ式**','補助ジブと、その支持ロープの組合せ']]))

# The designated book's examination model comes first.
patch('1-5',5,'ガーダ・サドル・トロリフレームなどが、試験でいう**構造部分**です。階段や運転室は、この区分には含めません。')
patch('1-5',12,'**ボックスガーダ**は、鋼板を箱形につないだ桁です。水平力やねじれにも強く、補桁を必要としません。')
patch('1-5',13,'**トラスガーダ**は主桁と補桁を組み合わせます。Iビームガーダやプレートガーダは、補桁なしで使う場合もあります。断面の形と、補桁の要否を結び付けます。')
drop('1-5',14)
add_after('1-5',4,table('1-5','structure',['部材','形と役割'],[
 ['**ガーダ**','トロリや荷を支える長い桁'],['**サドル**','ガーダの両端を支え、走行車輪を備える。代表例は鋼板を接合した箱形'],['**橋形クレーンの脚**','ガーダを下から支える。軽く強くするため、箱形や鋼管などを使う']]))
patch('1-5',25,'**剛脚は垂直荷重と水平荷重、揺脚は垂直荷重を受ける**と整理します。揺脚はガーダとの連結部を動ける構造にし、ガーダの伸縮やたわみに対応します。')
replace('1-5',27,'point',items=['**剛脚：上下と横を支える。**','**揺脚：上下を支え、ガーダの変形に対応する。**'])
drop('1-5',28,29)
# The former structural footnote diagram is replaced with a clear examination model.
patch('1-5',26,caption='剛脚は垂直・水平荷重、揺脚は垂直荷重を受ける、という試験での整理。')
patch('1-5',34,'**ホイスト**は、電動機・減速機・巻上げ部分・ブレーキなどを小さくまとめた装置です。この章では、**巻上装置と横行装置を一体化したもの**を基本形として覚えます。ロープ式はドラム、チェーン式はロードシーブを使います。')
drop('1-5',35)
patch('1-6',7,'**制動用ブレーキ**は動きを止め、荷を保持します。**速度制御用ブレーキ**は、荷を下ろす速さを調整します。「止めておく」と「速さを整える」を区別しましょう。')

# Gear example is now 20->60 twice throughout, followed by an inverse calculation.
patch('1-9',11,'1段目は60÷20＝**3**、2段目も60÷20＝**3**。全体の減速比は3×3＝**9**です。段ごとの比は足さず、掛け合わせます。')
patch('1-9',12,'Aが毎分**900回転**なら、Bは900÷3＝**300回転**。Bと同じ軸のCも300回転です。Dは300÷3＝**100回転**になります。')
patch('1-9',10,caption='A・Cは20歯、B・Dは60歯。BとCは同じ軸で同じ回転数。歯の形は模式で示す。')
add_after('1-9',13,*check('1-9','gear-reverse','**確認：** 図と同じ歯数で、Bが毎分300回転なら、AとDは毎分何回転？','**Aは900回転、Dは100回転。** A＝300×60÷20。CはBと同じ300回転なので、D＝300×20÷60。かみ合う歯車では「回転数×歯数」が等しくなります。'))
patch('1-9',16,'**はすば歯車**は、歯が斜めで、順にかみ合うため滑らかに回ります。平歯車より**大きな減速比にできる**特徴があります。一方、軸の長さ方向へ押す力（**スラスト**）が生じます。回転数の計算には歯数の比を使います。')
patch('1-9',25,'**円すいころ軸受**は、ラジアル荷重と、片方向のスラスト荷重を受けられます。「両方向」と覚えるのでなく、力の種類と向きを図で確かめます。')
patch('1-9',27,'給脂周期の代表値は、**平軸受：毎日1回程度、転がり軸受：6か月に1回程度**です。給油と点検の節で、方法と一緒に復習します。')
patch('1-9',41,'**ばね座金**：切り欠きのある輪のばね作用で、緩みを防ぐために使います。')
patch('1-9',37,caption='平座金は座面を保護し、舌付き座金は舌を折り曲げて回り止めにする。')
patch('1-9',45,'**ばねナット**は、ねじと同じ角度のばね鋼を**2～3巻き**して両端を結束した部品です。締めた六角ナットの上に取り付け、緩みを防ぎます。座面にはさむ「ばね座金」と区別します。')
patch('1-9',46,caption='ばねナットは巻いたばね鋼。六角ナットの上に取り付けて緩みを防ぐ。')
patch('1-9',50,'**割形軸継手**：二つ割りの円筒で軸を挟み、ボルトで固定します。軸を長さ方向へ動かさずに着脱でき、橋形クレーンの走行長軸などの低速軸に使います。2軸は一直線に合わせます。')
patch('1-9',53,'**歯車形軸継手**は歯のかみ合い、**ローラチェーン軸継手**は2個のスプロケットに掛けた2列のチェーンで動力を伝えます。どちらも、わずかな軸のずれや傾きに対応する、たわみ軸継手です。')
add_after('1-9',60,new('1-9','keyplate',text='**キー板（キープレート）**は、固定軸の回転や軸方向への抜け出しを防ぐ板です。軸の溝に差し込み、ボルトで固定します。歯車と軸の空回りを止めるキーとは、使う場所を区別します。'))
add_after('1-9',18,table('1-9','gear-types',['種類','形・覚える特徴'],[
 ['**平歯車**','まっすぐな歯。平行な軸に伝える'],['**はすば歯車**','斜めの歯。滑らか・大きな減速比・スラスト'],['**かさ歯車**','円錐の形。交差する軸に伝える'],['**ウォーム歯車**','ねじと歯車。一組で大きく減速できる']]))

# Rope-end comparison is placed before its detailed explanations.
replace('1-7',31,'table',headers=['末端処理','見分ける形・効率の代表値'],rows=[
 ['**ソケット止め**','開いた素線を筒の中で合金などにより固定：**100％**'],
 ['**圧縮止め**','折り返した部分を金属のスリーブで圧着：**95％**'],
 ['**アイスプライス**','端のストランドを本体へ編み込む：**70～95％**'],
 ['**クリップ止め**','折り返したロープをクリップで固定：**80～85％**'],
 ['**くさび止め**','ソケット内でロープをくさびに巻いて固定：**65～70％**']])
move_before('1-7',38,31)
patch('1-7',38,caption='末端処理5方式。金属の筒、編込み、クリップ、くさびの形を見分ける。')
patch('1-7',39,'**受け台（サドル）は本体側、Uボルトは端末側**にそろえます。本体側は荷を支える長い側、端末側は折り返した短い側です。複数のクリップを交互に裏返しません。',style='tip')
drop('1-7',41)
add_after('1-7',31,new('1-7','efficiency',text='効率は、加工前のロープの強さをどれだけ生かせるかの目安です。表は試験で扱う代表値として、形と結び付けて覚えます。'))
add_after('1-7',18,table('1-7','lay',['より方','2段階のより方向'],[['**普通より**','素線とストランドが反対方向'],['**ラングより**','素線とストランドが同方向']]))

# Drum combined figure precedes all three topics rather than appearing late.
move_before('1-13',22,8)
patch('1-13',22,caption='左：ドラムに残す捨巻き／中央：エコライザシーブ／右：Dとdの測り方。')
patch('1-13',17,'上の図の左側が捨巻きです。**ドラムに残った巻きの摩擦**が張力を受け持ち、ロープ取付部だけに力が集中するのを軽減します。')
patch('1-13',23,'上の図の中央上部が**エコライザシーブ**です。下側のシーブとフックは荷と一緒に動きますが、エコライザシーブは左右の張力をつり合わせ、通常の巻上げではほとんど回転しません。')

# Rigging: remove repeated narrative, preserve the linked lesson heading.
drop('1-8',10,11)
patch('1-8',13,'複索式のグラブでは、**支持ロープがバケットを支え、開閉ロープが口を動かします**。支持ロープを止め、開閉ロープを巻き取ると閉じ、巻き戻すと開きます。両方を同時に操作すると、開閉状態を保ったまま上げ下げできます。電動油圧式もあります。')
patch('1-8',23,'**スプレッダ**はコンテナ専用のつり具です。四隅の隅金具にツイストロックを差し込んで回し、ロックしてつり上げます。')
patch('1-8',14,'グラブは**ばら物をすくう**、スプレッダは**コンテナの四隅をロックする**。荷のつかみ方を見分けましょう。')

# Safety devices: comparisons plus numbers, instead of a wall of caveats.
replace('1-10',7,'table',headers=['巻過防止装置','位置の見方・ロープ交換後'],rows=[
 ['**直働式**（重錘形・ロッド形）','フックの位置を直接検出。交換後の作動位置の再調整は不要'],
 ['**間接式**（ねじ形・カム形）','ドラムの回転から位置を検出。交換後は作動位置を再調整']])
patch('1-10',8,'間接式は接点を組み合わせて**上限・下限**の制限に使えます。直働式の重錘形は、上がってきたフックが重錘を持ち上げるため、巻下げの下限検出には使いません。')
drop('1-10',9)
replace('1-10',10,'table',headers=['巻過防止の方式','停止後に残す間隔'],rows=[['一般','**0.25m以上**'],['直働式','**0.05m以上**']])
patch('1-10',11,'間隔は、つり具等の上面と衝突のおそれがある上部の物の下面の間で見ます。詳しい適用条件は、第2章「クレーンの使用」で確認します。')
add_after('1-10',11,new('1-10','legal-link',text='第2章：使うとき・働くときの決まり',style='reference',file='2-2'))
replace('1-10',21,'table',headers=['車輪止め','レール上面からの高さ'],rows=[['**横行用**','車輪直径の**1/4以上**。直径400mmなら100mm以上'],['**走行用**','車輪直径の**1/2以上**。直径400mmなら200mm以上']])
drop('1-10',22)
replace('1-10',30,'table',headers=['逸走防止装置','固定のしかた'],rows=[['**レールクランプ**','走行レールを挟んで移動を抑える'],['**アンカー**','決められた係留位置で基礎側へ固定する']])
patch('1-10',28,'屋外の走行クレーンでは、瞬間風速**30m/sを超える風のおそれ**があるとき、逸走防止措置を取ります。作業を続けてよい風速の上限ではありません。',style='caution')

# Brake classification first, then release mechanism. Preserve all linked IDs.
drop('1-11',6,8,9,13,17)
patch('1-11',11,'**形で分ける：** ブロック・バンド・ディスク。**動かす方法で分ける：** 電磁式・油圧式。例えば「ドラム形で電磁式」のように、二つの分類を組み合わせて呼びます。',style='tip')
move_before('1-11',12,5);move_before('1-11',11,5)
patch('1-11',7,'**電気が切れると、ばねで制動。通電すると、電磁石で開放。** 図の方式は、電気がなくても荷を保持できるよう、ばねがブレーキを効かせます。これを無電圧作動型といいます。')
patch('1-11',14,'**バンドブレーキ**は帯で締め、**ブロックブレーキ**は靴形の摩擦材を押し付けます。どちらもドラムの外周に摩擦を生みます。')
patch('1-11',15,'**ディスクブレーキ**は、円板を両側からパッドで挟みます。放熱しやすく、小形にでき、ホイストの巻上装置にも使われます。')
patch('1-11',16,caption='帯を締めて制動する。調整用ボルトは、緩めたときのすき間を均等にする。')
add_after('1-11',16,new('1-11','band-adjust',text='**調整用ボルトは、バンドを均等に緩めるため。** 緩めた帯がドラムの一部に当たり続けないよう、すき間を調整します。',style='tip'),*check('1-11','band-check','**確認：** バンドのすき間を調整する部品は、摩擦パッド？ 調整用ボルト？','**調整用ボルト。** 摩擦パッドはディスクを挟む部品です。バンドでは「緩めたときに均等に離れる」と結び付けます。'))
patch('1-11',20,'**電動油圧押上機ブレーキ：ばねで制動、油圧で開放。** 静かで衝撃が小さく、横行・走行などに使われます。停止までの時間は電磁式より長めです。**足踏み油圧式ディスクブレーキ**は、天井クレーンの走行やジブクレーンの旋回に使われます。')
replace('1-11',23,'table',headers=['対象','必要な制動トルク'],rows=[['つり上げ装置・起伏装置','定格荷重相当の荷をつったときのトルクの**1.5倍以上（150％以上）**']])

# Consolidate handling explanations and teach both start and stop notch timing.
drop('1-14',16,20,25,26)
patch('1-14',14,'**巻上げロープが長いほど、振れ幅と振れの周期は大きくなります。** 周期とは、一往復に掛かる時間です。ゆっくり戻ってくる荷の動きを思い浮かべましょう。')
patch('1-14',15,'**重い荷ほど慣性が大きく、動き出しにくく、止まりにくい。** 荷振れの原因となる急な加速・減速を避け、滑らかに操作します。')
move_before('1-14',32,14)
drop('1-14',24)
patch('1-14',28,'**追いノッチ**は、荷の振れに合わせた短い操作で振れを抑える方法です。発進時と停止時では、操作するタイミングが違います。')
replace('1-14',29,'svg',file='1-14_notch_start_20261106.svg',caption='発進時：いったん停止・減速して荷を待ち、ロープが鉛直になる前に再び動かす。',style='figure')
add_after('1-14',29,figure('1-14','notch-stop','1-14_notch_stop_20261106.svg','停止時：前へ進む荷が振り切れる前に、進行方向へ短く動かして切る。'),table('1-14','timing',['場面','追いノッチのタイミング'],[
 ['**発進時**','遅れた荷が追いつき、ロープが鉛直になる前に再び動かす'],['**停止時**','荷が前へ振り切れる前に入れ、直後に切る']]),new('1-14','operation-note',text='図は試験で学ぶ操作の考え方です。実際には、その機種・制御方式に対応した手順で操作します。'))
patch('1-14',36,'クライミング式では、荷をつるとジブや塔がたわみ、**作業半径が大きくなる**ことがあります。つる前の半径だけで決めず、たわみを考慮した作業半径に対応する定格荷重を確認します。')

# Lubrication: retain the useful period table, remove duplicate paragraphs.
drop('1-12',3,20,22)
patch('1-12',7,'**潤滑剤は、指定の種類と量を使います。** 油やグリースを入れすぎると、かき混ぜる抵抗が増え、発熱や漏れの原因になります。')
patch('1-12',8,'油面計で規定の範囲にあるかを確認します。グリースは、古いものが押し出されるなど、**必要な場所へ届いたこと**を確かめます。ポンプが動いていても、配管の詰まりで届かないことがあります。')
patch('1-12',25,'試験では、**平軸受は毎日、転がり軸受は6か月**を逆にした選択肢に注意します。実機では、メーカーや事業場が定めた周期に従います。')
patch('1-12',26,caption='グリースカップ・グリースガン・集中給油。周期は上の表で確認する。')
patch('1-12',28,'特に、**シーブを通る部分・ロープ端の取付部・エコライザシーブ付近**を確認します。逆巻きや乱巻きにも注意します。')
drop('1-12',12,13)
patch('1-12',29,caption='作業開始前・月次・年次の点検。記録や臨時点検の条件は、第2章の定期自主検査・点検を参照。')
add_after('1-12',29,new('1-12','inspection-link',text='第2章：定期的な検査と点検',style='reference',file='2-3'))
add_after('1-12',10,new('1-12','oil-heading','sub',text='減速機の油浴式――回る歯車で油を届ける'),new('1-12','oil',text='**油浴式**は、歯車の下部を油に浸し、回転ではね上げたギヤー油で歯車や軸受を潤滑します。'),new('1-12','oil-figure','img',asset='1-12_oil_bath_20261106',style='figure',caption='歯車が油をはね上げて、かみ合う部分や軸受へ届ける。'),new('1-12','oil-change',text='**密閉されていても、油の交換は必要です。** 長く使うと油が劣化し、金属粉やごみが混ざります。定期的に点検し、必要に応じて交換します。',style='tip'))

# Chapter-end retrieval, instead of ten uninterrupted review paragraphs.
sections['1-15']['blocks']=[new('1-15','intro',text='**図・数値・動きの意味を、自分で答えてみましょう。** 各問の下で答えと理由を確認できます。',style='lead')]
questions=[
 ('荷重','ジブのないクレーンで、つり上げ荷重10.0t、つり具分0.5t。定格荷重は？','**9.5t。** つり上げ荷重から、つり具分を引きます。ジブクレーンでは現在の姿勢に対応する能力も確認します。'),
 ('運動','トロリがガーダ上を動くのは横行？ 走行？','**横行。** 走行はクレーン全体が走行レールに沿って動くことです。上下の動きは巻上げ・巻下げです。'),
 ('角度と距離','ジブ傾斜角の基準は水平面？ 鉛直線？ 作業半径はどの距離？','**角度は水平面が基準。作業半径は旋回中心からつり具中心までの水平距離。** ジブそのものの長さとは違います。'),
 ('揺脚','剛脚と揺脚は、それぞれどの向きの荷重を受ける？','**剛脚：垂直・水平。揺脚：垂直。** 揺脚はガーダの伸縮やたわみに対応する側です。'),
 ('より方','普通よりとラングよりは、何の方向を比べる？','**素線のより方向と、ストランドのより方向。** 反対なら普通より、同じならラングより。Z・Sは、より方向そのものの区別です。'),
 ('ロープとシーブ','D/dが大きいほどロープの曲げはきつい？ 緩やか？ 捨巻きはいつ何巻残す？','**曲げは緩やか。捨巻きは最大払い出し時に2巻以上。** Dはピッチ円直径、dはロープ径です。'),
 ('歯車','20歯のAが60歯のBを回し、同軸の20歯Cが60歯Dを回す。Aが900rpmならDは？','**100rpm。** 全体の減速比は（60÷20）×（60÷20）＝9。900÷9＝100。BとCは同じ300rpmです。'),
 ('部品の識別','図のA～Dのうち、ばねナットはどれ？ 他の三つの名前も考えてみましょう。','**Aがばねナット。** ばね鋼を2～3巻きした形です。Bはばね座金、Cはダブルナット、Dは溝付きナット。形と取り付け位置を区別します。'),
 ('ブレーキ','ばねで制動する電磁ブレーキは、停電したら開く？ 効く？ バンドを均等に緩める部品は？','**停電すると効く。部品は調整用ボルト。** 通電した電磁石はブレーキを開放します。ブレーキの1.5倍は制動トルクの基準です。'),
 ('安全装置の数字','直径400mmの車輪。車輪止めは横行用・走行用それぞれ何mm以上？ 玉掛け用ワイヤロープの安全係数は？','**横行100mm以上、走行200mm以上。安全係数6以上。** 横行は直径の1/4、走行は1/2。安全係数＝切断荷重÷最大荷重です。'),
 ('追いノッチ','停止時、荷が前へ振り切れた後に、真下へ戻るまで待って操作する。正しい？','**誤り。前へ振り切れる前に、進行方向へ短く動かして切ります。** 発進時は、ロープが鉛直になる前に再び動かします。'),
 ('給油と逸走防止','平軸受と転がり軸受の給脂周期の代表値は？ 屋外の走行クレーンで逸走防止措置を取る風の条件は？','**平軸受は毎日1回程度、転がり軸受は6か月に1回程度。瞬間風速30m/sを超える風のおそれ。** 密閉された減速機箱でも油の点検・交換は必要です。')]
for i,(title,q,a) in enumerate(questions,1):
    sections['1-15']['blocks'].append(new('1-15',f'check-{i}-heading','sub',text=f'{i:02}　{title}'))
    sections['1-15']['blocks'].extend(check('1-15',f'check-{i}',q,a))
    if i==8: sections['1-15']['blocks'].insert(-1,new('1-15','nut','img',asset='1-15_fastener_check_20261106',style='figure',caption='A～Dの形を見比べて答える。'))

# The practice illustration uses letters instead of names, so it does not reveal
# the answer. The instructional figure is not repeated in this practice block.
for term in chapter.get('glossary',[]):
    if term['term']=='剛脚／揺脚':
        term['def']='剛脚は垂直荷重と水平荷重、揺脚は垂直荷重を受ける。揺脚はガーダの伸縮やたわみに対応する構造。'
    if term['term']=='クラブトロリ／ホイスト':
        term['def']='クラブトロリは巻上装置と横行装置を載せて自走する台車。ホイストは、巻上装置と横行装置を小形に一体化したものを基本形として覚える。'

for s in chapter['sections']:
    for b in s['blocks']:
        text=' '.join([b.get('text','')]+b.get('items',[])+sum(b.get('rows',[]),[]))
        if b['type'] in ('p','point','table','ul'):
            candidates=[t for t in re.findall(r'\*\*(.+?)\*\*',text) if len(t)<=16 and not re.search('[。！？：、]',t)]
            oldterms=[t for t in b.get('quizTerms',[]) if t in text and t.strip()]
            terms=list(dict.fromkeys(t for t in candidates+oldterms if len(t)<=28))
            if terms or 'quizTerms' in b:b['quizTerms']=terms
        if b['type'] in ('img','svg'): b['style']='figure'
        if b['type']=='p' and b.get('text','').startswith('- '): b['text']=b['text'][2:]

# Every protected fixed ID still resolves. No edits to exam questions required.
available={(s['id'],b['id']) for c in data['chapters'] for s in c['sections'] for b in s['blocks']}
assert protected <= available, protected-available
assert original['chapters'][1:]==data['chapters'][1:]
for s in chapter['sections']:
    assert len({b['id'] for b in s['blocks']})==len(s['blocks'])
(RES/'textbook.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n','utf-8',newline='\n')
print('Updated chapter 1; all exam reference IDs retained; chapters 2–4 unchanged.')
