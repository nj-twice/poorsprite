const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const translate_c_raylib = b.addTranslateC(.{
        .root_source_file = b.path("c/raylib.h"),
        .target = target,
        .optimize = optimize,
    });

    translate_c_raylib.linkSystemLibrary("raylib", .{});

    const module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{
                .name = "raylib",
                .module = translate_c_raylib.createModule(),
            },
        },
    });

    const exe = b.addExecutable(.{
        .name = "poorsprite",
        .root_module = module,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the program");
    run_step.dependOn(&run_cmd.step);
}
