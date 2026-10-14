# noise_preview.py - run: python3 noise_preview.py
W, H = 160, 80
SEED = 1
CELL = 16  # bigger = bigger blobs. game uses 16 now
CLIFF_THRESH = 190   # > this = cliff '#'
SPAWN_THRESH = 50    # < this = spawn 'o', else walkable '.'

def hash2(x, y, seed):
    # integer-only, asm-friendly. emulate 32-bit overflow with & 0xFFFFFFFF
    h = (x * 374761393 + y * 668265263 + seed * 974634211) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    h = (h ^ (h >> 16)) & 0xFFFFFFFF
    return h & 0xFF  # 0-255

def raw(x, y):
    return hash2(x, y, SEED)

def smooth(x, y):
    # value noise: hash coarse lattice, bilinear interp with ints
    x0, y0 = x // CELL, y // CELL
    fx = (x % CELL) * 256 // CELL   # 0..255
    fy = (y % CELL) * 256 // CELL
    a = hash2(x0,     y0,     SEED)
    b = hash2(x0 + 1, y0,     SEED)
    c = hash2(x0,     y0 + 1, SEED)
    d = hash2(x0 + 1, y0 + 1, SEED)
    top = a + ((b - a) * fx >> 8)
    bot = c + ((d - c) * fx >> 8)
    return top + ((bot - top) * fy >> 8)

def tile_char(v):
    if v > CLIFF_THRESH:
        return '#'
    if v < SPAWN_THRESH:
        return 'o'
    return '.'

print("=== RAW hash (what plain hash looks like: static, unusable) ===")
for y in range(H):
    print(''.join(tile_char(raw(x, y)) for x in range(W)))
print()
print(f"=== SMOOTH value noise, CELL={CELL} (what you'd ship) ===")
for y in range(H):
    print(''.join(tile_char(smooth(x, y)) for x in range(W)))
