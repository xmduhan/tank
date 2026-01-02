from PIL import Image, ImageDraw

# ========= 基础设置 =========
SCALE = 8            # 放大倍数（像素风关键）
W, H = 22, 24        # 精灵逻辑尺寸

img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

# ========= 颜色定义 =========
OUTLINE = (30, 40, 20)
GREEN_DARK = (90, 130, 40)
GREEN = (120, 170, 60)
GREEN_LIGHT = (160, 210, 90)

# ========= 辅助函数 =========
def rect(x1, y1, x2, y2, color):
    d.rectangle((x1, y1, x2, y2), fill=color)

# ========= 履带 =========
rect(0, 2, 3, 21, GREEN_DARK)
rect(18, 2, 21, 21, GREEN_DARK)

# ========= 主体 =========
rect(4, 2, 17, 21, GREEN)

# ========= 炮塔 =========
rect(6, 6, 15, 13, GREEN_LIGHT)
rect(9, 3, 12, 6, GREEN_LIGHT)

# ========= 细节模块 =========
rect(6, 15, 9, 18, GREEN_LIGHT)
rect(12, 15, 15, 18, GREEN_LIGHT)

# ========= 描边 =========
for x in range(W):
    for y in range(H):
        if img.getpixel((x, y))[3] != 0:
            for dx, dy in [(-1,0),(1,0),(0,-1),(0,1)]:
                nx, ny = x+dx, y+dy
                if 0 <= nx < W and 0 <= ny < H:
                    if img.getpixel((nx, ny))[3] == 0:
                        d.point((x, y), fill=OUTLINE)

# ========= 放大显示 =========
img = img.resize((W*SCALE, H*SCALE), Image.NEAREST)
img.save("tank_sprite.png")
img.show()
