//! Animation viewer.
//! Must not allocate memory.

const file = @import("file.zig");
const frame = @import("frame.zig");
const rl = @import("raylib");
const debug = @import("std").debug;

pub const Data = struct {
    frames: frame.FrameList = .empty,
    current_frame: ?u32 = null,
    timer: f32 = 0.0,
    fps: u16 = 2, // MUST NOT BE ZERO
    position: rl.Vector2 = .{ .x = 0, .y = 0 },
    grab: Grab = Grab{},
    zoom_factor: f32 = 1.0,
};

const Grab = struct {
    yes: bool = false,
    offset: rl.Vector2 = .{ .x = 0, .y = 0 },
};

pub fn update(data: *Data) void {
    debug.assert(data.fps != 0);

    if (data.frames.items.len == 0) return;
    if (data.current_frame == null) return;

    updateFrame(data);
    updatePosition(data);
    updateZoom(data);
}

pub fn draw(data: *const Data) void {
    if (data.current_frame == null) return;
    const frame_idx = data.current_frame.?;

    const pos = data.position;
    const scale = data.zoom_factor;
    rl.DrawTextureEx(data.frames.items[frame_idx], pos, 0, scale, rl.WHITE);

    drawHoverOutline(data);
}

const LINE_THICKNESS = 7;

fn drawHoverOutline(data: *const Data) void {
    if (!isMouseOnFrame(data)) return;

    const outline_color = rl.ColorAlpha(rl.GREEN, 0.3);

    const rect = getFrameOutineRec(data);
    rl.DrawRectangleLinesEx(rect, LINE_THICKNESS, outline_color);
}

fn getFrameOutineRec(data: *const Data) rl.Rectangle {
    const position = data.position;
    const frame_idx = data.current_frame.?;
    const width = @trunc(@as(f32, @floatFromInt(
        data.frames.items[frame_idx].width,
    )) * data.zoom_factor);
    const height = @trunc(@as(f32, @floatFromInt(
        data.frames.items[frame_idx].height,
    )) * data.zoom_factor);

    const rect = rl.Rectangle{
        .x = position.x,
        .y = position.y,
        .height = height,
        .width = width,
    };

    return rect;
}

fn isMouseOnFrame(data: *const Data) bool {
    const rect = getFrameOutineRec(data);
    const mouse_pos = rl.GetMousePosition();
    return rl.CheckCollisionPointRec(mouse_pos, rect);
}

const ZOOM_INCREMENT: f32 = 0.3;

fn updateZoom(data: *Data) void {
    const wheel_move = rl.GetMouseWheelMove();
    if (wheel_move == 0) return;
    if (wheel_move > 0) {
        data.zoom_factor += ZOOM_INCREMENT;
    } else {
        if (data.zoom_factor - ZOOM_INCREMENT <= 0) return;
        data.zoom_factor -= ZOOM_INCREMENT;
    }
}

fn updatePosition(data: *Data) void {
    if (isMouseOnFrame(data) and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT))
        toggleGrab(data);
    if (!data.grab.yes) return;

    const mouse_pos = rl.GetMousePosition();
    const offset = data.grab.offset;
    data.position.x = mouse_pos.x - offset.x;
    data.position.y = mouse_pos.y - offset.y;
}

fn toggleGrab(data: *Data) void {
    const grab = &data.grab;
    if (grab.yes) {
        grab.yes = !grab.yes;
        grab.offset = .{ .x = 0, .y = 0 };
    } else {
        const mouse_pos = rl.GetMousePosition();
        const offset = rl.Vector2{
            .x = mouse_pos.x - data.position.x,
            .y = mouse_pos.y - data.position.y,
        };
        grab.offset = offset;
        grab.yes = !grab.yes;
    }
}

fn updateFrame(data: *Data) void {
    data.timer += rl.GetFrameTime();
    if (data.timer > 1.0 / @as(f32, @floatFromInt(data.fps))) {
        data.timer = 0;
        data.current_frame.? = @mod(
            data.current_frame.? + 1,
            @as(u32, @intCast(data.frames.items.len)),
        );
    }
}
