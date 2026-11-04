"""Render original pixel-art samples from independent 3D views using Pillow.

Run from the repository root: python tools/create_visual_preview.py
This writes only Assets/Cenarios/PreviaVisual, never the approved source art.
The projection matches the existing exterior, not the interior's 2:1 grid.
"""
import json
import math
from array import array
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "Assets" / "Cenarios" / "PreviaVisual"
VIEWS = {"baixo_direita": 0, "baixo_esquerda": 90,
         "cima_esquerda": 180, "cima_direita": 270}


def color(value, factor=1):
    rgb = tuple(bytes.fromhex(value.lstrip("#")))
    return tuple(max(0, min(255, round(v * factor))) for v in rgb) + (255,)


def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2],
            a[0]*b[1]-a[1]*b[0])


class Scene:
    def __init__(self, size, pivot, pixels, angle=0):
        self.size, self.pivot, self.pixels = size, pivot, pixels
        self.angle = math.radians(angle)
        self.faces = []

    def transform(self, p):
        c, s = math.cos(self.angle), math.sin(self.angle)
        x, y, z = p
        return (round(x*c-y*s, 8), round(x*s+y*c, 8), z)

    def project(self, p):
        x, y, z = p
        return (round(self.pivot[0]+self.pixels*(x-y)),
                round(self.pivot[1]+self.pixels*(x*.3125+y*.5-z)))

    def face(self, points, paint, shade=True, edge=None):
        points = [self.transform(p) for p in points]
        a = tuple(points[1][i]-points[0][i] for i in range(3))
        b = tuple(points[2][i]-points[0][i] for i in range(3))
        n = cross(a, b)
        length = math.sqrt(sum(v*v for v in n))
        if length < 1e-8:
            return
        # Camera ray is (1, 1, .8125), the nullspace of the exterior projection.
        if n[0]+n[1]+n[2]*.8125 <= 1e-8:
            return
        light = (n[0]*-.3+n[1]*-.5+n[2]*.81)/length
        factor = .78+.25*max(-.4, light) if shade else 1
        depths = [p[0]+p[1]+p[2]*.8125 for p in points]
        self.faces.append((depths, [self.project(p) for p in points],
                           color(paint, factor), color(edge) if edge else None))

    def box(self, lo, hi, paint, edge=None):
        x, y, z = lo
        X, Y, Z = hi
        self.face([(x,y,Z),(X,y,Z),(X,Y,Z),(x,Y,Z)], paint, edge=edge)
        self.face([(X,Y,z),(x,Y,z),(x,Y,Z),(X,Y,Z)], paint, edge=edge)
        self.face([(x,y,z),(X,y,z),(X,y,Z),(x,y,Z)], paint, edge=edge)
        self.face([(X,y,z),(X,Y,z),(X,Y,Z),(X,y,Z)], paint, edge=edge)
        self.face([(x,Y,z),(x,y,z),(x,y,Z),(x,Y,Z)], paint, edge=edge)

    def wall(self, x, X, z, Z, paint, y=.025, edge=None):
        self.face([(X,y,z),(x,y,z),(x,y,Z),(X,y,Z)], paint,
                  shade=False, edge=edge)

    def render(self, path, shadow):
        image = Image.new("RGBA", self.size)
        draw = ImageDraw.Draw(image)
        draw.polygon([self.project(self.transform(p)) for p in shadow],
                     fill=(17, 24, 35, 75))
        width, height = self.size
        depth_buffer = array("f", [-math.inf]) * (width*height)
        pixels = image.load()
        for depths, points, paint, edge in self.faces:
            for i in range(1, len(points)-1):
                triangle = [points[0], points[i], points[i+1]]
                values = [depths[0], depths[i], depths[i+1]]
                (ax, ay), (bx, by), (cx, cy) = triangle
                area = (by-cy)*(ax-cx)+(cx-bx)*(ay-cy)
                if area == 0:
                    continue
                for y in range(max(0,min(ay,by,cy)), min(height,max(ay,by,cy)+1)):
                    for x in range(max(0,min(ax,bx,cx)), min(width,max(ax,bx,cx)+1)):
                        a = ((by-cy)*(x-cx)+(cx-bx)*(y-cy))/area
                        b = ((cy-ay)*(x-cx)+(ax-cx)*(y-cy))/area
                        c = 1-a-b
                        if min(a,b,c) < -1e-8:
                            continue
                        depth = a*values[0]+b*values[1]+c*values[2]
                        index = y*width+x
                        if depth >= depth_buffer[index]-1e-6:
                            depth_buffer[index] = depth
                            pixels[x,y] = paint
            if edge:
                for i, (x0,y0) in enumerate(points):
                    j = (i+1) % len(points)
                    x1,y1 = points[j]
                    steps = max(abs(x1-x0),abs(y1-y0),1)
                    for step in range(steps+1):
                        t = step/steps
                        x,y = round(x0+(x1-x0)*t),round(y0+(y1-y0)*t)
                        depth = depths[i]+(depths[j]-depths[i])*t+.002
                        if 0 <= x < width and 0 <= y < height and depth >= depth_buffer[y*width+x]:
                            depth_buffer[y*width+x] = depth
                            pixels[x,y] = edge
        image.save(path)
        return image


