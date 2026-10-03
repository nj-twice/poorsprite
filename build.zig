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

    loadUiAssets(b, exe);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the program");
    run_step.dependOn(&run_cmd.step);
}

fn loadUiAssets(b: *std.Build, exe: *std.Build.Step.Compile) void {
    exe.root_module.addAnonymousImport(
        "ui_button",
        .{ .root_source_file = b.path("assets/ui/icons/button.png") },
    );
    exe.root_module.addAnonymousImport(
        "ui_play",
        .{ .root_source_file = b.path("assets/ui/icons/play.png") },
    );
    exe.root_module.addAnonymousImport(
        "ui_pause",
        .{ .root_source_file = b.path("assets/ui/icons/pause.png") },
    );
    exe.root_module.addAnonymousImport(
        "ui_zoom_plus",
        .{ .root_source_file = b.path("assets/ui/icons/zoom_plus.png") },
    );
    exe.root_module.addAnonymousImport(
        "ui_zoom_minus",
        .{ .root_source_file = b.path("assets/ui/icons/zoom_minus.png") },
    );
    exe.root_module.addAnonymousImport(
        "ui_faster",
        .{ .root_source_file = b.path("assets/ui/icons/faster.png") },
    );
    exe.root_module.addAnonymousImport(
        "ui_slower",
        .{ .root_source_file = b.path("assets/ui/icons/slower.png") },
    );
    exe.root_module.addAnonymousImport(
        "ui_timeline_left",
        .{ .root_source_file = b.path("assets/ui/timeline/edge_left.png") },
    );
    exe.root_module.addAnonymousImport(
        "ui_timeline_right",
        .{ .root_source_file = b.path("assets/ui/timeline/edge_right.png") },
    );
    exe.root_module.addAnonymousImport(
        "ui_timeline_mid",
        .{ .root_source_file = b.path("assets/ui/timeline/mid.png") },
    );
    exe.root_module.addAnonymousImport(
        "ui_timeline_cursor",
        .{ .root_source_file = b.path("assets/ui/timeline/cursor.png") },
    );
}
