#!/usr/bin/env python3
"""Original low-poly GLB sedan and human characters for the chase view.

Not a manufacturer model. No logos, badges, or copied game characters.
CC0 for this project. Textures are painted here.
"""

from __future__ import annotations

import json
import math
import struct
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
CARS = ROOT / "assets" / "models" / "cars"
CHARS = ROOT / "assets" / "models" / "characters"


class Mesh:
    def __init__(self) -> None:
        self.pos: list[tuple[float, float, float]] = []
        self.nrm: list[tuple[float, float, float]] = []
        self.uv: list[tuple[float, float]] = []
        self.idx: list[int] = []

    def v(self, p, n, uv) -> int:
        self.pos.append(p)
        self.nrm.append(n)
        self.uv.append(uv)
        return len(self.pos) - 1

    def tri(self, a: int, b: int, c: int) -> None:
        self.idx.extend((a, b, c))

    def quad(self, a, b, c, d) -> None:
        self.tri(a, b, c)
        self.tri(a, c, d)


def _n(x, y, z):
    l = math.sqrt(x * x + y * y + z * z) or 1
    return (x / l, y / l, z / l)


def add_box(mesh: Mesh, cx, cy, cz, sx, sy, sz, uv) -> None:
    x0, x1 = cx - sx, cx + sx
    y0, y1 = cy - sy, cy + sy
    z0, z1 = cz - sz, cz + sz
    faces = [
        ([(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)], (0, 0, 1)),
        ([(x1, y0, z0), (x0, y0, z0), (x0, y1, z0), (x1, y1, z0)], (0, 0, -1)),
        ([(x1, y0, z1), (x1, y0, z0), (x1, y1, z0), (x1, y1, z1)], (1, 0, 0)),
        ([(x0, y0, z0), (x0, y0, z1), (x0, y1, z1), (x0, y1, z0)], (-1, 0, 0)),
        ([(x0, y1, z1), (x1, y1, z1), (x1, y1, z0), (x0, y1, z0)], (0, 1, 0)),
        ([(x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1)], (0, -1, 0)),
    ]
    u0, v0, u1, v1 = uv
    for pts, n in faces:
        ids = [mesh.v(p, n, (u0, v0)) for p in pts]
        ids[1] = mesh.v(pts[1], n, (u1, v0))
        ids[2] = mesh.v(pts[2], n, (u1, v1))
        ids[3] = mesh.v(pts[3], n, (u0, v1))
        mesh.quad(ids[0], ids[1], ids[2], ids[3])


def add_cylinder(mesh: Mesh, cx, cy, cz, radius, half_w, axis, uv, segs=12) -> None:
    u0, v0, u1, v1 = uv
    ring = []
    for i in range(segs):
        a = i / segs * math.tau
        c, s = math.cos(a), math.sin(a)
        if axis == "x":
            p0 = (cx - half_w, cy + c * radius, cz + s * radius)
            p1 = (cx + half_w, cy + c * radius, cz + s * radius)
            n = (0, c, s)
        else:
            p0 = (cx + c * radius, cy - half_w, cz + s * radius)
            p1 = (cx + c * radius, cy + half_w, cz + s * radius)
            n = (c, 0, s)
        ring.append((mesh.v(p0, n, (u0, v0)), mesh.v(p1, n, (u1, v1))))
    for i in range(segs):
        a0, b0 = ring[i]
        a1, b1 = ring[(i + 1) % segs]
        mesh.quad(a0, a1, b1, b0)


