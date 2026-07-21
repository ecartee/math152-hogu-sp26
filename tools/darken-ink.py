#!/usr/bin/env python3
"""
Darken the colored ink in a graph PNG until it meets a WCAG contrast ratio,
without touching the grid, the axes, or the white background.

Desmos exports curves and their labels in colors that look fine on screen but
measure ~3.2-3.8:1 against white -- under the 4.5:1 that text requires. Rather
than re-plotting the graph, this rescales each ink color toward black and
re-composites every pixel of that hue, so antialiased edges stay smooth and the
figure still looks like the original.

Usage:
    tools/darken-ink.py assets/s3-region.png            # fix in place (4.7:1)
    tools/darken-ink.py assets/s3-region.png --ratio 5  # stricter
    tools/darken-ink.py assets/s3-region.png --dry-run  # just report

Requires Pillow. If it is not installed:
    python3 -m venv /tmp/ink && /tmp/ink/bin/pip -q install pillow
    /tmp/ink/bin/python tools/darken-ink.py ...

Re-run tools/audit.sh afterward to confirm.
"""
import argparse
import sys
from collections import Counter

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow required: python3 -m venv /tmp/ink && /tmp/ink/bin/pip install pillow")

WHITE_L = 1.0


def lum(rgb):
    def f(v):
        v /= 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = rgb
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def ratio_vs_white(rgb):
    return (WHITE_L + 0.05) / (lum(rgb) + 0.05)


def family(rgb):
    r, g, b = rgb
    return "red" if r >= g and r >= b else ("green" if g >= b else "blue")


def core_inks(im, floor_frac=0.0004):
    """Darkest reasonably-common saturated color per hue family -- the stroke/label
    core. Pale fills and antialiased edges are lighter, so they drop out."""
    counts = Counter()
    data = im.tobytes()                            # RGB, 3 bytes per pixel
    for i in range(0, len(data), 3):
        r, g, b = data[i], data[i + 1], data[i + 2]
        if max(r, g, b) - min(r, g, b) < 40:      # grey/black/white
            continue
        counts[(r >> 3 << 3, g >> 3 << 3, b >> 3 << 3)] += 1
    floor = max(100, floor_frac * im.width * im.height)
    best = {}
    for rgb, n in counts.items():
        if n < floor:
            continue
        fam = family(rgb)
        if fam not in best or lum(rgb) < lum(best[fam][0]):
            best[fam] = (rgb, n)
    return best


def darkened(rgb, target):
    """Scale toward black until the ratio clears target."""
    scale = 1.0
    while scale > 0.05:
        cand = tuple(max(0, round(c * scale)) for c in rgb)
        if ratio_vs_white(cand) >= target:
            return cand
        scale -= 0.02
    return (0, 0, 0)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--ratio", type=float, default=4.7,
                    help="target contrast vs white (default 4.7, just over the 4.5 text rule)")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    im = Image.open(args.image).convert("RGB")
    inks = core_inks(im)
    if not inks:
        print(f"{args.image}: no saturated ink found -- nothing to do")
        return

    plan = {}
    # Colors are read back through a quantizing bucket, so a freshly-fixed image
    # measures a hair under target. Allow that slack, otherwise a second run
    # would darken an already-correct image again.
    accept = args.ratio - 0.15
    for fam, (rgb, n) in sorted(inks.items()):
        have = ratio_vs_white(rgb)
        if have >= accept:
            print(f"  {fam:5} rgb{rgb} {have:5.2f}:1  ok")
            continue
        new = darkened(rgb, args.ratio)
        print(f"  {fam:5} rgb{rgb} {have:5.2f}:1  ->  rgb{new} {ratio_vs_white(new):5.2f}:1")
        plan[fam] = (rgb, new)

    if not plan:
        print(f"{args.image}: already meets {args.ratio}:1")
        return
    if args.dry_run:
        print("(dry run -- nothing written)")
        return

    # Re-composite: treat each pixel as its family's ink laid over white at some
    # alpha, then lay the darkened ink over white at that same alpha.
    px = im.load()
    changed = 0
    for y in range(im.height):
        for x in range(im.width):
            p = px[x, y]
            if max(p) - min(p) < 12:
                continue
            fam = family(p)
            if fam not in plan:
                continue
            old, new = plan[fam]
            if lum(p) < lum(old) - 0.02:       # darker than the ink core: leave alone
                continue
            parts = [(255 - p[c]) / (255 - old[c]) for c in range(3) if 255 - old[c] > 8]
            if not parts:
                continue
            a = min(1.0, max(0.0, sum(parts) / len(parts)))
            px[x, y] = tuple(min(255, max(0, round(new[c] * a + 255 * (1 - a)))) for c in range(3))
            changed += 1

    im.save(args.image)
    print(f"{args.image}: remapped {changed} pixels")


if __name__ == "__main__":
    main()
