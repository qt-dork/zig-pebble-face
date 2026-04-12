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
    s_digits_bitmap: ?*pebble.GBitmap = null,
    s_digits_bitmaps: [10]?*pebble.GBitmap = undefined,
    date_digits: [3]usize = [_]usize{ 0, 0, 0 },

    sec_layer: ?*pebble.Layer = null,
    m_digits_bitmap: ?*pebble.GBitmap = null,
    m_digits_bitmaps: [10]?*pebble.GBitmap = undefined,
    sec_digits: [2]usize = [_]usize{ 0, 0 },

    min_layer: ?*pebble.Layer = null,
    l_digits_bitmap: ?*pebble.GBitmap = null,
    l_digits_bitmaps: [10]?*pebble.GBitmap = undefined,
    min_digits: [4]usize = [_]usize{ 0, 0, 0, 0 },

    text_layer: ?*pebble.TextLayer = null,
};

const DATE_DIGIT_WIDTH: i16 = 7;
const DATE_DIGIT_HEIGHT: i16 = 14;
const DATE_DIGIT_X: i16 = 147;
const DATE_DIGIT_Y: i16 = 125;
const DATE_DIGIT_SKIP: i16 = 6;

const SEC_DIGIT_WIDTH: i16 = 16;
const SEC_DIGIT_HEIGHT: i16 = 27;
const SEC_DIGIT_X: i16 = 143;
const SEC_DIGIT_Y: i16 = 157;
const SEC_DIGIT_SKIP: i16 = 2;

const MIN_DIGIT_WIDTH: i16 = 23;
const MIN_DIGIT_HEIGHT: i16 = 37;
const HR_DIGIT_X: i16 = 30;
const HR_DIGIT_Y: i16 = 147;
const HR_DIGIT_GAP: i16 = 3;
const HR_TO_MIN_DIGIT_GAP: i16 = 11;
const MIN_DIGIT_GAP: i16 = 2;

var s = State{};

// 55,83
// 52,52
// 54,52
const SEC_PATH_INFO: pebble.GPathInfo = .{
    .num_points = 3,
    .points = [_]pebble.GPoint{ .{ .x = 55, .y = 83 }, .{ .x = 52, .y = 60 }, .{ .x = 54, .y = 60 } },
};

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

    // sec
    const sec: usize = @intCast(time_info.?.tm_sec);
    setSec(sec);

    //hr-min
    const hr: usize = @intCast(time_info.?.tm_hour);
    const min: usize = @intCast(time_info.?.tm_min);
    setMin(hr, min);
}

fn updateDate(_: ?*pebble.Layer, ctx: ?*pebble.GContext) callconv(.c) void {
    pebble.graphics_context_set_compositing_mode(ctx, pebble.GCompOpSet);
    pog.debug(@src(), "date", .{});

    const month = s.date_digits[0];
    const month_dest: pebble.GRect = .{ .origin = .{ .x = DATE_DIGIT_X, .y = DATE_DIGIT_Y }, .size = .{ .h = DATE_DIGIT_HEIGHT, .w = DATE_DIGIT_WIDTH } };
    pebble.graphics_draw_bitmap_in_rect(ctx, s.s_digits_bitmaps[month], month_dest);
    const day_x_offset = DATE_DIGIT_X + DATE_DIGIT_WIDTH + 6; // 6 is the width of the dash
    const tens_day_dest: pebble.GRect = .{ .origin = .{ .x = day_x_offset, .y = DATE_DIGIT_Y }, .size = .{ .h = DATE_DIGIT_HEIGHT, .w = DATE_DIGIT_WIDTH } };
    const ones_day_dest: pebble.GRect = .{ .origin = .{ .x = day_x_offset + DATE_DIGIT_WIDTH + 2, .y = DATE_DIGIT_Y }, .size = .{ .h = DATE_DIGIT_HEIGHT, .w = DATE_DIGIT_WIDTH } };
    pebble.graphics_draw_bitmap_in_rect(ctx, s.s_digits_bitmaps[s.date_digits[1]], tens_day_dest);
    pebble.graphics_draw_bitmap_in_rect(ctx, s.s_digits_bitmaps[s.date_digits[2]], ones_day_dest);
}

fn setDate(month: usize, day: usize) void {
    const old_month = s.date_digits[0];
    const old_day = (s.date_digits[1] * 10) + s.date_digits[2];
    if (old_month == month and old_day == day) {
        return;
    }
    s.date_digits[0] = month;
    s.date_digits[1] = @divTrunc(day, 10);
    s.date_digits[2] = day % 10;

    pebble.layer_mark_dirty(s.date_layer);
}

fn updateSec(_: ?*pebble.Layer, ctx: ?*pebble.GContext) callconv(.c) void {
    pebble.graphics_context_set_compositing_mode(ctx, pebble.GCompOpSet);

    const tens_sec_dest: pebble.GRect = .{ .origin = .{ .x = SEC_DIGIT_X, .y = SEC_DIGIT_Y }, .size = .{ .h = SEC_DIGIT_HEIGHT, .w = SEC_DIGIT_WIDTH } };
    const ones_sec_dest: pebble.GRect = .{ .origin = .{ .x = SEC_DIGIT_X + SEC_DIGIT_WIDTH + 2, .y = SEC_DIGIT_Y }, .size = .{ .h = SEC_DIGIT_HEIGHT, .w = SEC_DIGIT_WIDTH } };
    pebble.graphics_draw_bitmap_in_rect(ctx, s.m_digits_bitmaps[s.sec_digits[0]], tens_sec_dest);
    pebble.graphics_draw_bitmap_in_rect(ctx, s.m_digits_bitmaps[s.sec_digits[1]], ones_sec_dest);
}

