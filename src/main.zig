const rl = @import("raylib");
const std = @import("std");

const SCREEN_WIDTH = 1200;
const SCREEN_HEIGHT = 800;
const NAME = "Poorsprite";

pub fn main() void {
    // Work around bug: https://codeberg.org/ziglang/zig/issues/35512
    _ = std.debug.lockStderr(&.{});
    std.debug.unlockStderr();

    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, NAME);
    defer rl.CloseWindow();
    rl.InitAudioDevice();
    defer rl.CloseAudioDevice();
    rl.SetTargetFPS(60);

    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        defer rl.EndDrawing();
        defer rl.ClearBackground(rl.BLACK);
    }
}
