"""Publish reviewed chapter 1 only; retain every unrelated live manifest entry.

Run without --publish for a read-only deployment plan. The live content and
manifest are checked before mutation, images precede text, and manifest is last.
Credentials are read from the existing ignored tools/.r2.env; never printed.
"""
import copy
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
import boto3
from botocore.config import Config

ROOT=Path(__file__).resolve().parents[2]
RES=ROOT/'crane-app/CraneExam/Resources'
OUT=ROOT/'tmp/ch1_release_20261106';OUT.mkdir(exist_ok=True)
spec=importlib.util.spec_from_file_location('ota',ROOT/'crane-app/tools/upload_content_r2.py')
ota=importlib.util.module_from_spec(spec);spec.loader.exec_module(ota);ota.load_env_file()
for key in ['R2_ACCOUNT_ID','R2_ACCESS_KEY_ID','R2_SECRET_ACCESS_KEY','R2_BUCKET']:
    assert os.environ.get(key),'Missing '+key
client=boto3.client('s3',endpoint_url='https://'+os.environ['R2_ACCOUNT_ID'].strip()+'.r2.cloudflarestorage.com',
    aws_access_key_id=os.environ['R2_ACCESS_KEY_ID'].strip(),aws_secret_access_key=os.environ['R2_SECRET_ACCESS_KEY'].strip(),
    config=Config(signature_version='s3v4',region_name='auto',connect_timeout=15,read_timeout=45,retries={'max_attempts':2}))
bucket=os.environ['R2_BUCKET'].strip();prefix=os.environ.get('R2_PREFIX','crane/').strip()
assert prefix=='crane/'
sha=lambda b:hashlib.sha256(b).hexdigest()
meta=lambda b:dict(sha256=sha(b),size=len(b))
def get(key):return client.get_object(Bucket=bucket,Key=prefix+key)['Body'].read()
def ctype(key):
    if key.endswith('.svg'):return 'image/svg+xml; charset=utf-8'
    if key.endswith('.pdf'):return 'application/pdf'
    return ota.content_type(key)
def put(key,raw):
    client.put_object(Bucket=bucket,Key=prefix+key,Body=raw,ContentType=ctype(key),CacheControl='no-cache')
    assert get(key)==raw,key
def public(key,expected):
    url='https://content.safa-lang.com/crane/'+key+'?v='+sha(expected)
    r=subprocess.run(['curl.exe','--fail','--silent','--show-error','--location','--max-time','60','--header','Cache-Control: no-cache',url],capture_output=True,check=True)
    assert r.stdout==expected,key
    return key

raw_manifest=get('_manifest.json');live=json.loads(raw_manifest)
live_text=get('content/textbook.json');assert meta(live_text)==live['files']['content/textbook.json']
live_exams=get('content/exams.json');assert meta(live_exams)==live['files']['content/exams.json']
current=(RES/'textbook.json').read_bytes();new_book=json.loads(current);old_book=json.loads(live_text)
baseline=json.loads((ROOT/'tmp/ch1_revision_20261106/textbook.json').read_text('utf-8'))
assert live['appId']=='crane'
assert old_book['chapters'][1:]==new_book['chapters'][1:]
assert old_book['chapters'][0] in [baseline['chapters'][0],new_book['chapters'][0]],'Live chapter changed since review'
lookup={(s['id'],b['id']) for c in new_book['chapters'] for s in c['sections'] for b in s['blocks']}
refs=[r for e in json.loads(live_exams) for q in e['questions'] for r in q.get('refs',[])]
assert all((r['section'],r['blockID']) in lookup for r in refs)

# Include all figures actually used in chapter 1, plus the generated source PNGs.
keys={'content/textbook.json'}
def collect(obj):
    if isinstance(obj,list):
        for x in obj:collect(x)
    elif isinstance(obj,dict):
        if obj.get('type')=='svg':keys.add('content/images/'+obj['file'])
        if obj.get('type')=='img':
            f=next((obj['asset']+x for x in ('.png','.jpg','.jpeg') if (RES/'images'/(obj['asset']+x)).is_file()),None)
            assert f,obj;keys.add('content/images/'+f)
        for v in obj.values():collect(v)
collect(new_book['chapters'][0])
assets=json.loads((ROOT/'crane-app/docs/reviews/chapter1-revision-assets-20261106.json').read_text('utf-8'))
keys.update('content/images/'+f for f in assets['generated'])
payload={k:(RES/k.removeprefix('content/')).read_bytes() for k in sorted(keys)}
changes={k:b for k,b in payload.items() if live['files'].get(k)!=meta(b)}
planned=copy.deepcopy(live)
planned['generatedAt']=datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
for k,b in changes.items():planned['files'][k]=meta(b)
assert all(planned['files'][k]==v for k,v in live['files'].items() if k not in changes)
new_manifest=(json.dumps(planned,ensure_ascii=False,separators=(',',':'),sort_keys=True)+'\n').encode()
plan=dict(scope='第1章の教材と掲載図のみ',files=list(changes),bytes=sum(map(len,changes.values())),live_exam_references_verified=len(refs),
          unaffected_files_preserved=True,pdf_url='https://content.safa-lang.com/crane/pdf/chapter1.pdf')
(OUT/'deployment_plan.json').write_text(json.dumps(plan,ensure_ascii=False,indent=2),'utf-8')
print(json.dumps(plan,ensure_ascii=False),flush=True)
if '--publish' not in sys.argv:sys.exit(0)

assert get('_manifest.json')==raw_manifest,'Live manifest changed before upload'
(OUT/'remote_manifest_before_publish.json').write_bytes(raw_manifest)
(OUT/'remote_textbook_before_publish.json').write_bytes(live_text)
for k in changes:
    if k in live['files']:
        old=get(k);assert meta(old)==live['files'][k],k
        path=OUT/'backup'/k;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(old)
for k,b in sorted(changes.items(),key=lambda item:item[0]=='content/textbook.json'):put(k,b)
# The PDF is downloadable independently; it is not part of the app's OTA payload.
pdf=(ROOT/'アプリ/教材/クレーン教材_第1章_クレーンに関する知識.pdf').read_bytes()
put('pdf/chapter1.pdf',pdf)
assert get('_manifest.json')==raw_manifest,'Concurrent deployment detected before manifest switch'
put('_manifest.json',new_manifest)
(OUT/'published_manifest.json').write_bytes(new_manifest)
with ThreadPoolExecutor(max_workers=4) as pool:
    verified=list(pool.map(lambda item:public(*item),[('_manifest.json',new_manifest),*changes.items(),('pdf/chapter1.pdf',pdf)]))
receipt=dict(plan,publishedAt=datetime.now(timezone.utc).isoformat(),public_sha256_verified=verified,
             textbook_sha256=sha(current),pdf_sha256=sha(pdf),native_build_status_queried=False)
(ROOT/'crane-app/docs/reviews/chapter1-ota-published-20261106.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n','utf-8',newline='\n')
print('Published and verified '+str(len(verified))+' public objects.',flush=True)
