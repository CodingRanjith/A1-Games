#!/usr/bin/env python3
"""Generate original rear-view racing sprites for GameRush City Racer.

All output images are original works created for this project and released
under CC0 1.0 (public domain dedication) for use in the GameRush 10 APK.
No third-party game assets (GTA, NFS, Asphalt, Forza, etc.) are used.
"""

from __future__ import annotations

import math
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
CARS = ROOT / "assets" / "images" / "cars"
CITY = ROOT / "assets" / "images" / "city"
ROADS = ROOT / "assets" / "images" / "roads"
BUILDINGS = ROOT / "assets" / "images" / "buildings"
ENV = ROOT / "assets" / "images" / "environment"
UI = ROOT / "assets" / "images" / "ui"


def ensure_dirs() -> None:
    for d in (CARS, CITY, ROADS, BUILDINGS, ENV, UI):
        d.mkdir(parents=True, exist_ok=True)


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def mix(c1: tuple[int, int, int], c2: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return (lerp(c1[0], c2[0], t), lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t))


def rgba(c: tuple[int, int, int], a: int = 255) -> tuple[int, int, int, int]:
    return (c[0], c[1], c[2], a)


def rounded_poly(draw: ImageDraw.ImageDraw, pts: list[tuple[float, float]], fill, width: int = 0) -> None:
    draw.polygon([(int(x), int(y)) for x, y in pts], fill=fill)


def draw_ellipse(draw: ImageDraw.ImageDraw, cx, cy, rx, ry, fill) -> None:
    draw.ellipse((int(cx - rx), int(cy - ry), int(cx + rx), int(cy + ry)), fill=fill)


