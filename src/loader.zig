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
const assets = @import("assets.zig");

pub fn update(
    init: std.process.Init,
    ui_data: *ui.Data,
    viewer_data: *viewer.Data,
) void {
    handleUi(init, ui_data);
    loadUiElements(init, ui_data);

    const filenames = ui_data.filelist;
    const select_idx: u32 = @intCast(ui_data.select_idx);
    handleViewer(init, viewer_data, filenames, select_idx);
}

const TEST_ELEMENT_POS: rl.Vector2 = .{ .x = 20, .y = setup.SCREEN_HEIGHT - 100 };
const TEST_ELEMENT_POS_2: rl.Vector2 = .{ .x = 20, .y = setup.SCREEN_HEIGHT - 200 };
const TEST_ELEMENT_POS_3: rl.Vector2 = .{ .x = 20, .y = setup.SCREEN_HEIGHT - 300 };

/// Create UI elements (buttons, timeline, ...) and load them
fn loadUiElements(
    init: std.process.Init,
    ui_data: *ui.Data,
) void {
    // IMPORTANT: Take POINTERS to Element's or ArrayList's,
    // else we're just copying an empty struct.

    const alloc = init.arena.allocator();
    const load = loadTextureFromAsset;
    const ui_elements = &ui_data.elements.items;

    if (ui_elements.len != 0) return;

    // Create the elements bases and add them to the list
    const pause_button = ui.Element.createBase(.ButtonPause, TEST_ELEMENT_POS);
    ui_data.elements.append(alloc, pause_button) catch unreachable;
    const zoom_in_button = ui.Element.createBase(.ButtonZoomIn, TEST_ELEMENT_POS_2);
    ui_data.elements.append(alloc, zoom_in_button) catch unreachable;
    const zoom_out_button = ui.Element.createBase(.ButtonZoomOut, TEST_ELEMENT_POS_3);
    ui_data.elements.append(alloc, zoom_out_button) catch unreachable;

    // Load their assets
    for (0..ui_elements.len) |i| {
        var element = &ui_elements.*[i];
        if (element.textures.items.len != 0) continue;

        switch (element.kind) {
            // WARNING: The order matters here; we rely on it when drawing.
            // Convention: The first element is the base button.
            .ButtonPause => {
                element.textures.append(alloc, load(assets.button)) catch unreachable;
                element.textures.append(alloc, load(assets.play)) catch unreachable;
                element.textures.append(alloc, load(assets.pause)) catch unreachable;
            },
            .ButtonZoomIn => {
                element.textures.append(alloc, load(assets.button)) catch unreachable;
                element.textures.append(alloc, load(assets.zoom_plus)) catch unreachable;
            },
            .ButtonZoomOut => {
                element.textures.append(alloc, load(assets.button)) catch unreachable;
                element.textures.append(alloc, load(assets.zoom_minus)) catch unreachable;
            },
        }

        const len = element.textures.items.len;
        std.log.debug("Element no.{d} textures len: {d}", .{ i, len });
    }
}

fn loadTextureFromAsset(
    asset: []const u8, // Note: Works because a slice is a pointer + a length.
) rl.Texture2D {
    const image = rl.LoadImageFromMemory(
        ".png",
        @ptrCast(asset),
        @intCast(asset.len),
    );
    return rl.LoadTextureFromImage(image);
}

fn handleUi(init: std.process.Init, data: *ui.Data) void {
    if (data.filelist.items.len == 0) data.filelist = file.lsSpriteDirs(init);
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
