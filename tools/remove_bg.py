from PIL import Image
import numpy as np

img = Image.open(r'P:\ProjectLI\Jabatan Air Sabah.jpg').convert('RGBA')
data = np.array(img)

r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]

# Remove near-white background
mask = (r > 200) & (g > 200) & (b > 200)
data[mask, 3] = 0

result = Image.fromarray(data)
out1 = r'P:\ProjectLI\src\main\webapp\assets\images\jabatan-air-sabah-bg.png'
out2 = r'P:\ProjectLI\runtime\apache-tomcat-11.0.18\webapps\sistemppa\assets\images\jabatan-air-sabah-bg.png'
result.save(out1, 'PNG')
result.save(out2, 'PNG')
print('Done:', out2)
