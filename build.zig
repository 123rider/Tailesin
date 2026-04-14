const std = @import("std");

// Although this function looks imperative, it does not perform the build
// directly and instead it mutates the build graph (`b`) that will be then
// executed by an external runner. The functions in `std.Build` implement a DSL
// for defining build steps and express dependencies between them, allowing the
// build runner to parallelize the build automatically (and the cache system to
// know when a step doesn't need to be re-run).
pub fn build(b: *std.Build) void {
    // Standard target options allow the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});
    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});
    // It's also possible to define more custom flags to toggle optional features
    // of this build script using `b.option()`. All defined flags (including
    // target and optimize options) will be listed when running `zig build --help`
    // in this directory.

    // This creates a module, which represents a collection of source files alongside
    // some compilation options, such as optimization mode and linked system libraries.
    // Zig modules are the preferred way of making Zig code available to consumers.
    // addModule defines a module that we intend to make available for importing
    // to our consumers. We must give it a name because a Zig package can expose
    // multiple modules and consumers will need to be able to specify which
    // module they want to access.

    // Here we define an executable. An executable needs to have a root module
    // which needs to expose a `main` function. While we could add a main function
    // to the module defined above, it's sometimes preferable to split business
    // logic and the CLI into two separate modules.
    //
    // If your goal is to create a Zig library for others to use, consider if
    // it might benefit from also exposing a CLI tool. A parser library for a
    // data serialization format could also bundle a CLI syntax checker, for example.
    //
    // If instead your goal is to create an executable, consider if users might
    // be interested in also being able to embed the core functionality of your
    // program in their own executable in order to avoid the overhead involved in
    // subprocessing your CLI tool.
    //
    // If neither case applies to you, feel free to delete the declaration you
    // don't need and to put everything under a single module.

    const is_host = b.graph.host.query.eql(target.query);

    const shape_dep = b.dependency("Simple2DShape", .{
        .target = target,
        .optimize = optimize,
    });
    const shape_mod = shape_dep.module("Canvas");

    if (is_host) {
        const raylib_dep = b.dependency("raylib_zig", .{
            .target = target,
            .optimize = optimize,
        });

        const raylib = raylib_dep.module("raylib"); // main raylib module
        const raygui = raylib_dep.module("raygui"); // raygui module
        const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library

        const exe = b.addExecutable(.{
            .name = "Taliesin",
            .root_module = b.createModule(.{
                // b.createModule defines a new module just like b.addModule but,
                // unlike b.addModule, it does not expose the module to consumers of
                // this package, which is why in this case we don't have to give it a name.
                .root_source_file = b.path("src/main.zig"),
                // Target and optimization levels must be explicitly wired in when
                // defining an executable or library (in the root module), and you
                // can also hardcode a specific target for an executable or library
                // definition if desireable (e.g. firmware for embedded devices).
                .target = target,
                .optimize = optimize,
                // List of modules available for import in source files part of the
                // root module.
                .imports = &.{
                    // Here "Taliesin" is the name you will use in your source code to
                    // import this module (e.g. `@import("Taliesin")`). The name is
                    // repeated because you are allowed to rename your imports, which
                    // can be extremely useful in case of collisions (which can happen
                    // importing modules from different packages).
                    .{ .name = "raylib", .module = raylib },
                    .{ .name = "raygui", .module = raygui },
                },
            }),
        });

        exe.root_module.linkLibrary(raylib_artifact);
        exe.root_module.addImport("canvas", shape_mod);
        b.installArtifact(exe);

        const run_step = b.step("run", "Run the app");

        // This creates a RunArtifact step in the build graph. A RunArtifact step
        // invokes an executable compiled by Zig. Steps will only be executed by the
        // runner if invoked directly by the user (in the case of top level steps)
        // or if another step depends on it, so it's up to you to define when and
        // how this Run step will be executed. In our case we want to run it when
        // the user runs `zig build run`, so we create a dependency link.
        const run_cmd = b.addRunArtifact(exe);
        run_step.dependOn(&run_cmd.step);

        // By making the run step depend on the default step, it will be run from the
        // installation directory rather than directly from within the cache directory.
        run_cmd.step.dependOn(b.getInstallStep());

        // This allows the user to pass arguments to the application in the build
        // command itself, like this: `zig build run -- arg1 arg2 etc`
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
    }

    const lib = b.addLibrary(.{
        .name = "Taliesin",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/exports.zig"),
            // Target and optimization levels must be explicitly wired in when
            // defining an executable or library (in the root module), and you
            // can also hardcode a specific target for an executable or library
            // definition if desireable (e.g. firmware for embedded devices).
            .target = target,
            .optimize = optimize,
        }),
    });

    lib.linkLibC();
    lib.root_module.addImport("canvas", shape_mod);
    b.installArtifact(lib);

    const wasm_exe = b.addExecutable(.{
        .name = "Taliesin",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/exports.zig"),
            // Target and optimization levels must be explicitly wired in when
            // defining an executable or library (in the root module), and you
            // can also hardcode a specific target for an executable or library
            // definition if desireable (e.g. firmware for embedded devices).
            .target = b.resolveTargetQuery(.{
                .os_tag = .freestanding,
                .cpu_arch = .wasm32,
            }),
            .optimize = optimize,
            .imports = &.{.{ .name = "canvas", .module = shape_mod }},
        }),
    });
    wasm_exe.entry = .disabled;

    b.installArtifact(wasm_exe);
}
