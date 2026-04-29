from __future__ import annotations

import argparse
import json
import math
import random
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
CARDS_JSON = ROOT / "data" / "tables" / "cards.json"
MANIFEST_JSON = ROOT / "tools" / "card_icon_manifest.json"
OUTPUT_DIR = ROOT / "assets" / "ui" / "icons" / "cards"
MANIFEST_PATH = OUTPUT_DIR / "_manifest.json"
SIZE = 512


@dataclass(frozen=True)
class Palette:
	base: tuple[int, int, int]
	bright: tuple[int, int, int]
	glow: tuple[int, int, int]
	dark: tuple[int, int, int]
	accent: tuple[int, int, int]


PALETTES: dict[int, Palette] = {
	1: Palette((214, 217, 222), (246, 247, 250), (226, 229, 236), (46, 50, 58), (164, 170, 182)),
	2: Palette((72, 208, 118), (187, 255, 207), (92, 240, 154), (21, 57, 37), (124, 255, 168)),
	3: Palette((63, 156, 255), (195, 234, 255), (93, 196, 255), (18, 42, 73), (132, 222, 255)),
	4: Palette((179, 95, 255), (231, 204, 255), (203, 126, 255), (44, 21, 69), (232, 146, 255)),
	5: Palette((255, 164, 54), (255, 229, 176), (255, 197, 88), (69, 35, 10), (255, 214, 112)),
	6: Palette((232, 68, 76), (255, 207, 211), (255, 108, 114), (73, 15, 22), (255, 164, 139)),
}


KEYWORD_MOTIFS: list[tuple[tuple[str, ...], tuple[str, ...]]] = [
	(("刃", "剑", "刀", "斩", "锋", "刺", "杀", "斧"), ("blade", "crescent_blade")),
	(("爪", "撕", "裂"), ("claw",)),
	(("盾", "壁", "甲", "护", "卫", "审判"), ("shield", "holy_cross")),
	(("心", "血", "命", "生", "愈", "不朽"), ("heart", "blood_drop")),
	(("眼", "视", "察", "洞"), ("eye",)),
	(("月", "影", "暗", "夜"), ("moon", "rune_obelisk")),
	(("炎", "火", "熔", "爆", "焰"), ("flame", "meteor")),
	(("雷", "风暴", "霆", "电"), ("lightning",)),
	(("风", "迅", "疾", "步", "速", "行"), ("wing", "swift_boot")),
	(("龙",), ("dragon_sigil",)),
	(("星", "辰", "轨"), ("star", "meteor")),
	(("晶", "宝", "能", "聚", "核", "石"), ("gem", "orb")),
	(("法", "术", "奥", "时", "符", "咒", "谕"), ("rune_obelisk", "hourglass")),
	(("圣", "光", "祷"), ("holy_cross", "crown")),
	(("书", "卷", "典", "指南", "学院"), ("book",)),
	(("宠", "兽"), ("beast_fang",)),
	(("弓", "矢", "弹幕"), ("meteor", "star")),
]


def clamp(value: float, low: float, high: float) -> float:
	return max(low, min(high, value))


