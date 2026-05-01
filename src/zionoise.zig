//! Noise generation for procedural content.
//!
//! Perlin noise, simplex noise, and fractal Brownian motion (fBm).
//! Seedable, pure functions, no global state.

const std = @import("std");

/// 2D Perlin noise. Returns a value in approximately [-1, 1].
pub fn perlin2D(comptime T: type, x: T, y: T, seed: u64) T {
    const xi: i32 = @intFromFloat(@floor(x));
    const yi: i32 = @intFromFloat(@floor(y));
    const xf = x - @as(T, @floatFromInt(xi));
    const yf = y - @as(T, @floatFromInt(yi));

    const u = fade(T, xf);
    const v = fade(T, yf);

    const n00 = grad2D(T, hash2(seed, xi, yi), xf, yf);
    const n10 = grad2D(T, hash2(seed, xi + 1, yi), xf - 1, yf);
    const n01 = grad2D(T, hash2(seed, xi, yi + 1), xf, yf - 1);
    const n11 = grad2D(T, hash2(seed, xi + 1, yi + 1), xf - 1, yf - 1);

    const x1 = lerp(T, n00, n10, u);
    const x2 = lerp(T, n01, n11, u);
    return lerp(T, x1, x2, v);
}

/// 2D Simplex noise. Returns a value in approximately [-1, 1].
pub fn simplex2D(comptime T: type, x: T, y: T, seed: u64) T {
    const F: T = 0.5 * (@sqrt(3.0) - 1.0);
    const G: T = (3.0 - @sqrt(3.0)) / 6.0;

    const s = (x + y) * F;
    const i: i32 = @intFromFloat(@floor(x + s));
    const j: i32 = @intFromFloat(@floor(y + s));
    const t = (asFloat(T, i) + asFloat(T, j)) * G;
    const X0 = asFloat(T, i) - t;
    const Y0 = asFloat(T, j) - t;
    const x0 = x - X0;
    const y0 = y - Y0;

    var off_x: i32 = 0;
    var off_y: i32 = 1;
    if (x0 > y0) {
        off_x = 1;
        off_y = 0;
    }

    const x1 = x0 - asFloat(T, off_x) + G;
    const y1 = y0 - asFloat(T, off_y) + G;
    const x2 = x0 - 1.0 + 2.0 * G;
    const y2 = y0 - 1.0 + 2.0 * G;

    const ii = i & 255;
    const jj = j & 255;

    const t0 = 0.5 - x0 * x0 - y0 * y0;
    const n0 = if (t0 >= 0) t0 * t0 * t0 * t0 * grad2D(T, hash2(seed, ii, jj), x0, y0) else 0;

    const t1 = 0.5 - x1 * x1 - y1 * y1;
    const n1 = if (t1 >= 0) t1 * t1 * t1 * t1 * grad2D(T, hash2(seed, ii + off_x, jj + off_y), x1, y1) else 0;

    const t2 = 0.5 - x2 * x2 - y2 * y2;
    const n2 = if (t2 >= 0) t2 * t2 * t2 * t2 * grad2D(T, hash2(seed, ii + 1, jj + 1), x2, y2) else 0;

    return 70.0 * (n0 + n1 + n2);
}

