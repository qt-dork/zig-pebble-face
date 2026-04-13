const std = @import("std");

const pebble = @import("pebble");
const presource = @import("pebble_appids");

const pog = @import("pog.zig");
const utils = @import("utils.zig");

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

    bat_layer: ?*pebble.Layer = null,
    bat_bitmap: ?*pebble.GBitmap = null,
    bat_bitmaps: [3]?*pebble.GBitmap = undefined,
    bat_level: usize = 100,

    day_layer: ?*pebble.TextLayer = null,
    day_font: pebble.GFont = null,
    day_buffer: [6]u8 = undefined,

    clock_layer: ?*pebble.Layer = null,
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

fn battery_callback(state: pebble.BatteryChargeState) callconv(.c) void {
    pog.debug(@src(), "battery state: {d}", .{state.charge_percent});
    s.bat_level = state.charge_percent;
    pebble.layer_mark_dirty(s.bat_layer);
}

const BAT_HEIGHT = 16;
const BAT_WIDTH = 10;
const BAT_X = 108;
const BAT_Y = 45;
const BAT_MID = 115;
const BAT_GAP = 122 - BAT_MID;

fn battery_update_proc(_: ?*pebble.Layer, ctx: ?*pebble.GContext) callconv(.c) void {
    pog.debug(@src(), "battery level: {d}", .{s.bat_level});
    const count: usize = @divTrunc(s.bat_level + 5, 10);
    pebble.graphics_context_set_compositing_mode(ctx, pebble.GCompOpSet);

    // 0 to 10
    // 0 means 5% or lower battery
    // 1 to 10 draws segments
    if (count > 0) {
        for (0..10) |i| {
            if (i < count) {
                // get dest
                const x: i16 = if (i == 0) BAT_X else (BAT_MID + ((@as(i16, @intCast(i)) - 1) * BAT_GAP));
                const point: pebble.GPoint = .{ .x = x, .y = BAT_Y };
                const size: pebble.GSize = .{ .h = 16, .w = 10 };

                pebble.graphics_draw_bitmap_in_rect(ctx, if (i == 0) s.bat_bitmaps[0] else if (i == 9) s.bat_bitmaps[2] else s.bat_bitmaps[1], .{ .origin = point, .size = size });
            }
        }
    }
}

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
    const date: usize = @intCast(time_info.?.tm_mday);
    setDate(month, date);

    // day
    const day: usize = @intCast(time_info.?.tm_wday);
    setDay(day);

    // sec
    const sec: usize = @intCast(time_info.?.tm_sec);
    setSec(sec);

    //hr-min
    const hr: usize = @intCast(time_info.?.tm_hour);
    const min: usize = @intCast(time_info.?.tm_min);
    setMin(hr, min);
}

fn clock_update_proc(_: ?*pebble.Layer, ctx: ?*pebble.GContext) callconv(.c) void {
    pog.debug(@src(), "redrawing clock", .{});
    var raw_time: pebble.time_t = undefined;
    var time_info: ?*pebble.tm = undefined;

    _ = pebble.time(&raw_time);
    time_info = pebble.localtime(&raw_time);

    const seconds: isize = time_info.?.tm_sec;
    const minutes: isize = time_info.?.tm_min;
    const hours: isize = @rem(time_info.?.tm_hour, 12);

    const hours_angle: isize = (hours * 30) + @divTrunc(minutes, 3) + @divTrunc(seconds, 120) - 90;
    drawLine(ctx, hours_angle, 24);
    const minutes_angle: isize = (minutes * 6) + @divTrunc(seconds, 10) - 90;
    drawLine(ctx, minutes_angle, 32);
    const seconds_angle: isize = (seconds * 6) - 90;
    drawOffsetLine(ctx, seconds_angle, 32, 28);
}

fn drawLine(ctx: ?*pebble.GContext, angle: isize, length: isize) void {
    const origin: pebble.GPoint = .{ .x = 53, .y = 83 };
    const p1 = origin;
    const p2 = utils.polarToPointOffset(origin, angle, length);

    pebble.graphics_context_set_antialiased(ctx, false);
    pebble.graphics_context_set_fill_color(ctx, pebble.GColorBlack);
    pebble.graphics_context_set_stroke_color(ctx, pebble.GColorBlack);
    pebble.graphics_context_set_stroke_width(ctx, 3);
    pog.debug(@src(), "p2: x = {d}, y = {d}", .{ p2.x, p2.y });
    pebble.graphics_draw_line(ctx, p1, p2);
}

