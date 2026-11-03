"""Import the supplied street kit and isolate approved exterior artwork."""
import argparse
import json
from pathlib import Path, PurePosixPath
from zipfile import ZipFile

from PIL import Image, ImageDraw


def cut(source, polygon, destination, holes=(), additions=()):
    mask = Image.new("L", source.size)
    draw = ImageDraw.Draw(mask)
    draw.polygon(polygon, fill=255)
    for addition in additions:
        draw.polygon(addition, fill=255)
    for hole in holes:
        draw.polygon(hole, fill=0)
    image = source.convert("RGBA")
    image.putalpha(mask)
    image.save(destination)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    target = root / "Assets" / "Cenarios" / "Bairro"
    target.mkdir(parents=True, exist_ok=True)
    with ZipFile(args.archive) as archive:
        names = [name for name in archive.namelist()
                 if PurePosixPath(name).suffix == ".png" and "/05_previas/" not in name]
        for name in names:
            path = PurePosixPath(name)
            if path.is_absolute() or ".." in path.parts:
                raise ValueError(f"Invalid path: {name}")
            destination = target / path.name
            destination.write_bytes(archive.read(name))
            image = Image.open(destination)
            if image.mode != "RGBA" or image.size != (128, 64):
                raise ValueError(f"Unexpected tile format: {name}")
            if image.getchannel("A").getextrema() != (0, 255):
                raise ValueError(f"Missing transparency: {name}")
        manifest = next(n for n in archive.namelist() if n.endswith("/manifesto_conexoes.json"))
        data = json.loads(archive.read(manifest))
        (target / "manifesto_conexoes.json").write_text(json.dumps(data, indent=2), encoding="utf-8")
    source = Image.open(root / "Assets" / "Cenarios" / "Exterior" / "PC_Store_Com_Telhado.png")
    cut(source, [(232,202),(772,0),(1465,246),(1465,648),(992,873),(935,848),
                 (935,817),(831,782),(745,756),(551,719),(470,697),(233,640)],
        target / "pc_store_recorte.png", additions=[
            [(475,667),(550,691),(552,731),(532,747),(474,729)],
            [(749,756),(782,739),(836,758),(837,810),(799,833),(748,816)],
            [(936,846),(970,825),(1005,846),(1006,924),(975,943),(935,924)]
        ])
    cut(source, [(94,576),(121,564),(124,533),(133,525),(233,560),(238,579),
                 (231,612),(225,619),(225,648),(215,653),(205,643),(205,621),
                 (112,595),(109,625),(99,629),(96,598),(90,590)],
        target / "banco_recorte.png",
        [[(114,603),(201,632),(201,658),(111,632)]])
    cut(source, [(235,578),(248,578),(252,584),(255,615),(250,620),(251,685),
                 (256,691),(257,733),(265,739),(265,747),(247,754),(227,749),
                 (225,738),(232,731),(233,693),(237,686),(237,621),(230,612),(230,587)],
        target / "poste_recorte.png")
    print(f"Imported {len(names)} tiles and three masked exterior layers. Original preserved.")


if __name__ == "__main__":
    main()
