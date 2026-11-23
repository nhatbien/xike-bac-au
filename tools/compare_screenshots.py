"""Pixel comparisons against supplied references; never a pixel-perfect claim.
Run after flutter drive. Dynamic dates, data, system bars remain in raw metrics.
"""
from pathlib import Path
from PIL import Image, ImageChops, ImageStat, ImageDraw
import json
root=Path(__file__).resolve().parents[1]
source=root/'artifacts/screenshots';out=root/'artifacts/visual';out.mkdir(parents=True,exist_ok=True)
pairs=[('1.png','01-home.png'),('2.png','02-breathing.png'),('3.png','03-breathing-paused.png'),('4.png','04-stopwatch-empty.png'),('5.png','05-settings.png'),('5.1.png','05-settings-bottom.png'),('6.png','06-statistics.png'),('6.1.png','06-statistics-bottom.png'),('7.png','07-logs.png')]
report=[]
for original,current in pairs:
 release_names={'1.png':'home.png','4.png':'stopwatch.png','5.png':'settings.png','5.1.png':'settings-bottom.png','6.png':'statistics.png','6.1.png':'statistics-bottom.png','7.png':'logs.png'}
 p=root/'artifacts/release-screenshots'/release_names.get(original,'missing.png')
 if not p.exists():p=source/current
 if not p.exists():continue
 a=Image.open(root/original).convert('RGB');b=Image.open(p).convert('RGB')
 native=b.size
 # Flutter captures its 1080x2337 surface, excluding the 63px navigation bar.
 # Compare physical pixels directly; mask the system status bar absent in PixelCopy.
 if a.width==b.width and a.height>=b.height:a=a.crop((0,0,b.width,b.height))
 elif b.size!=a.size:raise ValueError(f'Unexpected viewport mismatch {a.size} vs {b.size}')
 ImageDraw.Draw(a).rectangle((0,0,a.width,63),fill='#FBF3E4')
 ImageDraw.Draw(b).rectangle((0,0,b.width,63),fill='#FBF3E4')
 diff=ImageChops.difference(a,b);mae=sum(ImageStat.Stat(diff).mean)/3
 Image.blend(a,b,.5).save(out/f'{Path(original).stem}-overlay.png')
 diff.point(lambda x:min(255,x*3)).save(out/f'{Path(original).stem}-diff.png')
 thumb_a=a.copy();thumb_b=b.copy();thumb_a.thumbnail((270,600));thumb_b.thumbnail((270,600))
 canvas=Image.new('RGB',(540,625),'#eee');canvas.paste(thumb_a,(0,25));canvas.paste(thumb_b,(270,25));ImageDraw.Draw(canvas).text((8,6),f'{original} reference | Flutter',fill='black');canvas.save(out/f'{Path(original).stem}-comparison.jpg')
 report.append({'reference':original,'render':str(p.relative_to(root)),'native_size':native,'mean_absolute_RGB_error':round(mae,3),'normalized_error_percent':round(mae/255*100,3),'note':'Physical pixel comparison with status bar masked; dynamic dates, logs, attempt data and scroll state differ.'})
(out/'metrics.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
