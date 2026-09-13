//! Load and unload resources, interact with the environment.
//! Obviously, has no draw() function since it doesn't need to render anything.
//! Must be the only module that can allocate memory.

const rl = @import("raylib");
const frame = @import("frame.zig");
const file = @import("file.zig");
const std = @import("std");
const ui = @import("ui.zig");
const viewer = @import("viewer.zig");
const setup = @import("setup.zig");

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
        setInitialFrameProperties(viewer_data);
    }
    if (rl.IsKeyPressed(rl.KEY_BACKSPACE)) frame.unload(viewer_data);
}

const INIT_MARGIN = 80;

fn setInitialFrameProperties(viewer_data: *viewer.Data) void {
    // Calculate the appropriate zoom factor first.
    // The ideal initial position depends on the scaled frame.

    const target_size = if (setup.SCREEN_WIDTH < setup.SCREEN_HEIGHT)
        setup.SCREEN_WIDTH - (2 * INIT_MARGIN)
    else
        setup.SCREEN_HEIGHT - (2 * INIT_MARGIN);

    const actual_width: i32 = viewer_data.frames.items[0].width;
    const actual_height: i32 = viewer_data.frames.items[0].height;
    // To ensure the scaled frame fits into the square described by target_size,
    // we need to calculate zoom with respect to max(actual_width, actual_height).
    const actual_size = if (actual_height > actual_width) actual_height else actual_width;

    const zoom_factor: f32 =
        @as(f32, @floatFromInt(target_size)) / @as(f32, @floatFromInt(actual_size));

    const scaled_width: i32 =
        @trunc(@as(f32, @floatFromInt(actual_width)) * zoom_factor);
    const scaled_height: i32 =
        @trunc(@as(f32, @floatFromInt(actual_height)) * zoom_factor);

    const init_pos_x: f32 =
        @as(f32, @floatFromInt(setup.SCREEN_WIDTH)) / 2 -
        @as(f32, @floatFromInt(scaled_width)) / 2;
    const init_pos_y: f32 =
        @as(f32, @floatFromInt(setup.SCREEN_HEIGHT)) / 2 -
        @as(f32, @floatFromInt(scaled_height)) / 2;

    viewer_data.position = .{ .x = init_pos_x, .y = init_pos_y };
    viewer_data.zoom_factor = zoom_factor;
}
