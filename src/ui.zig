//! Buttons and text
//! Must not allocate memory.

const std = @import("std");
const rl = @import("raylib");
const loader = @import("loader.zig");
const Filenamelist = @import("file.zig").FilenameList;
const viewer = @import("viewer.zig");
const setup = @import("setup.zig");

pub fn getTimelineTotalLength() i32 {
    const ELEMENT_SIZE = Config.ELEMENT_SCALED_SIZE;
    const SEGMENTS_COUNT = Config.TIMELINE_MID_SEGMENT_COUNT;

    return ELEMENT_SIZE * (SEGMENTS_COUNT + 2); // +2 for left and right edges
}

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
    pub const TIMELINE_MID_SEGMENT_COUNT = 11;
    pub const TIMELINE_ANCHOR_POS = rl.Vector2{
        .x = @floatFromInt(ELEMENT_MARGIN + ELEMENT_SCALED_SIZE + 70),
        .y = @floatFromInt(
            setup.SCREEN_HEIGHT - StatusBar.HEIGHT - 40 - ELEMENT_SCALED_SIZE,
        ),
    };
};

pub const ElementKind = enum {
    ButtonPause,
    ButtonZoomIn,
    ButtonZoomOut,
    ButtonFaster,
    ButtonSlower,
    TimelineLeft,
    TimelineRight,
    TimelineMid,
    TimelineCursor,
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
    Seek,
    None,
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
    drawInteractable(ui_data, viewer_data);
    drawStatusBar(viewer_data);
}

const SmallBuf = [16]u8;

fn drawStatusBar(data: *const viewer.Data) void {
    rl.DrawRectangle(0, setup.SCREEN_HEIGHT - Config.StatusBar.HEIGHT, setup.SCREEN_WIDTH, Config.StatusBar.HEIGHT, rl.ColorAlpha(rl.GREEN, 0.2));

    var frame_count_buf: SmallBuf = @splat(0);
    const frame_count = if (data.current_frame) |frame|
        std.fmt.bufPrint(frame_count_buf[0..], "{d}/{d}", .{ frame + 1, data.frames.items.len }) catch unreachable
    else
        std.fmt.bufPrint(frame_count_buf[0..], "NONE", .{}) catch unreachable;

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
        .TimelineCursor => .None,
        .TimelineLeft => .Seek,
        .TimelineMid => .Seek,
        .TimelineRight => .Seek,
    };
}

/// Works differently for timeline mid segment
fn isMouseOnElement(element: Element) bool {
    const mouse_pos = rl.GetMousePosition();

    const rect = if (element.kind != .TimelineMid)
        rl.Rectangle{
            .x = element.position.x,
            .y = element.position.y,
            .height = Element.SCALE * Element.IMAGE_SIZE,
            .width = Element.SCALE * Element.IMAGE_SIZE,
        }
    else
        // Extended rectangle for the whole timeline mid section
        rl.Rectangle{
            .x = element.position.x,
            .y = element.position.y,
            .height = Element.SCALE * Element.IMAGE_SIZE,
            .width = Element.SCALE * Element.IMAGE_SIZE * Config.TIMELINE_MID_SEGMENT_COUNT,
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

fn drawInteractable(
    ui_data: *const Data,
    viewer_data: *const viewer.Data,
) void {
    // std.log.debug("Element count: {}", .{ui_data.elements.items.len});

    for (0..ui_data.elements.items.len) |idx| {
        const element = &ui_data.elements.items[idx];
        if (!element.visible) continue;

        // std.log.debug("Element idx: {}", .{idx});
        // std.log.debug("Element kind: {}", .{element.kind});
        // std.log.debug("Element texture len: {}", .{element.textures.items.len});

        const mouse_pos = rl.GetMousePosition();
        const frame = rl.Rectangle{
            .x = element.position.x,
            .y = element.position.y,
            .height = Element.SCALE * Element.IMAGE_SIZE,
            .width = Element.SCALE * Element.IMAGE_SIZE,
        };

        switch (element.kind) {
            .ButtonPause => drawPauseButton(
                element,
                viewer_data.pause,
                frame,
                mouse_pos,
            ),
            .ButtonZoomIn => drawGenericButton(element, frame, mouse_pos),
            .ButtonZoomOut => drawGenericButton(element, frame, mouse_pos),
            .ButtonFaster => drawGenericButton(element, frame, mouse_pos),
            .ButtonSlower => drawGenericButton(element, frame, mouse_pos),
            .TimelineRight => drawTimeline(element, frame, mouse_pos),
            .TimelineLeft => drawTimeline(element, frame, mouse_pos),
            .TimelineMid => drawTimeline(element, frame, mouse_pos),
            .TimelineCursor => drawTimelineCursor(
                element,
                viewer_data.current_frame,
                @intCast(viewer_data.frames.items.len),
            ),
        }
    }
}

fn drawTimelineCursor(cursor: *Element, current_frame: ?u32, total_frames: u32) void {
    const textures = &cursor.textures.items;
    std.debug.assert(textures.len == 1);

    const displacement: f32 = if (current_frame) |frame| blk: {
        const ratio: f32 = @as(f32, @floatFromInt(frame)) / @as(
            f32,
            @floatFromInt(total_frames),
        );
        break :blk @as(f32, @floatFromInt(getTimelineTotalLength())) * ratio;
    } else 0.0;

    const position = rl.Vector2{
        .x = cursor.position.x + displacement - 20, // The cursor goes beyond the timeline. Until I look into this, let's just translate it by some hardcoded value.
        .y = cursor.position.y,
    };

    rl.DrawTextureEx(textures.*[0], position, 0, Element.SCALE, rl.GREEN);
}

fn drawTimeline(
    element: *Element,
    frame: rl.Rectangle,
    mouse_pos: rl.Vector2,
) void {
    const textures = &element.textures.items;
    std.debug.assert(textures.len == 1);

    switch (element.kind) {
        .TimelineMid => {
            for (0..Config.TIMELINE_MID_SEGMENT_COUNT) |i| {
                const pos = rl.Vector2{
                    .x = element.position.x + @as(f32, @floatFromInt(i * Config.ELEMENT_SCALED_SIZE)),
                    .y = element.position.y,
                };
                const displaced_frame = rl.Rectangle{
                    .x = frame.x + @as(f32, @floatFromInt(i * Config.ELEMENT_SCALED_SIZE)),
                    .y = frame.y,
                    .width = frame.width,
                    .height = frame.height,
                };
                if (rl.CheckCollisionPointRec(mouse_pos, displaced_frame))
                    rl.DrawTextureEx(textures.*[0], pos, 0, Element.SCALE, rl.GREEN)
                else
                    rl.DrawTextureEx(textures.*[0], pos, 0, Element.SCALE, rl.WHITE);
            }
        },
        .TimelineCursor => {}, // Handled externally
        else => {
            if (rl.CheckCollisionPointRec(mouse_pos, frame))
                rl.DrawTextureEx(textures.*[0], element.position, 0, Element.SCALE, rl.GREEN)
            else
                rl.DrawTextureEx(textures.*[0], element.position, 0, Element.SCALE, rl.WHITE);
        },
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
