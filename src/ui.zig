//! Buttons and text
//! Must not allocate memory.

const std = @import("std");
const rl = @import("raylib");
const loader = @import("loader.zig");
const Filenamelist = @import("file.zig").FilenameList;

pub const Data = struct {
    show_menu: bool = true,
    select_idx: i32 = 0, // i32 so that we can use @mod w/ subtraction!
    animation_timer: f32 = 0.0,
    list: Filenamelist = .empty,
};

pub fn update(data: *Data) void {
    updateMenu(data);
}

fn updateMenu(data: *Data) void {
    const menu_item_count: i32 = @intCast(data.list.items.len);
    if (rl.IsKeyPressed(rl.KEY_M)) {
        data.show_menu = !data.show_menu;
    }
    if (menu_item_count == 0) return;
    if (rl.IsKeyPressed(rl.KEY_DOWN)) {
        data.select_idx = @mod((data.select_idx) + 1, menu_item_count);
    } else if (rl.IsKeyPressed(rl.KEY_UP)) {
        data.select_idx = @mod(data.select_idx - 1, menu_item_count);
    }
}

pub fn draw(data: *const Data) void {
    if (data.show_menu) {
        drawSelectionList(data);
        drawLoadedList();
    }
}

fn drawSelectionList(data: *const Data) void {
    const sprites = data.list;
    if (!data.show_menu) return;
    if (sprites.items.len == 0) rl.DrawText("EMPTY", 10, 30, 45, rl.RED) else {
        for (0..sprites.items.len) |i| {
            const color = if (i == data.select_idx)
                rl.GREEN
            else
                rl.WHITE;
            const text = sprites.items[i];
            rl.DrawText(text.ptr, 10, @as(i32, @intCast(10 + 40 * i)), 45, color);
        }
    }
}

fn drawLoadedList() void {}
