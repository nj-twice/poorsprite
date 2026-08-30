const rl = @import("raylib");
pub const file = @import("file.zig");
pub const string = @import("string.zig");
const std = @import("std");
const frame = @import("frame.zig");

const SCREEN_WIDTH = 1200;
const SCREEN_HEIGHT = 800;
const NAME = "Poorsprite";

const MAX_LOADED_SPRITES = 1;

pub const Data = struct {
    show_menu: bool = true,
    select_idx: i32 = 0, // i32 so that we can use @mod w/ subtraction!
    sprites: file.FilenameList,
    frames: frame.FrameList = .empty,
    current_frame: ?u32 = null,
    animation_timer: f32 = 0.0,

    fn create(init: std.process.Init) Data {
        const sprites = file.lsSpriteDirs(init);
        return Data{
            .sprites = sprites,
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
        update(&data, init);

        rl.BeginDrawing();
        defer rl.EndDrawing();
        defer rl.ClearBackground(rl.BLACK);

        draw(&data);
    }
}

fn update(data: *Data, init: std.process.Init) void {
    updateMenu(data);
    if (rl.IsKeyPressed(rl.KEY_ENTER)) {
        frame.load(data, init);
    }
    updateAnimation(data);
}

fn updateAnimation(data: *Data) void {
    if (data.frames.items.len == 0) return;
    if (data.current_frame == null) return;

    data.animation_timer += rl.GetFrameTime();
    if (data.animation_timer > 0.5) {
        data.animation_timer = 0;
        data.current_frame.? = if (data.current_frame.? + 1 >= data.frames.items.len)
            0
        else
            data.current_frame.? + 1;
    }
}

fn draw(data: *const Data) void {
    frame.draw(data);
    if (data.show_menu) {
        drawSelectionList(data);
        drawLoadedList();
    }
}

fn drawSelectionList(data: *const Data) void {
    const sprites = data.sprites;
    if (data.show_menu) {
        if (sprites.items.len != 0) {
            for (0..sprites.items.len) |i| {
                const color = if (i == data.select_idx)
                    rl.GREEN
                else
                    rl.WHITE;
                const text = sprites.items[i];
                rl.DrawText(text.ptr, 10, @as(i32, @intCast(10 + 40 * i)), 45, color);
            }
        } else {
            rl.DrawText("EMPTY", 10, 30, 45, rl.RED);
        }
    }
}

fn updateMenu(data: *Data) void {
    const menu_item_count: i32 = @intCast(data.sprites.items.len);
    if (rl.IsKeyPressed(rl.KEY_M)) {
        data.show_menu = !data.show_menu;
    }
    if (menu_item_count != 0) {
        if (rl.IsKeyPressed(rl.KEY_DOWN)) {
            data.select_idx = @mod((data.select_idx) + 1, menu_item_count);
        } else if (rl.IsKeyPressed(rl.KEY_UP)) {
            data.select_idx = @mod(data.select_idx - 1, menu_item_count);
        }
    }
}

fn drawLoadedList() void {}
