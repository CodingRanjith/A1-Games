#!/usr/bin/env python3
"""Render Kenney car GLBs from the elevated rear camera used in the race view.

Original composition. Not a screenshot from another game.
"""

from __future__ import annotations

import json
import math
import struct
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "images" / "cars"

W, H = 512, 680


def load_glb(path: Path):
    data = path.read_bytes()
    off = 12
    js = bin = None
    while off + 8 <= len(data):
        clen = struct.unpack_from("<I", data, off)[0]
        ctype = data[off + 4 : off + 8]
        chunk = data[off + 8 : off + 8 + clen]
        off = (off + 8 + clen + 3) & ~3
        if ctype.startswith(b"JSON"):
            js = json.loads(chunk)
        elif ctype.startswith(b"BIN"):
            bin = chunk
    tex_path = path.parent / "Textures" / "colormap.png"
    images = js.get("images") or []
    if images and images[0].get("uri"):
        tex_path = path.parent / images[0]["uri"]
    texture = Image.open(tex_path).convert("RGBA")
    acc = js["accessors"]
    views = js["bufferViews"]

    def read_floats(index, comps):
        a = acc[index]
        view = views[a["bufferView"]]
        start = view.get("byteOffset", 0) + a.get("byteOffset", 0)
        stride = view.get("byteStride", 4 * comps)
        count = a["count"]
        out = []
        for i in range(count):
            o = start + i * stride
            out.append(struct.unpack_from(f"<{comps}f", bin, o))
        return out

    def read_indices(index):
        a = acc[index]
        view = views[a["bufferView"]]
        start = view.get("byteOffset", 0) + a.get("byteOffset", 0)
        count = a["count"]
        ctype = a["componentType"]
        out = []
        if ctype == 5123:
            out = list(struct.unpack_from(f"<{count}H", bin, start))
        elif ctype == 5125:
            out = [v & 0xFFFF for v in struct.unpack_from(f"<{count}I", bin, start)]
        else:
            out = list(bin[start : start + count])
        return out

    def mat_from_node(node):
        if "matrix" in node:
            m = node["matrix"]
            return m
        t = node.get("translation", [0, 0, 0])
        r = node.get("rotation", [0, 0, 0, 1])
        s = node.get("scale", [1, 1, 1])
        x, y, z, w = r
        xx, yy, zz = x * x, y * y, z * z
        xy, xz, yz = x * y, x * z, y * z
        wx, wy, wz = w * x, w * y, w * z
        rot = [
            1 - 2 * (yy + zz), 2 * (xy - wz), 2 * (xz + wy), 0,
            2 * (xy + wz), 1 - 2 * (xx + zz), 2 * (yz - wx), 0,
            2 * (xz - wy), 2 * (yz + wx), 1 - 2 * (xx + yy), 0,
            0, 0, 0, 1,
        ]
        # column-major rotation * scale, then translation
        m = [0.0] * 16
        m[0], m[5], m[10], m[15] = s[0], s[1], s[2], 1
        # apply rot (column major) * scale
        rs = [0.0] * 16
        for col in range(4):
            for row in range(4):
                rs[col * 4 + row] = (
                    rot[0 * 4 + row] * (s[0] if col == 0 else 0)
                    + rot[1 * 4 + row] * (s[1] if col == 1 else 0)
                    + rot[2 * 4 + row] * (s[2] if col == 2 else 0)
                    + rot[3 * 4 + row] * (1 if col == 3 else 0)
                )
        rs[12], rs[13], rs[14] = t
        return rs

    def mul(a, b):
        o = [0.0] * 16
        for c in range(4):
            for r in range(4):
                o[c * 4 + r] = (
                    a[0 * 4 + r] * b[c * 4 + 0]
                    + a[1 * 4 + r] * b[c * 4 + 1]
                    + a[2 * 4 + r] * b[c * 4 + 2]
                    + a[3 * 4 + r] * b[c * 4 + 3]
                )
        return o

    def apply(m, p):
        x, y, z = p
        return (
            m[0] * x + m[4] * y + m[8] * z + m[12],
            m[1] * x + m[5] * y + m[9] * z + m[13],
            m[2] * x + m[6] * y + m[10] * z + m[14],
        )

    ident = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]
    parts = []

    def walk(index, parent):
        node = js["nodes"][index]
        world = mul(parent, mat_from_node(node))
        if "mesh" in node:
            mesh = js["meshes"][node["mesh"]]
            for prim in mesh["primitives"]:
                attrs = prim["attributes"]
                pos = read_floats(attrs["POSITION"], 3)
                nrm = read_floats(attrs["NORMAL"], 3) if "NORMAL" in attrs else [(0, 1, 0)] * len(pos)
                uv = read_floats(attrs["TEXCOORD_0"], 2) if "TEXCOORD_0" in attrs else [(0, 0)] * len(pos)
                idx = read_indices(prim["indices"]) if "indices" in prim else list(range(len(pos)))
                parts.append((pos, nrm, uv, idx, world))
        for child in node.get("children", []):
            walk(child, world)

    scene = js["scenes"][js.get("scene", 0)]
    for root in scene["nodes"]:
        walk(root, ident)
    return parts, texture, apply


