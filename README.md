# zionoise

> Noise generation for Zig: Perlin, Simplex, fBm. Seedable, pure functions.

Part of the [zio-zig](https://github.com/deblasis/zio-zig) ecosystem.

## Quick start

```zig
const noise = @import("zionoise");

// Perlin noise 2D
const v1 = noise.perlin2D(f32, 1.5, 2.5, 42);  // seed=42

// Simplex noise 2D and 3D
const v2 = noise.simplex2D(f32, 1.5, 2.5, 42);
const v3 = noise.simplex3D(f32, 1.0, 2.0, 3.0, 42);

// Fractal Brownian Motion (layered noise)
const terrain = noise.fbm2D(f32, 10.0, 10.0, 42, 4, 2.0, 0.5);
//                        coords    seed  octaves lacunarity persistence

// Generate a terrain heightmap
for (0..height) |y| {
    for (0..width) |x| {
        const h = noise.fbm2D(f32,
            @floatFromInt(x) * 0.05,
            @floatFromInt(y) * 0.05,
            seed, 6, 2.0, 0.5);
        heightmap[y * width + x] = h;
    }
}
```

```bash
zig build test          # Run 40 tests
zig build run-example   # Run example
```

## Example output

```
$ zig build run-example
Perlin 2D at (0.5, 0.5): 0.7500
Simplex 2D at (1.0, 1.0): 0.8805
fBm (4 octaves): 0.4000

2D Perlin noise:
.+++++++++....     ..+###++....++#####++
+++####++++++..    .++####++++++#####++.
+###########++..  ..++#####++++######++.
#############++....++###############+...
```

## API

All functions are pure — no state, no allocation.

### Perlin noise
- `perlin2D(T, x, y, seed)` — 2D Perlin noise, returns `T`

### Simplex noise
- `simplex2D(T, x, y, seed)` — 2D Simplex noise
- `simplex3D(T, x, y, z, seed)` — 3D Simplex noise

### Fractal Brownian Motion
- `fbm2D(T, x, y, seed, octaves, lacunarity, persistence)` — Layered Perlin noise for terrain/clouds

### Properties
- Perlin noise: zero at integer coordinates, range ≈ [-1, 1]
- Simplex noise: range ≈ [-1, 1]
- Same seed + same coords = same result (deterministic)

## License

MIT. Copyright (c) 2026 Alessandro De Blasis.
