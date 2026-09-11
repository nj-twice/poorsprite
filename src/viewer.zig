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
};

pub fn update(data: *Data) void {
    debug.assert(data.fps != 0);

    if (data.frames.items.len == 0) return;
    if (data.current_frame == null) return;

    data.timer += rl.GetFrameTime();
    if (data.timer > 1.0 / @as(f32, @floatFromInt(data.fps))) {
        data.timer = 0;
        data.current_frame.? = @mod(
            data.current_frame.? + 1,
            @as(u32, @intCast(data.frames.items.len)),
        );
    }
}
pub fn draw(data: *const Data) void {
    if (data.current_frame == null) return;
    const frame_idx = data.current_frame.?;

    const pos = rl.Vector2{ .x = 10, .y = 10 };
    const scale = 10;
    rl.DrawTextureEx(data.frames.items[frame_idx], pos, 0, scale, rl.WHITE);
}