def add_uv_sphere(mesh: Mesh, cx, cy, cz, r, uv, stacks=6, slices=10) -> None:
    u0, v0, u1, v1 = uv
    grid = []
    for i in range(stacks + 1):
        v = i / stacks
        phi = v * math.pi
        row = []
        for j in range(slices + 1):
            u = j / slices
            theta = u * math.tau
            n = (
                math.sin(phi) * math.cos(theta),
                math.cos(phi),
                math.sin(phi) * math.sin(theta),
            )
            p = (cx + n[0] * r, cy + n[1] * r, cz + n[2] * r)
            row.append(mesh.v(p, n, (u0 + (u1 - u0) * u, v0 + (v1 - v0) * v)))
        grid.append(row)
    for i in range(stacks):
        for j in range(slices):
            mesh.quad(grid[i][j], grid[i][j + 1], grid[i + 1][j + 1], grid[i + 1][j])


def _ring(mesh: Mesh, z, y0, y1, y2, w0, w1, uv) -> list[int]:
    """Cross-section: bottom, belt, roof, mirrored. Returns 6 vertex ids."""
    pts = [
        ((-w0, y0, z), (-0.2, -0.4, 0)),
        ((-w1, y1, z), (-1, 0.1, 0)),
        ((-w1 * 0.72, y2, z), (-0.3, 1, 0)),
        ((w1 * 0.72, y2, z), (0.3, 1, 0)),
        ((w1, y1, z), (1, 0.1, 0)),
        ((w0, y0, z), (0.2, -0.4, 0)),
    ]
    ids = []
    for i, (p, n) in enumerate(pts):
        u = uv[0] + (uv[2] - uv[0]) * (i / 5)
        ids.append(mesh.v(p, _n(*n), (u, uv[1] if i in (0, 5) else uv[3])))
    return ids


def build_sedan_body() -> Mesh:
    mesh = Mesh()
    paint = (0.02, 0.64, 0.24, 0.96)
    glass = (0.30, 0.68, 0.48, 0.96)
    chrome = (0.54, 0.70, 0.72, 0.96)
    tail = (0.04, 0.40, 0.22, 0.58)
    lamp = (0.04, 0.04, 0.24, 0.30)

    # z, floor, belt, roof, lower half-width, upper half-width
    stations = [
        (-1.28, 0.24, 0.46, 0.50, 0.56, 0.52),
        (-1.08, 0.18, 0.70, 0.76, 0.62, 0.58),
        (-0.62, 0.16, 0.74, 0.82, 0.64, 0.56),
        (-0.28, 0.16, 0.78, 1.04, 0.62, 0.50),
        (0.22, 0.16, 0.78, 1.06, 0.60, 0.48),
        (0.52, 0.16, 0.74, 0.84, 0.60, 0.50),
        (0.92, 0.16, 0.66, 0.70, 0.62, 0.56),
        (1.22, 0.18, 0.48, 0.52, 0.56, 0.48),
        (1.34, 0.24, 0.38, 0.40, 0.50, 0.42),
    ]
    rings = [_ring(mesh, *s, paint) for s in stations]
    for a, b in zip(rings, rings[1:]):
        for i in range(5):
            mesh.quad(a[i], a[i + 1], b[i + 1], b[i])
        mesh.quad(a[5], a[0], b[0], b[5])
    mesh.quad(rings[0][0], rings[0][5], rings[0][4], rings[0][1])
    mesh.quad(rings[0][1], rings[0][4], rings[0][3], rings[0][2])
    mesh.quad(rings[-1][1], rings[-1][4], rings[-1][5], rings[-1][0])
    mesh.quad(rings[-1][2], rings[-1][3], rings[-1][4], rings[-1][1])

    add_box(mesh, 0.02, 0.90, -0.02, 0.34, 0.10, 0.28, glass)
    add_box(mesh, 0, 0.50, -1.24, 0.46, 0.045, 0.02, tail)
    add_box(mesh, -0.34, 0.46, -1.22, 0.14, 0.035, 0.018, tail)
    add_box(mesh, 0.34, 0.46, -1.22, 0.14, 0.035, 0.018, tail)
    add_box(mesh, -0.20, 0.28, -1.26, 0.035, 0.025, 0.03, chrome)
    add_box(mesh, 0.20, 0.28, -1.26, 0.035, 0.025, 0.03, chrome)
    add_box(mesh, -0.10, 0.40, 1.32, 0.045, 0.10, 0.02, chrome)
    add_box(mesh, 0.10, 0.40, 1.32, 0.045, 0.10, 0.02, chrome)
    add_box(mesh, -0.32, 0.40, 1.30, 0.10, 0.04, 0.02, lamp)
    add_box(mesh, 0.32, 0.40, 1.30, 0.10, 0.04, 0.02, lamp)
    return mesh


