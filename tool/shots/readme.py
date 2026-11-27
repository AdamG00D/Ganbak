#!/usr/bin/env python3
"""بينقل صور الـ README من build/readme لـ docs/images (بعد flutter test tool/shots/readme_test.dart).

الصور بتتحوّل لـ 256 لون عشان الريبو ميتقلش. العربي في docs/images/screenshots والإنجليزي في screenshots/en.
"""
import glob
import os

from PIL import Image

SRC = 'build/readme'
DST = 'docs/images'


def save(src: str, dst: str) -> None:
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    img = Image.open(src).convert('RGB')
    img.quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).save(dst, optimize=True)
    print(dst)


for path in sorted(glob.glob(f'{SRC}/*.png')):
    name = os.path.basename(path)[:-4]
    if name.startswith('banner.'):
        save(path, f'{DST}/{name}.png')
        continue
    base, lang, _theme = name.rsplit('.', 2)
    save(path, f'{DST}/screenshots/{base}.png' if lang == 'ar' else f'{DST}/screenshots/en/{base}.png')
