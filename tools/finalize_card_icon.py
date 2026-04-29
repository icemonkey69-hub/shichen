from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


SIZE = 512


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--src", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--background", default="#00000000")
    parser.add_argument("--padding", type=int, default=36, help="transparent safe padding in final 512 canvas")
    args = parser.parse_args()

    src_path = Path(args.src)
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    image = Image.open(src_path).convert("RGBA")
    canvas = Image.new("RGBA", (SIZE, SIZE), args.background)

    safe_padding = max(0, min(int(args.padding), SIZE // 3))
    safe_size = max(1, SIZE - safe_padding * 2)
    scale = min(safe_size / float(image.width), safe_size / float(image.height))
    fit_width = max(1, int(round(image.width * scale)))
    fit_height = max(1, int(round(image.height * scale)))
    resized = image.resize((fit_width, fit_height), Image.Resampling.LANCZOS)

    left = (SIZE - fit_width) // 2
    top = (SIZE - fit_height) // 2
    canvas.alpha_composite(resized, (left, top))
    canvas.save(out_path)
    print(f"saved {out_path} ({SIZE}x{SIZE})")


if __name__ == "__main__":
    main()
