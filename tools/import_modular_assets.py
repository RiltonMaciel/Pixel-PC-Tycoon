"""Import local user artwork; preserve source packages and remove disconnected scraps."""
import argparse
import json
import shutil
from io import BytesIO
from pathlib import Path, PurePosixPath
from zipfile import ZipFile

from PIL import Image


def clean(image):
    image = image.convert("RGBA")
    w, h = image.size
    alpha = image.getchannel("A").tobytes()
    todo = bytearray(alpha)
    largest = []
    for start in range(len(todo)):
        if todo[start] < 8:
            continue
        pending, component = [start], []
        todo[start] = 0
        while pending:
            i = pending.pop()
            component.append(i)
            x, y = i % w, i // w
            neighbors = []
            if x:
                neighbors.append(i - 1)
            if x + 1 < w:
                neighbors.append(i + 1)
            if y:
                neighbors.append(i - w)
            if y + 1 < h:
                neighbors.append(i + w)
            for n in neighbors:
                if todo[n] >= 8:
                    todo[n] = 0
                    pending.append(n)
        if len(component) > len(largest):
            largest = component
    if not largest:
        raise ValueError("Empty sprite")
    cleaned = bytearray(w * h)
    for i in largest:
        cleaned[i] = alpha[i]
    image.putalpha(Image.frombytes("L", image.size, bytes(cleaned)))
    return image.crop(image.getbbox())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("downloads", type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    kit = args.downloads / "Pixel_PC_Tycoon_Kit_Modular_Cenario_v1"
    manifest = json.loads((kit / "04_documentacao" / "manifest_encaixes.json").read_text(encoding="utf-8"))
    target = root / "Assets" / "Cenarios" / "Modular"
    for asset in manifest["assets"]:
        relative = PurePosixPath(asset["file"])
        if relative.is_absolute() or ".." in relative.parts:
            raise ValueError("Invalid asset path")
        source = kit.joinpath(*relative.parts)
        with Image.open(source) as image:
            assert list(image.size) == asset["size_px"], source
            assert image.mode == "RGBA", source
            assert set(image.getchannel("A").tobytes()) == {0, 255}, source
        destination = target / relative.name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
    shutil.copyfile(kit / "04_documentacao" / "manifest_encaixes.json", target / "manifest_encaixes.json")
    count = 0
    for package, folder in [("05_personagens.zip", "Personagens"), ("03_moveis_e_equipamentos.zip", "Moveis")]:
        with ZipFile(args.downloads / package) as archive:
            for name in archive.namelist():
                path = PurePosixPath(name)
                if path.suffix.lower() != ".png":
                    continue
                if path.is_absolute() or ".." in path.parts:
                    raise ValueError("Invalid archive path")
                image = clean(Image.open(BytesIO(archive.read(name))))
                if folder == "Personagens":
                    canvas = Image.new("RGBA", (160, 240))
                    if image.width > 152 or image.height > 232:
                        raise ValueError(f"Character exceeds common canvas: {name}")
                    canvas.alpha_composite(image, (80 - image.width // 2, 232 - image.height))
                else:
                    canvas = Image.new("RGBA", (image.width + 16, image.height + 16))
                    canvas.alpha_composite(image, (8, 8))
                destination = root / "Assets" / folder / "Modulares"
                if folder == "Personagens":
                    destination /= path.parent.name
                destination.mkdir(parents=True, exist_ok=True)
                canvas.save(destination / path.name)
                count += 1
    print(f"Imported {len(manifest['assets'])} scenario pieces and {count} sprites. Sources untouched.")


if __name__ == "__main__":
    main()
