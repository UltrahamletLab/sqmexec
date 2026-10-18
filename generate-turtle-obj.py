"""Build a smooth, grouped OBJ mesh for the sqm turtle scene."""
from math import cos, pi, sin
from pathlib import Path

OUT = Path(__file__).resolve().parent / "assets" / "turtle.obj"
vertices = []
groups = {}


def add_vertex(point):
    vertices.append(point)
    return len(vertices)


def add_face(group, *indices):
    groups.setdefault(group, []).append(indices)


def uv_ellipsoid(group, center, radii, lon=32, lat=20):
    cx, cy, cz = center
    rx, ry, rz = radii
    grid = []
    for j in range(lat + 1):
        theta = pi * j / lat
        row = []
        for i in range(lon):
            phi = 2 * pi * i / lon
            row.append(add_vertex((
                cx + rx * sin(theta) * cos(phi),
                cy + ry * cos(theta),
                cz + rz * sin(theta) * sin(phi),
            )))
        grid.append(row)
    for j in range(lat):
        for i in range(lon):
            ni = (i + 1) % lon
            add_face(group, grid[j][i], grid[j + 1][i], grid[j + 1][ni], grid[j][ni])


def dome_shell():
    lon, lat = 64, 24
    grid = []
    for j in range(lat + 1):
        theta = (pi / 2) * j / lat
        row = []
        for i in range(lon):
            phi = 2 * pi * i / lon
            row.append(add_vertex((
                1.18 * sin(theta) * cos(phi),
                0.88 + 0.82 * cos(theta),
                0.88 * sin(theta) * sin(phi),
            )))
        grid.append(row)
    for j in range(lat):
        for i in range(lon):
            ni = (i + 1) % lon
            band = min(4, (j * 5) // lat)
            sector = i // 4
            group = "scutes" if (sector + band) % 3 == 0 else "shell"
            add_face(group, grid[j][i], grid[j + 1][i], grid[j + 1][ni], grid[j][ni])


def torus_y(group, major, minor, center_y, z_center, major_steps=64, minor_steps=10):
    grid = []
    for i in range(major_steps):
        u = 2 * pi * i / major_steps
        row = []
        for j in range(minor_steps):
            v = 2 * pi * j / minor_steps
            radius = major + minor * cos(v)
            row.append(add_vertex((
                radius * cos(u),
                center_y + minor * sin(v),
                z_center + radius * sin(u),
            )))
        grid.append(row)
    for i in range(major_steps):
        ni = (i + 1) % major_steps
        for j in range(minor_steps):
            nj = (j + 1) % minor_steps
            add_face(group, grid[i][j], grid[ni][j], grid[ni][nj], grid[i][nj])


# Belly and four splayed feet.
uv_ellipsoid("plastron", (0, 0.74, 0.06), (0.98, 0.43, 0.82), 40, 24)
for x in (-0.79, 0.79):
    for z in (-0.49, 0.62):
        uv_ellipsoid("skin", (x, 0.36, z), (0.38, 0.34, 0.39), 24, 16)
        uv_ellipsoid("claws", (x, 0.15, z - 0.025), (0.15, 0.055, 0.16), 16, 10)

# Smooth carapace with alternating green scute panels and a raised rim.
dome_shell()
torus_y("rim", 1.13, 0.105, 0.89, 0.0)

# Neck and friendly face, pointing toward -Z.
uv_ellipsoid("skin", (0, 1.00, -0.81), (0.39, 0.34, 0.55), 28, 18)
uv_ellipsoid("skin", (0, 1.21, -1.14), (0.48, 0.43, 0.48), 32, 20)
for x in (-0.19, 0.19):
    uv_ellipsoid("eyes", (x, 1.32, -1.535), (0.105, 0.125, 0.055), 20, 14)
    uv_ellipsoid("pupils", (x - 0.012, 1.315, -1.582), (0.047, 0.064, 0.027), 16, 12)
    uv_ellipsoid("highlights", (x - 0.028, 1.35, -1.604), (0.018, 0.023, 0.012), 12, 8)
for x in (-0.32, 0.32):
    uv_ellipsoid("cheeks", (x, 1.08, -1.49), (0.11, 0.065, 0.025), 16, 10)
uv_ellipsoid("skin", (0, 1.12, -1.60), (0.075, 0.055, 0.04), 16, 10)

# Small rounded smile made from overlapping smooth ellipsoids.
for i in range(9):
    x = -0.16 + i * 0.04
    y = 1.00 - 0.055 * (1 - (x / 0.16) ** 2)
    uv_ellipsoid("mouth", (x, y, -1.585), (0.03, 0.022, 0.018), 10, 6)

# Tail peeking behind the shell.
uv_ellipsoid("skin", (0, 0.66, 0.96), (0.20, 0.20, 0.38), 20, 12)

OUT.parent.mkdir(parents=True, exist_ok=True)
with OUT.open("w", encoding="ascii", newline="\n") as obj:
    obj.write("# Smooth grouped turtle mesh generated for sqm\n")
    obj.write("o turtle\n")
    for x, y, z in vertices:
        obj.write(f"v {x:.6f} {y:.6f} {z:.6f}\n")
    for group, faces in groups.items():
        obj.write(f"g {group}\n")
        for face in faces:
            obj.write("f " + " ".join(map(str, face)) + "\n")
print(f"{OUT}: {len(vertices)} vertices, {sum(map(len, groups.values()))} polygons")