def mix(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
	t = clamp(t, 0.0, 1.0)
	return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def rgba(color: tuple[int, int, int], alpha: int) -> tuple[int, int, int, int]:
	return color[0], color[1], color[2], alpha


def lighten(color: tuple[int, int, int], amount: float) -> tuple[int, int, int]:
	return mix(color, (255, 255, 255), amount)


def darken(color: tuple[int, int, int], amount: float) -> tuple[int, int, int]:
	return mix(color, (0, 0, 0), amount)


def regular_polygon(cx: float, cy: float, radius: float, sides: int, rotation: float = 0.0) -> list[tuple[float, float]]:
	points: list[tuple[float, float]] = []
	for idx in range(sides):
		angle = rotation + (math.tau * idx / sides)
		points.append((cx + math.cos(angle) * radius, cy + math.sin(angle) * radius))
	return points


def choose_motif(name: str, description: str, icon_id: str) -> str:
	text = f"{name} {description}"
	for keywords, motifs in KEYWORD_MOTIFS:
		if any(keyword in text for keyword in keywords):
			return motifs[int(icon_id) % len(motifs)]
	seed = sum(ord(ch) for ch in name + icon_id)
	fallbacks = ["orb", "gem", "star", "rune_obelisk", "meteor", "blade"]
	return fallbacks[seed % len(fallbacks)]


def create_background(draw: ImageDraw.ImageDraw, rng: random.Random, palette: Palette) -> None:
	draw.rounded_rectangle((0, 0, SIZE - 1, SIZE - 1), radius=64, fill=rgba(darken(palette.dark, 0.25), 255))
	for _ in range(14):
		sides = rng.randint(3, 6)
		cx = rng.uniform(-40, SIZE + 40)
		cy = rng.uniform(-40, SIZE + 40)
		radius = rng.uniform(80, 180)
		poly = regular_polygon(cx, cy, radius, sides, rng.uniform(0.0, math.tau))
		color = mix(palette.base, palette.glow, rng.uniform(0.1, 0.6))
		alpha = rng.randint(34, 86)
		draw.polygon(poly, fill=rgba(color, alpha))

	draw.rounded_rectangle((40, 40, SIZE - 40, SIZE - 40), radius=54, fill=rgba(darken(palette.dark, 0.12), 220), outline=rgba(lighten(palette.base, 0.15), 178), width=3)
	draw.rounded_rectangle((58, 58, SIZE - 58, SIZE - 58), radius=46, outline=rgba(lighten(palette.base, 0.25), 64), width=1)

	for idx in range(8):
		angle = math.tau * idx / 8.0 + rng.uniform(-0.08, 0.08)
		inner = 188
		outer = 222
		x1 = SIZE / 2 + math.cos(angle) * inner
		y1 = SIZE / 2 + math.sin(angle) * inner
		x2 = SIZE / 2 + math.cos(angle) * outer
		y2 = SIZE / 2 + math.sin(angle) * outer
		draw.line((x1, y1, x2, y2), fill=rgba(lighten(palette.accent, 0.25), 110), width=4)


def add_glow(base: Image.Image, palette: Palette, alpha_scale: float = 1.0) -> None:
	glow_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
	draw = ImageDraw.Draw(glow_layer)
	draw.ellipse((118, 118, SIZE - 118, SIZE - 118), fill=rgba(palette.glow, int(68 * alpha_scale)))
	draw.ellipse((160, 160, SIZE - 160, SIZE - 160), fill=rgba(lighten(palette.glow, 0.25), int(104 * alpha_scale)))
	glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(28))
	base.alpha_composite(glow_layer)


def add_sigil_ring(draw: ImageDraw.ImageDraw, rng: random.Random, palette: Palette) -> None:
	for idx in range(10):
		angle = math.tau * idx / 10.0 + rng.uniform(-0.05, 0.05)
		cx = SIZE / 2 + math.cos(angle) * 176
		cy = SIZE / 2 + math.sin(angle) * 176
		points = regular_polygon(cx, cy, rng.uniform(8, 14), 4, rotation=angle * 0.5)
		draw.polygon(points, fill=rgba(lighten(palette.base, 0.25), 120))