fn drawOffsetLine(ctx: ?*pebble.GContext, angle: i32, length: i32, end_length: i32) void {
    const origin: pebble.GPoint = .{ .x = 53, .y = 83 };
    const p1 = utils.polarToPointOffset(origin, angle, end_length);
    const p2 = utils.polarToPointOffset(origin, angle, length);

    pebble.graphics_context_set_antialiased(ctx, false);
    pebble.graphics_context_set_fill_color(ctx, pebble.GColorBlack);
    pebble.graphics_context_set_stroke_color(ctx, pebble.GColorBlack);
    pebble.graphics_context_set_stroke_width(ctx, 3);
    pog.debug(@src(), "p1: x = {d}, y = {d} - p2: x = {d}, y = {d}", .{ p1.x, p1.y, p2.x, p2.y });
    pebble.graphics_draw_line(ctx, p1, p2);
}

fn setDay(day: usize) void {
    pog.debug(@src(), "setting day", .{});

    switch (day) {
        0 => pebble.text_layer_set_text(s.day_layer, "sun"),
        1 => pebble.text_layer_set_text(s.day_layer, "mon"),
        2 => pebble.text_layer_set_text(s.day_layer, "tue"),
        3 => pebble.text_layer_set_text(s.day_layer, "wed"),
        4 => pebble.text_layer_set_text(s.day_layer, "thu"),
        5 => pebble.text_layer_set_text(s.day_layer, "fri"),
        6 => pebble.text_layer_set_text(s.day_layer, "sat"),
        else => {},
    }
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
    pebble.layer_mark_dirty(s.clock_layer);
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

    pog.debug(@src(), "Created window", .{});

    s.bg_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.IMAGE_BG));
    s.bg_bitmap_layer = pebble.bitmap_layer_create(bounds);

    pog.debug(@src(), "Created BG bitmap", .{});

    pebble.bitmap_layer_set_compositing_mode(s.bg_bitmap_layer, pebble.GCompOpSet);
    pebble.bitmap_layer_set_bitmap(s.bg_bitmap_layer, s.bg_bitmap);

    pebble.layer_add_child(window_layer, pebble.bitmap_layer_get_layer(s.bg_bitmap_layer));

    pog.debug(@src(), "Created BG", .{});

    s.pm_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.SPRITE_PM));
    s.pm_bitmap_layer = pebble.bitmap_layer_create(.{ .origin = .{ .x = 23, .y = 153 }, .size = .{ .h = 6, .w = 17 } });

    pebble.bitmap_layer_set_compositing_mode(s.pm_bitmap_layer, pebble.GCompOpSet);
    pebble.bitmap_layer_set_bitmap(s.pm_bitmap_layer, s.pm_bitmap);

    pebble.layer_add_child(window_layer, pebble.bitmap_layer_get_layer(s.pm_bitmap_layer));

    pog.debug(@src(), "Created PM", .{});

    s.date_layer = pebble.layer_create(bounds);
    pog.debug(@src(), "Created PM bounds", .{});
    pebble.layer_set_update_proc(s.date_layer, updateDate);
    pog.debug(@src(), "Set PM update proc", .{});
    pebble.layer_add_child(window_layer, s.date_layer);
    pog.debug(@src(), "Created PM as child", .{});
    s.s_digits_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.TYPE_S));
    pog.debug(@src(), "Got PM bitmap", .{});
    for (0..10) |i| {
        const idx: i16 = @intCast(i);
        const coords: pebble.GRect = .{ .origin = .{ .x = idx * DATE_DIGIT_WIDTH, .y = 0 }, .size = .{ .h = DATE_DIGIT_HEIGHT, .w = DATE_DIGIT_WIDTH } }; // error from grect being bad?

        s.s_digits_bitmaps[i] = pebble.gbitmap_create_as_sub_bitmap(s.s_digits_bitmap, coords);
        pog.debug(@src(), "Created PM sub-bitmap {d}", .{i});
    }

    pog.debug(@src(), "Created date", .{});

    s.sec_layer = pebble.layer_create(bounds);
    pebble.layer_set_update_proc(s.sec_layer, updateSec);
    pebble.layer_add_child(window_layer, s.sec_layer);
    s.m_digits_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.TYPE_M));
    for (0..10) |i| {
        const idx: i16 = @intCast(i);
        const coords: pebble.GRect = .{ .origin = .{ .x = idx * SEC_DIGIT_WIDTH, .y = 0 }, .size = .{ .h = SEC_DIGIT_HEIGHT, .w = SEC_DIGIT_WIDTH } }; // error from grect being bad?
        s.m_digits_bitmaps[i] = pebble.gbitmap_create_as_sub_bitmap(s.m_digits_bitmap, coords);
    }

    pog.debug(@src(), "Created sec", .{});

    s.min_layer = pebble.layer_create(bounds);
    pebble.layer_set_update_proc(s.min_layer, updateMin);
    pebble.layer_add_child(window_layer, s.min_layer);
    s.l_digits_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.TYPE_L));
    for (0..10) |i| {
        const idx: i16 = @intCast(i);
        const coords: pebble.GRect = .{ .origin = .{ .x = idx * MIN_DIGIT_WIDTH, .y = 0 }, .size = .{ .h = MIN_DIGIT_HEIGHT, .w = MIN_DIGIT_WIDTH } }; // error from grect being bad?
        s.l_digits_bitmaps[i] = pebble.gbitmap_create_as_sub_bitmap(s.l_digits_bitmap, coords);
    }

    pog.debug(@src(), "Created min", .{});

    s.bat_layer = pebble.layer_create(bounds);
    pog.debug(@src(), "Created battery bounds", .{});
    pebble.layer_set_update_proc(s.bat_layer, battery_update_proc);
    pog.debug(@src(), "Updated battery proc", .{});
    pebble.layer_add_child(window_layer, s.bat_layer);
    pog.debug(@src(), "Added battery layer as child", .{});
    s.bat_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.SPRITE_BAT));
    pog.debug(@src(), "Created battery bitmap", .{});
    for (0..3) |i| {
        const idx: i16 = @intCast(i);
        const coords: pebble.GRect = .{ .origin = .{ .x = idx * BAT_WIDTH, .y = 0 }, .size = .{ .h = BAT_HEIGHT, .w = BAT_WIDTH } };
        s.bat_bitmaps[i] = pebble.gbitmap_create_as_sub_bitmap(s.bat_bitmap, coords);
    }

    pog.debug(@src(), "Created battery", .{});

    // s.day_layer = pebble.text_layer_create(.{ .origin = .{ .x = 106, .y = 125 }, .size = .{ .w = 31, .h = 14 } });
    s.day_layer = pebble.text_layer_create(.{ .origin = .{ .x = 22, .y = 125 }, .size = .{ .h = 60, .w = 200 } });
    pog.debug(@src(), "Created day text layer", .{});
    s.day_font = pebble.fonts_load_custom_font(pebble.resource_get_handle(@intFromEnum(presource.RESOURCE_IDS.FONT_DSEG_14)));
    // pebble.text_layer_set_font(s.day_layer, pebble.fonts_get_system_font(pebble.FONT_KEY_GOTHIC_28));
    pebble.text_layer_set_font(s.day_layer, s.day_font);
    pog.debug(@src(), "Set day font", .{});
    pebble.text_layer_set_background_color(s.day_layer, pebble.GColorClear);
    pog.debug(@src(), "Set day bg color", .{});
    pebble.text_layer_set_text_color(s.day_layer, pebble.GColorBlack);
    pog.debug(@src(), "Set day color", .{});
    pebble.text_layer_set_text_alignment(s.day_layer, pebble.GTextAlignmentCenter);

    pebble.layer_add_child(window_layer, pebble.text_layer_get_layer(s.day_layer));

    s.clock_layer = pebble.layer_create(bounds);
    pebble.layer_set_update_proc(s.clock_layer, clock_update_proc);
    pebble.layer_add_child(window_layer, s.clock_layer);
}

fn window_unload(_: ?*pebble.Window) callconv(.c) void {
    pebble.gbitmap_destroy(s.bg_bitmap);
    pebble.bitmap_layer_destroy(s.bg_bitmap_layer);

    pog.debug(@src(), "Destroyed bg", .{});

    pebble.gbitmap_destroy(s.pm_bitmap);
    pebble.bitmap_layer_destroy(s.pm_bitmap_layer);

    pog.debug(@src(), "Destroyed pm", .{});

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

    pog.debug(@src(), "Destroyed date, sec, min", .{});

    for (0..3) |i| {
        pebble.gbitmap_destroy(s.bat_bitmaps[i]);
    }
    pebble.gbitmap_destroy(s.bat_bitmap);
    pebble.layer_destroy(s.bat_layer);

    pog.debug(@src(), "Destroyed bat", .{});

    pebble.fonts_unload_custom_font(s.day_font);
    pebble.text_layer_destroy(s.day_layer);
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

    // update battery
    pebble.battery_state_service_subscribe(battery_callback);
    battery_callback(pebble.battery_state_service_peek());

    pebble.app_event_loop();
}