def build_wheel() -> Mesh:
    mesh = Mesh()
    tire = (0.02, 0.08, 0.22, 0.28)
    alloy = (0.55, 0.08, 0.95, 0.28)
    add_cylinder(mesh, 0, 0, 0, 0.30, 0.11, "x", tire, segs=16)
    add_cylinder(mesh, 0, 0, 0, 0.16, 0.12, "x", alloy, segs=10)
    for i in range(5):
        a = i / 5 * math.tau
        add_box(
            mesh,
            math.cos(a) * 0.08,
            0,
            math.sin(a) * 0.08,
            0.12,
            0.015,
            0.018,
            alloy,
        )
    return mesh


def limb(mesh: Mesh, x0, y0, z0, x1, y1, z1, r, uv) -> None:
    steps = 4
    for i in range(steps):
        t0 = i / steps
        t1 = (i + 1) / steps
        p0 = (x0 + (x1 - x0) * t0, y0 + (y1 - y0) * t0, z0 + (z1 - z0) * t0)
        p1 = (x0 + (x1 - x0) * t1, y0 + (y1 - y0) * t1, z0 + (z1 - z0) * t1)
        mid = tuple((a + b) * 0.5 for a, b in zip(p0, p1))
        add_box(mesh, mid[0], mid[1], mid[2], r, abs(p1[1] - p0[1]) * 0.55 + r * 0.35, r * 0.8, uv)


def build_human(pose: str) -> Mesh:
    mesh = Mesh()
    skin = (0.02, 0.38, 0.22, 0.62)
    hair = (0.28, 0.38, 0.48, 0.62)
    suit = (0.52, 0.38, 0.96, 0.70)
    shoe = (0.02, 0.08, 0.22, 0.28)
    face = (0.02, 0.18, 0.22, 0.36)

    swing = 0.22 if pose == "walk_a" else (-0.22 if pose == "walk_b" else 0.0)
    seated = pose == "seat"
    hip_y = 0.72 if not seated else 0.48
    head_y = 1.48 if not seated else 1.18
    leg_y = 0.08 if not seated else 0.28
    leg_z = 0.0 if not seated else 0.28

    add_box(mesh, 0, hip_y + 0.22, 0, 0.20, 0.28, 0.11, suit)
    add_uv_sphere(mesh, 0, head_y, 0, 0.13, skin, stacks=5, slices=8)
    add_uv_sphere(mesh, 0, head_y + 0.04, -0.01, 0.135, hair, stacks=4, slices=8)
    add_box(mesh, 0, head_y - 0.02, 0.11, 0.06, 0.04, 0.015, face)

    if seated:
        limb(mesh, -0.08, hip_y, 0, -0.08, 0.42, 0.22, 0.055, suit)
        limb(mesh, 0.08, hip_y, 0, 0.08, 0.42, 0.22, 0.055, suit)
        limb(mesh, -0.08, 0.42, 0.22, -0.08, 0.22, 0.46, 0.045, suit)
        limb(mesh, 0.08, 0.42, 0.22, 0.08, 0.22, 0.46, 0.045, suit)
        add_box(mesh, -0.08, 0.20, 0.50, 0.05, 0.03, 0.08, shoe)
        add_box(mesh, 0.08, 0.20, 0.50, 0.05, 0.03, 0.08, shoe)
        limb(mesh, -0.22, hip_y + 0.32, 0, -0.34, hip_y + 0.12, 0.16, 0.04, suit)
        limb(mesh, 0.22, hip_y + 0.32, 0, 0.28, hip_y + 0.42, -0.05, 0.04, skin)
    else:
        limb(mesh, -0.09, hip_y, 0.02, -0.09, leg_y, swing + leg_z, 0.055, suit)
        limb(mesh, 0.09, hip_y, 0.02, 0.09, leg_y, -swing + leg_z, 0.055, suit)
        add_box(mesh, -0.09, 0.04, swing, 0.05, 0.03, 0.08, shoe)
        add_box(mesh, 0.09, 0.04, -swing, 0.05, 0.03, 0.08, shoe)
        limb(mesh, -0.24, hip_y + 0.38, 0, -0.30, hip_y + 0.05, -swing, 0.04, suit)
        limb(mesh, 0.24, hip_y + 0.38, 0, 0.30, hip_y + 0.05, swing, 0.04, suit)
        add_uv_sphere(mesh, -0.30, hip_y + 0.02, -swing, 0.035, skin, stacks=3, slices=6)
        add_uv_sphere(mesh, 0.30, hip_y + 0.02, swing, 0.035, skin, stacks=3, slices=6)
    return mesh


