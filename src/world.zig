const shareConst = @import("share.zig");
const std = @import("std");
const Lib = @import("canvas");

const Vector2 = shareConst.Vector2;
const GTTR = shareConst.GTTR;
const RADIUS = 15;
const PixelPerMeter = shareConst.PixelPerMeter;

const CordCompoents = std.ArrayList(Vector2);
const VelocityComponets = std.ArrayList(Vector2);
const ForcesComponets = std.ArrayList(Vector2);
const MassComopnets = std.ArrayList(f64);

pub const World = struct {
    allocator: std.mem.Allocator,
    cords: CordCompoents = .empty,
    vels: VelocityComponets = .empty,
    forces: ForcesComponets = .empty,
    masses: MassComopnets = .empty,
    len: usize = 0,

    pub fn init(allocator: std.mem.Allocator) World {
        return .{ .allocator = allocator };
    }

    pub fn spawn(self: *World, components: anytype) !void {
        const T = @TypeOf(components);
        const info = @typeInfo(T);

        // Khởi tạo giá trị mặc định để tránh mảng bị trống
        var c_val: Vector2 = .{ 0, 0 };
        var v_val: Vector2 = .{ 0, 0 };
        var m_val: f64 = 1.0; // Mặc định 1kg để không bị lỗi chia cho 0

        inline for (info.@"struct".fields) |field| {
            const value = @field(components, field.name);
            const FieldType = @TypeOf(value);

            if (std.mem.eql(u8, field.name, "cord") and FieldType == Vector2) {
                c_val = value;
            } else if (std.mem.eql(u8, field.name, "vel") and FieldType == Vector2) {
                v_val = value;
            } else if (std.mem.eql(u8, field.name, "mass") and (FieldType == f64 or FieldType == comptime_float or FieldType == comptime_int)) {
                m_val = value;
            }
        }

        // LUÔN LUÔN append vào TẤT CẢ các mảng sau khi duyệt xong
        try self.cords.append(self.allocator, c_val);
        try self.vels.append(self.allocator, v_val);
        try self.masses.append(self.allocator, m_val);
        try self.forces.append(self.allocator, .{ 0, 0 });

        // Cập nhật len dựa trên thực tế
        self.len = self.cords.items.len;
    }

    pub fn deinit(self: *World) void {
        self.cords.deinit(self.allocator);
        self.vels.deinit(self.allocator);
        self.forces.deinit(self.allocator);
        self.masses.deinit(self.allocator);
    }
};

pub fn drawnSystem(cords: []const Vector2, canvas: *Lib.Canvas) void {
    for (cords) |cord| Lib.Draw.drawCircle(canvas, cord, RADIUS, Lib.Color.RED);
}
/// function the move objects base on the forces it reicved
pub fn ForcesSystem(world: *World, dt: f64) void {
    // Lấy các slice ra trước để CPU truy cập nhanh hơn
    const forces = world.forces.items;
    const masses = world.masses.items;
    const vels = world.vels.items;
    const cords = world.cords.items;
    const dt_vec: Vector2 = @splat(dt);
    for (0..world.len) |i| {
        const m = masses[i];
        const m_inv_vec: Vector2 = @splat(1.0 / m);

        // 1. Accumulate Force
        forces[i] += Vector2{ 0, m * GTTR * PixelPerMeter };

        // 2. Integration (v = v + a*dt)
        const acceleration = forces[i] * m_inv_vec;
        vels[i] += acceleration * dt_vec;

        // 3. Move (p = p + v*dt)
        cords[i] += vels[i] * dt_vec;

        // 4. Reset
        forces[i] = .{ 0, 0 };
    }
}

// pub fn collisionSystem(world: *World) void {
//     const cords = world.cords.items;
//     const vels = world.vels.items;

//     const threshold = RADIUS * 2.0;
//     const threshold_sq = threshold * threshold;

   
// }

pub fn boundarySystem(world: *World, canvas: Lib.Canvas) void {
    const cords = world.cords.items;
    const vels = world.vels.items;

    // Sử dụng slice để an toàn hơn
    for (cords[0..world.len], vels[0..world.len]) |*pos, *vel| {
        // Kiểm tra va chạm sàn (Y-axis)
        if (pos.*[1] + RADIUS >= canvas.height) {
            pos.*[1] = canvas.height - RADIUS; // Fix lỗi lún sàn
            vel.*[1] *= -0.9; // Nảy lên và mất 10% năng lượng

            // Ma sát mặt đất: làm giảm vận tốc ngang (X-axis) khi chạm sàn
            vel.*[0] *= 0.95;
        }

        // Kiểm tra va chạm trần (Tùy chọn)
        if (pos.*[1] - RADIUS <= 0) {
            pos.*[1] = RADIUS;
            vel.*[1] *= -0.7;
        }

        // Kiểm tra va chạm tường trái/phải
        if (pos.*[0] + RADIUS >= canvas.width) {
            pos.*[0] = canvas.width - RADIUS;
            vel.*[0] *= -1;
        } else if (pos.*[0] - RADIUS <= 0) {
            pos.*[0] = RADIUS;
            vel.*[0] *= -1;
        }
    }
}