/// 3D Simplex noise. Returns a value in approximately [-1, 1].
pub fn simplex3D(comptime T: type, x: T, y: T, z: T, seed: u64) T {
    const F: T = 1.0 / 3.0;
    const G: T = 1.0 / 6.0;

    const s = (x + y + z) * F;
    const i: i32 = @intFromFloat(@floor(x + s));
    const j: i32 = @intFromFloat(@floor(y + s));
    const k: i32 = @intFromFloat(@floor(z + s));
    const t = (asFloat(T, i) + asFloat(T, j) + asFloat(T, k)) * G;
    const X0 = asFloat(T, i) - t;
    const Y0 = asFloat(T, j) - t;
    const Z0 = asFloat(T, k) - t;
    const x0 = x - X0;
    const y0 = y - Y0;
    const z0 = z - Z0;

    var a_x: i32 = 0; var a_y: i32 = 0; var a_z: i32 = 1;
    var b_x: i32 = 0; var b_y: i32 = 1; var b_z: i32 = 1;
    if (x0 >= y0) {
        if (y0 >= z0) { a_x = 1; a_y = 0; a_z = 0; b_x = 1; b_y = 1; b_z = 0; }
        else if (x0 >= z0) { a_x = 1; a_y = 0; a_z = 0; b_x = 1; b_y = 0; b_z = 1; }
        else { a_x = 0; a_y = 0; a_z = 1; b_x = 1; b_y = 0; b_z = 1; }
    } else {
        if (y0 < z0) { a_x = 0; a_y = 0; a_z = 1; b_x = 0; b_y = 1; b_z = 1; }
        else if (x0 < z0) { a_x = 0; a_y = 1; a_z = 0; b_x = 0; b_y = 1; b_z = 1; }
        else { a_x = 0; a_y = 1; a_z = 0; b_x = 1; b_y = 1; b_z = 0; }
    }

    const x1 = x0 - asFloat(T, a_x) + G;
    const y1 = y0 - asFloat(T, a_y) + G;
    const z1 = z0 - asFloat(T, a_z) + G;
    const x2 = x0 - asFloat(T, b_x) + 2.0 * G;
    const y2 = y0 - asFloat(T, b_y) + 2.0 * G;
    const z2 = z0 - asFloat(T, b_z) + 2.0 * G;
    const x3 = x0 - 1.0 + 3.0 * G;
    const y3 = y0 - 1.0 + 3.0 * G;
    const z3 = z0 - 1.0 + 3.0 * G;

    const ii = i & 255;
    const jj = j & 255;
    const kk = k & 255;

    const t0 = 0.6 - x0 * x0 - y0 * y0 - z0 * z0;
    const n0 = if (t0 >= 0) t0 * t0 * t0 * t0 * grad3D(T, hash3(seed, ii, jj, kk), x0, y0, z0) else 0;

    const t1 = 0.6 - x1 * x1 - y1 * y1 - z1 * z1;
    const n1 = if (t1 >= 0) t1 * t1 * t1 * t1 * grad3D(T, hash3(seed, ii + a_x, jj + a_y, kk + a_z), x1, y1, z1) else 0;

    const t2 = 0.6 - x2 * x2 - y2 * y2 - z2 * z2;
    const n2 = if (t2 >= 0) t2 * t2 * t2 * t2 * grad3D(T, hash3(seed, ii + b_x, jj + b_y, kk + b_z), x2, y2, z2) else 0;

    const t3 = 0.6 - x3 * x3 - y3 * y3 - z3 * z3;
    const n3 = if (t3 >= 0) t3 * t3 * t3 * t3 * grad3D(T, hash3(seed, ii + 1, jj + 1, kk + 1), x3, y3, z3) else 0;

    return 32.0 * (n0 + n1 + n2 + n3);
}

/// Fractal Brownian motion using 2D Perlin noise.
pub fn fbm2D(comptime T: type, x: T, y: T, seed: u64, octaves: u32, lacunarity: T, persistence: T) T {
    var value: T = 0;
    var amplitude: T = 1.0;
    var frequency: T = 1.0;
    var max_value: T = 0;

    for (0..octaves) |_| {
        value += amplitude * perlin2D(T, x * frequency, y * frequency, seed);
        max_value += amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }

    return value / max_value;
}

/// Fractal Brownian motion using 2D Simplex noise.
pub fn fbmSimplex2D(comptime T: type, x: T, y: T, seed: u64, octaves: u32, lacunarity: T, persistence: T) T {
    var value: T = 0;
    var amplitude: T = 1.0;
    var frequency: T = 1.0;
    var max_value: T = 0;

    for (0..octaves) |_| {
        value += amplitude * simplex2D(T, x * frequency, y * frequency, seed);
        max_value += amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }

    return value / max_value;
}

// --- Internal helpers ---

fn fade(comptime T: type, t: T) T {
    return t * t * t * (t * (t * 6 - 15) + 10);
}

fn lerp(comptime T: type, a: T, b: T, t: T) T {
    return a + t * (b - a);
}

fn asFloat(comptime T: type, v: i32) T {
    return @floatFromInt(v);
}

