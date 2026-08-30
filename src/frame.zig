const root = @import("root");
const file = root.file;
const string = root.string;
const std = @import("std");
const rl = @import("raylib");

pub const FrameList = std.ArrayList(rl.Texture2D);
const Filename = file.Filename;
const FilenameList = file.FilenameList;
const Entry = file.Entry;

/// Load the individual sprite frames to memory.
/// This function doesn't need to know the CWD because rl.LoadTexture() already
/// operates relative to CWD.
pub fn load(data: *root.Data, init: std.process.Init) void {
    if (data.sprites.items.len == 0) return;

    const select_idx: u32 = @intCast(data.select_idx);
    const selected_sprite = data.sprites.items[select_idx];

    const frames_names = listFramesNames(init, selected_sprite);

    for (0..frames_names.items.len) |i| {
        // Fill with 0's (splat) and not undefined, else path.ptr gets padded with
        // gibberish that is not readable by rl.LoadTexture(), which expects a
        // C-string (null-terminated).
        var path_buf: [100]u8 = @splat(0);
        const path = std.fmt.bufPrint(
            path_buf[0..],
            "{s}/{s}",
            .{ selected_sprite, frames_names.items[i] },
        ) catch unreachable;

        const texture = rl.LoadTexture(path.ptr);
        data.frames.append(init.arena.allocator(), texture) catch unreachable;
    }
    data.current_frame = 0;
}

/// From the selected sprite directory, extract then sort the names of all valid frames.
/// Currently, a valid frame has the filename "{int}.png".
/// Later, we might use more elaborate regex.
fn listFramesNames(init: std.process.Init, sprite: Filename) FilenameList {
    const frames = file.ls(init, sprite, isValidFrame) catch unreachable;
    const frames_names = file.entriesToFilenames(init, frames);
    std.mem.sort(Filename, frames_names.items, {}, lessThan);
    return frames_names;
}

// NOTE: We can check that it is properly sorting by swapping a and b.
fn lessThan(_: void, a: Filename, b: Filename) bool {
    return std.mem.lessThan(u8, a, b);
}

/// We assume frame_name ends in ".png".
fn isValidFrame(init: std.process.Init, entry: Entry) bool {
    _ = init;
    if (entry.kind != .file) return false;
    const frame_name = entry.basename;
    const no_suffix_name = string.removeSuffix(frame_name) catch return false;
    _ = std.fmt.parseInt(u32, no_suffix_name, 10) catch return false;
    return true;
}

pub fn draw(data: *const root.Data) void {
    if (data.current_frame == null) return;
    const frame_idx = data.current_frame.?;

    const pos = rl.Vector2{ .x = 10, .y = 10 };
    const scale = 10;
    rl.DrawTextureEx(data.frames.items[frame_idx], pos, 0, scale, rl.WHITE);
}