fn setSec(sec: usize) void {
    s.sec_digits[0] = @divTrunc(sec, 10);
    s.sec_digits[1] = sec % 10;
    pebble.layer_mark_dirty(s.sec_layer);
}

fn updateMin(_: ?*pebble.Layer, ctx: ?*pebble.GContext) callconv(.c) void {
    pebble.graphics_context_set_compositing_mode(ctx, pebble.GCompOpSet);
    pog.debug(@src(), "min", .{});

    const min_size = pebble.GSize{
        .h = MIN_DIGIT_HEIGHT,
        .w = MIN_DIGIT_WIDTH,
    };
    const tens_hr_dest: pebble.GRect = .{ .origin = .{ .x = HR_DIGIT_X, .y = HR_DIGIT_Y }, .size = min_size };
    const ones_hr_dest: pebble.GRect = .{ .origin = .{ .x = HR_DIGIT_X + MIN_DIGIT_WIDTH + HR_DIGIT_GAP, .y = HR_DIGIT_Y }, .size = min_size };

    const min_digit_x = HR_DIGIT_X + (MIN_DIGIT_WIDTH * 2) + (HR_DIGIT_GAP + HR_TO_MIN_DIGIT_GAP);
    const tens_min_dest: pebble.GRect = .{ .origin = .{ .x = min_digit_x, .y = HR_DIGIT_Y }, .size = min_size };
    const ones_min_dest: pebble.GRect = .{ .origin = .{ .x = min_digit_x + MIN_DIGIT_WIDTH + MIN_DIGIT_GAP, .y = HR_DIGIT_Y }, .size = min_size };

    if (s.min_digits[0] == 1) {
        pebble.graphics_draw_bitmap_in_rect(ctx, s.l_digits_bitmaps[s.min_digits[0]], tens_hr_dest);
    }
    pebble.graphics_draw_bitmap_in_rect(ctx, s.l_digits_bitmaps[s.min_digits[1]], ones_hr_dest);
    pebble.graphics_draw_bitmap_in_rect(ctx, s.l_digits_bitmaps[s.min_digits[2]], tens_min_dest);
    pebble.graphics_draw_bitmap_in_rect(ctx, s.l_digits_bitmaps[s.min_digits[3]], ones_min_dest);
}

fn setMin(hr: usize, min: usize) void {
    const old_hr = (s.min_digits[0] * 10) + s.min_digits[1];
    const old_min = (s.min_digits[2] * 10) + s.min_digits[3];
    pog.debug(@src(), "    hr: {d},     min: {d}", .{ hr, min });
    pog.debug(@src(), "old_hr: {d}, old_min: {d}", .{ old_hr, old_min });
    pog.debug(@src(), "old == new? {any}", .{old_hr == hr and old_min == min});
    if (old_hr == hr and old_min == min) {
        return;
    }

    s.min_digits[0] = @divTrunc(hr, 10);
    s.min_digits[1] = hr % 10;

    s.min_digits[2] = @divTrunc(min, 10);
    s.min_digits[3] = min % 10;

    pebble.layer_mark_dirty(s.min_layer);
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

    s.date_layer = pebble.layer_create(bounds);
    pebble.layer_set_update_proc(s.date_layer, updateDate);
    pebble.layer_add_child(window_layer, s.date_layer);
    s.s_digits_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.TYPE_S));
    for (0..10) |i| {
        const idx: i16 = @intCast(i);
        const coords: pebble.GRect = .{ .origin = .{ .x = idx * DATE_DIGIT_WIDTH, .y = 0 }, .size = .{ .h = DATE_DIGIT_HEIGHT, .w = DATE_DIGIT_WIDTH } }; // error from grect being bad?

        s.s_digits_bitmaps[i] = pebble.gbitmap_create_as_sub_bitmap(s.s_digits_bitmap, coords);
    }

    s.sec_layer = pebble.layer_create(bounds);
    pebble.layer_set_update_proc(s.sec_layer, updateSec);
    pebble.layer_add_child(window_layer, s.sec_layer);
    s.m_digits_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.TYPE_M));
    for (0..10) |i| {
        const idx: i16 = @intCast(i);
        const coords: pebble.GRect = .{ .origin = .{ .x = idx * SEC_DIGIT_WIDTH, .y = 0 }, .size = .{ .h = SEC_DIGIT_HEIGHT, .w = SEC_DIGIT_WIDTH } }; // error from grect being bad?
        s.m_digits_bitmaps[i] = pebble.gbitmap_create_as_sub_bitmap(s.m_digits_bitmap, coords);
    }

    s.min_layer = pebble.layer_create(bounds);
    pebble.layer_set_update_proc(s.min_layer, updateMin);
    pebble.layer_add_child(window_layer, s.min_layer);
    s.l_digits_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.TYPE_L));
    for (0..10) |i| {
        const idx: i16 = @intCast(i);
        const coords: pebble.GRect = .{ .origin = .{ .x = idx * MIN_DIGIT_WIDTH, .y = 0 }, .size = .{ .h = MIN_DIGIT_HEIGHT, .w = MIN_DIGIT_WIDTH } }; // error from grect being bad?
        s.l_digits_bitmaps[i] = pebble.gbitmap_create_as_sub_bitmap(s.l_digits_bitmap, coords);
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
        pebble.gbitmap_destroy(s.m_digits_bitmaps[i]);
        pebble.gbitmap_destroy(s.l_digits_bitmaps[i]);
    }
    pebble.gbitmap_destroy(s.s_digits_bitmap);
    pebble.gbitmap_destroy(s.m_digits_bitmap);
    pebble.gbitmap_destroy(s.l_digits_bitmap);
    pebble.layer_destroy(s.date_layer);
    pebble.layer_destroy(s.sec_layer);
    pebble.layer_destroy(s.min_layer);
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
