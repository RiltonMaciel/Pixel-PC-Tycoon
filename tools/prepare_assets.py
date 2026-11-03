"""Import approved artwork without redrawing it. Requires Pillow."""
import argparse
import shutil
from pathlib import Path

from PIL import Image


def clean_sprite(source: Path, destination: Path) -> None:
    image = Image.open(source).convert("RGBA")
    width, height = image.size
    alpha = image.getchannel("A")
    remaining = bytearray(alpha.tobytes())
    largest = []
    for start in range(len(remaining)):
        if remaining[start] < 16:
            continue
        stack = [start]
        remaining[start] = 0
        component = []
        while stack:
            index = stack.pop()
            component.append(index)
            x, y = index % width, index // width
            neighbors = []
            if x:
                neighbors.append(index - 1)
            if x + 1 < width:
                neighbors.append(index + 1)
            if y:
                neighbors.append(index - width)
            if y + 1 < height:
                neighbors.append(index + width)
            for neighbor in neighbors:
                if remaining[neighbor] >= 16:
                    remaining[neighbor] = 0
                    stack.append(neighbor)
        if len(component) > len(largest):
            largest = component
    if not largest:
        raise ValueError(f"No opaque sprite found: {source}")
    cleaned = bytearray(width * height)
    original = alpha.tobytes()
    for index in largest:
        cleaned[index] = original[index]
    image.putalpha(Image.frombytes("L", image.size, bytes(cleaned)))
    image = image.crop(image.getbbox())
    # Normalize apparent width; keep transparent margins and the base pivot.
    image = image.resize((240, round(image.height * 240 / image.width)), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (256, 256))
    canvas.alpha_composite(image, (8, 248 - image.height))
    destination.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(destination)
    print(f"{destination.name}: RGBA 256x256, base=(128,248)")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("package", type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    images = args.package / "Imagens"
    exterior = root / "Assets" / "Cenarios" / "Exterior"
    exterior.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(images / "01_PC_Store_Exterior_Com_Telhado.png", exterior / "PC_Store_Com_Telhado.png")
    target = root / "Assets" / "Moveis" / "Balcoes" / "balcao_pc_store"
    for angle in (0, 90, 180, 270):
        clean_sprite(images / "Balcao" / f"{angle}.png", target / f"{angle}.png")


if __name__ == "__main__":
    main()
