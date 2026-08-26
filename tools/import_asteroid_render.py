#!/usr/bin/env python3
"""Copy a fresh Blender asteroid render set (color/normal/roughness) from the
tmp render-output folder into the mod's graphics tree with proper naming.

Usage:
    python tools/import_asteroid_render.py <size> <variation>

Example:
    python tools/import_asteroid_render.py medium 2
    -> copies tmp/asteroid_render{color,normal,roughness}.png to
       graphics/entity/starship-scrap/medium/asteroid-starship-scrap-medium-{color,normal,roughness}-2.png

Reports each file's actual pixel dimensions after copying so a resolution
mismatch against asteroids.lua's declared `size` is caught immediately,
instead of surfacing as a load-time crash.
"""

import sys
import shutil
from pathlib import Path

TMP_DIR = Path(r"C:\Users\nacus\OneDrive\Documents\tmp")
GRAPHICS_ROOT = Path(__file__).resolve().parent.parent / "graphics" / "entity" / "starship-scrap"
KINDS = ("color", "normal", "roughness")


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)

    size_name, variation = sys.argv[1], sys.argv[2]
    dest_dir = GRAPHICS_ROOT / size_name
    if not dest_dir.is_dir():
        print(f"No such graphics folder: {dest_dir}")
        sys.exit(1)

    try:
        from PIL import Image
        have_pil = True
    except ImportError:
        have_pil = False

    for kind in KINDS:
        src = TMP_DIR / f"asteroid_render{kind}.png"
        if not src.exists():
            print(f"MISSING: {src}")
            continue
        dest = dest_dir / f"asteroid-starship-scrap-{size_name}-{kind}-{variation}.png"
        shutil.copyfile(src, dest)
        if have_pil:
            w, h = Image.open(dest).size
            print(f"{kind:10s} -> {dest.name}  ({w}x{h})")
        else:
            print(f"{kind:10s} -> {dest.name}  (Pillow not installed, size unknown)")


if __name__ == "__main__":
    main()
