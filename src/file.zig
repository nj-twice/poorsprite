//! Interface to the filesystem.
//! List and filter files.

const std = @import("std");
const string = @import("string.zig");

const Dir = std.Io.Dir;

pub const Filename = []const u8;
pub const FilenameList = std.ArrayList(Filename);

pub const Entry = Dir.Walker.Entry;
const EntryList = std.ArrayList(Entry);

/// List files in current directory and return the proper entries.
/// Optionally takes a filter_fn so that only entries for which the filter
/// evaluates to true are returned.
pub fn ls(
    init: std.process.Init,
    subdir: []const u8,
    filter_fn: *const fn (init: std.process.Init, entry: Entry) bool,
) Dir.OpenError!EntryList {
    const cwd = try std.Io.Dir.openDir(
        Dir.cwd(),
        init.io,
        subdir,
        .{ .iterate = true },
    );
    defer cwd.close(init.io);

    // We use gpa because it's a small local allocation.
    // What we actually need will be copied later.
    var dirwalker = Dir.walkSelectively(cwd, init.gpa) catch unreachable;
    defer dirwalker.deinit();

    var entry_list: EntryList = .empty;

    while (true) {
        const maybe_entry = dirwalker.next(init.io) catch unreachable;
        if (maybe_entry == null) break;
        const entry = maybe_entry.?;
        if (!filter_fn(init, entry)) continue;

        // Subsequent calls to next() invalidate previous iterations of slices inside entry.
        // We need to copy the bytes to owned slices.
        const path_copy: [:0]const u8 = std.mem.Allocator.dupeSentinel(
            init.arena.allocator(),
            u8,
            entry.path,
            0,
        ) catch unreachable;
        const basename_copy: [:0]const u8 = std.mem.Allocator.dupeSentinel(
            init.arena.allocator(),
            u8,
            entry.basename,
            0,
        ) catch unreachable;
        // NOTE: We used dupeSentinel and not regular dupe because otherwise,
        // the copied slices wouldn't satisfy the type requirements of Entry fields.
        // An alternative solution would be to @ptrCast the copies, but this results in
        // incorrect results when taking the raw ptr to the slice later.
        // This happens when casting to a C ptr in rl.DrawText(), for example.
        const entry_copy: Entry = .{
            .kind = entry.kind,
            .dir = entry.dir,
            .basename = basename_copy,
            .path = path_copy,
        };

        entry_list.append(init.arena.allocator(), entry_copy) catch |err| {
            std.debug.panic("Error: {}\n", .{err});
        };
    }

    return entry_list;
}

/// Convert a list of entries to a list of filenames.
pub fn entriesToFilenames(init: std.process.Init, entry_list: EntryList) FilenameList {
    var filename_list: FilenameList = .empty;
    const entry_len = entry_list.items.len;
    for (0..entry_len) |i| {
        filename_list.append(
            init.arena.allocator(),
            entry_list.items[i].basename,
        ) catch |err| {
            std.debug.panic("Error: {}\n", .{err});
        };
    }

    return filename_list;
}

/// List "sprite directories" in the current directory.
pub fn lsSpriteDirs(init: std.process.Init) FilenameList {
    const sprite_dirs = ls(init, ".", filters.isSpriteDir) catch unreachable;
    const sprite_filenames = entriesToFilenames(init, sprite_dirs);
    return sprite_filenames;
}

/// Useful filters meant to be passed to ls().
pub const filters = struct {
    /// Always evaluates to true. Used to list all files, unconditionally.
    pub fn none(init: std.process.Init, entry: Entry) bool {
        _ = init;
        _ = entry;
        return true;
    }

    /// Returns whether or not it is a "sprite directory".
    /// A sprite directory is a directory that contains at least one PNG file.
    /// Determining whether or not the sprite can actually be loaded is beyond this
    /// function's responsibility.
    fn isSpriteDir(init: std.process.Init, entry: Entry) bool {
        if (entry.kind != .directory) return false;
        const sub_entries = ls(init, entry.basename, isPngFile) catch unreachable;
        // A single "PNG file" is sufficient for the whole dir to qualify as sprite dir.
        if (sub_entries.items.len == 0) return false else return true;
    }

    fn isPngFile(init: std.process.Init, entry: Entry) bool {
        _ = init;
        if (entry.kind != .file) return false;
        const name = entry.basename;
        const actual_suffix: []const u8 = string.getLastFourChars(name) catch return false;
        const expected_suffix: []const u8 = ".png";
        if (std.mem.eql(u8, expected_suffix, actual_suffix)) return true else return false;
    }

    /// It is assumed frame_name already ends in ".png".
    pub fn isValidFrame(init: std.process.Init, entry: Entry) bool {
        _ = init;
        if (entry.kind != .file) return false;
        const frame_name = entry.basename;
        const no_suffix_name = string.removeSuffix(frame_name) catch return false;
        _ = std.fmt.parseInt(u32, no_suffix_name, 10) catch return false;
        return true;
    }
};
