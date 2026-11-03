"""Pixel-level asset checks. Run with Python and Pillow."""
import json
import hashlib
import csv
import unittest
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
KIT = ROOT / "Assets" / "Cenarios" / "Modular"


class AssetsTest(unittest.TestCase):
    def test_vizinhanca_manifest_and_states(self):
        folder = ROOT / "Assets" / "Cenarios" / "Vizinhanca"
        with (folder / "manifesto.csv").open(encoding="utf-8-sig", newline="") as manifest:
            rows = list(csv.DictReader(manifest))
        self.assertEqual(len(rows), 50)
        self.assertEqual(len(list(folder.rglob("*.png"))), 50)
        by_id = {Path(row["arquivo"]).stem: row for row in rows}
        self.assertEqual(len(by_id), 50)
        for row in rows:
            with self.subTest(file=row["arquivo"]), Image.open(folder / row["arquivo"]) as image:
                self.assertEqual(image.mode, "RGBA")
                self.assertEqual(image.size, (int(row["largura_px"]), int(row["altura_px"])))
                self.assertEqual(image.getchannel("A").getextrema(), (0, 255))
                box = image.getbbox()
                self.assertGreater(min(box[:2]), 0)
                self.assertLess(box[2], image.width)
                self.assertLess(box[3], image.height)
                self.assertTrue(0 <= int(row["pivo_x"]) < image.width)
                self.assertTrue(0 <= int(row["pivo_y"]) < image.height)
        for a, b in [("poste_iluminacao", "poste_iluminacao_aceso"), ("placa_aberto", "placa_fechado")]:
            for key in ["largura_px", "altura_px", "pivo_x", "pivo_y"]:
                self.assertEqual(by_id[a][key], by_id[b][key])

    def test_commercial_street_material(self):
        image = Image.open(ROOT / "Assets" / "Cenarios" / "Bairro" / "asfalto_continuo.png")
        self.assertEqual(image.size, (512, 512))
        self.assertEqual(image.mode, "RGB")
        self.assertEqual(image.crop((0, 0, 1, 512)).tobytes(), image.crop((511, 0, 512, 512)).tobytes())
        self.assertEqual(image.crop((0, 0, 512, 1)).tobytes(), image.crop((0, 511, 512, 512)).tobytes())
        self.assertEqual(image.crop((255, 0, 256, 512)).tobytes(), image.crop((256, 0, 257, 512)).tobytes())
        self.assertEqual(image.crop((0, 255, 512, 256)).tobytes(), image.crop((0, 256, 512, 257)).tobytes())

    def test_cafe_projection_and_source(self):
        folder = ROOT / "Assets" / "Cenarios" / "Bairro"
        data = json.loads((folder / "cafeteria.json").read_text(encoding="utf-8"))
        source = folder / "Fontes" / "cafeteria_original.png"
        self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), data["source_sha256"])
        image = Image.open(folder / "cafeteria.png")
        alpha = image.getchannel("A")
        self.assertEqual(set(alpha.tobytes()), {0, 255})
        x0, y0, x1, y1 = alpha.getbbox()
        self.assertGreater(min(x0, y0), 0)
        self.assertLess(x1, image.width)
        self.assertLess(y1, image.height)
        left, right, back = data["front_left"], data["front_right"], data["back_right"]
        self.assertAlmostEqual((right[1] - left[1]) / (right[0] - left[0]), 20 / 64)
        self.assertAlmostEqual((back[1] - right[1]) / (back[0] - right[0]), -32 / 64)

    def test_neighborhood_tiles(self):
        folder = ROOT / "Assets" / "Cenarios" / "Bairro"
        manifest = json.loads((folder / "manifesto_conexoes.json").read_text(encoding="utf-8"))
        names = [name for group in manifest["categories"].values() for name in group]
        self.assertEqual(len(names), 20)
        for name in names:
            with self.subTest(tile=name):
                image = Image.open(folder / f"{name}.png")
                self.assertEqual(image.size, (128, 64))
                self.assertEqual(image.mode, "RGBA")
                alpha = image.getchannel("A")
                self.assertEqual(alpha.getextrema(), (0, 255))
                for y in range(2, 62):
                    for x in range(2, 126):
                        if abs(x + 0.5 - 64) / 64 + abs(y + 0.5 - 32) / 32 < 0.95:
                            self.assertGreater(alpha.getpixel((x, y)), 0, (name, x, y))

    def test_exterior_cutouts_preserve_original_pixels(self):
        source = Image.open(ROOT / "Assets" / "Cenarios" / "Exterior" / "PC_Store_Com_Telhado.png").convert("RGB")
        for name in ["pc_store_recorte", "banco_recorte", "poste_recorte"]:
            with self.subTest(layer=name):
                image = Image.open(ROOT / "Assets" / "Cenarios" / "Bairro" / f"{name}.png")
                self.assertEqual(image.mode, "RGBA")
                self.assertEqual(image.size, source.size)
                self.assertEqual(image.convert("RGB").tobytes(), source.tobytes())
                self.assertEqual(image.getchannel("A").getextrema(), (0, 255))

    def test_kit_dimensions_and_alpha(self):
        manifest = json.loads((KIT / "manifest_encaixes.json").read_text(encoding="utf-8"))
        for item in manifest["assets"]:
            with self.subTest(asset=item["id"]):
                image = Image.open(KIT / Path(item["file"]).name)
                self.assertEqual(list(image.size), item["size_px"])
                self.assertEqual(image.mode, "RGBA")
                self.assertEqual(set(image.getchannel("A").tobytes()), {0, 255})

    def test_repeated_floor_has_no_internal_holes(self):
        tiles = [Image.open(KIT / f"piso_madeira_clara_{v}.png") for v in "abc"]
        for columns, rows in [(6, 5), (8, 7)]:
            with self.subTest(size=(columns, rows)):
                width, height = (columns + rows) * 64, (columns + rows) * 32
                canvas = Image.new("RGBA", (width, height))
                origin_x = rows * 64
                for u in range(columns):
                    for v in range(rows):
                        canvas.alpha_composite(tiles[(u * 7 + v * 11) % 3],
                                               (origin_x + 64 * (u - v) - 64, 32 * (u + v)))
                alpha = canvas.getchannel("A")
                holes = []
                for y in range(height):
                    for x in range(width):
                        u = (x + 0.5 - origin_x) / 128 + (y + 0.5) / 64
                        v = (y + 0.5) / 64 - (x + 0.5 - origin_x) / 128
                        if 0.03 < u < columns - 0.03 and 0.03 < v < rows - 0.03 and alpha.getpixel((x, y)) == 0:
                            holes.append((x, y))
                self.assertEqual(len(holes), 0, f"Floor gaps: {holes[:10]}")

    def test_character_pivots_and_padding(self):
        files = list((ROOT / "Assets" / "Personagens" / "Modulares").rglob("*.png"))
        self.assertEqual(len(files), 36)
        for file in files:
            with self.subTest(file=file.name):
                image = Image.open(file)
                self.assertEqual(image.size, (160, 240))
                alpha = image.getchannel("A")
                box = alpha.getbbox()
                self.assertEqual(box[3], 232)
                self.assertGreater(box[0], 0)
                self.assertLess(box[2], 160)

    def test_furniture_padding(self):
        files = list((ROOT / "Assets" / "Moveis" / "Modulares").glob("*.png"))
        self.assertEqual(len(files), 11)
        for file in files:
            with self.subTest(file=file.name):
                image = Image.open(file)
                self.assertEqual(image.mode, "RGBA")
                self.assertEqual(image.getchannel("A").getbbox(), (8, 8, image.width - 8, image.height - 8))


if __name__ == "__main__":
    unittest.main()
