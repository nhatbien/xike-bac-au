"""Crop the original photo and resize launcher icons. Requires Pillow."""

import json
from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]


def main():
    source = ImageOps.exif_transpose(Image.open(ROOT / "assets/web/dau.jpg")).convert("RGB")
    # Keep the seated person and the original ice background intact.
    # Coordinates are relative to the original 900 × 600 photograph.
    if source.size != (900, 600):
        raise ValueError("Expected the original 900 × 600 dau.jpg photograph")
    crop = source.crop((240, 180, 640, 580))
    # Extra original background keeps the person inside maskable icon shapes.
    maskable = source.crop((160, 40, 720, 600))

    outputs = {}

    def save(relative, size, picture=crop):
        path = ROOT / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        picture.resize((size, size), Image.Resampling.LANCZOS).save(path)
        outputs[path] = size

    save("assets/app_icon.png", 1024)
    densities = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for density, size in densities.items():
        save(f"android/app/src/main/res/mipmap-{density}/ic_launcher.png", size)

    catalog = Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")
    for entry in json.loads((ROOT / catalog / "Contents.json").read_text())["images"]:
        size = round(float(entry["size"].split("x")[0]) * float(entry["scale"][:-1]))
        save(catalog / entry["filename"], size)

    save("web/favicon.png", 32)
    for size in (192, 512):
        save(f"web/icons/Icon-{size}.png", size)
        save(f"web/icons/Icon-maskable-{size}.png", size, maskable)

    for path, size in outputs.items():
        with Image.open(path) as icon:
            assert icon.size == (size, size), path
            assert icon.mode == "RGB", path
    print(f"Generated and verified {len(outputs)} opaque square icons.")


if __name__ == "__main__":
    main()
