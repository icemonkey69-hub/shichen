from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "assets" / "ui" / "icons" / "cards"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sheet", required=True, help="Path to atlas image")
    parser.add_argument("--batch-json", required=True, help="Path to batch json file")
    parser.add_argument("--batch-index", required=True, type=int, help="1-based batch index")
    parser.add_argument("--columns", type=int, default=3)
    parser.add_argument("--rows", type=int, default=2)
    parser.add_argument("--padding", type=int, default=0)
    args = parser.parse_args()

    batch_data = json.loads(Path(args.batch_json).read_text(encoding="utf-8"))
    batch = batch_data[args.batch_index - 1]
    items = batch["items"]

    sheet = Image.open(args.sheet).convert("RGBA")
    width, height = sheet.size
    cell_w = width // args.columns
    cell_h = height // args.rows

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    for idx, item in enumerate(items):
        col = idx % args.columns
        row = idx // args.columns
        left = col * cell_w + args.padding
        top = row * cell_h + args.padding
        right = (col + 1) * cell_w - args.padding
        bottom = (row + 1) * cell_h - args.padding
        cropped = sheet.crop((left, top, right, bottom))
        out_path = OUTPUT_DIR / f"{item['icon']}.png"
        cropped.save(out_path)
        print(f"saved {out_path}")


if __name__ == "__main__":
    main()
