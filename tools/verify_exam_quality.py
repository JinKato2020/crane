"""本番形式の整合、改修対象の採点・参照・図表・保存IDを検証する。難易度の同等性の証明ではない。"""
from pathlib import Path
from collections import Counter
from fractions import Fraction
import json,re,math,hashlib

ROOT=Path(__file__).resolve().parents[1];RES=ROOT/'CraneExam/Resources'
exams=json.loads((RES/'exams.json').read_text(encoding='utf-8'))
ledger=json.loads((ROOT/'tools/exam_quality/changes.json').read_text(encoding='utf-8'))
qs={f"{e['round']}-{q['no']}":q for e in exams for q in e['questions']}
order=['クレーンに関する知識','関係法令','原動機・電気','力学']
for exam in exams:
 assert [q['displayNo'] for q in exam['questions']]==list(range(1,41))
 assert {q['no'] for q in exam['questions']}==set(range(1,41))
 assert [q['subject'] for q in exam['questions']]==[s for s in order for _ in range(10)]
 for q in exam['questions']:
  assert len(q['choices'])==len(set(q['choices']))==5 and 1<=q['answer']<=5
  assert not re.search(r'\b(?:cos|sin|tan)\s*\d',q['text'],re.I)
  if q.get('choiceHeaders'):
   assert len(q['choiceRows'])==5
   assert all(len(row)==len(q['choiceHeaders']) for row in q['choiceRows'])
   for choice,row in zip(q['choices'],q['choiceRows']):
    assert all(cell.replace(' ','') in choice.replace(' ','') for cell in row),(q['no'],row)
  for name in [q.get('figImg'),q.get('figImgExp')]:
   if name:assert any((RES/'images'/(name+ext)).exists() for ext in ['.png','.jpg','.svg'])
