const rl = @import("raylib");
const file = @import("file.zig");
const std = @import("std");

const SCREEN_WIDTH = 1200;
const SCREEN_HEIGHT = 800;
const NAME = "Poorsprite";

const MAX_LOADED_FILES = 1;

const Data = struct {
    show_menu: bool = true,
    select_idx: i32 = 0,
    files: file.FileList,

    fn create(init: std.process.Init) Data {
        const files = file.ls(init);
        return Data{
            .files = files,
        };
    }

    // De-init allocated memory
    fn drop(self: *Data, init: std.process.Init) void {
        // The Init doc says that only arena is freed automatically.
        // It says nothing about gpa.
        // Since we properly use arena for long-living allocations,
        // we likely won't have to use this function.
        // We keep it nonetheless, just in case.
        _ = self;
        _ = init;
    }
};

pub fn main(init: std.process.Init) !void {
    // Work around bug: https://codeberg.org/ziglang/zig/issues/35512
    _ = std.debug.lockStderr(&.{});
    std.debug.unlockStderr();

    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, NAME);
    defer rl.CloseWindow();
    rl.InitAudioDevice();
    defer rl.CloseAudioDevice();
    rl.SetTargetFPS(60);

    var data = Data.create(init);
    defer data.drop(init);

    while (!rl.WindowShouldClose()) {
        update(&data);

        rl.BeginDrawing();
        defer rl.EndDrawing();
        defer rl.ClearBackground(rl.BLACK);

        draw(&data);
    }
}

fn update(data: *Data) void {
    _ = data; // autofix
}

fn draw(data: *const Data) void {
    if (data.show_menu) {
        drawSelectionList(data);
        drawLoadedList();
    }
}

fn drawSelectionList(data: *const Data) void {
    const files = data.files;
    for (0..files.items.len) |i| {
        std.debug.print("File: {s}\n", .{files.items[i]});
    }
    std.debug.print("-----\n", .{});
}

fn drawLoadedList() void {}
