const main = @import("app.zig"); // Assuming your code is in main.zig
const App = main.App;
const MouseEvent = main.MouseEvent;

// We'll use the C allocator so the host language doesn't have to manage Zig memory
const std = @import("std");
const builtin = @import("builtin");

// 1. Chọn Allocator nền tùy theo môi trường

var da = std.heap.DebugAllocator(.{ .safety = false }).init;
var allocator = da.allocator();

/// EXPORT: Initialize the App and return an opaque pointer
export fn app_init(buffer: [*]u8, width: f64, height: f64, seed: u64) ?*App {
    const app_ptr = allocator.create(App) catch return null;

    app_ptr.* = App.initApp(.{
        .screenBuffer = buffer,
        .screenWidth = width,
        .screenHeight = height,
        .allocator = allocator,
        .seed = seed,
    });

    // Start logic (randomness, etc)
    app_ptr.startApp() catch {
        allocator.destroy(app_ptr);
        return null;
    };

    return app_ptr;
}

/// EXPORT: Update the state
export fn app_update(app: *App, dt: f64) i32 {
    app.update(dt) catch return 1;
    return 0;
}

/// EXPORT: Handle input
export fn app_on_mouse_click(app: *App, x: f64, y: f64) i32 {
    const pos = @Vector(2, f64){ x, y };
    app.onMouseInput(pos, MouseEvent.Lclicked) catch return 1;
    return 0;
}

/// EXPORT: Cleanup
export fn app_deinit(app: *App) void {
    app.stopApp();
    allocator.destroy(app);

    if (da.deinit() == .leak) {
        @breakpoint(); // Nếu chạy trong debugger/browser devtools, nó sẽ dừng tại đây
        while (true) {} // Treo máy để bạn soi memory
    }
}
