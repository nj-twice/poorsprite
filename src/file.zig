const root = @import("root");
const std = @import("std");

pub const SpriteList = std.ArrayList(Sprite);
pub const Sprite = []const u8;

/// List files in the current directory.
/// For now, it is meant to only run once, at startup.
pub fn ls(init: std.process.Init) SpriteList {
    const cwd_handle = std.Io.Dir.cwd();
    const cwd_open = std.Io.Dir.openDir(cwd_handle, init.io, ".", .{ .iterate = true }) catch |err| {
        std.log.err("Error: {}\n", .{err});
        @panic("Couldn't open CWD!\n");
    };
    defer cwd_open.close(init.io);

    // We use gpa because it's a small local allocation.
    // What we actually need will be copied later.
    var dirwalker = std.Io.Dir.walkSelectively(cwd_open, init.gpa) catch unreachable;
    defer dirwalker.deinit();

    var filelist: SpriteList = .empty;

    var entry = dirwalker.next(init.io) catch unreachable;
    while (entry != null) {
        // A subsequent call to next() renders the filename slice invalid memory.
        // We need to copy the bytes to owned slices.
        const filename = entry.?.basename;
        const filename_copy = std.mem.Allocator.dupe(init.arena.allocator(), u8, filename) catch unreachable;

        filelist.append(init.arena.allocator(), filename_copy) catch |err| {
            std.log.err("Error: {}\n", .{err});
            @panic("Error\n");
        };
        entry = dirwalker.next(init.io) catch unreachable;
    }

    return filelist;
}
