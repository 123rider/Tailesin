const Lib = @import("canvas");
const Canvas = Lib.Canvas;
const Color = Lib.Color;
const std = @import("std");

const GTTR = 9.8;

const Vector2 = @Vector(2, f64);
const PixelPerMeter = 100;
const Sprite = @import("sprites.zig");

const AppConfig = struct {
    screenBuffer: [*]u8,
    screenWidth: f64,
    screenHeight: f64,
    allocator: std.mem.Allocator,
};

pub const App = struct {
    canvas: Lib.Canvas,
    sprites: std.ArrayList(*Sprite.SpriteInterface),
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
            .sprites = .empty,
        };
    }
    pub fn startApp(self: *App) !void {
        self.sprites.deinit(self.allocator);
        self.sprites = .empty;

        var prng: std.Random.DefaultPrng = .init(blk: {
            var seed: u64 = undefined;
            try std.posix.getrandom(std.mem.asBytes(&seed));
            break :blk seed;
        });

        const random = prng.random();

        const balls = try self.allocator.alloc(Sprite.Thing, 10);
        for (balls, 0..) |*ball, i| {
            const vx = random.float(f64) * 4 - 2;
            const vy = -(random.float(f64) * 4 + 1);
            ball.* = Sprite.Thing.init(
                .{ @floatFromInt(100 + 40 * i), 50 },
                10,
                10,
            );
            balls.ptr[i].vel = .{ vx * PixelPerMeter, vy * PixelPerMeter };
            try self.sprites.append(self.allocator, &balls.ptr[i].interface);
        }
    }

    fn drawn(self: *App) !void {
        self.canvas.clearScreen(Color.WHITE);
        for (self.sprites.items) |item| {
            item.draw(&self.canvas);
        }
    }

    pub fn stopApp(self: *App) void {
        self.sprites.deinit(self.allocator);
    }

    pub fn update(self: *App, dt: f64) !void {
        // update
        for (self.sprites.items) |sprite| {
            if (sprite.getPhysics()) |phys| {
                // Reset lực
                phys.force.* = .{ 0, 0 };

                // 1. Trọng lực
                const g_f = @Vector(2, f64){ 0, phys.mass.* * PixelPerMeter * GTTR };
                phys.force.* += g_f;

                // 2. Lực cản không khí
                const drag_k = 0.5;
                phys.force.* += phys.vel.* * @as(@Vector(2, f64), @splat(-drag_k));

                // 3. Bạn có thể thêm các trường lực (Fields) ở đây
                // phys.force.* += global_wind_field.getForce(phys.pos.*);
            }
        }

        for (self.sprites.items) |item| {
            item.update(dt, self.canvas.width, self.canvas.height);
        }
        try self.drawn();
    }
};
