"""Draws the app icon (assets/icon/icon.png + foreground.png) from the app's name.

Run by CI before `dart run flutter_launcher_icons`. Needs Pillow; if anything
fails the app simply keeps the default icon.
"""
import os
import re
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

SIZE = 1024
CYAN = (0, 229, 255)
VIOLET = (124, 58, 237)
OBSIDIAN = (5, 6, 10)

FONTS = [
    "/System/Library/Fonts/GeezaPro.ttc",
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
    "/Library/Fonts/Arial Unicode.ttf",
    "/usr/share/fonts/truetype/noto/NotoSansArabic-Bold.ttf",
    "/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "C:/Windows/Fonts/arialbd.ttf",
]


def app_name():
    try:
        src = open("lib/core/config/app_config.dart", encoding="utf-8").read()
        m = re.search(r"'APP_NAME',\s*defaultValue:\s*'((?:\\.|[^'\\])*)'", src)
        if m:
            return m.group(1).replace("\\'", "'").replace("\\$", "$").replace("\\\\", "\\")
    except OSError:
        pass
    return "App"


def has_glyph(font, ch):
    """True when the font really draws ch (not the 'missing glyph' box)."""
    try:
        missing = font.getmask("\U0010FFFD")
        actual = font.getmask(ch)
        if actual.getbbox() is None:
            return False
        if actual.size != missing.size:
            return True
        a = Image.frombytes("L", actual.size, bytes(actual))
        b = Image.frombytes("L", missing.size, bytes(missing))
        return ImageChops.difference(a, b).getbbox() is not None
    except Exception:
        return False


def pick_font(ch, size):
    for path in FONTS:
        if not os.path.exists(path):
            continue
        try:
            font = ImageFont.truetype(path, size)
        except OSError:
            continue
        if has_glyph(font, ch):
            return font
    return None


def gradient():
    img = Image.new("RGB", (SIZE, SIZE))
    px = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            t = (x + y) / (2 * (SIZE - 1))
            px[x, y] = tuple(int(CYAN[i] + (VIOLET[i] - CYAN[i]) * t) for i in range(3))
    return img


def letter_layer(ch, box):
    """Transparent layer with ch centred inside a box of the given size."""
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    font = pick_font(ch, int(box * 0.62)) or pick_font("E", int(box * 0.62))
    text = ch if font and has_glyph(font, ch) else "E"
    if font is None:
        try:
            font = ImageFont.load_default(size=int(box * 0.62))
        except TypeError:
            font = ImageFont.load_default()
    draw = ImageDraw.Draw(layer)
    left, top, right, bottom = draw.textbbox((0, 0), text, font=font)
    x = (SIZE - (right - left)) / 2 - left
    y = (SIZE - (bottom - top)) / 2 - top
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).text((x, y + 14), text, font=font, fill=(0, 0, 0, 110))
    layer = Image.alpha_composite(layer, shadow.filter(ImageFilter.GaussianBlur(18)))
    ImageDraw.Draw(layer).text((x, y), text, font=font, fill=(255, 255, 255, 255))
    return layer


def main():
    name = app_name().strip() or "App"
    ch = name[0].upper()
    os.makedirs("assets/icon", exist_ok=True)

    # full icon: gradient square + letter (Android legacy, iOS, web)
    base = gradient().convert("RGBA")
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((-200, -260, 700, 560), fill=(255, 255, 255, 60))
    base = Image.alpha_composite(base, glow.filter(ImageFilter.GaussianBlur(120)))
    icon = Image.alpha_composite(base, letter_layer(ch, SIZE))
    icon.convert("RGB").save("assets/icon/icon.png")

    # adaptive foreground: the letter inside the 66% safe zone, on transparency
    letter_layer(ch, int(SIZE * 0.6)).save("assets/icon/foreground.png")
    # adaptive background: the gradient
    gradient().save("assets/icon/background.png")
    print("icon for", name, "->", ch)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:  # never break the build over the icon
        print("icon skipped:", error)
        sys.exit(0)