def wheel(scene, x, y):
    side = 1 if y > 0 else -1
    for radius, offset, paint in [(.46, 0, "17202a"), (.36, .012, "303c4c"),
                                   (.255, .022, "a0b0ba"), (.17, .03, "354856"),
                                   (.07, .04, "b9c9cf")]:
        circle = [(x+radius*math.cos(t*math.tau/24), y+side*offset,
                   .46+radius*math.sin(t*math.tau/24)) for t in range(24)]
        if side > 0:
            circle.reverse()
        scene.face(circle, paint, shade=False)
    for i in range(5):
        a = i*math.tau/5
        points = []
        for r, b in [(.09, a-.15), (.24, a-.07), (.24, a+.07), (.09, a+.15)]:
            points.append((x+r*math.cos(b), y+side*.035, .46+r*math.sin(b)))
        if side > 0:
            points.reverse()
        scene.face(points, "b0bfc9", shade=False)


def vehicle(angle, pickup=False):
    scene = Scene((512, 320), (256, 220), 50, angle)
    paint = "ca3938" if pickup else "277cbd"
    light = "ed6a4c" if pickup else "58b3d3"
    length = 2.35 if pickup else 2.15
    scene.box((-length,-.90,.43), (length,.90,.87), paint, "182c40")
    scene.box((-length+.08,-.92,.47), (length-.1,.92,.57), "26394a")
    scene.box((1.1,-.86,.87), (length-.07,.86,1.0), paint)
    scene.box((-length,-.84,.87), (-1.38,.84,1.03), paint)
    back = -.45 if pickup else -1.32
    roof_back = -.3 if pickup else -.96
    roof_z = 1.83 if pickup else 1.66
    # Cabin is a tapered volume, not a rotated photograph.
    bottom = [(back,-.86,1.0),(1.12,-.86,1.0),
              (1.12,.86,1.0),(back,.86,1.0)]
    top = [(roof_back,-.64,roof_z),(.55,-.64,roof_z),
           (.55,.64,roof_z),(roof_back,.64,roof_z)]
    scene.face(top, paint, edge="28475d")
    for i in range(4):
        scene.face([bottom[i],bottom[(i+1)%4],top[(i+1)%4],top[i]],
                   paint, edge="243c51")
    # Front and rear windows follow the actual sloping cabin surfaces.
    for front in (True, False):
        z0, z1 = 1.09, roof_z-.085
        t0, t1 = (z0-1)/(roof_z-1), (z1-1)/(roof_z-1)
        lower, upper = (1.12,.55) if front else (back,roof_back)
        offset = .014 if front else -.014
        x0, x1 = lower+(upper-lower)*t0+offset, lower+(upper-lower)*t1+offset
        w0, w1 = .86-.22*t0-.045, .86-.22*t1-.045
        points = [(x0,-w0,z0),(x0,w0,z0),(x1,w1,z1),(x1,-w1,z1)]
        if not front:
            points.reverse()
        scene.face(points, "18374d", shade=False, edge="91abb4")
        # A narrow highlight, not a semi-opaque white windshield.
        stripe = [(x0,-.58,z0+.005),(x0,-.42,z0+.005),
                  (x1,.05,z1+.005),(x1,-.11,z1+.005)]
        if not front:
            stripe.reverse()
        scene.face(stripe, "47778e", shade=False)
    for side in (-1, 1):
        for left, right in [(back+.12, -.18), (-.10, .96)]:
            if right <= left:
                continue
            upper_left = max(roof_back+.06, left+.18)
            upper_right = min(.48, right-.15)
            if upper_right <= upper_left:
                continue
            points = [(left,side*.846,1.075),(right,side*.846,1.075),
                      (upper_right,side*.677,roof_z-.08),
                      (upper_left,side*.677,roof_z-.08)]
            if side > 0:
                points.reverse()
            scene.face(points, "26485c", shade=False, edge="769aa9")
        # Door seams, handles, side mirrors and sill highlights.
        for x in [-.12, back+.04]:
            scene.box((x-.013,side*.914-.012,.61),
                      (x+.013,side*.914+.012,.96), "203c50")
        scene.box((-.36,side*.935-.025,.92), (-.16,side*.935+.025,.97), "b7d0d5")
        scene.box((.82,side*1.04-.07,1.06), (1.02,side*1.04+.07,1.18), paint)
        scene.box((-.95,side*.923-.008,.59), (1.13,side*.923+.008,.615), light)
        for x in (-1.44, 1.44):
            wheel(scene, x, side*.96)
    if pickup:
        # Open cargo bed has a floor and separate rails, visible from rear views.
        scene.box((-2.22,-.72,.89), (-.60,.72,.92), "283743")
        for y in (-.87,.78):
            scene.box((-2.28,y,.90), (-.53,y+.09,1.13), paint)
        scene.box((-2.31,-.85,.88), (-2.21,.85,1.12), paint)
        for x in [-1.9,-1.55,-1.2,-.85]:
            scene.box((x,-.69,.92), (x+.035,.69,.94), "46545d")
    else:
        scene.box((-1.03,-.52,roof_z+.01), (.48,-.47,roof_z+.045), "34424f")
        scene.box((-1.03,.47,roof_z+.01), (.48,.52,roof_z+.045), "34424f")
    # Distinct headlights, grille and taillights allow semantic direction tests.
    for side in (-1, 1):
        y = side*.65
        scene.box((length+.005,y-.15,.72), (length+.02,y+.15,.88), "ffe8a6")
        scene.box((-length-.02,y-.14,.66), (-length-.005,y+.14,.86), "e96b52")
    scene.box((length+.025,-.43,.57), (length+.04,.43,.70), "142733")
    for z in [.59,.63,.67]:
        scene.box((length+.045,-.38,z), (length+.05,.38,z+.012), "77939d")
    scene.box((length+.052,-.15,.59), (length+.06,.15,.65), "c1c8b3")
    scene.box((-length-.03,-.18,.56), (-length-.02,.18,.64), "c1c8b3")
    return scene