def paint_car_texture(path: Path) -> None:
    img = Image.new("RGB", (256, 256), (12, 14, 16))
    d = ImageDraw.Draw(img)
    d.rectangle((4, 160, 70, 250), fill=(18, 20, 24))
    d.rectangle((70, 170, 130, 250), fill=(28, 36, 48))
    d.rectangle((130, 180, 190, 250), fill=(168, 174, 182))
    d.rectangle((8, 100, 60, 150), fill=(196, 28, 36))
    d.rectangle((8, 8, 70, 80), fill=(230, 236, 242))
    img.save(path)


def paint_character_texture(path: Path, suit, hair, skin) -> None:
    img = Image.new("RGB", (256, 256), skin)
    d = ImageDraw.Draw(img)
    d.rectangle((4, 8, 60, 78), fill=(22, 22, 26))
    d.ellipse((18, 28, 30, 40), fill=(20, 16, 14))
    d.ellipse((36, 28, 48, 40), fill=(20, 16, 14))
    d.rectangle((70, 80, 130, 170), fill=hair)
    d.rectangle((8, 90, 60, 160), fill=skin)
    d.rectangle((130, 80, 250, 190), fill=suit)
    d.rectangle((4, 180, 60, 250), fill=(28, 28, 32))
    img.save(path)


def _pack(mesh: Mesh) -> bytes:
    pos = b"".join(struct.pack("<3f", *p) for p in mesh.pos)
    nrm = b"".join(struct.pack("<3f", *n) for n in mesh.nrm)
    uv = b"".join(struct.pack("<2f", *u) for u in mesh.uv)
    idx = b"".join(struct.pack("<H", i) for i in mesh.idx)
    return pos + nrm + uv + idx, len(mesh.pos), len(mesh.idx), len(pos), len(nrm), len(uv)


