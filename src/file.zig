const root = @import("root");
const std = @import("std");

pub const SpriteList = std.ArrayList(Sprite);
pub const Sprite = []const u8;

/// List "sprite directories" in the current directory.
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

    while (true) {
        const entry = dirwalker.next(init.io) catch unreachable;
        if (entry == null) break;
        if (!isSpriteDir(entry.?, init)) continue;

        // A subsequent call to next() renders the filename slice invalid memory.
        // We need to copy the bytes to an owned slice.
        const filename = entry.?.basename;
        const filename_copy = std.mem.Allocator.dupe(init.arena.allocator(), u8, filename) catch unreachable;

        filelist.append(init.arena.allocator(), filename_copy) catch |err| {
            std.log.err("Error: {}\n", .{err});
            @panic("Error\n");
        };
    }

    return filelist;
}

/// Takes a directory entry and returns whether or not it is a "sprite directory".
/// A sprite directory is a directory that contains at least one PNG file.
/// Determining whether or not the sprite can actually be loaded is beyond this
/// function's responsibility.
fn isSpriteDir(entry: std.Io.Dir.Walker.Entry, init: std.process.Init) bool {
    if (entry.kind != .directory) {
        std.log.debug("{s} is NOT a directory", .{entry.basename});
        return false;
    }

    // Open the directory and walk through it
    const dir_open = std.Io.Dir.openDir(
        entry.dir,
        init.io,
        entry.basename,
        .{ .iterate = true },
    ) catch |err|
        std.debug.panic("Couldn't open {}. Error: {}\n", .{ entry, err });
    defer dir_open.close(init.io);

    var dirwalker = std.Io.Dir.walkSelectively(dir_open, init.gpa) catch unreachable;
    defer dirwalker.deinit();

    while (true) {
        const sub_entry = dirwalker.next(init.io) catch unreachable;
        if (sub_entry == null) return false;

        const name = sub_entry.?.basename;
        const actual_suffix: []const u8 = getLastFourChars(name) catch continue;
        const expected_suffix: []const u8 = ".png";

        if (sub_entry.?.kind == .file and
            std.mem.eql(u8, expected_suffix, actual_suffix)) return true;
    }
}

const StringError = error{TooShort};

fn getLastFourChars(input: []const u8) StringError![]const u8 {
    if (input.len < 4) return StringError.TooShort;
    const len = input.len;

    const output: []const u8 = input[len - 4 .. len];
    return output;
}

test getLastFourChars {
    const string1 = "Hello, are you here?";
    const result1 = "ere?";
    const string2 = "Hi";
    const result2 = StringError.TooShort;
    const string3 = "OJpjdwx";
    const result3 = "jdwx";
    try std.testing.expectEqualSlices(
        u8,
        result1,
        getLastFourChars(string1) catch unreachable,
    );
    try std.testing.expectEqual(
        result2,
        getLastFourChars(string2),
    );
    try std.testing.expectEqualSlices(
        u8,
        result3,
        getLastFourChars(string3) catch unreachable,
    );
}
