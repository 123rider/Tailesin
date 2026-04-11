const Lib = @import("canvas");
const Canvas = Lib.Canvas;
const Color = Lib.Color;
const Vector2 = @Vector(2, f64);

const PhysicsData = struct {
    mass: *f64,
    force: *@Vector(2, f64),
    vel: *@Vector(2, f64),
    pos: *@Vector(2, f64),
};

/// 1m ~ 1 pixel
const PixelPerMeter = 100; // move these consts to somewhere else
///(m/s^2)
const GTTR = 9.8;

pub const SpriteInterface = struct {
    vtable: *const VTable,

    pub const VTable = struct {
        update: *const fn (self: *SpriteInterface, dt: f64, screenWidth: f64, screenHeight: f64) void,
        draw: *const fn (self: *SpriteInterface, canvas: *Canvas) void,
        getPhysics: ?*const fn (self: *SpriteInterface) PhysicsData = null,
    };

    pub fn update(self: *SpriteInterface, dt: f64, screenWidth: f64, screenHeight: f64) void {
        self.vtable.update(self, dt, screenWidth, screenHeight);
    }

    pub fn draw(self: *SpriteInterface, canvas: *Canvas) void {
        self.vtable.draw(self, canvas);
    }

    pub fn getPhysics(self: *SpriteInterface) ?PhysicsData {
        if (self.vtable.getPhysics) |func| return func(self);
        return null;
    }
};

pub const Thing = struct {
    interface: SpriteInterface,
    radius: f64,
    mass: f64,

    cord: Vector2,
    vel: Vector2,
    force: Vector2,

    pub fn init(cord: Vector2, r: f64, m: f64) Thing {
        return .{
            .interface = .{
                .vtable = &.{
                    .update = Thing.update,
                    .draw = Thing.draw,
                    .getPhysics = Thing.getPhysics,
                },
            },
            .cord = cord,
            .radius = r,
            .vel = .{ 0, 0 },
            .force = .{ 0, 0 },
            .mass = m,
        };
    }

    pub fn update(base: *SpriteInterface, dt: f64, screenWidth: f64, screenHeight: f64) void {
        const self: *Thing = @alignCast(@fieldParentPtr("interface", base));

        if (self.mass <= 0) return;

        // a = F/m
        const a = self.force * @as(Vector2, @splat(1 / self.mass));
        self.vel += a * @as(@Vector(2, f64), @splat(dt));

        // p = p + v * dt
        self.cord += self.vel * @as(@Vector(2, f64), @splat(dt));

        // border
        if (self.cord[1] + self.radius > screenHeight) {
            if (self.vel[1] <= 0.01) {
                self.vel[1] = 0;
            }
            self.cord[1] = screenHeight - self.radius;
            self.vel[1] *= -0.9;
        }

        if (self.cord[0] - self.radius < 0) {
            self.cord[0] = self.radius;
            self.vel[0] *= -0.9;
        } else if (self.cord[0] + self.radius > screenWidth) { // Sửa dấu < thành >
            self.cord[0] = screenWidth - self.radius;
            self.vel[0] *= -0.9;
        }
    }

    pub fn draw(base: *SpriteInterface, canvas: *Canvas) void {
        const self: *Thing = @alignCast(@fieldParentPtr("interface", base));

        Lib.Draw.drawCircle(canvas, self.cord, self.radius, Color.RED);
    }

    pub fn getPhysics(base: *SpriteInterface) PhysicsData {
        const self: *Thing = @alignCast(@fieldParentPtr("interface", base));
        return PhysicsData{
            .mass = &self.mass,
            .force = &self.force,
            .vel = &self.vel,
            .pos = &self.cord,
        };
    }
};
