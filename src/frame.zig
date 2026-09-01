const file = @import("file.zig");
const std = @import("std");
const rl = @import("raylib");
const viewer = @import("viewer.zig");

pub const FrameList = std.ArrayList(rl.Texture2D);
const Filename = file.Filename;
const FilenameList = file.FilenameList;
const Entry = file.Entry;

/// Load actual sprite textures from sprite filenames.
/// This function doesn't need to know the CWD because rl.LoadTexture() already
/// operates relative to CWD.
pub fn load(
    init: std.process.Init,
    viewer_data: *viewer.Data,
    filenames: FilenameList,
    select_idx: u32,
) void {
    if (filenames.items.len == 0) return;
    const selected_sprite = filenames.items[select_idx];
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
        viewer_data.frames.append(init.arena.allocator(), texture) catch unreachable;
    }
    viewer_data.current_frame = 0;
}

pub fn unload(viewer_data: *viewer.Data) void {
    if (viewer_data.frames.items.len == 0 or viewer_data.current_frame == null) return;
    for (0..viewer_data.frames.items.len) |i| {
        rl.UnloadTexture(viewer_data.frames.items[i]);
    }
    viewer_data.current_frame = null;
    viewer_data.frames.clearRetainingCapacity();
}

/// From the selected sprite directory, extract then sort the names of all valid frames.
/// Currently, a valid frame has the filename "{int}.png".
/// Later, we might use more elaborate regex.
fn listFramesNames(init: std.process.Init, sprite: Filename) FilenameList {
    const frames = file.ls(init, sprite, file.filters.isValidFrame) catch unreachable;
    const frames_names = file.entriesToFilenames(init, frames);
    std.mem.sort(Filename, frames_names.items, {}, lessThan);
    return frames_names;
}

// NOTE: We can check that it is properly sorting by swapping a and b.
fn lessThan(_: void, a: Filename, b: Filename) bool {
    return std.mem.lessThan(u8, a, b);
}