def draw_blade(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	blade = [(256, 104), (315, 244), (278, 344), (234, 344), (197, 244)]
	draw.polygon(blade, fill=rgba(lighten(palette.bright, 0.05), 255), outline=rgba(lighten(palette.base, 0.32), 220))
	draw.polygon([(256, 126), (290, 242), (256, 318), (223, 242)], fill=rgba(lighten(palette.glow, 0.12), 160))
	draw.rectangle((224, 338, 288, 360), fill=rgba(lighten(palette.accent, 0.12), 245))
	draw.rectangle((242, 360, 270, 420), fill=rgba(lighten(palette.base, 0.22), 245))
	draw.polygon([(206, 350), (306, 350), (328, 376), (184, 376)], fill=rgba(lighten(palette.base, 0.08), 230))


def draw_crescent_blade(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	draw.pieslice((122, 118, 390, 386), start=292, end=68, fill=rgba(lighten(palette.bright, 0.08), 255))
	draw.pieslice((174, 154, 340, 336), start=292, end=68, fill=rgba(darken(palette.dark, 0.18), 255))
	draw.rectangle((238, 264, 274, 416), fill=rgba(lighten(palette.base, 0.18), 245))
	draw.polygon([(214, 304), (300, 304), (324, 332), (190, 332)], fill=rgba(lighten(palette.accent, 0.08), 225))


def draw_claw(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	for offset in (-74, 0, 74):
		draw.polygon([(188 + offset, 132), (258 + offset, 212), (226 + offset, 372), (180 + offset, 352), (204 + offset, 214)], fill=rgba(lighten(palette.bright, 0.05), 240))
		draw.polygon([(212 + offset, 182), (232 + offset, 218), (206 + offset, 332)], fill=rgba(lighten(palette.glow, 0.2), 150))


def draw_shield(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	points = [(256, 104), (348, 150), (332, 286), (256, 388), (180, 286), (164, 150)]
	draw.polygon(points, fill=rgba(lighten(palette.base, 0.12), 245), outline=rgba(lighten(palette.bright, 0.15), 210))
	draw.polygon([(256, 134), (310, 164), (298, 274), (256, 334), (214, 274), (202, 164)], fill=rgba(lighten(palette.glow, 0.1), 155))
	draw.rectangle((242, 154, 270, 316), fill=rgba(lighten(palette.bright, 0.28), 215))
	draw.rectangle((196, 220, 316, 246), fill=rgba(lighten(palette.bright, 0.28), 215))


def draw_heart(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	draw.polygon([(256, 388), (154, 262), (170, 168), (228, 136), (256, 174), (284, 136), (342, 168), (358, 262)], fill=rgba(lighten(palette.glow, 0.02), 245), outline=rgba(lighten(palette.bright, 0.12), 210))
	draw.polygon([(256, 354), (182, 256), (192, 190), (228, 174), (256, 208), (284, 174), (320, 190), (330, 256)], fill=rgba(lighten(palette.bright, 0.12), 120))


def draw_blood_drop(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	draw.polygon([(256, 102), (334, 254), (308, 354), (256, 404), (204, 354), (178, 254)], fill=rgba(lighten(palette.glow, 0.0), 245), outline=rgba(lighten(palette.bright, 0.18), 200))
	draw.polygon([(256, 142), (304, 254), (286, 324), (256, 354), (226, 324), (208, 254)], fill=rgba(lighten(palette.bright, 0.15), 108))


def draw_eye(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	draw.polygon([(112, 256), (182, 186), (330, 186), (400, 256), (330, 326), (182, 326)], fill=rgba(lighten(palette.base, 0.15), 240), outline=rgba(lighten(palette.bright, 0.1), 220))
	draw.ellipse((198, 198, 314, 314), fill=rgba(lighten(palette.glow, 0.08), 235))
	draw.ellipse((226, 226, 286, 286), fill=rgba(darken(palette.dark, 0.35), 235))
	draw.ellipse((240, 212, 266, 238), fill=rgba(lighten(palette.bright, 0.4), 160))


def draw_moon(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	draw.ellipse((134, 114, 378, 358), fill=rgba(lighten(palette.base, 0.16), 245))
	draw.ellipse((206, 134, 394, 340), fill=rgba(darken(palette.dark, 0.08), 255))
	for idx in range(3):
		y = 200 + idx * 38
		draw.line((164, y, 278, y - 12), fill=rgba(lighten(palette.bright, 0.18), 120), width=6)


def draw_flame(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	draw.polygon([(256, 92), (324, 218), (304, 396), (256, 348), (208, 396), (188, 238)], fill=rgba(lighten(palette.glow, 0.04), 245), outline=rgba(lighten(palette.bright, 0.12), 210))
	draw.polygon([(256, 148), (294, 234), (278, 324), (256, 302), (234, 324), (218, 250)], fill=rgba(lighten(palette.bright, 0.18), 145))


def draw_lightning(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	points = [(296, 98), (198, 254), (252, 254), (204, 414), (320, 236), (262, 236)]
	draw.polygon(points, fill=rgba(lighten(palette.bright, 0.06), 245), outline=rgba(lighten(palette.glow, 0.18), 210))
	draw.polygon([(272, 136), (226, 218), (270, 218), (246, 312), (300, 236), (262, 236)], fill=rgba(lighten(palette.glow, 0.14), 120))


def draw_wing(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	for direction in (-1, 1):
		points = [(256, 244), (256 + 110 * direction, 152), (256 + 148 * direction, 178), (256 + 132 * direction, 238), (256 + 168 * direction, 298), (256 + 128 * direction, 328), (256 + 80 * direction, 310)]
		draw.polygon(points, fill=rgba(lighten(palette.base, 0.15), 245), outline=rgba(lighten(palette.bright, 0.12), 210))
	draw.ellipse((222, 214, 290, 282), fill=rgba(lighten(palette.glow, 0.12), 200))


def draw_swift_boot(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	draw.polygon([(176, 286), (246, 206), (302, 206), (338, 252), (314, 286), (250, 286), (290, 324), (168, 324)], fill=rgba(lighten(palette.base, 0.15), 245), outline=rgba(lighten(palette.bright, 0.1), 210))
	for idx in range(3):
		x = 142 + idx * 42
		draw.line((x, 282 - idx * 12, x + 58, 270 - idx * 12), fill=rgba(lighten(palette.glow, 0.18), 160), width=6)


def draw_gem(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	points = [(256, 96), (344, 176), (320, 316), (256, 402), (192, 316), (168, 176)]
	draw.polygon(points, fill=rgba(lighten(palette.base, 0.15), 245), outline=rgba(lighten(palette.bright, 0.12), 210))
	draw.polygon([(256, 118), (300, 182), (256, 364), (212, 182)], fill=rgba(lighten(palette.glow, 0.22), 118))
	draw.line((256, 96, 256, 402), fill=rgba(lighten(palette.bright, 0.26), 120), width=6)
	draw.line((168, 176, 344, 176), fill=rgba(lighten(palette.bright, 0.26), 120), width=6)


def draw_orb(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	draw.ellipse((152, 152, 360, 360), fill=rgba(lighten(palette.base, 0.06), 240), outline=rgba(lighten(palette.bright, 0.12), 220), width=6)
	draw.ellipse((188, 188, 324, 324), fill=rgba(lighten(palette.glow, 0.18), 132))
	draw.arc((122, 122, 390, 390), start=36, end=168, fill=rgba(lighten(palette.bright, 0.18), 160), width=6)
	draw.arc((138, 138, 374, 374), start=220, end=320, fill=rgba(lighten(palette.accent, 0.22), 140), width=6)


def draw_star(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	points = []
	for idx in range(10):
		radius = 148 if idx % 2 == 0 else 62
		angle = -math.pi / 2 + math.tau * idx / 10.0
		points.append((256 + math.cos(angle) * radius, 256 + math.sin(angle) * radius))
	draw.polygon(points, fill=rgba(lighten(palette.base, 0.12), 245), outline=rgba(lighten(palette.bright, 0.12), 220))
	draw.ellipse((214, 214, 298, 298), fill=rgba(lighten(palette.glow, 0.18), 140))


def draw_meteor(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	draw.ellipse((206, 202, 338, 334), fill=rgba(lighten(palette.base, 0.14), 240), outline=rgba(lighten(palette.bright, 0.12), 210), width=5)
	for idx in range(4):
		offset = idx * 26
		draw.polygon([(156 - offset, 190 + offset), (236 - offset, 218 + offset), (236 - offset, 246 + offset)], fill=rgba(lighten(palette.glow, 0.12), max(50, 170 - idx * 30)))


def draw_book(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	draw.polygon([(138, 174), (240, 148), (240, 348), (138, 374)], fill=rgba(lighten(palette.base, 0.12), 245), outline=rgba(lighten(palette.bright, 0.1), 210))
	draw.polygon([(374, 174), (272, 148), (272, 348), (374, 374)], fill=rgba(lighten(palette.base, 0.18), 245), outline=rgba(lighten(palette.bright, 0.1), 210))
	draw.line((256, 144, 256, 376), fill=rgba(lighten(palette.bright, 0.18), 180), width=5)
	draw.line((168, 216, 224, 204), fill=rgba(lighten(palette.glow, 0.18), 120), width=5)
	draw.line((288, 216, 344, 204), fill=rgba(lighten(palette.glow, 0.18), 120), width=5)


def draw_rune_obelisk(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	draw.polygon([(256, 108), (322, 182), (304, 374), (208, 374), (190, 182)], fill=rgba(lighten(palette.base, 0.12), 245), outline=rgba(lighten(palette.bright, 0.08), 210))
	draw.rectangle((242, 154, 270, 328), fill=rgba(lighten(palette.glow, 0.15), 170))
	draw.rectangle((214, 214, 298, 240), fill=rgba(lighten(palette.bright, 0.15), 140))
	draw.rectangle((226, 282, 286, 302), fill=rgba(lighten(palette.bright, 0.15), 140))


def draw_hourglass(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	draw.polygon([(192, 132), (320, 132), (286, 214), (226, 214)], fill=rgba(lighten(palette.base, 0.14), 240), outline=rgba(lighten(palette.bright, 0.1), 210))
	draw.polygon([(226, 298), (286, 298), (320, 380), (192, 380)], fill=rgba(lighten(palette.base, 0.14), 240), outline=rgba(lighten(palette.bright, 0.1), 210))
	draw.line((224, 214, 288, 298), fill=rgba(lighten(palette.glow, 0.2), 180), width=6)
	draw.line((288, 214, 224, 298), fill=rgba(lighten(palette.glow, 0.2), 180), width=6)


def draw_holy_cross(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	draw.rectangle((230, 118, 282, 390), fill=rgba(lighten(palette.base, 0.16), 245))
	draw.rectangle((144, 206, 368, 258), fill=rgba(lighten(palette.base, 0.16), 245))
	draw.ellipse((198, 86, 314, 202), outline=rgba(lighten(palette.bright, 0.2), 180), width=8)


def draw_dragon_sigil(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	draw.polygon([(170, 294), (198, 164), (272, 126), (350, 156), (366, 232), (322, 300), (246, 336)], fill=rgba(lighten(palette.base, 0.12), 245), outline=rgba(lighten(palette.bright, 0.12), 210))
	draw.polygon([(268, 164), (314, 166), (336, 206), (304, 230), (258, 214)], fill=rgba(lighten(palette.glow, 0.16), 160))
	draw.line((218, 140, 242, 108), fill=rgba(lighten(palette.accent, 0.14), 190), width=8)
	draw.line((314, 142, 342, 106), fill=rgba(lighten(palette.accent, 0.14), 190), width=8)


def draw_beast_fang(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	draw.polygon([(196, 128), (234, 330), (198, 388), (154, 328)], fill=rgba(lighten(palette.base, 0.12), 245), outline=rgba(lighten(palette.bright, 0.08), 210))
	draw.polygon([(316, 128), (358, 328), (314, 388), (278, 330)], fill=rgba(lighten(palette.base, 0.12), 245), outline=rgba(lighten(palette.bright, 0.08), 210))
	draw.ellipse((214, 220, 298, 304), fill=rgba(lighten(palette.glow, 0.18), 120))


def draw_crown(draw: ImageDraw.ImageDraw, palette: Palette, rng: random.Random) -> None:
	draw.polygon([(152, 320), (188, 176), (246, 256), (286, 156), (326, 256), (384, 176), (360, 320)], fill=rgba(lighten(palette.base, 0.14), 245), outline=rgba(lighten(palette.bright, 0.1), 210))
	draw.rectangle((152, 304, 360, 350), fill=rgba(lighten(palette.base, 0.22), 230))
	for x in (188, 286, 336):
		draw.ellipse((x - 12, 144, x + 12, 168), fill=rgba(lighten(palette.glow, 0.18), 210))


MOTIF_DRAWERS: dict[str, Callable[[ImageDraw.ImageDraw, Palette, random.Random], None]] = {
	"blade": draw_blade,
	"crescent_blade": draw_crescent_blade,
	"claw": draw_claw,
	"shield": draw_shield,
	"heart": draw_heart,
	"blood_drop": draw_blood_drop,
	"eye": draw_eye,
	"moon": draw_moon,
	"flame": draw_flame,
	"lightning": draw_lightning,
	"wing": draw_wing,
	"swift_boot": draw_swift_boot,
	"gem": draw_gem,
	"orb": draw_orb,
	"star": draw_star,
	"meteor": draw_meteor,
	"book": draw_book,
	"rune_obelisk": draw_rune_obelisk,
	"hourglass": draw_hourglass,
	"holy_cross": draw_holy_cross,
	"dragon_sigil": draw_dragon_sigil,
	"beast_fang": draw_beast_fang,
	"crown": draw_crown,
}


def render_icon(card_row: dict) -> tuple[Image.Image, str]:
	tier = int(card_row.get("tier", 1))
	palette = PALETTES.get(tier, PALETTES[1])
	name = str(card_row.get("name", "")).strip()
	description = str(card_row.get("description", "")).strip()
	icon_id = str(card_row.get("icon", "")).strip()
	seed = int(icon_id or card_row.get("id", 0) or 0)
	rng = random.Random(seed)
	base = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
	draw = ImageDraw.Draw(base)
	create_background(draw, rng, palette)
	add_glow(base, palette, 1.0)
	draw = ImageDraw.Draw(base)
	add_sigil_ring(draw, rng, palette)
	motif = choose_motif(name, description, icon_id or str(seed))
	drawer = MOTIF_DRAWERS.get(motif, draw_orb)
	drawer(draw, palette, rng)

	shine = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
	shine_draw = ImageDraw.Draw(shine)
	shine_draw.polygon([(94, 68), (214, 68), (420, 444), (300, 444)], fill=rgba((255, 255, 255), 42))
	shine = shine.filter(ImageFilter.GaussianBlur(18))
	base.alpha_composite(shine)

	frame = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
	frame_draw = ImageDraw.Draw(frame)
	frame_draw.rounded_rectangle((18, 18, SIZE - 18, SIZE - 18), radius=62, outline=rgba(lighten(palette.base, 0.22), 210), width=4)
	frame_draw.rounded_rectangle((30, 30, SIZE - 30, SIZE - 30), radius=54, outline=rgba(lighten(palette.accent, 0.12), 72), width=2)
	base.alpha_composite(frame)
	return base, motif


def load_rows(source_manifest: Path | None) -> list[dict]:
	if source_manifest is not None and source_manifest.exists():
		rows = json.loads(source_manifest.read_text(encoding="utf-8"))
		return [dict(row) for row in rows]
	return json.loads(CARDS_JSON.read_text(encoding="utf-8"))


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("--manifest", default=str(MANIFEST_JSON), help="optional manifest json with icon/tier/name/description rows")
	parser.add_argument("--tier", type=int, action="append", help="only render matching tiers; can be repeated")
	parser.add_argument("--icon", action="append", help="only render matching icon ids; can be repeated")
	parser.add_argument("--skip-icon", action="append", help="skip matching icon ids; can be repeated")
	parser.add_argument("--limit", type=int, default=0, help="maximum icons to render after filtering")
	args = parser.parse_args()

	OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
	manifest_path = Path(args.manifest) if str(args.manifest).strip() else None
	rows = load_rows(manifest_path)
	allowed_tiers = set(args.tier or [])
	allowed_icons = {str(icon_id).strip() for icon_id in (args.icon or []) if str(icon_id).strip()}
	skip_icons = {str(icon_id).strip() for icon_id in (args.skip_icon or []) if str(icon_id).strip()}
	manifest: list[dict] = []
	for row in rows:
		icon_id = str(row.get("icon", "")).strip()
		if not icon_id:
			continue
		tier = int(row.get("tier", 0) or 0)
		if allowed_tiers and tier not in allowed_tiers:
			continue
		if allowed_icons and icon_id not in allowed_icons:
			continue
		if skip_icons and icon_id in skip_icons:
			continue
		image, motif = render_icon(row)
		output_path = OUTPUT_DIR / f"{icon_id}.png"
		image.save(output_path)
		manifest.append(
			{
				"id": row.get("id"),
				"name": row.get("name"),
				"icon": icon_id,
				"tier": tier,
				"motif": motif,
			}
		)
		if args.limit > 0 and len(manifest) >= args.limit:
			break
	MANIFEST_PATH.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
	print(f"generated {len(manifest)} card icons -> {OUTPUT_DIR}")


if __name__ == "__main__":
	main()
