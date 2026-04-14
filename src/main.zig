/// this lib only recived an buffer an proivde way to interact with that buffer
/// creating an buffer and display is your probelm
/// this example using raylib to render it out
const std = @import("std");
const rl = @import("raylib");
const builtin = @import("builtin");
const app = @import("app.zig");

const width = 1200;
const height = 600;
const maxDeletaTime = 0.016;

pub fn main() !void {
    var buffer: [width * height]@import("canvas").Color.Pixel = undefined;
    var da = if (builtin.mode == .Debug)
        std.heap.DebugAllocator(.{}).init
    else {};

    if (builtin.mode == .Debug) {
        defer _ = da.deinit();
    }

    const allocator = if (builtin.mode == .Debug)
        da.allocator()
    else
        std.heap.smp_allocator;

    var seed: u64 = undefined;
    std.crypto.random.bytes(std.mem.asBytes(&seed));

    var App = app.App.initApp(.{
        .screenBuffer = @ptrCast(&buffer),
        .screenHeight = height,
        .screenWidth = width,
        .allocator = allocator,
        .seed = seed,
    });

    rl.initWindow(width, height, "Zig Software Rasterizer");
    defer rl.closeWindow();
    const screenImage = rl.Image{
        .data = &buffer,
        .width = width,
        .height = height,
        .mipmaps = 1,
        .format = rl.PixelFormat.uncompressed_r8g8b8a8,
    };

    const screenTexture = try rl.loadTextureFromImage(screenImage);
    defer rl.unloadTexture(screenTexture);

    rl.setTargetFPS(60);

    try App.startApp();
    defer App.stopApp();

    while (!rl.windowShouldClose()) {
        if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
            const cord = rl.getMousePosition();
            try App.onMouseInput(
                .{ @floatCast(cord.x), @floatCast(cord.y) },
                app.MouseEvent.Lclicked,
            );
        }

        try App.update(@floatCast(@min(rl.getFrameTime(), maxDeletaTime)));

        // raylib logic to update buffer
        rl.updateTexture(screenTexture, @ptrCast(&buffer));
        rl.beginDrawing();
        defer rl.endDrawing();

        // Vẽ texture chứa kết quả rasterize của bạn lên toàn bộ cửa sổ
        rl.drawTexture(screenTexture, 0, 0, rl.Color.white);

        rl.drawFPS(10, 10);
    }
}
