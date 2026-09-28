#!/usr/bin/env python3
"""Local visual preview of the generated map (no Roblox Studio required).

Renders SVGs from the headless build:
  plan_<deck>.svg   horizontal slice at walking height (collision in dark,
                    non-colliding dressing in colour, floors tinted, anchors)
  elevation_port.svg  orthographic port-side elevation (painter's algorithm)
  view_harbor.svg   perspective from the harbor spawn toward the liner
  view_<name>.svg   other perspective camera presets

Usage: python tools/preview.py [out_dir] [--views]
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(ROOT, "tests"))

import harness  # noqa: E402


def rgb(c, k=1.0):
    return "rgb(%d,%d,%d)" % tuple(max(0, min(255, int(v * 255 * k))) for v in c)


ANCHOR_COLORS = {
    "LootSpawn": "#7fd17f", "HeavyLootSpawn": "#e05a5a", "HidePoint": "#5aa9e0", "EarlyExtraction": "#4ce07a",
    "StalkerNode": "#ff9b42", "ContractSpawn": "#f2c14e", "EvidenceSpawn": "#d9d0ff", "CapturePoint": "#b060ff",
    "BoardingPoint": "#ffffff", "PlayerSpawn": "#00ffff", "BarricadePoint": "#ff5fa2", "PoweredDoor": "#ffe066",
}


def plan(build, y0, y1, bounds, scale, title):
    x0, z0, x1, z1 = bounds
    W, H = (x1 - x0) * scale, (z1 - z0) * scale
    out = ['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d" style="background:#0b0f16">' % (W, H + 30, W, H + 30)]
    out.append('<text x="6" y="%d" fill="#ddd" font-family="monospace" font-size="14">%s</text>' % (H + 20, title))

    def rect(a, fill, op=1.0, stroke=None):
        ax0, _, az0, ax1, _, az1 = a
        sx0, sx1 = (max(ax0, x0) - x0) * scale, (min(ax1, x1) - x0) * scale
        sz0, sz1 = (max(az0, z0) - z0) * scale, (min(az1, z1) - z0) * scale
        if sx1 <= sx0 or sz1 <= sz0:
            return
        st = ' stroke="%s" stroke-width="0.5"' % stroke if stroke else ""
        out.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" fill-opacity="%.2f"%s/>' % (sx0, sz0, sx1 - sx0, sz1 - sz0, fill, op, st))

    floors, walls, decor = [], [], []
    for p in build.parts:
        if p.transparency >= 0.99 and not p.tags:
            continue
        a = p.aabb()
        if a[3] < x0 or a[0] > x1 or a[5] < z0 or a[2] > z1:
            continue
        if a[4] <= y0 + 0.6 and a[4] >= y0 - 1.2:
            floors.append((a, p))
        if a[1] < y1 and a[4] > y0 + 0.7:
            if p.collide and p.transparency < 0.99:
                walls.append((a, p))
            elif p.transparency < 0.99:
                decor.append((a, p))
    for a, p in floors:
        rect(a, rgb(p.color, 0.45))
    for a, p in decor:
        rect(a, rgb(p.color, 0.9), 0.55)
    for a, p in walls:
        glass = "SightTransparent" in p.tags
        rect(a, "#7fc8ff" if glass else rgb(p.color, 0.8), 0.9 if not glass else 0.6, stroke="#000")
    for p in build.parts:
        for t, col in ANCHOR_COLORS.items():
            if t in p.tags:
                x, y, z = p.pos
                if y0 - 2 <= y <= y1 + 4 and x0 <= x <= x1 and z0 <= z <= z1:
                    out.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s" stroke="#000" stroke-width="0.6"/>' % ((x - x0) * scale, (z - z0) * scale, 1.1 * scale, col))
                break
    out.append("</svg>")
    return "\n".join(out)


# ---------------------------------------------------------------------------
# perspective / orthographic polygon rendering (painter's algorithm)
# ---------------------------------------------------------------------------
FACES = [
    ((1, 0, 0), [(1, -1, -1), (1, 1, -1), (1, 1, 1), (1, -1, 1)]),
    ((-1, 0, 0), [(-1, -1, 1), (-1, 1, 1), (-1, 1, -1), (-1, -1, -1)]),
    ((0, 1, 0), [(-1, 1, -1), (-1, 1, 1), (1, 1, 1), (1, 1, -1)]),
    ((0, -1, 0), [(-1, -1, 1), (-1, -1, -1), (1, -1, -1), (1, -1, 1)]),
    ((0, 0, 1), [(1, -1, 1), (1, 1, 1), (-1, 1, 1), (-1, -1, 1)]),
    ((0, 0, -1), [(-1, -1, -1), (-1, 1, -1), (1, 1, -1), (1, -1, -1)]),
]


def _rot(p, v):
    r = p.rot
    return (r[0] * v[0] + r[1] * v[1] + r[2] * v[2], r[3] * v[0] + r[4] * v[1] + r[5] * v[2], r[6] * v[0] + r[7] * v[1] + r[8] * v[2])


def render(build, cam, target, fov=60, W=1600, H=900, ortho=None, fog=(0.32, 700), max_dist=2600, bg="#0e141d", title=""):
    fx = [target[i] - cam[i] for i in range(3)]
    fl = math.sqrt(sum(v * v for v in fx))
    fwd = [v / fl for v in fx]
    up0 = (0, 1, 0)
    right = [fwd[1] * up0[2] - fwd[2] * up0[1], fwd[2] * up0[0] - fwd[0] * up0[2], fwd[0] * up0[1] - fwd[1] * up0[0]]
    rl = math.sqrt(sum(v * v for v in right))
    right = [v / rl for v in right]
    up = [right[1] * fwd[2] - right[2] * fwd[1], right[2] * fwd[0] - right[0] * fwd[2], right[0] * fwd[1] - right[1] * fwd[0]]
    f = (H / 2) / math.tan(math.radians(fov) / 2)
    light = (-0.35, 0.8, 0.45)
    ll = math.sqrt(sum(v * v for v in light))
    light = [v / ll for v in light]
    fogc = (0.46, 0.52, 0.6)
    polys = []
    for p in build.parts:
        if p.transparency >= 0.95:
            continue
        if p.shape == "Terrain":
            continue
        d = [p.pos[i] - cam[i] for i in range(3)]
        depth_c = sum(d[i] * fwd[i] for i in range(3))
        if ortho is None and depth_c < -max(p.size) or math.sqrt(sum(v * v for v in d)) > max_dist:
            continue
        hx, hy, hz = p.size[0] / 2, p.size[1] / 2, p.size[2] / 2
        cyl = p.shape == "Cylinder"
        for n, corners in FACES:
            wn = _rot(p, n)
            pts = []
            ok = True
            for c in corners:
                lc = (c[0] * hx, c[1] * hy, c[2] * hz)
                if cyl and n[0] == 0:
                    lc = (lc[0], lc[1] * 0.85, lc[2] * 0.85)
                w = _rot(p, lc)
                wp = [p.pos[i] + w[i] for i in range(3)]
                rel = [wp[i] - cam[i] for i in range(3)]
                z = sum(rel[i] * fwd[i] for i in range(3))
                x = sum(rel[i] * right[i] for i in range(3))
                y = sum(rel[i] * up[i] for i in range(3))
                if ortho is None:
                    if z < 1:
                        ok = False
                        break
                    sx, sy = W / 2 + f * x / z, H / 2 - f * y / z
                else:
                    sx, sy = W / 2 + x * ortho, H / 2 - y * ortho
                pts.append((sx, sy, z))
            if not ok:
                continue
            # back-face cull
            if ortho is None:
                facing = sum(wn[i] * (cam[i] - (p.pos[i] + wn[i] * 0)) for i in range(3))
                cen = [p.pos[i] + _rot(p, (n[0] * hx, n[1] * hy, n[2] * hz))[i] for i in range(3)]
                facing = sum(wn[i] * (cam[i] - cen[i]) for i in range(3))
            else:
                facing = -sum(wn[i] * fwd[i] for i in range(3))
            if facing <= 0:
                continue
            xs = [q[0] for q in pts]
            ys = [q[1] for q in pts]
            if max(xs) < 0 or min(xs) > W or max(ys) < 0 or min(ys) > H:
                continue
            area = abs((xs[0] - xs[2]) * (ys[1] - ys[3]) - (xs[1] - xs[3]) * (ys[0] - ys[2])) / 2
            if area < 0.4:
                continue
            depth = sum(q[2] for q in pts) / 4
            shade = 0.45 + 0.55 * max(0.0, sum(wn[i] * light[i] for i in range(3)))
            col = list(p.color)
            if p.material == "Neon":
                shade = 1.25
            elif p.material == "Glass":
                shade *= 0.9
            col = [min(1, c * shade) for c in col]
            if fog:
                dist = max(0.0, depth)
                k = 1 - math.exp(-dist * fog[0] / fog[1] * 3) if p.material != "Neon" else (1 - math.exp(-dist * fog[0] / fog[1] * 1.3))
                col = [col[i] * (1 - k) + fogc[i] * k for i in range(3)]
            op = 1 - p.transparency
            polys.append((depth, pts, col, op))
    polys.sort(key=lambda t: -t[0])
    out = ['<svg xmlns="http://www.w3.org/2000/svg" width="1400" height="1400" viewBox="0 %d %d %d">' % (-(W-H)//2, W, W)]
    out.append('<defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0a0f18"/><stop offset="0.55" stop-color="#3a4656"/><stop offset="1" stop-color="#5b6776"/></linearGradient></defs>')
    out.append('<rect width="%d" height="%d" fill="url(#sky)"/>' % (W, H))
    # sea plane horizon (approx): draw the water as a band below the horizon line
    if ortho is None:
        hz_y = H / 2 - f * (sum([(0 - 0) * 0])) if False else None
    for depth, pts, col, op in polys:
        d = "M" + " L".join("%.1f,%.1f" % (q[0], q[1]) for q in pts) + " Z"
        out.append('<path d="%s" fill="%s" fill-opacity="%.2f"/>' % (d, rgb(col), op))
    if title:
        out.append('<text x="10" y="%d" fill="#ddd" font-family="monospace" font-size="16">%s</text>' % (H - 12, title))
    out.append("</svg>")
    return "\n".join(out)


def water_parts(build, y=4.0):
    """Terrain water is not a part; add a flat proxy so renders show the sea."""
    class W:
        pass
    ps = []
    for (x0, z0, x1, z1) in [(-900, -700, 900, 1100)]:
        p = harness.Part()
        p.path = "Water"
        p.name = "Water"
        p.shape = "Block"
        p.size = (x1 - x0, 0.2, z1 - z0)
        p.pos = ((x0 + x1) / 2, y - 0.1, (z0 + z1) / 2)
        p.rot = (1, 0, 0, 0, 1, 0, 0, 0, 1)
        p.material = "Water"
        p.color = (0.07, 0.15, 0.18)
        p.transparency = 0
        p.collide = False
        p.query = False
        p.shadow = False
        p.anchored = True
        p.tags = set()
        p.attrs = {}
        ps.append(p)
    return ps


VIEWS = {
    "harbor_spawn": ((149, 16, 736), (60, 40, 24), 58),
    "tender_mid": ((236, 10, 300), (40, 50, 24), 60),
    "aft_quarter": ((330, 30, 170), (120, 45, 30), 55),
    "bow_quarter": ((-420, 40, 200), (-120, 45, 24), 55),
    "ladder": ((214, 10, 90), (232, 30, 58), 70),
    "aft_deck": ((238, 38, 30), (190, 36, 24), 75),
    "promenade": ((188, 37, 53), (40, 36, 53), 75),
    "corridor_A": ((188, 36.5, 24), (100, 36, 24), 75),
    "corridor_B": ((10, 20.5, 24), (100, 20, 24), 75),
    "corridor_C": ((10, 4.5, 24), (100, 4, 24), 75),
    "ballroom": ((100, 38, 31), (124, 40, 44), 80),
}


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else os.path.join(ROOT, "build", "preview")
    os.makedirs(out_dir, exist_ok=True)
    build, _, _ = harness.run_build()
    decks = {"A": 32, "B": 16, "C": 0}
    for d, y in decks.items():
        svg = plan(build, y, y + 6, (-4, -14, 200, 62), 6, "Deck %s plan slice y=%d..%d" % (d, y, y + 6))
        with open(os.path.join(out_dir, "plan_%s.svg" % d), "w") as f:
            f.write(svg)
    svg = plan(build, 8, 16, (-60, 540, 380, 800), 3, "Harbor plan slice y=8..16")
    with open(os.path.join(out_dir, "plan_harbor.svg"), "w") as f:
        f.write(svg)
    if "--views" in sys.argv:
        build.parts.extend(water_parts(build))
        ortho = render(build, (0, 50, 1400), (0, 50, 0), ortho=1.9, W=1800, H=700, fog=None, title="Port elevation (orthographic)")
        with open(os.path.join(out_dir, "elevation_port.svg"), "w") as f:
            f.write(ortho)
        for name, (cam, tgt, fov) in VIEWS.items():
            interior = name.startswith("corridor") or name == "ballroom"
            svg = render(build, cam, tgt, fov=fov, fog=None if interior else (0.33, 700), max_dist=300 if interior else 2600, title=name)
            with open(os.path.join(out_dir, "view_%s.svg" % name), "w") as f:
                f.write(svg)
    print("wrote previews to", out_dir)


if __name__ == "__main__":
    main()