def shop():
    # Same footprint and door scale as the approved neighborhood. Extra canvas
    # padding moves every landmark equally, so collision geometry is unchanged.
    origin = (62, 404.4375)
    scene = Scene((704, 576), origin, 55)
    width, depth = 394/55, 168/55
    scene.box((0,-depth,0), (width,0,4.90), "d9c6a0", "51504c")
    scene.box((0,-depth,0), (width,.035,.28), "365f4b")
    # Facade stone joints and reliefs.
    for z in [3.18,3.55,4.05,4.55]:
        scene.wall(0,width,z,z+.025,"b6a384",.045)
    for x in [0,.28,2.50,4.82,width-.28]:
        scene.box((x,-.03,.28), (x+.22,.15,4.64), "d8c49c")
        scene.box((x-.035,-.04,.28), (x+.255,.17,.43), "9b906f")
    for x, X in [(.52,2.40),(2.86,4.56),(5.15,width-.48)]:
        scene.wall(x-.06,X+.06,.40,3.16,"244839",.08)
        scene.wall(x,X,.47,3.08,"284e53",.09, "b6c09d")
        scene.wall(x+.04,X-.04,2.85,3.04,"527977",.10)
        # Shelves, bottles, jars and crates behind the window.
        for z in [.72,1.25,1.80,2.35]:
            scene.wall(x+.06,X-.06,z-.055,z,"ab8050",.11)
            for i in range(max(1, int((X-x)/.21))):
                p = x+.1+i*.21
                hue = ["d9a24d","73924d","c36543","d1c393"][i % 4]
                scene.wall(p,p+.12,z+.03,z+.29,hue,.12)
                scene.wall(p+.035,p+.085,z+.29,z+.35,"a8b095",.121)
        # Narrow pane reflections leave the goods readable.
        scene.wall(x+.12,x+.19,.55,2.78,"75928b",.14)
        for p in [x, (x+X)/2, X-.035]:
            scene.wall(p,p+.035,.45,3.10,"57765b",.15)
    # Central walk-in door: 1.45 m wide, 2.55 m high, no stretched human scale.
    scene.wall(2.84,4.56,.36,3.13,"b6aa78",.17)
    scene.wall(2.92,4.48,.42,3.06,"203e43",.18)
    scene.wall(3.00,4.40,.56,2.93,"3e6668",.19)
    scene.wall(3.00,4.40,.58,.94,"295449",.20)
    scene.wall(4.10,4.14,1.2,1.74,"d1c99c",.22)
    scene.wall(2.80,4.62,.24,.34,"b6b09b",.24)
    # Sign, striped awning and lighting, all separately projected.
    scene.wall(.40,width-.40,3.67,4.47,"214737",.17,"6e9561")
    mask = Image.new("L", (90, 14))
    ImageDraw.Draw(mask).text((0,0), "MERCADO", font=ImageFont.load_default(),
                             fill=255, stroke_width=0)
    bounds = mask.getbbox()
    mask = mask.crop(bounds)
    step = min(5.3/mask.width, .47/mask.height)
    start = (width-mask.width*step)/2
    for y in range(mask.height):
        for x in range(mask.width):
            if mask.getpixel((x,y)) >= 120:
                scene.wall(start+x*step,start+(x+1)*step,
                           4.12-y*step,4.12-(y-1)*step,"eadab0",.18)
    for i in range(18):
        x, X = .12+i*(width-.24)/18, .12+(i+1)*(width-.24)/18
        paint = "eee0bb" if i % 2 else "c7663e"
        scene.face([(x,.10,3.58),(X,.10,3.58),(X,.74,3.27),(x,.74,3.27)],
                   paint, edge="866748")
        scene.wall(x,X,3.10,3.27,paint,.74)
    for x in [.32,width-.32]:
        scene.box((x-.075,.18,2.65), (x+.075,.34,2.92), "e8c273")
        scene.box((x-.10,.16,2.91), (x+.10,.37,2.96), "333e3b")
    # Side wall masonry/window and a tiled, raised parapet.
    for z in [.8,1.6,2.4,3.2,4.0]:
        scene.box((width+.004,-depth,z), (width+.016,-.04,z+.018), "b9aa89")
    scene.box((width+.02,-2.62,1.0), (width+.06,-.55,3.05), "47615c")
    scene.box((width+.065,-2.53,1.10), (width+.075,-.64,2.95), "6a8b83")
    scene.box((width+.08,-1.62,1.1), (width+.10,-1.56,2.95), "b4b99e")
    scene.box((-.08,-depth-.08,4.85), (width+.08,.08,4.98), "385b48")
    scene.box((.05,-depth+.05,4.99), (width-.05,-.05,5.02), "50515b")
    for x in range(1,8):
        scene.box((x*.85,-depth+.06,5.025), (x*.85+.016,-.06,5.04), "696977")
    for y in [-.8,-1.6,-2.4]:
        scene.box((.06,y,5.025), (width-.06,y+.016,5.04), "696977")
    scene.box((1.05,-2.35,5.03), (2.12,-1.60,5.62), "b1aea1", "5a6565")
    for z in [5.15,5.25,5.35,5.45]:
        scene.wall(1.13,2.04,z,z+.035,"4b595c",-1.585)
    landmarks = {"pivo":[259,463], "frente":[62,404.4375],
                 "canto":[456,527.5625], "fundo":[624,443.5625]}
    return scene, landmarks


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    manifest = {"status":"amostra_pendente_aprovacao", "projecao":{"u":[64,20],"v":[-64,32]},
                "carros":{}, "lojas":{}}
    for name, pickup in [("carro_azul",False), ("picape_vermelha",True)]:
        entries = {}
        for view, angle in VIEWS.items():
            path = OUTPUT / f"{name}_{view}.png"
            scene = vehicle(angle, pickup)
            shadow = [(2.65*math.cos(i*math.tau/48),
                       1.17*math.sin(i*math.tau/48),0) for i in range(48)]
            scene.render(path, shadow)
            entries[view] = {"arquivo":path.name,"pivo":[256,220],"escala":1.0,
                             "angulo_modelo":angle}
        manifest["carros"][name] = entries
    scene, landmarks = shop()
    scene.render(OUTPUT / "mercadinho.png",
                 [(-.1,-3.15,0),(7.35,-3.15,0),(7.35,.24,0),(-.1,.24,0)])
    manifest["lojas"]["mercadinho"] = {"arquivo":"mercadinho.png", **landmarks}
    (OUTPUT / "manifesto.json").write_text(json.dumps(manifest, indent=2)+"\n", encoding="utf-8")
    print("Created 8 independent vehicle views and 1 storefront; originals unchanged.")


if __name__ == "__main__":
    main()
