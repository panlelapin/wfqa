"""Regenerate the WFQA launcher and catalog PNGs (Python 3 + Pillow)."""
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
size = 512
blue = (83, 137, 175)
mask = Image.new("L", (size, size))
ImageDraw.Draw(mask).rounded_rectangle((0, 0, 511, 511), radius=80, fill=255)
glyph = Image.new("L", mask.size)
pen = ImageDraw.Draw(glyph)
# Original Android glyph bounds: 122..389. Match its 44 px bar thickness.
for box in ((122, 234, 389, 277), (234, 122, 277, 389)):
    pen.rounded_rectangle(box, radius=22, fill=255)
icon = Image.new("RGB", mask.size, blue)
for offset in range(390, 0, -1):
    shade = 1 - .17 * (1 - offset / 390)
    icon.paste(tuple(round(c * shade) for c in blue),
               (offset, offset, offset + size, offset + size), glyph)
icon.paste("white", mask=glyph)
icon.putalpha(mask)
art = root / "fdroid/com.github.panlelapin.wfqa/en-US/images/icon.png"
art.parent.mkdir(parents=True, exist_ok=True)
icon.save(art)
for density, px in zip(("mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"),
                       (48, 72, 96, 144, 192)):
    icon.resize((px, px), Image.Resampling.LANCZOS).save(
        root / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png")
