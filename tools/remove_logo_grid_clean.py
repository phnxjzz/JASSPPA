from pathlib import Path
from PIL import Image
import numpy as np

src = Path(r"P:\ProjectLI\sabah-logo-11550717896ipwsp2ehqk.png")
outputs = [
    Path(r"P:\ProjectLI\src\main\webapp\assets\images\logo-sabah-2025.png"),
    Path(r"P:\ProjectLI\runtime\apache-tomcat-11.0.18\webapps\sistemppa\assets\images\logo-sabah-2025.png"),
]

img = Image.open(src).convert("RGBA")
a = np.array(img)
rgb = a[:, :, :3].astype(np.int16)
alpha = a[:, :, 3] > 0

mx = rgb.max(axis=2)
mn = rgb.min(axis=2)
sat = mx - mn
light = rgb.mean(axis=2)

# Remove checker/grid-like background tones: light + near-neutral colors.
mask_grid = alpha & (((light >= 186) & (sat <= 26)) | ((light >= 170) & (sat <= 12)))
a[mask_grid, 3] = 0

# Also clear near-white remnants aggressively.
mask_white = (a[:, :, 3] > 0) & (a[:, :, 0] >= 235) & (a[:, :, 1] >= 235) & (a[:, :, 2] >= 235)
a[mask_white, 3] = 0

# Trim transparent outer border for cleaner composition.
al = a[:, :, 3]
ys, xs = np.where(al > 0)
if len(xs) > 0 and len(ys) > 0:
    x0, x1 = xs.min(), xs.max()
    y0, y1 = ys.min(), ys.max()
    a = a[y0:y1 + 1, x0:x1 + 1]

out_img = Image.fromarray(a, mode="RGBA")
for out in outputs:
    out.parent.mkdir(parents=True, exist_ok=True)
    out_img.save(out)

print(f"Original size: {img.size}")
print(f"Final size: {out_img.size}")
print(f"Grid-like pixels cleared: {int(mask_grid.sum())}")
print(f"Near-white pixels cleared: {int(mask_white.sum())}")
for out in outputs:
    print(f"Saved: {out}")
