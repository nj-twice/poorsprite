const rl = @import("raylib");
const std = @import("std");
const ui = @import("ui.zig");
const viewer = @import("viewer.zig");
const loader = @import("loader.zig");
const setup = @import("setup.zig");

pub const Data = struct {
    ui: ui.Data = ui.Data{},
    viewer: viewer.Data = viewer.Data{},
};

pub fn main(init: std.process.Init) !void {
    // Work around bug: https://codeberg.org/ziglang/zig/issues/35512
    _ = std.debug.lockStderr(&.{});
    std.debug.unlockStderr();

    rl.InitWindow(setup.SCREEN_WIDTH, setup.SCREEN_HEIGHT, setup.NAME);
    defer rl.CloseWindow();
    rl.InitAudioDevice();
    defer rl.CloseAudioDevice();
    rl.SetTargetFPS(60);

    var data = Data{};

    while (!rl.WindowShouldClose()) {
        update(&data, init);

        rl.BeginDrawing();
        defer rl.EndDrawing();
        defer rl.ClearBackground(rl.BLACK);

        draw(&data);
    }
}

fn update(data: *Data, init: std.process.Init) void {
    loader.update(init, &data.ui, &data.viewer);
    ui.update(&data.ui);
    viewer.update(&data.viewer);
}

fn draw(data: *const Data) void {
    viewer.draw(&data.viewer);
    ui.draw(&data.ui);
}