def write_glb(path: Path, nodes: list[dict], texture_uri: str) -> None:
    blobs = []
    mesh_json = []
    accessors = []
    views = []
    offset = 0
    for node in nodes:
        blob, count, icount, lp, ln, lu = _pack(node["mesh"])
        start = offset
        view_base = len(views)
        views.append({"buffer": 0, "byteOffset": start, "byteLength": lp})
        views.append({"buffer": 0, "byteOffset": start + lp, "byteLength": ln})
        views.append({"buffer": 0, "byteOffset": start + lp + ln, "byteLength": lu})
        views.append({"buffer": 0, "byteOffset": start + lp + ln + lu, "byteLength": icount * 2})
        base = len(accessors)
        accessors.append(
            {
                "bufferView": view_base,
                "componentType": 5126,
                "count": count,
                "type": "VEC3",
            }
        )
        accessors.append(
            {
                "bufferView": view_base + 1,
                "componentType": 5126,
                "count": count,
                "type": "VEC3",
            }
        )
        accessors.append(
            {
                "bufferView": view_base + 2,
                "componentType": 5126,
                "count": count,
                "type": "VEC2",
            }
        )
        accessors.append(
            {
                "bufferView": view_base + 3,
                "componentType": 5123,
                "count": icount,
                "type": "SCALAR",
            }
        )
        mesh_json.append(
            {
                "name": node["name"],
                "primitives": [
                    {
                        "attributes": {
                            "POSITION": base,
                            "NORMAL": base + 1,
                            "TEXCOORD_0": base + 2,
                        },
                        "indices": base + 3,
                    }
                ],
            }
        )
        blobs.append(blob)
        offset += len(blob)
        pad = (4 - (offset % 4)) % 4
        blobs.append(b"\x00" * pad)
        offset += pad

    bin_blob = b"".join(blobs)
    gltf_nodes = []
    for i, node in enumerate(nodes):
        item = {"name": node["name"], "mesh": i}
        if "translation" in node:
            item["translation"] = node["translation"]
        gltf_nodes.append(item)
    doc = {
        "asset": {"version": "2.0", "generator": "a1-games-original"},
        "scene": 0,
        "scenes": [{"nodes": list(range(len(nodes)))}],
        "nodes": gltf_nodes,
        "meshes": mesh_json,
        "accessors": accessors,
        "bufferViews": views,
        "buffers": [{"byteLength": len(bin_blob)}],
        "images": [{"uri": texture_uri}],
    }
    js = json.dumps(doc, separators=(",", ":")).encode("utf-8")
    js += b" " * ((4 - (len(js) % 4)) % 4)
    total = 12 + 8 + len(js) + 8 + len(bin_blob)
    out = b"glTF" + struct.pack("<II", 2, total)
    out += struct.pack("<I", len(js)) + b"JSON" + js
    out += struct.pack("<I", len(bin_blob)) + b"BIN\x00" + bin_blob
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(out)


def main() -> None:
    (CARS / "Textures").mkdir(parents=True, exist_ok=True)
    (CHARS / "Textures").mkdir(parents=True, exist_ok=True)
    paint_car_texture(CARS / "Textures" / "executive.png")
    skins = {
        "ace": ((214, 48, 56), (27, 27, 27), (224, 180, 138)),
        "nova": ((20, 170, 188), (61, 35, 20), (198, 134, 66)),
        "shade": ((29, 53, 87), (17, 17, 17), (141, 85, 36)),
        "luna": ((123, 44, 191), (43, 27, 18), (241, 201, 160)),
        "bolt": ((45, 106, 79), (74, 55, 40), (212, 165, 116)),
    }
    for name, (suit, hair, skin) in skins.items():
        paint_character_texture(CHARS / "Textures" / f"{name}.png", suit, hair, skin)

    body = build_sedan_body()
    wheel = build_wheel()
    write_glb(
        CARS / "executive-sedan.glb",
        [
            {"name": "body", "mesh": body},
            {"name": "wheel-front-left", "mesh": wheel, "translation": [0.62, 0.30, 0.78]},
            {"name": "wheel-front-right", "mesh": wheel, "translation": [-0.62, 0.30, 0.78]},
            {"name": "wheel-back-left", "mesh": wheel, "translation": [0.62, 0.30, -0.78]},
            {"name": "wheel-back-right", "mesh": wheel, "translation": [-0.62, 0.30, -0.78]},
        ],
        "Textures/executive.png",
    )
    for pose, file in (
        ("idle", "human.glb"),
        ("walk_a", "human-walk-a.glb"),
        ("walk_b", "human-walk-b.glb"),
        ("seat", "human-seat.glb"),
    ):
        write_glb(
            CHARS / file,
            [{"name": "body", "mesh": build_human(pose)}],
            "Textures/ace.png",
        )
    print("wrote executive sedan and character glbs")


if __name__ == "__main__":
    main()
