#!/usr/bin/env python3
"""Elevated rear vehicle plates. Original artwork, not a game screenshot."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parents[1] / "assets" / "images" / "cars"
W, H = 520, 700


def shade(color, t):
    return tuple(max(0, min(255, int(c * t))) for c in color)


def draw_vehicle(path: Path, paint, kind: str) -> None:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = W // 2
    roof = shade(paint, 1.08)
    body = paint
    dark = shade(paint, 0.62)
    glass = (28, 42, 58, 230)
    if kind == "cycle":
        _cycle(d, cx)
    elif kind == "bike":
        _bike(d, cx, paint)
    elif kind == "bus":
        _bus(d, cx, paint)
    elif kind == "truck":
        _truck(d, cx, paint)
    elif kind == "van":
        _van(d, cx, body, roof, dark, glass)
    elif kind == "suv":
        _sedan(d, cx, body, roof, dark, glass, tall=True)
    elif kind == "sport":
        _sedan(d, cx, body, roof, dark, glass, low=True)
    else:
        _sedan(d, cx, body, roof, dark, glass)
    img = img.filter(ImageFilter.SMOOTH)
    img.save(path)


def _cycle(d, cx):
    d.line([(cx, 180), (cx, 520)], fill=(40, 42, 46, 255), width=10)
    d.ellipse((cx - 70, 150, cx + 70, 290), outline=(30, 32, 36, 255), width=16)
    d.ellipse((cx - 70, 430, cx + 70, 570), outline=(30, 32, 36, 255), width=16)
    d.ellipse((cx - 18, 200, cx + 18, 236), fill=(180, 40, 36, 255))
    d.polygon([(cx - 28, 250), (cx + 28, 250), (cx + 18, 340), (cx - 18, 340)], fill=(52, 56, 62, 255))


def _bike(d, cx, paint):
    d.rounded_rectangle((cx - 70, 210, cx + 70, 520), 18, fill=paint + (255,))
    d.rounded_rectangle((cx - 36, 240, cx + 36, 300), 8, fill=(24, 36, 48, 230))
    d.ellipse((cx - 88, 140, cx + 88, 310), outline=(28, 30, 34, 255), width=18)
    d.ellipse((cx - 88, 430, cx + 88, 600), outline=(28, 30, 34, 255), width=18)
    d.rounded_rectangle((cx - 40, 470, cx + 40, 492), 4, fill=(210, 36, 42, 255))


def _wheel(d, x, y, s=1.0):
    d.ellipse((x - 28 * s, y - 16 * s, x + 28 * s, y + 16 * s), fill=(22, 22, 24, 255))
    d.ellipse((x - 12 * s, y - 8 * s, x + 12 * s, y + 8 * s), fill=(150, 154, 160, 255))


def _lights(d, x, y, span):
    d.rounded_rectangle((x - span, y, x - span + 54, y + 16), 4, fill=(210, 36, 42, 255))
    d.rounded_rectangle((x + span - 54, y, x + span, y + 16), 4, fill=(210, 36, 42, 255))


def _sedan(d, cx, body, roof, dark, glass, tall=False, low=False):
    lift = -20 if low else (16 if tall else 0)
    d.rounded_rectangle((cx - 168, 250 + lift, cx + 168, 620 + lift), 28, fill=body + (255,))
    d.polygon(
        [(cx - 132, 300 + lift), (cx + 132, 300 + lift), (cx + 118, 210 + lift), (cx - 118, 210 + lift)],
        fill=roof + (255,),
    )
    d.rounded_rectangle((cx - 108, 228 + lift, cx + 108, 292 + lift), 10, fill=glass)
    d.rounded_rectangle((cx - 150, 430 + lift, cx + 150, 560 + lift), 12, fill=dark + (255,))
    _lights(d, cx, 478 + lift, 130)
    d.rounded_rectangle((cx - 70, 530 + lift, cx + 70, 552 + lift), 6, fill=(40, 42, 46, 255))
    _wheel(d, cx - 150, 590 + lift)
    _wheel(d, cx + 150, 590 + lift)
    d.polygon(
        [(cx - 40, 188 + lift), (cx + 40, 188 + lift), (cx + 28, 168 + lift), (cx - 28, 168 + lift)],
        fill=roof + (255,),
    )


def _van(d, cx, body, roof, dark, glass):
    d.rounded_rectangle((cx - 176, 160, cx + 176, 630), 22, fill=body + (255,))
    d.rounded_rectangle((cx - 140, 188, cx + 140, 300), 12, fill=glass)
    d.rectangle((cx - 150, 420, cx + 150, 540), fill=dark + (255,))
    _lights(d, cx, 470, 138)
    _wheel(d, cx - 150, 600, 1.15)
    _wheel(d, cx + 150, 600, 1.15)


def _bus(d, cx, paint):
    d.rounded_rectangle((cx - 170, 90, cx + 170, 620), 18, fill=paint + (255,))
    d.rounded_rectangle((cx - 130, 120, cx + 130, 250), 10, fill=(28, 42, 58, 230))
    for y in (280, 360, 440):
        d.rounded_rectangle((cx - 120, y, cx - 40, y + 48), 4, fill=(36, 52, 68, 220))
        d.rounded_rectangle((cx + 40, y, cx + 120, y + 48), 4, fill=(36, 52, 68, 220))
    _lights(d, cx, 530, 120)
    _wheel(d, cx - 120, 590, 1.1)
    _wheel(d, cx + 120, 590, 1.1)


def _truck(d, cx, paint):
    d.rounded_rectangle((cx - 188, 120, cx + 188, 390), 8, fill=(236, 238, 240, 255))
    d.rectangle((cx - 160, 150, cx + 160, 176), fill=(180, 186, 192, 255))
    d.rounded_rectangle((cx - 150, 390, cx + 150, 560), 16, fill=paint + (255,))
    d.rounded_rectangle((cx - 90, 410, cx + 90, 470), 8, fill=(30, 44, 58, 230))
    _lights(d, cx, 500, 110)
    _wheel(d, cx - 120, 590, 1.2)
    _wheel(d, cx + 120, 590, 1.2)
    _wheel(d, cx - 70, 610, 1.05)
    _wheel(d, cx + 70, 610, 1.05)


def main() -> None:
    jobs = {
        "ember_gt.png": ((48, 50, 54), "sedan"),
        "cycle.png": ((40, 42, 46), "cycle"),
        "bike.png": ((30, 30, 34), "bike"),
        "bus.png": ((214, 168, 32), "bus"),
        "truck.png": ((46, 92, 64), "truck"),
        "nightline.png": ((32, 86, 176), "sedan"),
        "volt_x.png": ((186, 28, 36), "sport"),
        "titan.png": ((228, 184, 40), "van"),
        "phantom_rs.png": ((168, 24, 32), "suv"),
        "traffic_blue.png": ((78, 82, 88), "sedan"),
        "traffic_silver.png": ((190, 194, 198), "suv"),
        "traffic_taxi.png": ((198, 42, 38), "sedan"),
        "traffic_van.png": ((236, 238, 240), "truck"),
        "traffic_hatch.png": ((42, 46, 52), "van"),
    }
    for name, (paint, kind) in jobs.items():
        draw_vehicle(OUT / name, paint, kind)
        print(name)


if __name__ == "__main__":
    main()