def render(glb: Path, dest: Path, paint=(210, 214, 220)) -> None:
    parts, texture, apply = load_glb(glb)
    tex = texture.load()
    tw, th = texture.size
    pixels = [[(0, 0, 0, 0) for _ in range(W)] for _ in range(H)]
    zbuf = [[1e9 for _ in range(W)] for _ in range(H)]

    # Elevated rear camera. Car front is +Z, so we sit behind (-Z) and above.
    eye = (0.08, 2.2, -5.1)
    target = (0.0, 0.48, 0.25)
    forward = _norm((target[0] - eye[0], target[1] - eye[1], target[2] - eye[2]))
    right = _norm(_cross(forward, (0, 1, 0)))
    up = _cross(right, forward)
    light = _norm((0.25, 0.85, -0.45))
    focal = 620.0

    def project(p):
        rel = (p[0] - eye[0], p[1] - eye[1], p[2] - eye[2])
        cz = rel[0] * forward[0] + rel[1] * forward[1] + rel[2] * forward[2]
        if cz < 0.15:
            return None
        cx = rel[0] * right[0] + rel[1] * right[1] + rel[2] * right[2]
        cy = rel[0] * up[0] + rel[1] * up[1] + rel[2] * up[2]
        sx = W * 0.5 + focal * cx / cz
        sy = H * 0.58 - focal * cy / cz
        return sx, sy, cz

    for pos, nrm, uv, idx, world in parts:
        verts = []
        for i, p in enumerate(pos):
            wp = apply(world, p)
            wn = _norm(apply(world, nrm[i]))
            pr = project(wp)
            verts.append((pr, wn, uv[i]))
        for i in range(0, len(idx) - 2, 3):
            a, b, c = verts[idx[i]], verts[idx[i + 1]], verts[idx[i + 2]]
            if a[0] is None or b[0] is None or c[0] is None:
                continue
            _fill(pixels, zbuf, tex, tw, th, a, b, c, light, paint)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    img.putdata([px for row in pixels for px in row])
    img = _trim(img)
    dest.parent.mkdir(parents=True, exist_ok=True)
    img.save(dest)
    print(dest.name, img.size)


