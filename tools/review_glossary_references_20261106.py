"""Human-reviewed anchor choices; no generic section-opening fallbacks."""
import json
from pathlib import Path
from revise_glossary_20261106 import ROOT, RESOURCE, block_text
book=json.loads(RESOURCE.read_text(encoding='utf-8'))
sections={s['id']:s for c in book['chapters'] for s in c['sections']}
# Each selector is an observed block ID or an unambiguous subheading.
choices={
 '1:2':[('1-2','1-2-96062aafe700'),('1-2','1-2-7c8f021ebaea')],
 '1:42':[('1-13','1-13-0d17883358e9'),('1-13','1-13-437b3a015f0f'),('1-13','1-13-1c4c85ab80b1')],
 '1:0':[('1-1','1-1-cf7c091abacb')], '1:7':[('1-1','1-1-efc0d7b18cbf')],
 '1:22':[('1-5','1-5-c7d541a91f35')], '1:24':[('1-5','1-5-735785f20040')],
 '1:25':[('1-6','1-6-59cf53f8ce2d')], '1:28':[('1-5','1-5-735785f20040')],
 '1:29':[('1-6','1-6-875acbbe8668')],
 '1:45':[('1-7','1-7-5e957a7d280b')], '1:48':[('1-7','1-7-48c33e31c196')],
 '1:56':[('1-8','クロー'),('1-8','1-8-8194eeca7818')],
 '1:61':[('1-10','1-10-8faf07bf1c2d')],
 '1:66':[('1-11','1-11-bc25bc2119f6')], '1:67':[('1-11','1-11-4c38923f3bc4')],
 '1:68':[('1-11','1-11-dd0d0ad2324f')], '1:71':[('1-12','1-12-rev26-oil-heading')],
 '2:0':[('2-1','2-1-eb337800cabe')], '2:1':[('2-1','2-1-757d4290d2ea')],
 '2:2':[('2-1','2-1-4d415413567b')],
 '2:5':[('2-1','2-1-6e5f97aef1a7')], '2:6':[('2-1','2-1-6e5f97aef1a7')],
 '2:10':[('2-1','2-1-3641eea0032a')],
 '2:14':[('2-2','2-2-3b2e1a771fd7')], '2:15':[('2-2','2-2-8747b08ac135')],
 '2:16':[('2-2','2-2-3b2e1a771fd7')], '2:17':[('2-2','2-2-3b2e1a771fd7')],
 '2:20':[('2-3','2-3-695b732dee88'),('2-3','2-3-454c618d29a6')],
 '2:21':[('2-3','2-3-d17e8b66b3dd')], '2:23':[('2-3','2-3-e835bf64c9a6')],
 '2:25':[('2-4','2-4-b371510f6fad')], '2:28':[('2-4','2-4-f6ccf91c77b9')],
 '2:32':[('2-5','2-5-7362134016f1')], '2:33':[('2-5','2-5-8dd76f1977f1')],
 '2:36':[('2-6','2-6-05a2159c39f3')], '2:38':[('2-6','2-6-a08e03300c9c')],
 '2:41':[('2-6','2-6-72c28462b176')],
 '2:43':[('1-8','フックブロックと外れ止め'),('2-5','2-5-048ae38b3a53')],
 '3:2':[('3-1','3-1-308fa0f85948')], '3:3':[('3-7','3-7-b94266da2b39')],
 '3:4':[('3-1','3-1-85937840267d'),('3-1','3-1-b57dab0ecd68')],
 '3:7':[('3-1','3-1-rev26-rms-heading')],
 '3:11':[('3-2','3-2-505a2ec98141'),('3-2','並列接続の合成抵抗')],
 '3:14':[('3-2','3-2-91e5eed680cb')],
 '3:16':[('3-3','3-3-1ceaa4dca2a6')],
 '3:17':[('3-3','3-3-92b8df3bec44'),('3-3','3-3-e8caae223e3e'),('3-3','3-3-a669a783e29b')],
 '3:22':[('3-4','3-4-e53e63e5201b'),('3-4','3-4-b75884d9837a')],
 '3:23':[('3-4','3-4-ebb565fd47f2')], '3:24':[('3-4','3-4-b75884d9837a')],
 '3:25':[('3-4','3-4-abf297eccbc7'),('3-4','3-4-14e0a3754aad')],
 '3:36':[('3-6','3-6-f9bbcdf28e9a')], '3:37':[('3-6','3-6-rev26-poles-heading')],
 '3:39':[('3-6','3-6-rev26-braking-methods-heading')], '3:41':[('3-6','3-6-88f3477cf348')],
 '3:45':[('3-7','3-7-c805c0252398')], '3:47':[('3-7','3-7-6c1c293723f5')],
 '3:48':[('3-7','3-7-27fdbd45e49f')], '3:50':[('3-6','3-6-b99d300f3c14')],
 '3:52':[('3-3','lesson-motor-efficiency')],
 '4:2':[('4-0','4-0-3e6951244dfc')], '4:8':[('4-1','4-1-c4a7d4b0308e')],
 '4:9':[('4-1','4-1-e2fa8ed9f9bb')], '4:11':[('4-2','4-2-944ffa4704d1')],
 '4:12':[('4-2','4-2-6486f723e2f9')], '4:21':[('4-4','4-4-ed5380ed8a33')],
 '4:26':[('4-5','4-5-cbd237f08508')], '4:27':[('4-5','4-5-cbd237f08508')],
 '4:28':[('4-6','4-6-736e75654309')],
 '4:29':[('4-6','4-6-97f37b8cd3f7'),('4-6','4-6-04a28acb3df3')],
 '4:32':[('4-7','4-7-990f3b827392'),('4-7','4-7-dc9015edb24f'),('4-7','4-7-321da012f92e')],
 '4:37':[('4-7','lesson-mechanical-efficiency')],
}
out={}
for key, refs in choices.items():
 cid,i=map(int,key.split(':'));term=book['chapters'][cid-1]['glossary'][i]
 out[key]=[]
 for sid,selector in refs:
  blocks=sections[sid]['blocks']
  found=[b for b in blocks if b['id']==selector]
  if not found:found=[b for b in blocks if b['type']=='sub' and selector in b.get('text','')]
  assert len(found)==1,(key,selector,len(found))
  b=found[0]
  label=b['text'].replace('**','') if b['type']=='sub' else term.get('displayTerm',term['term'])
  if key=='2:43':label='つり具の例' if sid=='1-8' else '玉掛用具の安全基準'
  out[key].append({'section':sid,'blockID':b['id'],'label':label})
(ROOT/'tools/glossary_reference_overrides_20261106.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('reviewed overrides',len(out))
