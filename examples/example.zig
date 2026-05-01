const std = @import("std");
const zn = @import("zionoise");

pub fn main() !void {
    std.debug.print("=== zionoise example ===\n\n", .{});

    std.debug.print("Perlin 2D at (0.5, 0.5): {d:.4}\n", .{zn.perlin2D(f32, 0.5, 0.5, 42)});
    std.debug.print("Simplex 2D at (1.0, 1.0): {d:.4}\n", .{zn.simplex2D(f32, 1.0, 1.0, 42)});
    std.debug.print("Simplex 3D at (1,1,1): {d:.4}\n", .{zn.simplex3D(f32, 1, 1, 1, 42)});
    std.debug.print("fBm (4 octaves): {d:.4}\n", .{zn.fbm2D(f32, 0.5, 0.5, 42, 4, 2.0, 0.5)});

    // ASCII noise visualization
    std.debug.print("\n2D Perlin noise:\n", .{});
    for (0..16) |y| {
        for (0..40) |x| {
            const v = zn.perlin2D(f32, @floatFromInt(x) / 10, @floatFromInt(y) / 10, 42);
            const c: u8 = if (v > 0.3) '#' else if (v > 0) '+' else if (v > -0.3) '.' else ' ';
            std.debug.print("{c}", .{c});
        }
        std.debug.print("\n", .{});
    }
}