def new_canvas(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def paint_gradient_rect(
    img: Image.Image,
    box: tuple[int, int, int, int],
    c_top: tuple[int, int, int, int],
    c_bot: tuple[int, int, int, int],
) -> None:
    x0, y0, x1, y1 = box
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    h = max(1, y1 - y0)
    for i in range(h):
        t = i / (h - 1) if h > 1 else 0
        col = (
            lerp(c_top[0], c_bot[0], t),
            lerp(c_top[1], c_bot[1], t),
            lerp(c_top[2], c_bot[2], t),
            lerp(c_top[3], c_bot[3], t),
        )
        draw.line((x0, y0 + i, x1, y0 + i), fill=col)
    img.alpha_composite(overlay)


def draw_car(
    path: Path,
    *,
    body: tuple[int, int, int],
    accent: tuple[int, int, int],
    kind: str,
    width: int = 180,
    height: int = 300,
) -> None:
    """Original rear 3/4 camera-behind sports/traffic car sprite."""
    img = new_canvas(width, height)
    draw = ImageDraw.Draw(img)
    cx = width / 2

    # Body proportions
    if kind == "suv":
        body_w, cabin_h, roof_y, bumper_y = 0.78, 0.34, 0.18, 0.90
        spoiler = False
        light_bar = False
        tall_glass = True
    elif kind == "sedan":
        body_w, cabin_h, roof_y, bumper_y = 0.70, 0.30, 0.20, 0.88
        spoiler = False
        light_bar = False
        tall_glass = True
    elif kind == "ev":
        body_w, cabin_h, roof_y, bumper_y = 0.74, 0.28, 0.22, 0.88
        spoiler = False
        light_bar = True
        tall_glass = True
    elif kind == "super":
        body_w, cabin_h, roof_y, bumper_y = 0.86, 0.22, 0.26, 0.86
        spoiler = True
        light_bar = False
        tall_glass = False
    elif kind == "van":
        body_w, cabin_h, roof_y, bumper_y = 0.80, 0.42, 0.12, 0.90
        spoiler = False
        light_bar = False
        tall_glass = True
    elif kind == "taxi":
        body_w, cabin_h, roof_y, bumper_y = 0.72, 0.32, 0.18, 0.88
        spoiler = False
        light_bar = False
        tall_glass = True
    else:  # sports
        body_w, cabin_h, roof_y, bumper_y = 0.76, 0.24, 0.24, 0.87
        spoiler = True
        light_bar = False
        tall_glass = False

    dark = mix(body, (8, 8, 12), 0.55)
    mid = mix(body, (20, 20, 24), 0.22)
    bright = mix(body, (255, 255, 255), 0.28)
    chrome = (196, 204, 214)
    glass = (28, 48, 68, 220)
    rubber = (18, 18, 22, 255)

    # Shadow
    draw_ellipse(draw, cx, height * 0.94, width * 0.38, height * 0.045, (0, 0, 0, 90))

    # Tires (rear, slightly outboard)
    tire_y = height * 0.78
    tire_rx, tire_ry = width * 0.10, height * 0.09
    for side in (-1, 1):
        tx = cx + side * width * (body_w * 0.48)
        draw_ellipse(draw, tx, tire_y, tire_rx, tire_ry, rubber)
        draw_ellipse(draw, tx, tire_y, tire_rx * 0.55, tire_ry * 0.55, (70, 74, 82, 255))
        draw_ellipse(draw, tx, tire_y, tire_rx * 0.22, tire_ry * 0.22, (30, 32, 36, 255))

    # Main body trapezoid (rear)
    top_w = width * body_w * 0.72
    bot_w = width * body_w
    y_roof = height * roof_y
    y_lip = height * bumper_y
    y_deck = height * (roof_y + cabin_h)

    body_pts = [
        (cx - top_w / 2, y_roof + 8),
        (cx + top_w / 2, y_roof + 8),
        (cx + bot_w / 2, y_lip),
        (cx - bot_w / 2, y_lip),
    ]
    rounded_poly(draw, body_pts, rgba(mid))

    # Lower bumper darker
    bump_pts = [
        (cx - bot_w * 0.48, height * 0.78),
        (cx + bot_w * 0.48, height * 0.78),
        (cx + bot_w * 0.50, y_lip),
        (cx - bot_w * 0.50, y_lip),
    ]
    rounded_poly(draw, bump_pts, rgba(dark))

    # Metallic highlight on left
    hi_pts = [
        (cx - top_w * 0.42, y_roof + 14),
        (cx - top_w * 0.18, y_roof + 14),
        (cx - bot_w * 0.22, height * 0.76),
        (cx - bot_w * 0.40, height * 0.76),
    ]
    rounded_poly(draw, hi_pts, rgba(bright, 90))

    # Rear windshield
    gw = top_w * 0.78
    glass_top = y_roof + (12 if tall_glass else 18)
    glass_bot = y_deck - 6
    glass_pts = [
        (cx - gw * 0.42, glass_top),
        (cx + gw * 0.42, glass_top),
        (cx + gw * 0.55, glass_bot),
        (cx - gw * 0.55, glass_bot),
    ]
    rounded_poly(draw, glass_pts, glass)
    # Glass reflection
    ref_pts = [
        (cx - gw * 0.36, glass_top + 6),
        (cx - gw * 0.08, glass_top + 6),
        (cx - gw * 0.02, glass_bot - 8),
        (cx - gw * 0.28, glass_bot - 8),
    ]
    rounded_poly(draw, ref_pts, (220, 235, 255, 55))

    # Roof
    roof_pts = [
        (cx - top_w * 0.36, y_roof),
        (cx + top_w * 0.36, y_roof),
        (cx + top_w * 0.44, y_roof + 16),
        (cx - top_w * 0.44, y_roof + 16),
    ]
    rounded_poly(draw, roof_pts, rgba(mix(body, (0, 0, 0), 0.18)))

    if spoiler:
        sy = y_roof - 6
        draw.rounded_rectangle(
            (cx - top_w * 0.48, sy, cx + top_w * 0.48, sy + 10),
            radius=3,
            fill=rgba(dark),
        )
        draw.rectangle((cx - top_w * 0.40, sy + 10, cx - top_w * 0.34, y_roof + 8), fill=rgba(dark))
        draw.rectangle((cx + top_w * 0.34, sy + 10, cx + top_w * 0.40, y_roof + 8), fill=rgba(dark))

    # C-pillars
    for side in (-1, 1):
        pillar = [
            (cx + side * gw * 0.42, glass_top),
            (cx + side * top_w * 0.50, y_roof + 10),
            (cx + side * bot_w * 0.42, y_deck),
            (cx + side * gw * 0.55, glass_bot),
        ]
        rounded_poly(draw, pillar, rgba(mix(body, (0, 0, 0), 0.35)))

    # Tail lights
    ly = height * 0.70
    lw, lh = width * 0.16, height * 0.045
    red = (255, 40, 48, 255)
    glow = (255, 90, 70, 160)
    if light_bar:
        draw.rounded_rectangle(
            (cx - bot_w * 0.38, ly, cx + bot_w * 0.38, ly + lh * 0.7),
            radius=4,
            fill=(40, 220, 255, 230),
        )
        draw.rounded_rectangle(
            (cx - bot_w * 0.36, ly + 2, cx + bot_w * 0.36, ly + lh * 0.45),
            radius=3,
            fill=(200, 250, 255, 180),
        )
    else:
        for side in (-1, 1):
            lx = cx + side * bot_w * 0.28
            draw.rounded_rectangle((lx - lw / 2, ly, lx + lw / 2, ly + lh), radius=4, fill=glow)
            draw.rounded_rectangle(
                (lx - lw / 2 + 3, ly + 2, lx + lw / 2 - 3, ly + lh - 2),
                radius=3,
                fill=red,
            )

    # Center brake light
    draw.rounded_rectangle(
        (cx - width * 0.10, glass_bot - 4, cx + width * 0.10, glass_bot + 4),
        radius=2,
        fill=(255, 50, 50, 200),
    )

    # License plate (blank — original, no real plates)
    pw, ph = width * 0.28, height * 0.055
    py = height * 0.80
    draw.rounded_rectangle((cx - pw / 2, py, cx + pw / 2, py + ph), radius=3, fill=(230, 230, 226, 255))
    draw.rounded_rectangle(
        (cx - pw / 2 + 2, py + 2, cx + pw / 2 - 2, py + ph - 2),
        radius=2,
        fill=(40, 90, 160, 255) if kind != "taxi" else (20, 20, 24, 255),
    )

    # Exhausts
    ey = height * 0.86
    for side in (-1, 1):
        ex = cx + side * bot_w * 0.18
        draw_ellipse(draw, ex, ey, 7, 5, (40, 40, 44, 255))
        draw_ellipse(draw, ex, ey, 4, 3, (18, 18, 18, 255))

    # Side mirrors
    my = y_deck - 8
    for side in (-1, 1):
        mx = cx + side * bot_w * 0.52
        draw.rounded_rectangle((mx - 8, my, mx + 8, my + 12), radius=3, fill=rgba(dark))
        draw.ellipse((mx - 5, my + 2, mx + 5, my + 10), fill=(80, 110, 140, 200))

    # Accent stripe
    if kind in ("sports", "super", "ev"):
        draw.rectangle(
            (cx - 4, y_deck + 4, cx + 4, height * 0.76),
            fill=rgba(accent, 180),
        )

    if kind == "taxi":
        # Roof sign
        draw.rounded_rectangle(
            (cx - 28, y_roof - 18, cx + 28, y_roof + 2),
            radius=2,
            fill=(255, 210, 40, 255),
        )
        draw.rectangle((cx - 22, y_roof - 12, cx + 22, y_roof - 4), fill=(30, 30, 30, 255))

    # Soft blur for slightly photographic edges
    img = img.filter(ImageFilter.GaussianBlur(radius=0.4))
    img = ImageEnhance.Contrast(img).enhance(1.08)
    img = ImageEnhance.Color(img).enhance(1.12)
    img.save(path, "PNG", optimize=True)
    print("wrote", path.relative_to(ROOT))


def draw_tree(path: Path, palm: bool = False) -> None:
    img = new_canvas(96, 160)
    d = ImageDraw.Draw(img)
    d.ellipse((28, 138, 68, 156), fill=(0, 0, 0, 60))
    if palm:
        d.rectangle((44, 70, 52, 148), fill=(110, 72, 40, 255))
        for a in range(-70, 80, 22):
            rad = math.radians(a)
            x2 = 48 + math.sin(rad) * 40
            y2 = 68 - math.cos(rad) * 28
            d.polygon([(48, 72), (x2, y2), (48 + math.sin(rad + 0.3) * 18, 78)], fill=(46, 140, 72, 255))
    else:
        d.rectangle((44, 100, 52, 148), fill=(92, 58, 32, 255))
        d.ellipse((12, 28, 84, 108), fill=(36, 120, 58, 255))
        d.ellipse((22, 18, 74, 70), fill=(52, 150, 70, 255))
        d.ellipse((30, 40, 78, 92), fill=(28, 100, 48, 255))
    img.save(path, "PNG", optimize=True)
    print("wrote", path.relative_to(ROOT))


def draw_street_light(path: Path) -> None:
    img = new_canvas(48, 160)
    d = ImageDraw.Draw(img)
    d.rectangle((20, 40, 28, 156), fill=(48, 52, 60, 255))
    d.polygon([(24, 18), (24, 36), (44, 28), (44, 20)], fill=(60, 64, 72, 255))
    d.ellipse((36, 18, 48, 32), fill=(255, 230, 140, 230))
    d.ellipse((32, 14, 52, 36), fill=(255, 210, 80, 70))
    img.save(path, "PNG", optimize=True)
    print("wrote", path.relative_to(ROOT))


def draw_barrier(path: Path) -> None:
    img = new_canvas(80, 40)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((2, 8, 78, 32), radius=4, fill=(210, 210, 214, 255))
    for i, col in enumerate(((220, 40, 40, 255), (240, 240, 240, 255)) * 3):
        d.polygon(
            [(6 + i * 12, 8), (18 + i * 12, 8), (12 + i * 12, 32), (0 + i * 12, 32)],
            fill=col,
        )
    img.save(path, "PNG", optimize=True)
    print("wrote", path.relative_to(ROOT))


def draw_sign(path: Path, text_bars: bool = True) -> None:
    img = new_canvas(64, 96)
    d = ImageDraw.Draw(img)
    d.rectangle((28, 40, 36, 94), fill=(70, 74, 80, 255))
    d.rounded_rectangle((8, 4, 56, 52), radius=8, fill=(30, 90, 200, 255))
    d.rounded_rectangle((12, 8, 52, 48), radius=6, fill=(245, 245, 250, 255))
    if text_bars:
        d.rectangle((20, 18, 44, 24), fill=(30, 90, 200, 255))
        d.rectangle((18, 30, 46, 36), fill=(30, 90, 200, 255))
    img.save(path, "PNG", optimize=True)
    print("wrote", path.relative_to(ROOT))


def draw_cone(path: Path) -> None:
    img = new_canvas(40, 56)
    d = ImageDraw.Draw(img)
    d.polygon([(20, 4), (36, 50), (4, 50)], fill=(255, 110, 30, 255))
    d.polygon([(20, 18), (30, 34), (10, 34)], fill=(245, 245, 245, 255))
    d.rectangle((6, 48, 34, 54), fill=(40, 40, 44, 255))
    img.save(path, "PNG", optimize=True)
    print("wrote", path.relative_to(ROOT))


def draw_skyline(path: Path, palette: str) -> None:
    palettes = {
        "tokyo": ((11, 2, 32), (45, 16, 84), (255, 45, 149), (123, 44, 191)),
        "dubai": ((10, 22, 40), (28, 58, 82), (255, 200, 87), (0, 187, 249)),
        "nyc": ((5, 7, 15), (26, 36, 56), (76, 201, 240), (255, 107, 53)),
        "mumbai": ((12, 20, 24), (30, 48, 56), (82, 183, 136), (244, 162, 97)),
        "paris": ((26, 15, 32), (61, 36, 64), (231, 111, 81), (155, 93, 229)),
    }
    sky_top, sky_bot, neon_a, neon_b = palettes[palette]
    w, h = 512, 220
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    paint_gradient_rect(img, (0, 0, w, h), rgba(sky_top, 255), rgba(sky_bot, 255))
    d = ImageDraw.Draw(img)
    # Moon
    d.ellipse((390, 18, 430, 58), fill=(255, 255, 255, 210))
    d.ellipse((400, 22, 448, 70), fill=rgba(sky_top, 255))
    # Stars
    for i in range(40):
        x = (i * 73 + palette.__hash__()) % w
        y = (i * 37) % 90
        d.point((x, y), fill=(255, 255, 255, 160))
    # Buildings
    x = -10
    seed = sum(ord(c) for c in palette)
    i = 0
    while x < w + 20:
        bw = 18 + (seed + i * 17) % 36
        bh = 50 + (seed + i * 29) % 120
        col = mix(sky_bot, (10, 12, 18), 0.4)
        d.rectangle((x, h - bh, x + bw, h), fill=rgba(col))
        win = neon_a if i % 2 == 0 else neon_b
        wy = h - bh + 8
        while wy < h - 10:
            wx = x + 4
            while wx < x + bw - 5:
                if ((wx + wy + i) % 7) > 2:
                    d.rectangle((wx, wy, wx + 3, wy + 4), fill=rgba(win, 160))
                wx += 8
            wy += 10
        x += bw + 4 + (i % 5)
        i += 1
    img.save(path, "PNG", optimize=True)
    print("wrote", path.relative_to(ROOT))


def draw_road_texture(path: Path) -> None:
    w, h = 64, 128
    img = Image.new("RGBA", (w, h), (28, 28, 34, 255))
    d = ImageDraw.Draw(img)
    for y in range(0, h, 4):
        shade = 26 + (y * 3) % 8
        d.line((0, y, w, y), fill=(shade, shade, shade + 4, 40))
    img.save(path, "PNG", optimize=True)
    print("wrote", path.relative_to(ROOT))


def draw_finish_banner(path: Path) -> None:
    img = new_canvas(256, 48)
    d = ImageDraw.Draw(img)
    for r in range(2):
        for c in range(16):
            col = (20, 20, 22, 255) if (r + c) % 2 == 0 else (245, 245, 245, 255)
            d.rectangle((c * 16, r * 24, (c + 1) * 16, (r + 1) * 24), fill=col)
    img.save(path, "PNG", optimize=True)
    print("wrote", path.relative_to(ROOT))


def draw_speedo_ring(path: Path) -> None:
    img = new_canvas(160, 160)
    d = ImageDraw.Draw(img)
    d.ellipse((8, 8, 152, 152), outline=(255, 255, 255, 40), width=8)
    d.ellipse((20, 20, 140, 140), outline=(230, 57, 70, 180), width=4)
    img.save(path, "PNG", optimize=True)
    print("wrote", path.relative_to(ROOT))


def main() -> None:
    ensure_dirs()
    cars = [
        ("ember_gt.png", (214, 40, 48), (255, 210, 80), "sports"),
        ("nightline.png", (18, 28, 48), (80, 160, 255), "sedan"),
        ("volt_x.png", (20, 170, 190), (180, 255, 80), "ev"),
        ("titan.png", (210, 110, 40), (40, 40, 44), "suv"),
        ("phantom_rs.png", (236, 238, 242), (180, 40, 50), "super"),
        ("traffic_blue.png", (50, 100, 150), (200, 200, 210), "sedan"),
        ("traffic_silver.png", (160, 168, 176), (40, 40, 48), "sedan"),
        ("traffic_taxi.png", (230, 180, 30), (20, 20, 24), "taxi"),
        ("traffic_van.png", (70, 90, 80), (30, 30, 34), "van"),
        ("traffic_hatch.png", (90, 50, 140), (220, 180, 80), "sports"),
    ]
    for name, body, accent, kind in cars:
        draw_car(CARS / name, body=body, accent=accent, kind=kind)

    draw_tree(ENV / "tree.png", palm=False)
    draw_tree(ENV / "palm.png", palm=True)
    draw_street_light(ENV / "street_light.png")
    draw_barrier(ENV / "barrier.png")
    draw_sign(ENV / "traffic_sign.png")
    draw_cone(ENV / "cone.png")
    draw_finish_banner(ENV / "finish_banner.png")

    for name in ("tokyo", "dubai", "nyc", "mumbai", "paris"):
        draw_skyline(CITY / f"skyline_{name}.png", name)

    draw_road_texture(ROADS / "asphalt.png")
    draw_speedo_ring(UI / "speedo_ring.png")
    print("done")


if __name__ == "__main__":
    main()
