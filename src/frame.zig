const root = @import("root");
const file = root.file;
const string = root.string;
const std = @import("std");
const rl = @import("raylib");
pub const FrameList = std.ArrayList(rl.Texture2D);
const FrameName = []const u8;
const FrameNameList = std.ArrayList(FrameName);

/// Load the individual sprite frames to memory.
/// This function doesn't need to know the CWD because rl.LoadTexture() already
/// operates relative to CWD.
pub fn load(data: *root.Data, init: std.process.Init) void {
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
fn listFramesNames(init: std.process.Init, sprite: file.Sprite) FrameNameList {
    const sprite_dir_open = std.Io.Dir.openDir(
        std.Io.Dir.cwd(),
        init.io,
        sprite,
        .{ .iterate = true },
    ) catch |err| std.debug.panic("Couldn't open {s}. Error: {}\n", .{ sprite, err });
    defer sprite_dir_open.close(init.io);

    var dirwalker = std.Io.Dir.walkSelectively(sprite_dir_open, init.gpa) catch unreachable;
    defer dirwalker.deinit();

    var frame_name_list: FrameNameList = .empty;

    while (true) {
        const entry = dirwalker.next(init.io) catch unreachable;
        if (entry == null) break;
        if (entry.?.kind != .file) continue;

        const frame_name = entry.?.basename;

        if (!isValidFrame(frame_name)) continue;

        const filename_copy = std.mem.Allocator.dupe(init.arena.allocator(), u8, frame_name) catch unreachable;

        frame_name_list.append(init.arena.allocator(), filename_copy) catch |err|
            std.debug.panic("Error: {}\n", .{err});
    }

    std.mem.sort(FrameName, frame_name_list.items, {}, lessThan);

    return frame_name_list;
}

// NOTE: We can check that it is properly sorting by swapping a and b.
fn lessThan(_: void, a: FrameName, b: FrameName) bool {
    return std.mem.lessThan(u8, a, b);
}

/// We assume frame_name ends in ".png".
fn isValidFrame(frame_name: FrameName) bool {
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