def _fill(pixels, zbuf, tex, tw, th, a, b, c, light, paint):
    (ax, ay, az), an, au = a
    (bx, by, bz), bn, bu = b
    (cx, cy, cz), cn, cu = c
    minx = max(0, int(min(ax, bx, cx)))
    maxx = min(W - 1, int(max(ax, bx, cx)) + 1)
    miny = max(0, int(min(ay, by, cy)))
    maxy = min(H - 1, int(max(ay, by, cy)) + 1)
    area = (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
    if abs(area) < 0.5:
        return
    for y in range(miny, maxy + 1):
        for x in range(minx, maxx + 1):
            w0 = (bx - ax) * (y - ay) - (by - ay) * (x - ax)
            w1 = (cx - bx) * (y - by) - (cy - by) * (x - bx)
            w2 = (ax - cx) * (y - cy) - (ay - cy) * (x - cx)
            if area > 0:
                if w0 < 0 or w1 < 0 or w2 < 0:
                    continue
            else:
                if w0 > 0 or w1 > 0 or w2 > 0:
                    continue
            inv = 1 / area
            b0, b1, b2 = w1 * inv, w2 * inv, w0 * inv
            depth = az * b0 + bz * b1 + cz * b2
            if depth >= zbuf[y][x]:
                continue
            zbuf[y][x] = depth
            uu = au[0] * b0 + bu[0] * b1 + cu[0] * b2
            vv = au[1] * b0 + bu[1] * b1 + cu[1] * b2
            tx = int(uu * (tw - 1)) % tw
            ty = int((1 - vv) * (th - 1)) % th
            r, g, b, _a = _paint_color(tex[tx, ty], paint)
            nx = an[0] * b0 + bn[0] * b1 + cn[0] * b2
            ny = an[1] * b0 + bn[1] * b1 + cn[1] * b2
            nz = an[2] * b0 + bn[2] * b1 + cn[2] * b2
            nd = max(0.28, nx * light[0] + ny * light[1] + nz * light[2])
            shade = 0.45 + 0.7 * nd
            pixels[y][x] = (
                min(255, int(r * shade)),
                min(255, int(g * shade)),
                min(255, int(b * shade)),
                255,
            )


def _paint_color(sample, paint):
    r, g, b, a = sample
    lum = (r + g + b) / 3
    if b > r + 25 and b > g + 10 and b > 90:
        glass = 0.35 + lum / 500
        return (int(30 * glass), int(55 * glass), int(90 * glass), a)
    if lum < 48:
        shade = lum / 48
        return (int(16 + 18 * shade), int(16 + 18 * shade), int(18 + 16 * shade), a)
    if lum > 210 and abs(r - g) < 30:
        return (235, 236, 238, a)
    if r > 160 and r > g + 40 and r > b + 40:
        return (196, 32, 36, a)
    shade = 0.55 + (lum / 255) * 0.7
    return (
        min(255, int(paint[0] * shade)),
        min(255, int(paint[1] * shade)),
        min(255, int(paint[2] * shade)),
        a,
    )


def _trim(img: Image.Image) -> Image.Image:
    bbox = img.getbbox()
    if not bbox:
        return img
    pad = 18
    x0 = max(0, bbox[0] - pad)
    y0 = max(0, bbox[1] - pad)
    x1 = min(img.width, bbox[2] + pad)
    y1 = min(img.height, bbox[3] + pad)
    return img.crop((x0, y0, x1, y1))


def _norm(v):
    l = math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]) or 1
    return (v[0] / l, v[1] / l, v[2] / l)


def _cross(a, b):
    return (
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    )


def main() -> None:
    jobs = {
        "ember_gt.png": (ROOT / "assets/models/cars/sedan-sports.glb", (46, 48, 52)),
        "nightline.png": (ROOT / "assets/models/cars/hatchback-sports.glb", (28, 78, 168)),
        "volt_x.png": (ROOT / "assets/models/cars/race.glb", (196, 32, 42)),
        "titan.png": (ROOT / "assets/models/cars/van.glb", (232, 186, 42)),
        "phantom_rs.png": (ROOT / "assets/models/cars/suv-luxury.glb", (176, 28, 36)),
        "traffic_blue.png": (ROOT / "assets/models/traffic/sedan.glb", (70, 74, 80)),
        "traffic_silver.png": (ROOT / "assets/models/traffic/suv.glb", (188, 192, 196)),
        "traffic_taxi.png": (ROOT / "assets/models/traffic/taxi.glb", (212, 48, 42)),
        "traffic_van.png": (ROOT / "assets/models/traffic/truck.glb", (236, 238, 240)),
        "traffic_hatch.png": (ROOT / "assets/models/traffic/delivery.glb", (40, 44, 48)),
    }
    for name, (src, paint) in jobs.items():
        render(src, OUT / name, paint)


if __name__ == "__main__":
    main()
