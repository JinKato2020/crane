"""Optimize the exported PDF and render pages for final human visual review."""
from pathlib import Path
import fitz
from PIL import Image, ImageDraw
import json
from pypdf import PdfWriter

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'tmp/ch1_revision_20261106'
src=OUT/'chapter1-candidate.pdf'; dst=OUT/'chapter1-optimized.pdf'
# Recompress only opaque raster image objects, leaving page/form resources and
# all text/vector operators intact. Keep every image's original pixel dimensions.
writer=PdfWriter(clone_from=src)
seen=set();recompressed=0
for page in writer.pages:
    for image in list(page.images):
        ref=image.indirect_reference
        if not ref or ref.idnum in seen:continue
        seen.add(ref.idnum)
        if image.image.mode in ('RGB','L') and '/SMask' not in ref.get_object():
            image.replace(image.image,quality=88,subsampling=0)
            recompressed+=1
writer.compress_identical_objects(remove_duplicates=True,remove_unreferenced=True)
with dst.open('wb') as stream:writer.write(stream)
doc=fitz.open(dst)
original=fitz.open(src)
assert len(doc)==len(original)
assert [p.get_text() for p in doc]==[p.get_text() for p in original]
terms=['つり上げ荷重','減速比','ばねナット','バンドブレーキ','停止時：','油浴式','部品の識別','末端処理']
selected={1};sparse=[];sheet_files=[]
for i,page in enumerate(doc):
    text=page.get_text()
    if i and len(text)<150 and not page.get_images():sparse.append(dict(page=i+1,text=text))
    if any(t in text for t in terms):selected.add(i+1)
for first in range(0,len(doc),20):
    sheet=Image.new('RGB',(1100,1680),'#dce2e7'); draw=ImageDraw.Draw(sheet)
    for index in range(first,min(first+20,len(doc))):
        pix=doc[index].get_pixmap(matrix=fitz.Matrix(.36,.36),alpha=False)
        thumb=Image.frombytes('RGB',[pix.width,pix.height],pix.samples)
        x=(index-first)%4*275+25;y=(index-first)//4*336+22
        sheet.paste(thumb,(x,y));draw.text((x,y-16),f'Page {index+1}',fill='black')
    path=OUT/f'pdf-sheet-{first//20+1}.jpg';sheet.save(path,quality=88);sheet_files.append(path.name)
for n in selected:
    doc[n-1].get_pixmap(matrix=fitz.Matrix(1.35,1.35),alpha=False).save(OUT/f'pdf-page-{n}.png')
report=dict(pages=len(doc),size_bytes=dst.stat().st_size,text_preserved_after_compression=True,recompressed_images=recompressed,
            sparse_pages=sparse,rendered_pages=sorted(selected),contact_sheets=sheet_files)
(OUT/'pdf-checks.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),'utf-8')
print(json.dumps(report,ensure_ascii=False))
