"""Material 3 Expressive shapes, ported from androidx.

Port of code from the Android Open Source Project (androidx):
Copyright 2022-2025 The Android Open Source Project.
Licensed under the Apache License, Version 2.0
(http://www.apache.org/licenses/LICENSE-2.0). The shape vertex data and the
rounded-polygon construction follow the upstream sources listed below; this
file is a translation to Python, not the original.

This is the one source for the M3 shape library that AedwenOS draws with:

- the Plymouth loader frames (scripts/generate-plymouth-assets.py);
- the shell's QML shapes and the loading indicator
  (org/aedwen/ui/m3shapes.js, written by scripts/generate-m3-shapes.py).

Port of androidx.graphics.shapes (RoundedPolygon, CornerRounding, the
rounded-corner construction with smoothing, circle / rectangle / star) and
of compose.material3 MaterialShapes (all 35 shapes, same vertex data). The
upstream sources it follows are:

    graphics/graphics-shapes/src/commonMain/kotlin/androidx/graphics/shapes/
        RoundedPolygon.kt  Shapes.kt  Cubic.kt  Utils.kt  CornerRounding.kt
    compose/material3/material3/src/commonMain/kotlin/androidx/compose/
        material3/MaterialShapes.kt  LoadingIndicator.kt

Every shape is a closed list of cubic Bezier segments, normalised like
RoundedPolygon.normalized() into the unit square (approximate bounds: the
anchor and control points). Morphing (morph()) differs from androidx's
feature-matching Morph: both outlines are resampled by arc length and lined
up at the cyclic offset with the smallest squared distance, then lerped.
That keeps corners travelling to nearby corners, which is what the feature
mapping achieves, without porting the whole matcher.
"""

import math

DISTANCE_EPS = 1e-4


# --- small vector helpers ---------------------------------------------------
def _sub(a, b):
    return (a[0] - b[0], a[1] - b[1])


def _add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def _mul(a, k):
    return (a[0] * k, a[1] * k)


def _dot(a, b):
    return a[0] * b[0] + a[1] * b[1]


def _len(a):
    return math.hypot(a[0], a[1])


def _dir(a):
    d = _len(a)
    if d <= 0:
        raise ValueError("zero-length direction")
    return (a[0] / d, a[1] / d)


def _rot90(a):
    return (-a[1], a[0])