for record in ledger['changes']:
 q=qs[record['id']]
 digest=hashlib.sha256(json.dumps(q,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()
 assert digest==record['afterSHA256'],record['id']
for key,record in ledger['truthChecks'].items():
 q=qs[key];bad=set(record['falseIndices'])
 if record['combination']:
  expected=bad if record['asksFalse'] else set(range(1,6))-bad
  chosen={ord(c)-ord('A')+1 for c in re.findall('[A-E]',q['choices'][q['answer']-1])}
  assert chosen==expected,(key,chosen,expected)
 else:assert bad=={q['answer']},key
for key,d in ledger['circuitFixtures'].items():
 rp=Fraction(d['a']) if d['openB'] else 1/(Fraction(1,d['a'])+Fraction(1,d['b']))
 rt=rp+d['series'];current=Fraction(d['voltage'])/rt
 assert math.isclose(float(rt),d['totalResistance'])
 assert math.isclose(float(current),d['current'])
 assert math.isclose(float(current*d['series']),d['seriesVoltage'])
 assert math.isclose(float(current*rp),d['parallelVoltage'])
 assert qs[key]['answer']==d['statementSourceOrder'].index(d['falseSourceIndex'])+1
checks=[('2-25',14.7*2/1.41/9.8,2.13),('11-38',3000*2/1.41/9.8,434),('4-23',1.41/1.16,1.22),('5-27',2/1.16,1.72),('12-38',2/1.16,1.72)]
for key,actual,expected in checks:
 numeric=[]
 for s in qs[key]['choices']:
  m=re.search(r'[\d.]+',s);assert m,(key,s);numeric.append(float(m[0]))
 closest=min(range(5),key=lambda i:abs(numeric[i]-actual))
 assert closest+1==qs[key]['answer'] and numeric[closest]==expected,(key,numeric,actual)
assert sorted(zip([3*1.16/2,2.4*1.41/2,1.8*2/2],'ABC'),reverse=True)[0][1]=='C'
assert qs['1-34']['choices'][qs['1-34']['answer']-1]=='C、A、B'
assert qs['10-38']['choices'][qs['10-38']['answer']-1]=='A、C、B'
# Independently recomputed from the stated loads, dimensions and circuit conditions.
# Values use the units displayed in each item's choices, including t, kN and mA.
scalar_cases={
 '1-31':math.hypot(6,8),'1-32':12*2/6,'1-36':3.14*.2**2*.5*7800,'1-37':math.hypot(.8,.6)*10,
 '2-21':800*9.8/2,'2-23':100*3/(300+100),'2-24':400*9.8,'2-25':14.7*2/1.41/9.8,'2-27':2*.5*.5*7.8,
 '3-28':2/(.5**2),'3-31':math.sqrt(13**2-5**2),'3-32':600*2/3,'3-38':2*.5*.1*7800,
 '4-19':50/2000*1000,'4-21':300*2/3,'4-23':1.41/1.16,'4-25':(2*1-1*.4)*.05*7800,'4-26':2000*9.8*.3/1000,
 '5-22':600/200,'5-23':(400+80)*9.8/4,'5-25':(2*1-.4*.5)*.05*7800,'5-27':2/1.16,'5-29':500*9.8*.3,
 '6-21':math.hypot(12,5),'6-22':500*1.2/300,'6-24':2*9.8/2,'6-29':(.4*.3-.2*.1)*2*7800,
 '7-21':math.hypot(12-5,24),'7-22':600*.5/1.5,'7-23':2*9.8/2,'7-25':1/2000,'7-28':196,
 '8-21':2*(9.8+.4)/2,'8-22':300*9.8*.8/2.4,'8-23':4*9.8/2*2,'8-28':200*9.8*.3,
 '9-32':18*3.5/6,'9-35':math.hypot(24,18),'9-38':750*9.8/2*2/1000,'9-39':180*9.8/(3.14*9**2),'9-40':360*9.8/2,
 '10-32':8.4*1.2/2.1,'10-33':.4*.3*.25*7800,'10-36':300*9.8*.25,'10-40':420*9.8/3,
 '11-32':(20*3.5+10*2.5)/5,'11-33':3.14*.1**2*.5*2700,'11-38':3000*2/1.41/9.8,'11-40':1.6/4,
 '12-5':900*18/54*20/100,'12-32':(12*4+6*1.5)/6,'12-35':2*3.14*15/(3*60),'12-38':2/1.16,'12-39':140*9.8/(3.14*7**2),'12-40':(280+20)*9.8/2,
}
def numbers(s):return [float(x.replace(',','')) for x in re.findall(r'\d[\d,]*(?:\.\d+)?',s)]
for key,expected in scalar_cases.items():
 values=[numbers(c)[0] for c in qs[key]['choices']]
 errors=[abs(v-expected) for v in values];best=min(errors)
 assert errors.count(best)==1 and errors.index(best)+1==qs[key]['answer'],(key,values,expected)
 assert math.isclose(values[qs[key]['answer']-1],expected,rel_tol=.01),(key,values,expected)
pairs={
 '1-33':(240*9.8/2,2*.5),'3-10':(900*20/80,900*20/80*24/72),
 '3-33':(1.2*9.8/4,4*.4),'4-22':(.4/4,1.2*9.8/4*.4),
 '5-14':(120*60/6,(1200-1140)/1200*100),'6-23':(1.2*9.8/4/.8,4*.5),
 '7-24':(3*9.8*2/3,3*9.8/3),'8-30':(2*.5,600*9.8*.5/1000),
}
for key,expected in pairs.items():
 # Parse cells separately: min⁻¹ is a unit, not an additional numerical value.
 rows=[[numbers(c)[0] for c in row] for row in qs[key]['choiceRows']]
 valid=[i+1 for i,row in enumerate(rows) if all(math.isclose(a,b,rel_tol=.005) for a,b in zip(row,expected))]
 assert valid==[qs[key]['answer']],(key,rows,expected)
before=RES/'exams.json.bak_pre_quality_20261101'
if before.exists():
 old={f"{e['round']}-{q['no']}":q for e in json.loads(before.read_text(encoding='utf-8')) for q in e['questions']}
 assert set(old)==set(qs)
 for key in [f'4-{i}' for i in range(31,41)]:
  assert sorted(old[key]['choices'])==sorted(qs[key]['choices'])
  assert old[key]['choices'][old[key]['answer']-1]==qs[key]['choices'][qs[key]['answer']-1]
print(f'PASS: 480 stable IDs, official subject order, {len(ledger["truthChecks"])} truth tables, {len(ledger["circuitFixtures"])} circuits, 7 coefficient checks, choice tables and figure references')
print(f'PASS: {len(scalar_cases)} independently calculated numerical answers and {len(pairs)} paired answers')
