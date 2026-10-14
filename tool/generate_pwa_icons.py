#!/usr/bin/env python3
"""Generate PWA icons for web/ from assets/images/app_icon.png."""

from __future__ import annotations

import os
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "images" / "app_icon.png"
WEB = ROOT / "web"
ICONS = WEB / "icons"
THEME = (1, 117, 194, 255)  # #0175C2 — matches manifest.json


def fit_square(im: Image.Image, size: int, bg: tuple | None = None, scale: float = 1.0) -> Image.Image:
    w, h = im.size
    side = max(w, h)
    fill = (0, 0, 0, 0) if bg is None else bg
    canvas = Image.new("RGBA", (side, side), fill)
    canvas.paste(im, ((side - w) // 2, (side - h) // 2), im)
    if scale != 1.0:
        new_side = int(side * scale)
        scaled = canvas.resize((new_side, new_side), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (side, side), fill)
        canvas.paste(scaled, ((side - new_side) // 2, (side - new_side) // 2), scaled)
    return canvas.resize((size, size), Image.Resampling.LANCZOS)


def maskable(im: Image.Image, size: int) -> Image.Image:
    base = Image.new("RGBA", (size, size), THEME)
    logo = fit_square(im, int(size * 0.72))
    base.paste(logo, ((size - logo.width) // 2, (size - logo.height) // 2), logo)
    return base.convert("RGB")


def main() -> None:
    if not SRC.is_file():
        raise SystemExit(f"Missing source icon: {SRC}")

    ICONS.mkdir(parents=True, exist_ok=True)
    img = Image.open(SRC).convert("RGBA")

    fit_square(img, 32).save(WEB / "favicon.png")
    fit_square(img, 192).save(ICONS / "Icon-192.png")
    fit_square(img, 512).save(ICONS / "Icon-512.png")
    maskable(img, 192).save(ICONS / "Icon-maskable-192.png")
    maskable(img, 512).save(ICONS / "Icon-maskable-512.png")

    print("PWA icons written to web/ and web/icons/")


if __name__ == "__main__":
    main()
