from pathlib import Path
from collections import deque
from PIL import Image
import numpy as np

src = Path(r"P:\ProjectLI\sabah-logo-11550717896ipwsp2ehqk.png")
outputs = [
    Path(r"P:\ProjectLI\src\main\webapp\assets\images\logo-sabah-2025.png"),
    Path(r"P:\ProjectLI\runtime\apache-tomcat-11.0.18\webapps\sistemppa\assets\images\logo-sabah-2025.png"),
]

img = Image.open(src).convert("RGBA")
arr = np.array(img)
rgb = arr[:, :, :3]
alpha = arr[:, :, 3]

# Candidate background pixels: bright near-white, still opaque
bright = (rgb[:, :, 0] >= 242) & (rgb[:, :, 1] >= 242) & (rgb[:, :, 2] >= 242) & (alpha > 0)

h, w = bright.shape
bg = np.zeros((h, w), dtype=bool)
q = deque()

# Seed flood fill from image border only (keeps internal white details)
for x in range(w):
    if bright[0, x]:
        bg[0, x] = True
        q.append((0, x))
    if bright[h - 1, x] and not bg[h - 1, x]:
        bg[h - 1, x] = True
        q.append((h - 1, x))
for y in range(h):
    if bright[y, 0] and not bg[y, 0]:
        bg[y, 0] = True
        q.append((y, 0))
    if bright[y, w - 1] and not bg[y, w - 1]:
        bg[y, w - 1] = True
        q.append((y, w - 1))

# 8-direction flood fill over bright pixels
neighbors = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]
while q:
    y, x = q.popleft()
    for dy, dx in neighbors:
        ny, nx = y + dy, x + dx
        if 0 <= ny < h and 0 <= nx < w and bright[ny, nx] and not bg[ny, nx]:
            bg[ny, nx] = True
            q.append((ny, nx))

# Make background transparent
arr[bg, 3] = 0
result = Image.fromarray(arr, mode="RGBA")

for out in outputs:
    out.parent.mkdir(parents=True, exist_ok=True)
    result.save(out)

print(f"Processed size: {w}x{h}")
print(f"Transparent pixels added: {int(bg.sum())}")
for out in outputs:
    print(f"Saved: {out}")
