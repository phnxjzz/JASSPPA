from PIL import Image
import numpy as np

# Try the new 2025 logo first
src = r'P:\ProjectLI\Logo jabatan air sabah_files\logo-jans-2025-main.png'

img = Image.open(src).convert('RGBA')
data = np.array(img)

r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]

# Remove near-white background (tolerance 200+)
mask = (r > 200) & (g > 200) & (b > 200)
data[mask, 3] = 0

result = Image.fromarray(data)
out1 = r'P:\ProjectLI\src\main\webapp\assets\images\logo-jabatan-air-sabah.png'
out2 = r'P:\ProjectLI\runtime\apache-tomcat-11.0.18\webapps\sistemppa\assets\images\logo-jabatan-air-sabah.png'
result.save(out1, 'PNG')
result.save(out2, 'PNG')
print('Done:', out1)
print('Size:', result.size)
