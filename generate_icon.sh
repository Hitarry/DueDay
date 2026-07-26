#!/bin/bash
# 生成 DueDay.icns 图标（时钟表盘）
cd "$(dirname "$0")"

ICON_DIR="DueDay.iconset"
mkdir -p "$ICON_DIR"

# 用 Python 生成 1024x1024 表盘 PNG（只有圆形 + 两根指针，无刻度）
python3 << 'PYEOF'
import struct, zlib, math

def create_png(width, height, pixel_func):
    def chunk(chunk_type, data):
        c = chunk_type + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xFFFFFFFF)

    raw = b''
    for y in range(height):
        raw += b'\x00'
        for x in range(width):
            r, g, b, a = pixel_func(x, y, width, height)
            raw += struct.pack('BBBB', r, g, b, a)

    header = b'\x89PNG\r\n\x1a\n'
    ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
    idat = chunk(b'IDAT', zlib.compress(raw))
    iend = chunk(b'IEND', b'')
    return header + ihdr + idat + iend

width = height = 1024
cx = cy = width // 2
r = int(width * 0.42)

def pixel(x, y, w, h):
    dx, dy = x - cx, y - cy
    dist = math.sqrt(dx*dx + dy*dy)
    angle = math.atan2(dy, dx)

    # Clock circle outline
    if abs(dist - r) < w * 0.018:
        return (50, 50, 50, 255)
    # Hour hand (2 o'clock)
    hand_angle = math.pi / 6  # 30 degrees
    hx = math.cos(hand_angle) * r * 0.45
    hy = -math.sin(hand_angle) * r * 0.45
    h_dist = abs(dy - (hy/hx)*dx) / math.sqrt(1 + (hy/hx)*(hy/hx)) if hx != 0 else abs(dx)
    if h_dist < w * 0.025 and dx * hx + dy * hy > 0 and math.sqrt(dx*dx+dy*dy) < math.sqrt(hx*hx+hy*hy):
        return (50, 50, 50, 255)
    # Minute hand (12 o'clock)
    if abs(dx) < w * 0.015 and dy < 0 and math.sqrt(dx*dx+dy*dy) < r * 0.68:
        return (50, 50, 50, 255)
    # Center dot
    if dist < w * 0.03:
        return (50, 50, 50, 255)
    # Transparent background
    return (0, 0, 0, 0)

png = create_png(width, height, pixel)
with open('DueDay.iconset/icon_512x512@2x.png', 'wb') as f:
    f.write(png)

print("PNG created")
PYEOF

# Verify file exists
if [ ! -f "DueDay.iconset/icon_512x512@2x.png" ]; then
    echo "PNG generation failed!"
    exit 1
fi

# Create all icon sizes using sips
cp "DueDay.iconset/icon_512x512@2x.png" "DueDay.iconset/icon_512x512.png"
sips -z 256 256 "DueDay.iconset/icon_512x512@2x.png" --out "DueDay.iconset/icon_256x256@2x.png" > /dev/null 2>&1
sips -z 256 256 "DueDay.iconset/icon_512x512.png" --out "DueDay.iconset/icon_256x256.png" > /dev/null 2>&1
sips -z 128 128 "DueDay.iconset/icon_512x512.png" --out "DueDay.iconset/icon_128x128.png" > /dev/null 2>&1
sips -z 64 64 "DueDay.iconset/icon_512x512.png" --out "DueDay.iconset/icon_64x64.png" > /dev/null 2>&1
sips -z 32 32 "DueDay.iconset/icon_512x512.png" --out "DueDay.iconset/icon_32x32.png" > /dev/null 2>&1
sips -z 16 16 "DueDay.iconset/icon_512x512.png" --out "DueDay.iconset/icon_16x16.png" > /dev/null 2>&1

# Convert to .icns
iconutil -c icns "DueDay.iconset" -o "Resources/DueDay.icns"

echo "=== DueDay.icns generated ==="
ls -la Resources/DueDay.icns
