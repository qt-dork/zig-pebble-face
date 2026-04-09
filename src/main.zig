const std = @import("std");

const pebble = @import("pebble");
const presource = @import("pebble_appids");

const pog = @import("pog.zig");

const State = struct {
    window: ?*pebble.Window = null,
    bg_bitmap_layer: ?*pebble.BitmapLayer = null,
    bg_bitmap: ?*pebble.GBitmap = null,
    pm_bitmap_layer: ?*pebble.BitmapLayer = null,
    pm_bitmap: ?*pebble.GBitmap = null,
    date_layer: ?*pebble.Layer = null,
    // text_s_bitmap_layer: ?*pebble.BitmapLayer = null,
    s_digits_bitmap: ?*pebble.GBitmap = null,
    s_digits_bitmaps: [10]?*pebble.GBitmap = undefined,
    date_digits: [3]usize = [_]usize{ 0, 0, 0 },
    text_layer: ?*pebble.TextLayer = null,
};

const DATE_DIGIT_WIDTH: i16 = 7;
const DATE_DIGIT_HEIGHT: i16 = 14;
const DATE_DIGIT_X: i16 = 147;
const DATE_DIGIT_Y: i16 = 125;
const DATE_DIGIT_SKIP: i16 = 6;

var s = State{};

fn handle_tick(_: ?*pebble.tm, _: pebble.TimeUnits) callconv(.c) void {
    updateClock();
}

fn updateClock() void {
    var raw_time: pebble.time_t = undefined;
    var time_info: ?*pebble.tm = undefined;

    _ = pebble.time(&raw_time);
    time_info = pebble.localtime(&raw_time);

    // am/pm
    if (time_info.?.tm_hour > 11) {
        pebble.layer_set_hidden(pebble.bitmap_layer_get_layer(s.pm_bitmap_layer), false);
    } else {
        pebble.layer_set_hidden(pebble.bitmap_layer_get_layer(s.pm_bitmap_layer), true);
    }

    // date
    const month: usize = @intCast(time_info.?.tm_mon + 1);
    const day: usize = @intCast(time_info.?.tm_mday);
    setDate(month, day);
}

fn updateDate(_: ?*pebble.Layer, ctx: ?*pebble.GContext) callconv(.c) void {
    pebble.graphics_context_set_compositing_mode(ctx, pebble.GCompOpSet);

    const month = s.date_digits[0];
    const month_dest: pebble.GRect = .{ .origin = .{ .x = DATE_DIGIT_X, .y = DATE_DIGIT_Y }, .size = .{ .h = DATE_DIGIT_HEIGHT, .w = DATE_DIGIT_WIDTH } };
    pebble.graphics_draw_bitmap_in_rect(ctx, s.s_digits_bitmaps[month], month_dest);

    const day_x_offset = DATE_DIGIT_X + DATE_DIGIT_WIDTH + 6; // 6 is the width of the dash
    const tens_day_dest: pebble.GRect = .{ .origin = .{ .x = day_x_offset, .y = DATE_DIGIT_Y }, .size = .{ .h = DATE_DIGIT_HEIGHT, .w = DATE_DIGIT_WIDTH } };
    const ones_day_dest: pebble.GRect = .{ .origin = .{ .x = day_x_offset + DATE_DIGIT_WIDTH, .y = DATE_DIGIT_Y }, .size = .{ .h = DATE_DIGIT_HEIGHT, .w = DATE_DIGIT_WIDTH } };
    pebble.graphics_draw_bitmap_in_rect(ctx, s.s_digits_bitmaps[s.date_digits[1]], tens_day_dest);
    pebble.graphics_draw_bitmap_in_rect(ctx, s.s_digits_bitmaps[s.date_digits[2]], ones_day_dest);
}

fn setDate(month: usize, day: usize) void {
    pog.debug(@src(), "month: {d}, day: {d}", .{ month, day });
    s.date_digits[0] = month;
    s.date_digits[1] = @divTrunc(day, 10);
    s.date_digits[2] = day % 10;
    pebble.layer_mark_dirty(s.date_layer);
}

