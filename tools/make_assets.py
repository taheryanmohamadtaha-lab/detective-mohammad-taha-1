"""Generates backgrounds, character crops and procedural audio.
Run: python3 tools/make_assets.py <photo.png>
All files are written into assets/ and icon.png (no network needed)."""
import sys, random, wave
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

photo = sys.argv[1]
im = Image.open(photo).convert("RGB")
W, H = im.size
# --- character images (derived from the supplied photo; identity preserved) ---
full = im.resize((1024, 1024), Image.LANCZOS)
full.save("assets/characters/detective_full.jpg", quality=90)
face = im.crop((int(W*0.115), int(H*0.04), int(W*0.865), int(H*0.79))).resize((640, 640), Image.LANCZOS)
face.save("assets/characters/detective_portrait.png")
noir = ImageEnhance.Color(face).enhance(0.8)
noir = ImageEnhance.Contrast(noir).enhance(1.1)
noir = Image.blend(noir, Image.new("RGB", noir.size, (20, 34, 64)), 0.12)
vig = Image.new("L", noir.size, 0)
ImageDraw.Draw(vig).ellipse((-60, -60, 700, 700), fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(70))
noir = Image.composite(noir, Image.new("RGB", noir.size, (8, 12, 22)), vig)
noir.save("assets/characters/detective_noir.png")
noir.resize((200, 200), Image.LANCZOS).save("assets/characters/detective_dialogue.png")
noir.resize((192, 192), Image.LANCZOS).save("icon.png")
s = Image.new("RGB", (200, 200), (30, 40, 58))
d = ImageDraw.Draw(s)
d.ellipse((60, 30, 140, 120), fill=(120, 132, 154))
d.ellipse((20, 120, 180, 300), fill=(120, 132, 154))
s.save("assets/characters/npc.png")

BW, BH = 720, 1280


def grad(top, bot):
    a = np.linspace(0, 1, BH)[:, None, None]
    t = np.array(top)[None, None, :]
    b = np.array(bot)[None, None, :]
    return Image.fromarray((t*(1-a) + b*a).repeat(BW, axis=1).astype("uint8"))


def finish(img, name, rain=False, glow=None):
    d = ImageDraw.Draw(img, "RGBA")
    if rain:
        r = random.Random(7)
        for _ in range(260):
            x = r.randint(0, BW); y = r.randint(0, BH)
            d.line((x, y, x-6, y+34), fill=(190, 205, 230, 70), width=2)
    img = img.convert("RGB")
    if glow:
        g = Image.new("RGBA", img.size, (0, 0, 0, 0))
        ImageDraw.Draw(g).ellipse((glow[0]-260, glow[1]-260, glow[0]+260, glow[1]+260), fill=(255, 190, 90, 90))
        g = g.filter(ImageFilter.GaussianBlur(90))
        img = Image.alpha_composite(img.convert("RGBA"), g).convert("RGB")
    v = Image.new("L", img.size, 0)
    ImageDraw.Draw(v).ellipse((-200, -150, BW+200, BH+150), fill=255)
    v = v.filter(ImageFilter.GaussianBlur(160))
    img = Image.composite(img, Image.new("RGB", img.size, (4, 6, 12)), v)
    img.save(f"assets/backgrounds/{name}.jpg", quality=82)


def buildings(img, seed, base, col, win=(255, 200, 110), density=0.3):
    d = ImageDraw.Draw(img)
    r = random.Random(seed)
    x = -20
    while x < BW:
        w = r.randint(90, 190); h = r.randint(300, 780)
        d.rectangle((x, base-h, x+w, BH), fill=col)
        for wy in range(base-h+30, base-20, 46):
            for wx in range(x+14, x+w-24, 34):
                if r.random() < density:
                    d.rectangle((wx, wy, wx+16, wy+24), fill=win)
        x += w+6


