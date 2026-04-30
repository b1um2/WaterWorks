from PIL import Image
imgName = "credits"
img = Image.open(imgName+".png").convert('RGB')
with open(imgName+".bin", "wb") as f:
    for y in range(256):
        for x in range(512):
            r, g, b = img.getpixel((x, y))

            color = 0 << 24 | r << 16 | g << 8 | b
            f.write(color.to_bytes(4, 'little'))