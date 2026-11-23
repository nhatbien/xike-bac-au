from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.merge import Merger
from fontTools.varLib.instancer import instantiateVariableFont
import tempfile
root=Path(__file__).resolve().parents[1]
src=root/'assets/web/fonts'; dst=root/'assets/fonts';dst.mkdir(exist_ok=True)
for family in ['BeVietnamPro','Lora']:
 for weight in [400,500,600,700]:
  with tempfile.TemporaryDirectory() as tmp:
   parts=[]
   for subset in ['latin','latin-ext','vietnamese']:
    p=src/f'{family}-{weight if family!="Lora" else "400_700"}-{subset}.woff2'
    font=TTFont(p)
    if 'fvar' in font: font=instantiateVariableFont(font,{'wght':weight},inplace=False)
    font.flavor=None
    out=Path(tmp)/f'{subset}.ttf';font.save(out);parts.append(str(out))
   merged=Merger().merge(parts);merged.save(dst/f'{family}-{weight}.ttf')
