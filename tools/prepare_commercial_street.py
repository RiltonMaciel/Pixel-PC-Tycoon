"""Prepare supplied cafe/asphalt artwork without modifying the input files."""
import argparse
import hashlib
import json
import math
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps

from import_modular_assets import clean

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "Assets" / "Cenarios" / "Bairro"
FRONT = ((190, 637), (754, 717))
SIDE = (1041, 536)
DOOR = ((644, 514), (644, 697))


def prepare(cafe_path, asphalt_path):
    source_dir = TARGET / "Fontes"
    source_dir.mkdir(parents=True, exist_ok=True)
    for path, name in [(cafe_path, "cafeteria_original.png"), (asphalt_path, "asfalto_original.png")]:
        target = source_dir / name
        if path.resolve() != target.resolve():
            shutil.copyfile(path, target)
    cafe = Image.open(cafe_path).convert("RGBA")
    if cafe.size != (1152, 768):
        raise ValueError("Cafe landmarks require the approved 1152x768 image.")
    if cafe.getchannel("A").getextrema()[0] != 0:
        raise ValueError("The cafe must have a transparent background.")
    # Keep the original coordinates while reusing connected-component cleanup.
    alpha = cafe.getchannel("A").point(lambda p: 255 if p >= 8 else 0)
    box = alpha.getbbox()
    if box is None:
        raise ValueError("Empty cafe artwork.")
    cafe.putalpha(alpha)
    isolated = clean(cafe)
    if isolated.size != (box[2] - box[0], box[3] - box[1]):
        raise ValueError("Disconnected artwork changed the expected cafe bounds.")
    cleaned = Image.new("RGBA", cafe.size)
    cleaned.alpha_composite(isolated, box[:2])
    front_slope = (FRONT[1][1] - FRONT[0][1]) / (FRONT[1][0] - FRONT[0][0])
    side_slope = (SIDE[1] - FRONT[1][1]) / (SIDE[0] - FRONT[1][0])
    vertical = (20 / 64 + 32 / 64) / (front_slope - side_slope)
    shear = 20 / 64 - front_slope * vertical
    size = (cafe.width + 16, math.ceil(cafe.height * vertical + cafe.width * shear) + 16)
    adjusted = cleaned.transform(
        size, Image.Transform.AFFINE,
        (1, 0, -8, -shear / vertical, 1 / vertical, (8 * shear - 8) / vertical),
        resample=Image.Resampling.NEAREST,
    )
    adjusted.save(TARGET / "cafeteria.png")

    def point(p):
        return [p[0] + 8, p[0] * shear + p[1] * vertical + 8]

    metadata = {
        "source_sha256": hashlib.sha256(cafe_path.read_bytes()).hexdigest(),
        "source_size": list(cafe.size),
        "affine": {"shear_y": shear, "scale_y": vertical, "margin": 8},
        "front_left": point(FRONT[0]), "front_right": point(FRONT[1]),
        "back_right": point(SIDE), "door_top": point(DOOR[0]), "door_bottom": point(DOOR[1]),
        "note": "Geometric adaptation, not a redrawn building. Original retained in Fontes.",
    }
    (TARGET / "cafeteria.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    asphalt = Image.open(asphalt_path).convert("RGB")
    if asphalt.size != (256, 256):
        raise ValueError("Expected the supplied 256x256 asphalt texture.")
    seamless = Image.new("RGB", (512, 512))
    seamless.paste(asphalt, (0, 0))
    seamless.paste(ImageOps.mirror(asphalt), (256, 0))
    seamless.paste(ImageOps.flip(asphalt), (0, 256))
    seamless.paste(ImageOps.flip(ImageOps.mirror(asphalt)), (256, 256))
    seamless.save(TARGET / "asfalto_continuo.png")
    paving = Image.new("RGB", (128, 128))
    noise = asphalt.convert("L")
    for y in range(128):
        for x in range(128):
            grain = (noise.getpixel((x, y)) - 65) // 6
            paving.putpixel((x, y), (174 + grain, 171 + grain, 161 + grain))
    draw = ImageDraw.Draw(paving)
    for at in (0, 64):
        draw.line((at, 0, at, 127), fill=(154, 151, 142))
        draw.line((0, at, 127, at), fill=(154, 151, 142))
    paving.save(TARGET / "calcada_continua.png")
    print(json.dumps(metadata, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("cafe", type=Path)
    parser.add_argument("asphalt", type=Path)
    args = parser.parse_args()
    prepare(args.cafe, args.asphalt)
