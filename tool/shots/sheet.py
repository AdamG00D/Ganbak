#!/usr/bin/env python3
"""يجمع صور كل شاشة (عربي/إنجليزي × فاتح/غامق) في صورة واحدة: build/shots/sheets/<اسم>.png"""
import glob, os, sys
from PIL import Image

src = 'build/shots'
dst = os.path.join(src, 'sheets')
os.makedirs(dst, exist_ok=True)
names = sorted({os.path.basename(p).split('.')[0] for p in glob.glob(f'{src}/*.png')})
only = sys.argv[1:]
for name in names:
    if only and not any(o in name for o in only):
        continue
    tiles = [f'{src}/{name}.{l}.{t}.png' for l in ('ar', 'en') for t in ('light', 'dark')]
    tiles = [Image.open(t) for t in tiles if os.path.exists(t)]
    if not tiles:
        continue
    scale = 0.5
    w, h = int(tiles[0].width * scale), int(tiles[0].height * scale)
    sheet = Image.new('RGB', (w * len(tiles) + 8 * (len(tiles) - 1), h), (128, 128, 128))
    for i, t in enumerate(tiles):
        sheet.paste(t.resize((w, h), Image.LANCZOS), (i * (w + 8), 0))
    sheet.save(f'{dst}/{name}.png')
    print(f'{dst}/{name}.png')