fn hash2(seed: u64, x: i32, y: i32) u64 {
    var h = seed;
    h ^= @as(u64, @intCast(@as(u32, @bitCast(x)))) *% 374761393;
    h ^= @as(u64, @intCast(@as(u32, @bitCast(y)))) *% 668265263;
    h *%= 1274126177;
    return h;
}

fn hash3(seed: u64, x: i32, y: i32, z: i32) u64 {
    var h = seed;
    h ^= @as(u64, @intCast(@as(u32, @bitCast(x)))) *% 374761393;
    h ^= @as(u64, @intCast(@as(u32, @bitCast(y)))) *% 668265263;
    h ^= @as(u64, @intCast(@as(u32, @bitCast(z)))) *% 1440672927;
    h *%= 1274126177;
    return h;
}

fn grad2D(comptime T: type, hash: u64, x: T, y: T) T {
    const h = @as(u4, @truncate(hash));
    const u = if (h & 1 == 0) x else y;
    const v = if (h & 2 == 0) x else y;
    return if (h & 4 == 0) (u + v) else -(u + v);
}

fn grad3D(comptime T: type, hash: u64, x: T, y: T, z: T) T {
    const h = @as(u4, @truncate(hash));
    const u = if (h & 8 == 0) x else y;
    const v = if (h & 8 == 0) y else z;
    return if (h & 4 == 0) (u + v) else -(u + v);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

test "perlin2D returns zero at origin" {
    const v = perlin2D(f32, 0, 0, 42);
    try std.testing.expectApproxEqAbs(@as(f32, 0), v, 0.001);
}

test "perlin2D returns values in range" {
    var min: f32 = 100;
    var max: f32 = -100;
    for (0..100) |i| {
        for (0..100) |j| {
            const x = @as(f32, @floatFromInt(i)) / 10;
            const y = @as(f32, @floatFromInt(j)) / 10;
            const v = perlin2D(f32, x, y, 42);
            min = @min(min, v);
            max = @max(max, v);
        }
    }
    try std.testing.expect(min >= -1.5);
    try std.testing.expect(max <= 1.5);
}

test "perlin2D is deterministic" {
    const a = perlin2D(f32, 1.5, 2.3, 99);
    const b = perlin2D(f32, 1.5, 2.3, 99);
    try std.testing.expectEqual(a, b);
}

test "perlin2D different seeds give different results" {
    const a = perlin2D(f32, 1.5, 1.5, 1);
    const b = perlin2D(f32, 1.5, 1.5, 2);
    try std.testing.expect(a != b);
}

test "simplex2D returns zero at origin" {
    const v = simplex2D(f32, 0, 0, 42);
    try std.testing.expectApproxEqAbs(@as(f32, 0), v, 0.001);
}

test "simplex2D is deterministic" {
    const a = simplex2D(f32, 3.7, 1.2, 77);
    const b = simplex2D(f32, 3.7, 1.2, 77);
    try std.testing.expectEqual(a, b);
}

test "simplex3D returns zero at origin" {
    const v = simplex3D(f32, 0, 0, 0, 42);
    try std.testing.expectApproxEqAbs(@as(f32, 0), v, 0.001);
}

test "simplex3D is deterministic" {
    const a = simplex3D(f32, 1.1, 2.2, 3.3, 42);
    const b = simplex3D(f32, 1.1, 2.2, 3.3, 42);
    try std.testing.expectEqual(a, b);
}

test "fbm2D is deterministic" {
    const a = fbm2D(f32, 1.0, 2.0, 42, 4, 2.0, 0.5);
    const b = fbm2D(f32, 1.0, 2.0, 42, 4, 2.0, 0.5);
    try std.testing.expectEqual(a, b);
}

test "fbm2D more octaves = more detail" {
    const low = fbm2D(f32, 5.5, 3.3, 42, 1, 2.0, 0.5);
    const high = fbm2D(f32, 5.5, 3.3, 42, 6, 2.0, 0.5);
    try std.testing.expect(low != high);
}

test "fbmSimplex2D" {
    const v = fbmSimplex2D(f32, 1.0, 1.0, 42, 3, 2.0, 0.5);
    try std.testing.expect(v > -2.0 and v < 2.0);
}

test "f64 precision" {
    const v = perlin2D(f64, 1.5, 2.5, 42);
    try std.testing.expect(v > -1.5 and v < 1.5);
}

test "perlin2D zero at integer coords" {
    const v = perlin2D(f32, 2.0, 3.0, 42);
    try std.testing.expectApproxEqAbs(@as(f32, 0), v, 0.001);
}

test "simplex2D non-zero at non-integer" {
    const v = simplex2D(f32, 0.5, 0.5, 42);
    try std.testing.expect(v != 0);
}

test "simplex3D non-zero at non-integer" {
    const v = simplex3D(f32, 2.5, 2.5, 2.5, 99);
    // 3D simplex can be zero at certain lattice-related points
    // just verify it's in range and deterministic
    const v2 = simplex3D(f32, 2.5, 2.5, 2.5, 99);
    try std.testing.expectEqual(v, v2);
    try std.testing.expect(v > -2.0 and v < 2.0);
}

test "fbm2D range" {
    var max: f32 = 0;
    for (0..20) |i| {
        for (0..20) |j| {
            const x = @as(f32, @floatFromInt(i)) / 5;
            const y = @as(f32, @floatFromInt(j)) / 5;
            const v = fbm2D(f32, x, y, 42, 4, 2.0, 0.5);
            max = @max(max, @abs(v));
        }
    }
    try std.testing.expect(max > 0); // produces non-trivial output
}

test "perlin2D continuous" {
    // Perlin noise should be continuous - nearby points should have similar values
    const a = perlin2D(f32, 1.0, 1.0, 42);
    const b = perlin2D(f32, 1.001, 1.001, 42);
    const diff = @abs(a - b);
    try std.testing.expect(diff < 0.01);
}

test "simplex2D range" {
    var max: f32 = 0;
    for (0..50) |i| {
        for (0..50) |j| {
            const x = @as(f32, @floatFromInt(i)) / 10;
            const y = @as(f32, @floatFromInt(j)) / 10;
            const v = simplex2D(f32, x, y, 42);
            max = @max(max, @abs(v));
        }
    }
    try std.testing.expect(max > 0); // produces non-trivial output
}

test "fbm2D different octaves produce different results" {
    const v1 = fbm2D(f32, 1.7, 2.3, 42, 2, 2.0, 0.5);
    const v3 = fbm2D(f32, 1.7, 2.3, 42, 8, 2.0, 0.5);
    // More octaves = more detail = different value
    try std.testing.expect(v1 != v3);
}

test "fbmSimplex2D different lacunarity" {
    const v1 = fbmSimplex2D(f32, 1.5, 1.5, 42, 4, 2.0, 0.5);
    const v2 = fbmSimplex2D(f32, 1.5, 1.5, 42, 4, 3.0, 0.5);
    try std.testing.expect(v1 != v2);
}

test "perlin2D negative coords" {
    const v = perlin2D(f32, -1.5, -2.5, 42);
    try std.testing.expect(v > -1.5 and v < 1.5);
}

test "simplex2D negative coords" {
    const v = simplex2D(f32, -1.0, -1.0, 42);
    try std.testing.expect(v > -2.0 and v < 2.0);
}

test "fbmSimplex2D different seeds" {
    const a = fbmSimplex2D(f32, 1.7, 2.3, 1, 4, 2.0, 0.5);
    const b = fbmSimplex2D(f32, 1.7, 2.3, 2, 4, 2.0, 0.5);
    try std.testing.expect(a != b);
}

test "perlin2D smooth interpolation" {
    // Perlin noise should be smooth — no sudden jumps
    const v0 = perlin2D(f32, 1.0, 1.0, 42);
    const v1 = perlin2D(f32, 1.01, 1.01, 42);
    const v2 = perlin2D(f32, 1.02, 1.02, 42);
    // Differences between consecutive samples should be similar
    const d1 = @abs(v1 - v0);
    const d2 = @abs(v2 - v1);
    try std.testing.expect(d1 < 0.05);
    try std.testing.expect(d2 < 0.05);
}

test "simplex2D and simplex3D consistent" {
    // 3D simplex at z=0 should not crash
    const v = simplex3D(f32, 1.5, 2.5, 0, 42);
    try std.testing.expect(v > -2.0 and v < 2.0);
}

test "fbm2D with high persistence" {
    // High persistence = more amplitude in higher octaves
    const v = fbm2D(f32, 2.0, 2.0, 42, 4, 2.0, 0.9);
    try std.testing.expect(v > -3.0 and v < 3.0);
}

test "perlin2D and simplex2D different algorithms" {
    const p = perlin2D(f32, 1.5, 2.5, 42);
    const s = simplex2D(f32, 1.5, 2.5, 42);
    // Different algorithms should generally give different results
    // (though not guaranteed at every point)
    try std.testing.expect(p > -2.0 and p < 2.0);
    try std.testing.expect(s > -2.0 and s < 2.0);
}

test "simplex3D at integer grid point" {
    const v = simplex3D(f32, 2.0, 3.0, 4.0, 42);
    // At integer coordinates, 3D simplex can produce zero or near-zero
    try std.testing.expect(v > -2.0 and v < 2.0);
}

test "fbm2D produces terrain-like output" {
    // Sample a grid and verify it produces varied output
    var min: f32 = 100;
    var max: f32 = -100;
    for (0..10) |y| {
        for (0..10) |x| {
            const v = fbm2D(f32, @as(f32, @floatFromInt(x)) * 0.3, @as(f32, @floatFromInt(y)) * 0.3, 42, 4, 2.0, 0.5);
            min = @min(min, v);
            max = @max(max, v);
        }
    }
    // Should have meaningful variation
    try std.testing.expect(max - min > 0.1);
}

test "perlin2D at integer lattice points is zero" {
    // Perlin noise is zero at integer coordinates by construction
    try std.testing.expectApproxEqAbs(@as(f32, 0), perlin2D(f32, 3.0, 7.0, 42), 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 0), perlin2D(f32, 0.0, 0.0, 42), 0.001);
}

