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
before=RES/'exams.json.bak_pre_quality_20261101'
if before.exists():
 old={f"{e['round']}-{q['no']}":q for e in json.loads(before.read_text(encoding='utf-8')) for q in e['questions']}
 assert set(old)==set(qs)
 for key in [f'4-{i}' for i in range(31,41)]:
  assert sorted(old[key]['choices'])==sorted(qs[key]['choices'])
  assert old[key]['choices'][old[key]['answer']-1]==qs[key]['choices'][qs[key]['answer']-1]
print(f'PASS: 480 stable IDs, official subject order, {len(ledger["truthChecks"])} truth tables, {len(ledger["circuitFixtures"])} circuits, 7 coefficient checks, choice tables and figure references')
