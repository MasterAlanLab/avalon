"""Compare a supplied reference image with a 390x844 device capture.

    python3 tool/fidelity/compare.py reference.png out/capture.png out/comparison.png

Provide reference.png separately. A 434x888 image is cropped to its phone
screen at (11,11); other reference sizes are scaled to 390x844. Captures
are aligned to a 58 pt reference status bar. The capture's status bar height
defaults to 47.67 pt and can be overridden with a fourth argument.
Requires Pillow.
"""
import sys
from PIL import Image, ImageDraw

ref_path, shot_path, out_path = sys.argv[1:4]
scale = 2
ref = Image.open(ref_path).convert("RGB")
if ref.size == (434, 888):
    ref = ref.crop((11, 11, 401, 855))
ref = ref.resize((390 * scale, 844 * scale), Image.LANCZOS)
shot = Image.open(shot_path).convert("RGB").resize((390 * scale, 844 * scale), Image.LANCZOS)
status_bar = float(sys.argv[4]) if len(sys.argv) > 4 else 47.67
shifted = Image.new("RGB", shot.size, (242, 242, 247))
shifted.paste(shot, (0, round((58 - status_bar) * scale)))
gap = 24
out = Image.new("RGB", (390 * scale * 2 + gap, 844 * scale + 40), "white")
out.paste(ref, (0, 40))
out.paste(shifted, (390 * scale + gap, 40))
d = ImageDraw.Draw(out)
d.text((10, 10), "Reference image (390x844)", fill="black")
d.text((390 * scale + gap + 10, 10), "Device capture (390x844, content-aligned)", fill="black")
out.save(out_path)
