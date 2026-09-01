//! Load and unload resources, interact with the environment.
//! Obviously, has no draw() function since it doesn't need to render anything.
//! Must be the only module that can allocate memory.

const rl = @import("raylib");
const frame = @import("frame.zig");
const file = @import("file.zig");
const std = @import("std");
const ui = @import("ui.zig");
const viewer = @import("viewer.zig");

pub fn update(
    init: std.process.Init,
    ui_data: *ui.Data,
    viewer_data: *viewer.Data,
) void {
    handleUi(init, ui_data);

    const filenames = ui_data.list;
    const select_idx: u32 = @intCast(ui_data.select_idx);
    handleViewer(init, viewer_data, filenames, select_idx);
}

fn handleUi(init: std.process.Init, data: *ui.Data) void {
    if (data.list.items.len == 0) data.list = file.lsSpriteDirs(init);
}

fn handleViewer(
    init: std.process.Init,
    viewer_data: *viewer.Data,
    filenames: file.FilenameList,
    select_idx: u32,
) void {
    if (rl.IsKeyPressed(rl.KEY_ENTER)) {
        frame.unload(viewer_data);
        frame.load(init, viewer_data, filenames, select_idx);
    }
    if (rl.IsKeyPressed(rl.KEY_BACKSPACE)) frame.unload(viewer_data);
}
