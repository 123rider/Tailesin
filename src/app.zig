const Lib = @import("canvas");
const Canvas = Lib.Canvas;
const Color = Lib.Color;
const std = @import("std");

const GTTR = 9.8;

const Vector2 = @Vector(2, f64);
const PixelPerMeter = 100;

const AppConfig = struct {
    screenBuffer: [*]u8,
    screenWidth: f64,
    screenHeight: f64,
    allocator: std.mem.Allocator,
};

pub const App = struct {
    canvas: Lib.Canvas,
    allocator: std.mem.Allocator,

    pub fn initApp(config: AppConfig) App {
        const buffer: []Lib.Color.Pixel = @as([*]Lib.Color.Pixel, @ptrCast(@alignCast(config.screenBuffer)))[0..@intFromFloat(config.screenHeight * config.screenWidth)];

        return App{
            .allocator = config.allocator,
            .canvas = .{
                .width = config.screenWidth,
                .height = config.screenHeight,
                .buffer = buffer,
            },
        };
    }
    pub fn startApp(self: *App) !void {
        _ = self;
    }

    fn drawn(self: *App) !void {
        self.canvas.clearScreen(Color.WHITE);
    }

    pub fn stopApp(self: *App) void {
        _ = self;
    }

    pub fn update(self: *App, dt: f64) !void {
        _ = dt;
        try self.drawn();
    }
};