def make():
    img = grad((20, 28, 46), (34, 38, 56)); d = ImageDraw.Draw(img)  # office
    d.rectangle((0, 900, BW, BH), fill=(44, 30, 22))
    buildings(img, 1, 520, (16, 22, 38), density=0.25)
    d.rectangle((80, 140, 640, 520), outline=(70, 60, 50), width=14)
    d.line((360, 140, 360, 520), fill=(70, 60, 50), width=10)
    d.rectangle((60, 820, 660, 880), fill=(70, 44, 28))
    d.rectangle((90, 880, 120, 1100), fill=(55, 34, 22)); d.rectangle((600, 880, 630, 1100), fill=(55, 34, 22))
    d.polygon([(500, 820), (540, 700), (580, 700), (620, 820)], fill=(40, 60, 50))
    finish(img, "office", glow=(560, 720))

    img = grad((10, 16, 32), (26, 30, 44)); buildings(img, 2, 1000, (14, 18, 30), density=0.22)  # street
    d = ImageDraw.Draw(img); d.rectangle((0, 1000, BW, BH), fill=(22, 26, 36))
    d.rectangle((120, 600, 134, 1010), fill=(40, 44, 54))
    finish(img, "street_rain", rain=True, glow=(127, 600))

    img = grad((18, 20, 40), (40, 30, 34)); d = ImageDraw.Draw(img)  # mansion
    d.rectangle((60, 380, 660, 1000), fill=(34, 26, 28)); d.polygon([(40, 380), (360, 190), (680, 380)], fill=(26, 20, 24))
    for wx in (120, 300, 480):
        for wy in (460, 700):
            d.rectangle((wx, wy, wx+90, wy+140), fill=(255, 196, 110) if (wx+wy) % 3 else (40, 40, 60))
    d.rectangle((310, 840, 410, 1000), fill=(60, 40, 30)); d.rectangle((0, 1000, BW, BH), fill=(18, 30, 22))
    finish(img, "mansion", glow=(360, 900))

    img = grad((30, 22, 28), (50, 32, 30)); d = ImageDraw.Draw(img)  # hotel
    d.polygon([(0, 0), (260, 400), (260, 900), (0, 1280)], fill=(60, 36, 34))
    d.polygon([(720, 0), (460, 400), (460, 900), (720, 1280)], fill=(60, 36, 34))
    d.rectangle((260, 400, 460, 900), fill=(26, 18, 22)); d.rectangle((300, 520, 420, 900), fill=(84, 52, 36))
    finish(img, "hotel", glow=(360, 360))

    img = grad((14, 16, 22), (28, 30, 38)); d = ImageDraw.Draw(img)  # interrogation
    d.rectangle((0, 900, BW, BH), fill=(30, 32, 38)); d.rectangle((140, 760, 580, 820), fill=(80, 84, 94))
    d.rectangle((160, 820, 190, 1000), fill=(60, 64, 72)); d.rectangle((530, 820, 560, 1000), fill=(60, 64, 72))
    d.rectangle((200, 200, 520, 460), fill=(34, 44, 56))
    finish(img, "interrogation", glow=(360, 60))

    img = grad((20, 22, 26), (36, 32, 28)); d = ImageDraw.Draw(img); r = random.Random(5)  # archive
    for sx in (40, 380):
        d.rectangle((sx, 160, sx+300, 1100), fill=(52, 38, 28))
        for sy in range(190, 1080, 120):
            d.rectangle((sx+10, sy+96, sx+290, sy+104), fill=(30, 22, 16))
            bx = sx+14
            while bx < sx+280:
                bw = r.randint(14, 30); bh = r.randint(60, 92)
                d.rectangle((bx, sy+100-bh, bx+bw, sy+100), fill=(r.randint(70, 150), r.randint(50, 100), r.randint(40, 80)))
                bx += bw+3
    finish(img, "archive", glow=(360, 200))

    img = grad((14, 26, 34), (24, 40, 48)); d = ImageDraw.Draw(img)  # lab
    d.rectangle((0, 860, BW, 940), fill=(70, 86, 96)); d.rectangle((0, 940, BW, BH), fill=(26, 36, 42))
    for fx, c in ((120, (90, 220, 180)), (300, (120, 180, 255)), (480, (240, 190, 90))):
        d.rectangle((fx, 690, fx+70, 860), outline=(200, 220, 230), width=4)
        d.rectangle((fx+6, 760, fx+64, 856), fill=c)
    finish(img, "lab", glow=(360, 120))

    img = grad((16, 12, 14), (34, 24, 20)); d = ImageDraw.Draw(img); r = random.Random(11)  # hideout
    for i in range(14):
        x = r.randint(-20, 600); y = r.randint(760, 1120)
        d.rectangle((x, y, x+r.randint(90, 160), y+r.randint(70, 130)), fill=(70+i, 46, 30))
    d.rectangle((0, 1120, BW, BH), fill=(18, 14, 14))
    finish(img, "hideout", glow=(360, 500))


make()

SR = 22050


def save(name, arr):
    arr = np.clip(arr, -1, 1)
    data = (arr*32767).astype("<i2")
    with wave.open(f"assets/audio/{name}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())


rng = np.random.default_rng(3)
n = SR*6
rain = np.convolve(rng.normal(0, 1, n), np.ones(6)/6, mode="same")
drops = (rng.random(n) > 0.9992) * rng.normal(0, 4, n)
rain = rain*0.35 + np.convolve(drops, np.ones(30)/30, mode="same")
rain[:800] *= np.linspace(0, 1, 800); rain[-800:] *= np.linspace(1, 0, 800)
save("rain", rain*0.6)
t = np.arange(SR*8)/SR
drone = 0.35*np.sin(2*np.pi*55*t) + 0.25*np.sin(2*np.pi*82.5*t+0.4) + 0.12*np.sin(2*np.pi*110*t)
drone *= 0.75 + 0.25*np.sin(2*np.pi*(1/8)*t)
mel = np.zeros_like(t)
for i, f in enumerate([220, 261.6, 246.9, 196]):
    s0 = int(i*2*SR); seg = t[s0:s0+2*SR]-t[s0]
    mel[s0:s0+2*SR] = 0.10*np.sin(2*np.pi*f*seg)*np.exp(-seg*1.6)
save("drone", (drone+mel)*0.7)
tt = np.arange(int(SR*0.06))/SR; save("click", np.sin(2*np.pi*900*tt)*np.exp(-tt*70)*0.6)
tt = np.arange(int(SR*0.5))/SR; save("found", (np.sin(2*np.pi*660*tt)+np.sin(2*np.pi*990*tt)*0.7)*np.exp(-tt*6)*0.4)
tt = np.arange(int(SR*0.4))/SR; save("wrong", np.sin(2*np.pi*150*tt)*np.exp(-tt*7)*0.7)
print("assets ok")