fn window_load(window: ?*pebble.Window) callconv(.c) void {
    const window_layer = pebble.window_get_root_layer(window);
    const bounds = pebble.layer_get_bounds(window_layer);

    s.bg_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.IMAGE_BG));
    s.bg_bitmap_layer = pebble.bitmap_layer_create(bounds);

    pebble.bitmap_layer_set_compositing_mode(s.bg_bitmap_layer, pebble.GCompOpSet);
    pebble.bitmap_layer_set_bitmap(s.bg_bitmap_layer, s.bg_bitmap);

    pebble.layer_add_child(window_layer, pebble.bitmap_layer_get_layer(s.bg_bitmap_layer));

    s.pm_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.SPRITE_PM));
    s.pm_bitmap_layer = pebble.bitmap_layer_create(.{ .origin = .{ .x = 23, .y = 153 }, .size = .{ .h = 6, .w = 17 } });

    pebble.bitmap_layer_set_compositing_mode(s.pm_bitmap_layer, pebble.GCompOpSet);
    pebble.bitmap_layer_set_bitmap(s.pm_bitmap_layer, s.pm_bitmap);

    pebble.layer_add_child(window_layer, pebble.bitmap_layer_get_layer(s.pm_bitmap_layer));

    pog.debug(@src(), "Hello!", .{});

    s.date_layer = pebble.layer_create(bounds);
    pebble.layer_set_update_proc(s.date_layer, updateDate);
    pebble.layer_add_child(window_layer, s.date_layer);
    s.s_digits_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.TYPE_S));
    for (0..10) |i| {
        const idx: i16 = @intCast(i);
        const coords: pebble.GRect = .{ .origin = .{ .x = 0, .y = idx * DATE_DIGIT_WIDTH }, .size = .{ .h = DATE_DIGIT_WIDTH, .w = DATE_DIGIT_WIDTH } }; // error from grect being bad?

        s.s_digits_bitmaps[i] = pebble.gbitmap_create_as_sub_bitmap(s.s_digits_bitmap, coords);
        pog.debug(@src(), "{d}", .{i});
    }

    // s.text_layer = pebble.text_layer_create(.{
    //     .origin = .{ .x = 0, .y = @divTrunc(bounds.size.h, 2) - 25 },
    //     .size = .{ .w = bounds.size.w, .h = 50 },
    // });
    // pebble.text_layer_set_font(s.text_layer, pebble.fonts_get_system_font(pebble.FONT_KEY_GOTHIC_28_BOLD));
    // pebble.text_layer_set_text_color(s.text_layer, pebble.GColorBlue);
    // pebble.text_layer_set_text_alignment(s.text_layer, pebble.GTextAlignmentCenter);
    // pebble.text_layer_set_text(s.text_layer, "Hello World!");

    // pebble.layer_add_child(window_layer, pebble.text_layer_get_layer(s.text_layer));
}

fn window_unload(_: ?*pebble.Window) callconv(.c) void {
    pebble.gbitmap_destroy(s.bg_bitmap);
    pebble.bitmap_layer_destroy(s.bg_bitmap_layer);

    pebble.gbitmap_destroy(s.pm_bitmap);
    pebble.bitmap_layer_destroy(s.pm_bitmap_layer);

    for (0..10) |i| {
        pebble.gbitmap_destroy(s.s_digits_bitmaps[i]);
    }
    pebble.gbitmap_destroy(s.s_digits_bitmap);
    pebble.layer_destroy(s.date_layer);
}

export fn main() void {
    s.window = pebble.window_create();
    if (s.window == null) {
        unreachable;
    }
    defer pebble.window_destroy(s.window);

    pebble.window_set_window_handlers(s.window, .{
        .load = window_load,
        .unload = window_unload,
    });

    pebble.window_stack_push(s.window, true);

    // update clock
    updateClock();
    pebble.tick_timer_service_subscribe(pebble.SECOND_UNIT, handle_tick);

    pebble.app_event_loop();
}
