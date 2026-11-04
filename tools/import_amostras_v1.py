"""Validate and import the supplied sample ZIP without changing PNG bytes."""
import argparse
from io import BytesIO
import hashlib
import json
from pathlib import Path
from zipfile import ZipFile

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "Assets" / "Cenarios" / "AmostrasV1"
MODELS = ("compacto_azul", "picape_vermelha")
DIRECTIONS = ("baixo_direita", "baixo_esquerda", "cima_direita", "cima_esquerda")
STORE = "fachadas/mercadinho/mercadinho.png"


def import_samples(path):
    names = [f"veiculos/{model}/{direction}.png"
             for model in MODELS for direction in DIRECTIONS] + [STORE]
    with ZipFile(path) as archive:
        manifest = json.loads(archive.read("manifesto.json"))
        prepared = []
        for name in names:
            raw = archive.read(name)
            image = Image.open(BytesIO(raw))
            entry = manifest["assets"][name]
            expected = (704, 576) if name == STORE else (512, 320)
            if image.mode != "RGBA" or image.size != expected:
                raise ValueError(f"Invalid RGBA dimensions: {name}")
            if entry["arquivo"] != name or tuple(entry["canvas_px"]) != expected:
                raise ValueError(f"Manifest disagrees with image: {name}")
            if image.getchannel("A").getextrema() != (0, 255):
                raise ValueError(f"Missing alpha range: {name}")
            pivot = entry["pivo_chao_px"]
            if len(pivot) != 2 or not (0 <= pivot[0] < image.width and 0 <= pivot[1] < image.height):
                raise ValueError(f"Invalid pivot: {name}")
            prepared.append((name, raw))
        metadata = {"archive_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                    "sources": {}, "pixels_modified": False}
        for name, raw in prepared:
            destination = TARGET.joinpath(*name.split("/"))
            destination.parent.mkdir(parents=True, exist_ok=True)
            metadata["sources"][name] = hashlib.sha256(raw).hexdigest()
            destination.write_bytes(raw)
        (TARGET / "manifesto.json").write_text(
            json.dumps(manifest, indent=2, ensure_ascii=True)+"\n", encoding="utf-8")
        (TARGET / "importacao.json").write_text(json.dumps(metadata, indent=2)+"\n", encoding="utf-8")
        print("Imported 9 samples; source PNG bytes preserved.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    import_samples(parser.parse_args().archive)