def _lerp(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


# --- cubics -----------------------------------------------------------------
def _line(p0, p1):
    return (p0, _lerp(p0, p1, 1 / 3), _lerp(p0, p1, 2 / 3), p1)


def _cubic_point(c, t):
    u = 1 - t
    return (
        u * u * u * c[0][0] + 3 * u * u * t * c[1][0] + 3 * u * t * t * c[2][0] + t * t * t * c[3][0],
        u * u * u * c[0][1] + 3 * u * u * t * c[1][1] + 3 * u * t * t * c[2][1] + t * t * t * c[3][1],
    )


def _split(c, t):
    p01 = _lerp(c[0], c[1], t)
    p12 = _lerp(c[1], c[2], t)
    p23 = _lerp(c[2], c[3], t)
    p012 = _lerp(p01, p12, t)
    p123 = _lerp(p12, p23, t)
    mid = _lerp(p012, p123, t)
    return (c[0], p01, p012, mid), (mid, p123, p23, c[3])


def _zero_length(c):
    return abs(c[0][0] - c[3][0]) < DISTANCE_EPS and abs(c[0][1] - c[3][1]) < DISTANCE_EPS


def _circular_arc(center, p0, p1):
    p0d = _dir(_sub(p0, center))
    p1d = _dir(_sub(p1, center))
    r0 = _rot90(p0d)
    r1 = _rot90(p1d)
    clockwise = _dot(r0, _sub(p1, center)) >= 0
    cosa = _dot(p0d, p1d)
    if cosa > 0.999:
        return _line(p0, p1)
    k = (
        _len(_sub(p0, center)) * 4 / 3
        * (math.sqrt(2 * (1 - cosa)) - math.sqrt(1 - cosa * cosa)) / (1 - cosa)
        * (1 if clockwise else -1)
    )
    return (p0, _add(p0, _mul(r0, k)), _sub(p1, _mul(r1, k)), p1)


# --- rounded corners (RoundedPolygon.kt: RoundedCorner) ---------------------
class _Corner:
    def __init__(self, p0, p1, p2, radius, smoothing):
        self.p0, self.p1, self.p2 = p0, p1, p2
        v01, v21 = _sub(p0, p1), _sub(p2, p1)
        d01, d21 = _len(v01), _len(v21)
        if d01 > 0 and d21 > 0:
            self.d1 = _mul(v01, 1 / d01)
            self.d2 = _mul(v21, 1 / d21)
            self.radius = radius
            self.smoothing = smoothing
            self.cos = _dot(self.d1, self.d2)
            self.sin = math.sqrt(max(0.0, 1 - self.cos * self.cos))
            self.round_cut = radius * (self.cos + 1) / self.sin if self.sin > 1e-3 else 0.0
        else:
            self.d1 = self.d2 = (0.0, 0.0)
            self.radius = self.smoothing = self.cos = self.sin = 0.0
            self.round_cut = 0.0

    @property
    def cut(self):
        return (1 + self.smoothing) * self.round_cut

    def _smoothing_for(self, allowed):
        if allowed > self.cut:
            return self.smoothing
        if allowed > self.round_cut:
            return self.smoothing * (allowed - self.round_cut) / (self.cut - self.round_cut)
        return 0.0

    @staticmethod
    def _line_intersection(p0, d0, p1, d1):
        rd1 = _rot90(d1)
        den = _dot(d0, rd1)
        if abs(den) < DISTANCE_EPS:
            return None
        num = _dot(_sub(p1, p0), rd1)
        if abs(den) < DISTANCE_EPS * abs(num):
            return None
        return _add(p0, _mul(d0, num / den))

    def _flanking(self, round_cut, smoothing, corner, side_start, inter, other_inter, center, r):
        side_dir = _dir(_sub(side_start, corner))
        curve_start = _add(corner, _mul(side_dir, round_cut * (1 + smoothing)))
        p = _lerp(inter, _mul(_add(inter, other_inter), 0.5), smoothing)
        curve_end = _add(center, _mul(_dir(_sub(p, center)), r))
        tangent = _rot90(_sub(curve_end, center))
        anchor_end = self._line_intersection(side_start, side_dir, curve_end, tangent) or inter
        anchor_start = _mul(_add(curve_start, _mul(anchor_end, 2)), 1 / 3)
        return (curve_start, anchor_start, anchor_end, curve_end)

    def cubics(self, allowed0, allowed1):
        allowed = min(allowed0, allowed1)
        if self.round_cut < DISTANCE_EPS or allowed < DISTANCE_EPS or self.radius < DISTANCE_EPS:
            return [(self.p1, self.p1, self.p1, self.p1)]
        round_cut = min(allowed, self.round_cut)
        s0 = self._smoothing_for(allowed0)
        s1 = self._smoothing_for(allowed1)
        r = self.radius * round_cut / self.round_cut
        center_dist = math.sqrt(r * r + round_cut * round_cut)
        center = _add(self.p1, _mul(_dir(_mul(_add(self.d1, self.d2), 0.5)), center_dist))
        i0 = _add(self.p1, _mul(self.d1, round_cut))
        i2 = _add(self.p1, _mul(self.d2, round_cut))
        f0 = self._flanking(round_cut, s0, self.p1, self.p0, i0, i2, center, r)
        f2 = self._flanking(round_cut, s1, self.p1, self.p2, i2, i0, center, r)
        f2 = (f2[3], f2[2], f2[1], f2[0])
        return [f0, _circular_arc(center, f0[3], f2[0]), f2]


def rounded_polygon(vertices, roundings):
    """vertices: [(x, y)]; roundings: [(radius, smoothing)] per vertex.
    Returns the closed outline as a list of cubics (RoundedPolygon.cubics)."""
    n = len(vertices)
    corners = [
        _Corner(vertices[(i - 1) % n], vertices[i], vertices[(i + 1) % n], *roundings[i])
        for i in range(n)
    ]
    adjusts = []
    for i in range(n):
        exp_round = corners[i].round_cut + corners[(i + 1) % n].round_cut
        exp_cut = corners[i].cut + corners[(i + 1) % n].cut
        side = _len(_sub(vertices[i], vertices[(i + 1) % n]))
        if exp_round > side:
            adjusts.append((side / exp_round, 0.0))
        elif exp_cut > side:
            adjusts.append((1.0, (side - exp_round) / (exp_cut - exp_round)))
        else:
            adjusts.append((1.0, 1.0))
    corner_cubics = []
    for i in range(n):
        allowed = []
        for delta in (0, 1):
            rc, cr = adjusts[(i + n - 1 + delta) % n]
            allowed.append(corners[i].round_cut * rc + (corners[i].cut - corners[i].round_cut) * cr)
        corner_cubics.append(corners[i].cubics(allowed[0], allowed[1]))
    # features: corner, edge, corner, edge, ...
    features = []
    for i in range(n):
        features.append(corner_cubics[i])
        features.append([_line(corner_cubics[i][-1][3], corner_cubics[(i + 1) % n][0][0])])
    # RoundedPolygon.cubics: start halfway through the first corner, drop
    # zero-length pieces (stretching the previous cubic to cover them)
    out = []
    first_end = first_start = None
    if len(features[0]) == 3:
        a, b = _split(features[0][1], 0.5)
        first_start = [features[0][0], a]
        first_end = [b, features[0][2]]
    last = None
    first = None
    for i in range(len(features) + 1):
        if i == 0 and first_end is not None:
            fc = first_end
        elif i == len(features):
            if first_start is None:
                break
            fc = first_start
        else:
            fc = features[i]
        for c in fc:
            if not _zero_length(c):
                if last is not None:
                    out.append(last)
                last = c
                if first is None:
                    first = c
            elif last is not None:
                last = (last[0], last[1], last[2], c[3])
    out.append((last[0], last[1], last[2], first[0]))
    return out


def _transform(cubics, f):
    return [tuple(f(p) for p in c) for c in cubics]


def _rotate(cubics, degrees):
    a = math.radians(degrees)
    ca, sa = math.cos(a), math.sin(a)
    return _transform(cubics, lambda p: (p[0] * ca - p[1] * sa, p[0] * sa + p[1] * ca))


def _scale(cubics, sx, sy):
    return _transform(cubics, lambda p: (p[0] * sx, p[1] * sy))


def normalized(cubics):
    """RoundedPolygon.normalized(): fit (approximate bounds) into the unit
    square, centred on the shorter axis."""
    xs = [p[0] for c in cubics for p in c]
    ys = [p[1] for c in cubics for p in c]
    w, h = max(xs) - min(xs), max(ys) - min(ys)
    side = max(w, h)
    ox = (side - w) / 2 - min(xs)
    oy = (side - h) / 2 - min(ys)
    return _transform(cubics, lambda p: ((p[0] + ox) / side, (p[1] + oy) / side))


# --- androidx Shapes.kt -----------------------------------------------------
def _ngon(n, radius=1.0):
    return [(radius * math.cos(2 * math.pi * i / n), radius * math.sin(2 * math.pi * i / n)) for i in range(n)]


def circle(n=8, radius=1.0):
    poly_r = radius / math.cos(math.pi / n)
    return rounded_polygon(_ngon(n, poly_r), [(radius, 0.0)] * n)


def rectangle(width, height, roundings):
    l, t, r, b = -width / 2, -height / 2, width / 2, height / 2
    return rounded_polygon([(r, b), (l, b), (l, t), (r, t)], roundings)


def star(n, radius=1.0, inner=0.5, rounding=(0.0, 0.0)):
    verts = []
    for i in range(n):
        a = 2 * math.pi * i / n
        verts.append((radius * math.cos(a), radius * math.sin(a)))
        a = math.pi / n * (2 * i + 1)
        verts.append((inner * math.cos(a), inner * math.sin(a)))
    return rounded_polygon(verts, [rounding] * len(verts))


def _custom(points, reps, center=(0.5, 0.5), mirroring=False):
    """MaterialShapes.customPolygon / doRepeat. points: [((x, y), (r, s))]."""
    out = []
    if mirroring:
        angles = [math.degrees(math.atan2(p[1] - center[1], p[0] - center[0])) for p, _ in points]
        dists = [_len(_sub(p, center)) for p, _ in points]
        actual = reps * 2
        section = 360 / actual
        last = len(points) - 1
        for it in range(actual):
            for index in range(len(points)):
                i = index if it % 2 == 0 else last - index
                if i > 0 or it % 2 == 0:
                    a = section * it + (angles[i] if it % 2 == 0 else section - angles[i] + 2 * angles[0])
                    a = math.radians(a)
                    out.append(((math.cos(a) * dists[i] + center[0], math.sin(a) * dists[i] + center[1]), points[i][1]))
    else:
        np_ = len(points)
        for it in range(np_ * reps):
            (x, y), r = points[it % np_]
            a = math.radians((it // np_) * 360 / reps)
            ox, oy = x - center[0], y - center[1]
            out.append(((ox * math.cos(a) - oy * math.sin(a) + center[0], ox * math.sin(a) + oy * math.cos(a) + center[1]), r))
    return rounded_polygon([p for p, _ in out], [r for _, r in out])


def P(x, y, r=0.0, s=0.0):
    return ((x, y), (r, s))


R15, R20, R30, R50, R100 = (0.15, 0), (0.2, 0), (0.3, 0), (0.5, 0), (1.0, 0)


# --- MaterialShapes.kt: the 35 shapes ---------------------------------------
def _material():
    return {
        "circle": circle(10),
        "square": rectangle(1, 1, [R30] * 4),
        "slanted": _custom([P(0.926, 0.970, 0.189, 0.811), P(-0.021, 0.967, 0.187, 0.057)], 2),
        "arch": _rotate(rounded_polygon(_ngon(4), [R100, R100, R20, R20]), -135),
        "fan": _custom([P(1.004, 1.000, 0.148, 0.417), P(0.000, 1.000, 0.151), P(0.000, -0.003, 0.148),
                        P(0.978, 0.020, 0.803)], 1),
        "arrow": _custom([P(0.500, 0.892, 0.313), P(-0.216, 1.050, 0.207), P(0.499, -0.160, 0.215, 1.000),
                          P(1.225, 1.060, 0.211)], 1),
        "semiCircle": rectangle(1.6, 1, [R20, R20, R100, R100]),
        "oval": _rotate(_scale(circle(8), 1, 0.64), -45),
        "pill": _custom([P(0.961, 0.039, 0.426), P(1.001, 0.428), P(1.000, 0.609, 1.000)], 2, mirroring=True),
        "triangle": _rotate(rounded_polygon(_ngon(3), [R20] * 3), -90),
        "diamond": _custom([P(0.500, 1.096, 0.151, 0.524), P(0.040, 0.500, 0.159)], 2),
        "clamShell": _custom([P(0.171, 0.841, 0.159), P(-0.020, 0.500, 0.140), P(0.170, 0.159, 0.159)], 2),
        "pentagon": _custom([P(0.500, -0.009, 0.172), P(1.030, 0.365, 0.164), P(0.828, 0.970, 0.169)], 1,
                            mirroring=True),
        "gem": _custom([P(0.499, 1.023, 0.241, 0.778), P(-0.005, 0.792, 0.208), P(0.073, 0.258, 0.228),
                        P(0.433, -0.000, 0.491)], 1, mirroring=True),
        "sunny": star(8, inner=0.8, rounding=R15),
        "verySunny": _custom([P(0.500, 1.080, 0.085), P(0.358, 0.843, 0.085)], 8),
        "cookie4": _custom([P(1.237, 1.236, 0.258), P(0.500, 0.918, 0.233)], 4),
        "cookie6": _custom([P(0.723, 0.884, 0.394), P(0.500, 1.099, 0.398)], 6),
        "cookie7": _rotate(star(7, inner=0.75, rounding=R50), -90),
        "cookie9": _rotate(star(9, inner=0.8, rounding=R50), -90),
        "cookie12": _rotate(star(12, inner=0.8, rounding=R50), -90),
        "ghostish": _custom([P(0.500, 0, 1.000), P(1, 0, 1.000), P(1, 1.140, 0.254, 0.106), P(0.575, 0.906, 0.253)],
                            1, mirroring=True),
        "clover4": _custom([P(0.500, 0.074), P(0.725, -0.099, 0.476)], 4, mirroring=True),
        "clover8": _custom([P(0.500, 0.036), P(0.758, -0.101, 0.209)], 8),
        "burst": _custom([P(0.500, -0.006, 0.006), P(0.592, 0.158, 0.006)], 12),
        "softBurst": _custom([P(0.193, 0.277, 0.053), P(0.176, 0.055, 0.053)], 10),
        "boom": _custom([P(0.457, 0.296, 0.007), P(0.500, -0.051, 0.007)], 15),
        "softBoom": _custom([P(0.733, 0.454), P(0.839, 0.437, 0.532), P(0.949, 0.449, 0.439, 1.000),
                             P(0.998, 0.478, 0.174)], 16, mirroring=True),
        "flower": _custom([P(0.370, 0.187), P(0.416, 0.049, 0.381), P(0.479, 0.001, 0.095)], 8, mirroring=True),
        "puffy": _scale(_custom([P(0.500, 0.053), P(0.545, -0.040, 0.405), P(0.670, -0.035, 0.426),
                                 P(0.717, 0.066, 0.574), P(0.722, 0.128), P(0.777, 0.002, 0.360),
                                 P(0.914, 0.149, 0.660), P(0.926, 0.289, 0.660), P(0.881, 0.346),
                                 P(0.940, 0.344, 0.126), P(1.003, 0.437, 0.255)], 2, mirroring=True), 1, 0.742),
        "puffyDiamond": _custom([P(0.870, 0.130, 0.146), P(0.818, 0.357), P(1.000, 0.332, 0.853)], 4,
                                mirroring=True),
        "pixelCircle": _custom([P(0.500, 0.000), P(0.704, 0.000), P(0.704, 0.065), P(0.843, 0.065),
                                P(0.843, 0.148), P(0.926, 0.148), P(0.926, 0.296), P(1.000, 0.296)], 2,
                               mirroring=True),
        "pixelTriangle": _custom([P(0.110, 0.500), P(0.113, 0.000), P(0.287, 0.000), P(0.287, 0.087),
                                  P(0.421, 0.087), P(0.421, 0.170), P(0.560, 0.170), P(0.560, 0.265),
                                  P(0.674, 0.265), P(0.675, 0.344), P(0.789, 0.344), P(0.789, 0.439),
                                  P(0.888, 0.439)], 1, mirroring=True),
        "bun": _custom([P(0.796, 0.500), P(0.853, 0.518, 1), P(0.992, 0.631, 1), P(0.968, 1.000, 1)], 2,
                       mirroring=True),
        "heart": _custom([P(0.500, 0.268, 0.016), P(0.792, -0.066, 0.958), P(1.064, 0.276, 1.000),
                          P(0.501, 0.946, 0.129)], 1, mirroring=True),
    }


SHAPES = {name: normalized(c) for name, c in _material().items()}
NAMES = list(SHAPES)

# LoadingIndicatorDefaults.IndeterminateIndicatorPolygons
LOADER_SEQUENCE = ["softBurst", "cookie9", "pentagon", "pill", "sunny", "cookie4", "oval"]
# LoadingIndicator.kt
MORPH_INTERVAL_MS = 650
GLOBAL_ROTATION_MS = 4666
SPRING_DAMPING = 0.6
SPRING_STIFFNESS = 200.0
# LoadingIndicatorDefaults: ActiveSize 38dp in a 48dp container
ACTIVE_SCALE = 38 / 48


def spring(t_ms):
    """Morph progress after t_ms of the indicator's spring (damping 0.6,
    stiffness 200, unit mass, from 0 to 1). Overshoots past 1."""
    t = t_ms / 1000
    w0 = math.sqrt(SPRING_STIFFNESS)
    z = SPRING_DAMPING
    wd = w0 * math.sqrt(1 - z * z)
    return 1 - math.exp(-z * w0 * t) * (math.cos(wd * t) + z * w0 / wd * math.sin(wd * t))


# --- outlines, sampling and morphing ----------------------------------------
def svg_path(cubics, size=1.0):
    def f(p):
        return f"{p[0] * size:.4f} {p[1] * size:.4f}"

    out = [f"M {f(cubics[0][0])}"]
    for c in cubics:
        out.append(f"C {f(c[1])} {f(c[2])} {f(c[3])}")
    out.append("Z")
    return " ".join(out)


def sample(cubics, n=160):
    """n points evenly spaced by arc length along the outline."""
    dense = []
    for c in cubics:
        for k in range(24):
            dense.append(_cubic_point(c, k / 24))
    dense.append(dense[0])
    acc = [0.0]
    for a, b in zip(dense, dense[1:]):
        acc.append(acc[-1] + _len(_sub(b, a)))
    total = acc[-1]
    out = []
    j = 0
    for i in range(n):
        target = total * i / n
        while acc[j + 1] < target:
            j += 1
        seg = acc[j + 1] - acc[j]
        t = 0 if seg == 0 else (target - acc[j]) / seg
        out.append(_lerp(dense[j], dense[j + 1], t))
    return out


def align(a, b):
    """Rotate the point list b (same length as a) to the cyclic offset that
    is closest to a. Both outlines run the same way round (all M3 shapes are
    built clockwise), so only the offset is searched."""
    n = len(a)
    best, best_k = None, 0
    for k in range(n):
        d = 0.0
        for i in range(0, n, 2):
            p, q = a[i], b[(i + k) % n]
            d += (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2
        if best is None or d < best:
            best, best_k = d, k
    return b[best_k:] + b[:best_k]


def morph(a, b, t):
    """Lerp two aligned point lists."""
    return [_lerp(p, q, t) for p, q in zip(a, b)]


def loader_scale(names=LOADER_SEQUENCE):
    """LoadingIndicator's calculateScaleFactor() times ActiveIndicatorScale:
    shrinks the sequence so no shape clips its box while it rotates."""
    factor = 1.0
    for n in names:
        pts = sample(SHAPES[n], 240)
        xs, ys = [p[0] for p in pts], [p[1] for p in pts]
        w, h = max(xs) - min(xs), max(ys) - min(ys)
        cx, cy = (max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2
        r = max(math.hypot(p[0] - cx, p[1] - cy) for p in pts)
        factor = min(factor, max(w / (2 * r), h / (2 * r)))
    return factor * ACTIVE_SCALE
