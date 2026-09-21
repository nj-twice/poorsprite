//! Buttons and text
//! Must not allocate memory.

const std = @import("std");
const rl = @import("raylib");
const loader = @import("loader.zig");
const Filenamelist = @import("file.zig").FilenameList;

pub const ButtonAction = enum {
    TogglePause,
    // TODO: Add more!
};

pub const Element = struct {
    const SCALE: f32 = 3.0;
    const IMAGE_SIZE = 24; // Hardcoded for now. Must be consistent with assets' images.

    texture: rl.Texture2D,
    position: rl.Vector2,
    action: ?ButtonAction = null, // Null means not interactable (decorative)
};
pub const ElementList = std.ArrayList(Element);

pub const Data = struct {
    show_menu: bool = true,
    select_idx: i32 = 0, // i32 so that we can use @mod w/ subtraction!
    animation_timer: f32 = 0.0,
    filelist: Filenamelist = .empty,
    elements: ElementList = .empty,
};

pub fn update(data: *Data) ?ButtonAction {
    updateMenu(data);
    const button_action = updateButtons(data);
    return button_action;
}

fn updateButtons(data: *Data) ?ButtonAction {
    for (0..data.elements.items.len) |idx| {
        const element = data.elements.items[idx];
        if (isMouseOnElement(element) and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
            return data.elements.items[idx].action;
        }
    }
    return null;
}

fn isMouseOnElement(element: Element) bool {
    const mouse_pos = rl.GetMousePosition();
    const rect = rl.Rectangle{
        .x = element.position.x,
        .y = element.position.y,
        .height = Element.SCALE * Element.IMAGE_SIZE,
        .width = Element.SCALE * Element.IMAGE_SIZE,
    };
    return rl.CheckCollisionPointRec(mouse_pos, rect);
}

fn updateMenu(data: *Data) void {
    const menu_item_count: i32 = @intCast(data.filelist.items.len);
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
    drawButtons(data);
}

fn drawButtons(data: *const Data) void {
    for (0..data.elements.items.len) |idx| {
        const button = data.elements.items[idx];
        const mouse_pos = rl.GetMousePosition();
        const frame = rl.Rectangle{
            .x = button.position.x,
            .y = button.position.y,
            .height = Element.SCALE * Element.IMAGE_SIZE,
            .width = Element.SCALE * Element.IMAGE_SIZE,
        };
        if (rl.CheckCollisionPointRec(mouse_pos, frame))
            rl.DrawTextureEx(button.texture, button.position, 0, Element.SCALE, rl.GREEN)
        else
            rl.DrawTextureEx(button.texture, button.position, 0, Element.SCALE, rl.WHITE);
    }
}

fn drawSelectionList(data: *const Data) void {
    const sprites = data.filelist;
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
