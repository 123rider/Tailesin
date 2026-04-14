const Lib = @import("canvas");
const Canvas = Lib.Canvas;
const Color = Lib.Color;
const std = @import("std");
const share = @import("share.zig");

pub const MouseEvent = enum {
    Lclicked,
};

const World = @import("World.zig");

const AppConfig = struct {
    screenBuffer: [*]u8,
    screenWidth: f64,
    screenHeight: f64,
    allocator: std.mem.Allocator,
    seed: u64,
};

pub const App = struct {
    canvas: Lib.Canvas,
    allocator: std.mem.Allocator,
    ecm: World.World,
    // used for random generation
    seed: u64,

    pub fn initApp(config: AppConfig) App {
        const buffer: []Lib.Color.Pixel = @as([*]Lib.Color.Pixel, @ptrCast(@alignCast(config.screenBuffer)))[0..@intFromFloat(config.screenHeight * config.screenWidth)];

        return App{
            .allocator = config.allocator,
            .canvas = .{
                .width = config.screenWidth,
                .height = config.screenHeight,
                .buffer = buffer,
            },
            .ecm = World.World.init(config.allocator),
            .seed = config.seed
        };
    }
    pub fn startApp(self: *App) !void {
        var prng: std.Random.DefaultPrng = .init(self.seed);
        const rand = prng.random();

        for (0..10) |i| {
            try self.ecm.spawn(.{
                .cord = share.Vector2{ @floatFromInt(i * 60 + 20), self.canvas.height / 8 },
                .vel = share.Vector2{ (rand.float(f64) - 0.5) * 200, (rand.float(f64) - 0.5) * 100 },
                .mass = 10,
            });
        }
    }

    fn drawn(self: *App) !void {
        self.canvas.clearScreen(Color.WHITE);
        World.drawnSystem(self.ecm.cords.items, &self.canvas);
    }

    pub fn stopApp(self: *App) void {
        self.ecm.deinit();
    }

    pub fn update(self: *App, dt: f64) !void {
        World.ForcesSystem(&self.ecm, dt);
        World.boundarySystem(&self.ecm, self.canvas);
        try self.drawn();
    }

    pub fn onMouseInput(self: *App, cord: @Vector(2, f64), evnet: MouseEvent) !void {
        switch (evnet) {
            MouseEvent.Lclicked => {
                const x_dir: f64 = if (cord[0] <= self.canvas.width / 2) -1 else 1;
                try self.ecm.spawn(.{
                    .cord = cord,
                    .vel = share.Vector2{ 2 * share.PixelPerMeter * x_dir, 0 },
                    .mass = 10,
                });
            },
        }
    }
};
