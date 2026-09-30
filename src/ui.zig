//! Buttons and text
//! Must not allocate memory.

const std = @import("std");
const rl = @import("raylib");
const loader = @import("loader.zig");
const Filenamelist = @import("file.zig").FilenameList;
const viewer = @import("viewer.zig");
const setup = @import("setup.zig");

pub const Config = struct {
    pub const StatusBar = struct {
        pub const HEIGHT = 50;
        pub const SPACING = 10;
        pub const MARGIN = 10;
    };
    pub const ELEMENT_MARGIN = 40;
    pub const ELEMENT_SIZE = Element.IMAGE_SIZE;
    pub const ELEMENT_SCALED_SIZE: i32 = @trunc(ELEMENT_SIZE * Element.SCALE);
    pub const BUTTON_SPACING = 10;
};

pub const ElementKind = enum {
    ButtonPause,
    ButtonZoomIn,
    ButtonZoomOut,
    ButtonFaster,
    ButtonSlower,
};

/// There is an incentive to keep this type separate from ElementKind.
/// Later, a single ElementKind might emit different actions depending on whether
/// the user left- or right-clicked, for exemple.
pub const ButtonAction = enum {
    TogglePause,
    ZoomIn,
    ZoomOut,
    Faster,
    Slower,
};

pub const Element = struct {
    const SCALE: f32 = 3.0;
    const IMAGE_SIZE = 24; // Hardcoded for now. Must be consistent with assets' images.

    textures: std.ArrayList(rl.Texture2D) = .empty,
    kind: ElementKind,
    position: rl.Vector2,
    visible: bool = true,

    /// Simply creates the base. The allocated fields are handled by the loader.
    pub fn createBase(kind: ElementKind, init_position: rl.Vector2) Element {
        return Element{
            .kind = kind,
            .position = init_position,
        };
    }
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
    const button_action = handleButtons(data);
    return button_action;
}

pub fn draw(
    ui_data: *const Data,
    viewer_data: *const viewer.Data,
) void {
    drawFromUiData(ui_data);
    drawButtons(ui_data, viewer_data);
    drawStatusBar(viewer_data);
}

const SmallBuf = [16]u8;

fn drawStatusBar(data: *const viewer.Data) void {
    rl.DrawRectangle(0, setup.SCREEN_HEIGHT - Config.StatusBar.HEIGHT, setup.SCREEN_WIDTH, Config.StatusBar.HEIGHT, rl.ColorAlpha(rl.GREEN, 0.2));

    const current_frame = if (data.current_frame) |frame| frame else 0;

    var frame_count_buf: SmallBuf = @splat(0);
    const frame_count = std.fmt.bufPrint(frame_count_buf[0..], "{d}/{d}", .{ current_frame, data.frames.items.len }) catch unreachable;
    var fps_buf: SmallBuf = @splat(0);
    const fps = std.fmt.bufPrint(fps_buf[0..], "{d}", .{data.fps}) catch unreachable;
    var zoom_factor_buf: SmallBuf = @splat(0);
    const zoom_factor = std.fmt.bufPrint(zoom_factor_buf[0..], "{d:3.1}", .{data.zoom_factor}) catch unreachable;

    drawStatusBarText(frame_count, 0);
    drawStatusBarText(fps, 1);
    drawStatusBarText(zoom_factor, 2);
}

fn drawStatusBarText(content: []const u8, idx: i32) void {
    rl.DrawText(content.ptr, 10 + ((idx + 1) * 250), setup.SCREEN_HEIGHT - 45, 45, rl.WHITE);
}

/// Handle buttons interaction
fn handleButtons(data: *Data) ?ButtonAction {
    for (0..data.elements.items.len) |idx| {
        const element = data.elements.items[idx];
        const action = getElementAction(element.kind);
        if (isMouseOnElement(element) and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
            return action;
        }
    }
    return null;
}

fn getElementAction(kind: ElementKind) ButtonAction {
    return switch (kind) {
        .ButtonPause => .TogglePause,
        .ButtonZoomIn => .ZoomIn,
        .ButtonZoomOut => .ZoomOut,
        .ButtonFaster => .Faster,
        .ButtonSlower => .Slower,
    };
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

fn drawFromUiData(data: *const Data) void {
    if (data.show_menu) {
        drawSelectionList(data);
        drawLoadedList();
    }
}

fn drawButtons(
    ui_data: *const Data,
    viewer_data: *const viewer.Data,
) void {
    std.log.debug("Element count: {}", .{ui_data.elements.items.len});

    for (0..ui_data.elements.items.len) |idx| {
        const button = &ui_data.elements.items[idx];
        if (!button.visible) continue;

        std.log.debug("Button idx: {}", .{idx});
        std.log.debug("Button kind: {}", .{button.kind});
        std.log.debug("Button texture len: {}", .{button.textures.items.len});

        const mouse_pos = rl.GetMousePosition();
        const frame = rl.Rectangle{
            .x = button.position.x,
            .y = button.position.y,
            .height = Element.SCALE * Element.IMAGE_SIZE,
            .width = Element.SCALE * Element.IMAGE_SIZE,
        };

        switch (button.kind) {
            .ButtonPause => drawPauseButton(
                button,
                viewer_data.pause,
                frame,
                mouse_pos,
            ),
            .ButtonZoomIn => drawGenericButton(button, frame, mouse_pos),
            .ButtonZoomOut => drawGenericButton(button, frame, mouse_pos),
            .ButtonFaster => drawGenericButton(button, frame, mouse_pos),
            .ButtonSlower => drawGenericButton(button, frame, mouse_pos),
        }
    }
}

fn drawPauseButton(
    button: *Element,
    pause_state: bool,
    frame: rl.Rectangle,
    mouse_pos: rl.Vector2,
) void {
    const textures = &button.textures.items;
    std.debug.assert(textures.len == 3);

    if (rl.CheckCollisionPointRec(mouse_pos, frame))
        rl.DrawTextureEx(textures.*[0], button.position, 0, Element.SCALE, rl.GREEN)
    else
        rl.DrawTextureEx(textures.*[0], button.position, 0, Element.SCALE, rl.WHITE);

    if (pause_state)
        rl.DrawTextureEx(textures.*[1], button.position, 0, Element.SCALE, rl.WHITE)
    else
        rl.DrawTextureEx(textures.*[2], button.position, 0, Element.SCALE, rl.WHITE);
}

/// A "generic button" has 2 textures at most: the base button and the icon.
fn drawGenericButton(
    button: *Element,
    frame: rl.Rectangle,
    mouse_pos: rl.Vector2,
) void {
    const textures = &button.textures.items;
    std.debug.assert(textures.len == 2);

    if (rl.CheckCollisionPointRec(mouse_pos, frame)) {
        rl.DrawTextureEx(textures.*[0], button.position, 0, Element.SCALE, rl.GREEN);
        rl.DrawTextureEx(textures.*[1], button.position, 0, Element.SCALE, rl.WHITE);
    } else {
        rl.DrawTextureEx(textures.*[0], button.position, 0, Element.SCALE, rl.WHITE);
        rl.DrawTextureEx(textures.*[1], button.position, 0, Element.SCALE, rl.WHITE);
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
