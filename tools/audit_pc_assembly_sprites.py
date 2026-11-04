#!/usr/bin/env python3
"""Audit individual PC assembly PNGs. Requires Pillow.
Usage: python tools/audit_pc_assembly_sprites.py assets/minigames/pc_assembly --output sprite_audit.csv
Does not modify source images.
"""
import argparse
import csv
from collections import Counter
from pathlib import Path
from PIL import Image

def audit(path):
    with Image.open(path) as src:
        image = src.convert("RGBA")
    width, height = image.size
    px = list(image.getdata())
    alpha = [p[3] for p in px]
    opaque = sum(a == 255 for a in alpha)
    transparent = sum(a == 0 for a in alpha)
    partial = width * height - opaque - transparent
    # Color-cluster warning: large same-color regions may be unwanted backgrounds.
    colors = Counter(p[:3] for p in px if p[3] >= 240)
    common = colors.most_common(1)
    dominant = common[0][1] / max(1, opaque) if common else 0
    border = []
    for x in range(width):
        border += [alpha[x], alpha[(height-1)*width+x]]
    for y in range(height):
        border += [alpha[y*width], alpha[y*width+width-1]]
    flags = []
    if any(a > 0 for a in border): flags.append("nontransparent_border")
    if transparent == 0: flags.append("no_transparent_pixels")
    if dominant >= 0.20: flags.append("dominant_opaque_color_review")
    if width < 16 or height < 16: flags.append("small_sprite")
    return {"file":str(path), "width":width, "height":height,
            "opaque_pct":round(opaque/len(px)*100,2),
            "transparent_pct":round(transparent/len(px)*100,2),
            "partial_alpha_pct":round(partial/len(px)*100,2),
            "dominant_opaque_color_pct":round(dominant*100,2),
            "flags":";".join(flags)}

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("assets_dir", type=Path)
    parser.add_argument("--output", type=Path, default=Path("sprite_audit.csv"))
    args=parser.parse_args()
    if not args.assets_dir.is_dir(): parser.error("Assets directory does not exist")
    files=sorted(args.assets_dir.rglob("*.png"))
    if not files: parser.error("No PNG files found")
    rows=[audit(p) for p in files]
    with args.output.open("w", newline="", encoding="utf-8") as f:
        writer=csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader(); writer.writerows(rows)
    print(f"Audited {len(rows)} PNGs; flagged {sum(bool(r['flags']) for r in rows)} for manual review. Report: {args.output}")

if __name__ == "__main__":
    main()
