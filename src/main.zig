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
    updateMenu(data);
}

fn draw(data: *const Data) void {
    if (data.show_menu) {
        drawSelectionList(data);
        drawLoadedList();
    }
}

fn drawSelectionList(data: *const Data) void {
    const files = data.files;
    if (data.show_menu) {
        if (files.items.len != 0) {
            for (0..files.items.len) |i| {
                const color = if (@as(i32, @intCast(i)) == data.select_idx)
                    rl.GREEN
                else
                    rl.WHITE;
                const text = files.items[i];
                rl.DrawText(text.ptr, 10, @as(i32, @intCast(10 + 40 * i)), 45, color);
            }
        } else {
            rl.DrawText("EMPTY", 10, 30, 45, rl.RED);
        }
    }
}

fn updateMenu(data: *Data) void {
    const menu_item_count: i32 = @intCast(data.files.items.len);
    if (rl.IsKeyPressed(rl.KEY_DOWN)) {
        data.select_idx = @mod(data.select_idx + 1, menu_item_count);
    } else if (rl.IsKeyPressed(rl.KEY_UP)) {
        data.select_idx = @mod(data.select_idx - 1, menu_item_count);
    }
    if (rl.IsKeyPressed(rl.KEY_M)) {
        data.show_menu = !data.show_menu;
    }
}

fn drawLoadedList() void {}