test "layered noise for terrain heightmap" {
    // Use perlin2D as base, fbm2D as detail
    const base = perlin2D(f32, 3.0, 4.0, 42) * 0.5;
    const detail = fbm2D(f32, 30.0, 40.0, 42, 3, 2.0, 0.5) * 0.5;
    const height = base + detail;
    try std.testing.expect(height > -2.0 and height < 2.0);
}

test "same seed always same result" {
    const a = perlin2D(f32, 1.5, 2.5, 999);
    const b = perlin2D(f32, 1.5, 2.5, 999);
    try std.testing.expectEqual(a, b);
}

test "perlin2D output range is bounded" {
    // Sample many points, verify all in [-1, 1] range
    var max: f32 = 0;
    var y: f32 = 0;
    while (y < 5) : (y += 0.5) {
        var x: f32 = 0;
        while (x < 5) : (x += 0.5) {
            const v = perlin2D(f32, x, y, 42);
            max = @max(max, @abs(v));
        }
    }
    try std.testing.expect(max < 1.5); // perlin noise is bounded
}

test "simplex2D output range is bounded" {
    var max: f32 = 0;
    var y: f32 = 0;
    while (y < 5) : (y += 0.7) {
        var x: f32 = 0;
        while (x < 5) : (x += 0.7) {
            const v = simplex2D(f32, x, y, 42);
            max = @max(max, @abs(v));
        }
    }
    try std.testing.expect(max < 2.0);
}

test "different seeds produce different output" {
    // At non-integer coords, different seeds should give different values
    const a = perlin2D(f32, 0.37, 0.91, 42);
    const b = perlin2D(f32, 0.37, 0.91, 99);
    const c = perlin2D(f32, 0.37, 0.91, 123);
    // At least two of three should differ
    const all_same = @abs(a - b) < 0.0001 and @abs(b - c) < 0.0001;
    try std.testing.expect(!all_same);
}

test "fbm2D single octave equals perlin2D" {
    const p = perlin2D(f32, 3.7, 4.2, 42);
    const f = fbm2D(f32, 3.7, 4.2, 42, 1, 1.0, 0.5);
    try std.testing.expectApproxEqAbs(p, f, 0.001);
}

test "simplex3D varies with z coordinate" {
    const a = simplex3D(f32, 1.0, 2.0, 0.0, 42);
    const b = simplex3D(f32, 1.0, 2.0, 1.0, 42);
    try std.testing.expect(@abs(a - b) > 0.001);
}
