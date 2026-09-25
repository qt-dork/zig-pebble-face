const std = @import("std");

const pebble = @import("pebble");
const presource = @import("pebble_appids");

const messaging = @import("messaging.zig");
const pog = @import("pog.zig");
const settings = @import("settings.zig");
const tz = @import("tz.zig");
const utils = @import("utils.zig");

const State = struct {
    window: ?*pebble.Window = null,
    init_done: bool = false,
    is_24h: bool = false,
    date_format: settings.DateFormatOptions = .MonthDay,
    bg_bitmap_layer: ?*pebble.BitmapLayer = null,
    bg_bitmap: ?*pebble.GBitmap = null,
    pm_bitmap_layer: ?*pebble.BitmapLayer = null,
    pm_bitmap: ?*pebble.GBitmap = null,

    date_layer: ?*pebble.Layer = null,
    s_digits_bitmap: ?*pebble.GBitmap = null,
    s_digits_bitmaps: [10]?*pebble.GBitmap = undefined,
    date_digits: [4]usize = [_]usize{ 0, 0, 0, 0 },
    dash_bitmap: ?*pebble.GBitmap = null,

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

    map_layer: ?*pebble.Layer = null,
    map_bitmap: ?*pebble.GBitmap = null,
    map_bitmaps: [20]?*pebble.GBitmap = undefined,
    cur_map: ?usize = null,

    day_layer: ?*pebble.TextLayer = null,
    day_faded_layer: ?*pebble.TextLayer = null,
    day_font: pebble.GFont = null,
    day_buffer: [6]u8 = undefined,

    faded_layer: ?*pebble.Layer = null,
    pm_faded_bitmap: ?*pebble.GBitmap = null,
    s_digits_faded_bitmap: ?*pebble.GBitmap = null,
    s_digits_faded_bitmaps: [2]?*pebble.GBitmap = undefined,
    m_digits_faded_bitmap: ?*pebble.GBitmap = null,
    l_digits_faded_bitmap: ?*pebble.GBitmap = null,
    l_digits_faded_bitmaps: [2]?*pebble.GBitmap = undefined,
    bat_faded_bitmap: ?*pebble.GBitmap = null,
    bat_faded_bitmaps: [3]?*pebble.GBitmap = undefined,

    clock_layer: ?*pebble.Layer = null,
};

const Pos = struct { x: i16, y: i16 };

const HR_TENS: Pos = .{ .x = 30, .y = 147 };
const HR_ONES: Pos = .{ .x = 56, .y = 147 };
const MIN_DIGIT_WIDTH: i16 = 23;
const MIN_DIGIT_HEIGHT: i16 = 37;
const MIN_TENS: Pos = .{ .x = 90, .y = 147 };
const MIN_ONES: Pos = .{ .x = 115, .y = 147 };

const SEC_DIGIT_WIDTH: i16 = 16;
const SEC_DIGIT_HEIGHT: i16 = 27;
const SEC_TENS: Pos = .{ .x = 143, .y = 157 };
const SEC_ONES: Pos = .{ .x = 161, .y = 157 };

const DATE_DIGIT_WIDTH: i16 = 7;
const DATE_DIGIT_HEIGHT: i16 = 14;
const DATE_Y: i16 = 125;
const DATE_DASH_WIDTH: i16 = 3;
const DATE_DASH_HEIGHT: i16 = 2;
const DATE_DASH_Y: i16 = 131;

// The date block is 33px wide and reads either MM-DD or DD-MM. The month's
// leading "1" is a 7px cell whose ink only fills its rightmost 3px, so it is
// drawn 4px to the left of where its visible ink sits
const DateLayout = struct {
    month_tens: i16,
    month_ones: i16,
    dash: i16,
    day_tens: i16,
    day_ones: i16,
};
const DATE_MM_DD: DateLayout = .{ .month_tens = 140, .month_ones = 149, .dash = 157, .day_tens = 161, .day_ones = 170 };
const DATE_DD_MM: DateLayout = .{ .month_tens = 161, .month_ones = 170, .dash = 161, .day_tens = 144, .day_ones = 153 };

const PM: Pos = .{ .x = 23, .y = 153 };
const PM_WIDTH: i16 = 17;
const PM_HEIGHT: i16 = 6;

const DAY_TEXT_RECT: pebble.GRect = .{ .origin = .{ .x = 22, .y = 125 }, .size = .{ .h = 60, .w = 200 } };

// Ghost LCD segments are drawn in #aaffaa (see the faded sprite sheets).
const FADED_GREEN: pebble.GColor = .{ .argb = 0b11101110 };

const MAP_HEIGHT: i16 = 38;
const MAP_WIDTH: i16 = 69;

var s = State{};

// 55,83
// 52,52
// 54,52
const SEC_PATH_INFO: pebble.GPathInfo = .{
    .num_points = 3,
    .points = [_]pebble.GPoint{ .{ .x = 55, .y = 83 }, .{ .x = 52, .y = 60 }, .{ .x = 54, .y = 60 } },
};

fn battery_callback(state: pebble.BatteryChargeState) callconv(.c) void {
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
    const count: usize = @divTrunc(s.bat_level + 5, 10);
    pebble.graphics_context_set_compositing_mode(ctx, pebble.GCompOpSet);

    // Draw all ten ghost segments, then light the charged ones on top
    // 0 means 5% or lower battery
    // 0 has no segments
    for (0..10) |i| {
        // get dest
        const x: i16 = if (i == 0) BAT_X else (BAT_MID + ((@as(i16, @intCast(i)) - 1) * BAT_GAP));
        const point: pebble.GPoint = .{ .x = x, .y = BAT_Y };
        const size: pebble.GSize = .{ .h = BAT_HEIGHT, .w = BAT_WIDTH };

        const ghost = if (i == 0) s.bat_faded_bitmaps[0] else if (i == 9) s.bat_faded_bitmaps[2] else s.bat_faded_bitmaps[1];
        pebble.graphics_draw_bitmap_in_rect(ctx, ghost, .{ .origin = point, .size = size });

        if (i < count) {
            const lit = if (i == 0) s.bat_bitmaps[0] else if (i == 9) s.bat_bitmaps[2] else s.bat_bitmaps[1];
            pebble.graphics_draw_bitmap_in_rect(ctx, lit, .{ .origin = point, .size = size });
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

    const is_24h = settings.settingsIs24Hour();
    const mode_changed = is_24h != s.is_24h;
    if (mode_changed) {
        s.is_24h = is_24h;
        pebble.layer_mark_dirty(s.faded_layer);
        pebble.layer_mark_dirty(s.min_layer);
    }

    if (s.init_done and settings.settingsGetSeconds() == .PerFifteen and @rem(time_info.?.tm_sec, 15) != 0 and !mode_changed) return;

    // am/pm (only in 12h mode)
    const pm_visible = !s.is_24h and time_info.?.tm_hour > 11;
    pebble.layer_set_hidden(pebble.bitmap_layer_get_layer(s.pm_bitmap_layer), !pm_visible);

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

    s.init_done = true;
}

fn clock_update_proc(_: ?*pebble.Layer, ctx: ?*pebble.GContext) callconv(.c) void {
    var raw_time: pebble.time_t = undefined;
    var time_info: ?*pebble.tm = undefined;
    var utc: ?*pebble.tm = undefined;

    _ = pebble.time(&raw_time);
    time_info = pebble.localtime(&raw_time);
    utc = pebble.gmtime(&raw_time);

    var offset: pebble.tm = undefined;
    const zone = settings.settingsGetTimeZone();
    if (zone == .None) {
        offset = time_info.?.*;
    } else {
        offset = tz.offsetTime(utc.?.*, zone);
    }

    const seconds: isize = offset.tm_sec;
    const minutes: isize = offset.tm_min;
    const hours: isize = @rem(offset.tm_hour, 12);

    const hours_angle: isize = (hours * 30) + @divTrunc(minutes, 2) + @divTrunc(seconds, 120) - 90;
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
    pebble.graphics_draw_line(ctx, p1, p2);
}

fn setDay(_: usize) void {
    var raw_time: pebble.time_t = undefined;
    var time_info: ?*pebble.tm = undefined;

    _ = pebble.time(&raw_time);
    time_info = pebble.localtime(&raw_time);
    _ = pebble.strftime(&s.day_buffer, s.day_buffer.len, "%a", time_info);
    pebble.text_layer_set_text(s.day_layer, &s.day_buffer);
}

fn dateLayout() DateLayout {
    return if (s.date_format == .DayMonth) DATE_DD_MM else DATE_MM_DD;
}

fn drawAt(ctx: ?*pebble.GContext, bmp: ?*pebble.GBitmap, x: i16, y: i16, size: pebble.GSize) void {
    pebble.graphics_draw_bitmap_in_rect(ctx, bmp, .{ .origin = .{ .x = x, .y = y }, .size = size });
}

fn updateDate(_: ?*pebble.Layer, ctx: ?*pebble.GContext) callconv(.c) void {
    pebble.graphics_context_set_compositing_mode(ctx, pebble.GCompOpSet);

    const layout = dateLayout();
    const size = pebble.GSize{ .h = DATE_DIGIT_HEIGHT, .w = DATE_DIGIT_WIDTH };

    // The month-tens slot only ever holds a "1" (months 10-12); for months 1-9 it
    // stays blank so the faded "1" ghost shows through, mirroring the 12h hour tens.
    if (s.date_digits[0] != 0) {
        drawAt(ctx, s.s_digits_bitmaps[s.date_digits[0]], layout.month_tens, DATE_Y, size);
    }
    drawAt(ctx, s.s_digits_bitmaps[s.date_digits[1]], layout.month_ones, DATE_Y, size);
    drawAt(ctx, s.s_digits_bitmaps[s.date_digits[2]], layout.day_tens, DATE_Y, size);
    drawAt(ctx, s.s_digits_bitmaps[s.date_digits[3]], layout.day_ones, DATE_Y, size);

    const dash_dest = pebble.GRect{ .origin = .{ .x = layout.dash, .y = DATE_DASH_Y }, .size = .{ .h = DATE_DASH_HEIGHT, .w = DATE_DASH_WIDTH } };
    pebble.graphics_draw_bitmap_in_rect(ctx, s.dash_bitmap, dash_dest);
}

fn setDate(month: usize, day: usize) void {
    const old_month = (s.date_digits[0] * 10) + s.date_digits[1];
    const old_day = (s.date_digits[2] * 10) + s.date_digits[3];
    if (old_month == month and old_day == day) {
        return;
    }
    s.date_digits[0] = @divTrunc(month, 10);
    s.date_digits[1] = month % 10;
    s.date_digits[2] = @divTrunc(day, 10);
    s.date_digits[3] = day % 10;

    pebble.layer_mark_dirty(s.date_layer);
}

fn updateSec(_: ?*pebble.Layer, ctx: ?*pebble.GContext) callconv(.c) void {
    pebble.graphics_context_set_compositing_mode(ctx, pebble.GCompOpSet);

    const size = pebble.GSize{ .h = SEC_DIGIT_HEIGHT, .w = SEC_DIGIT_WIDTH };
    drawAt(ctx, s.m_digits_bitmaps[s.sec_digits[0]], SEC_TENS.x, SEC_TENS.y, size);
    drawAt(ctx, s.m_digits_bitmaps[s.sec_digits[1]], SEC_ONES.x, SEC_ONES.y, size);
}

fn setSec(sec: usize) void {
    s.sec_digits[0] = @divTrunc(sec, 10);
    s.sec_digits[1] = sec % 10;
    if (settings.settingsGetSeconds() == .PerFifteen and sec % 15 != 0) return;
    pebble.layer_mark_dirty(s.sec_layer);
    pebble.layer_mark_dirty(s.clock_layer);
}

fn updateMin(_: ?*pebble.Layer, ctx: ?*pebble.GContext) callconv(.c) void {
    pebble.graphics_context_set_compositing_mode(ctx, pebble.GCompOpSet);

    const size = pebble.GSize{ .h = MIN_DIGIT_HEIGHT, .w = MIN_DIGIT_WIDTH };

    if (s.min_digits[0] != 0) {
        drawAt(ctx, s.l_digits_bitmaps[s.min_digits[0]], HR_TENS.x, HR_TENS.y, size);
    }
    drawAt(ctx, s.l_digits_bitmaps[s.min_digits[1]], HR_ONES.x, HR_ONES.y, size);
    drawAt(ctx, s.l_digits_bitmaps[s.min_digits[2]], MIN_TENS.x, MIN_TENS.y, size);
    drawAt(ctx, s.l_digits_bitmaps[s.min_digits[3]], MIN_ONES.x, MIN_ONES.y, size);
}

fn twelveHour(hr: usize) usize {
    const h = hr % 12;
    return if (h == 0) 12 else h;
}

fn setMin(hr: usize, min: usize) void {
    const shown_hr = if (s.is_24h) hr else twelveHour(hr);

    // useless checking to avoid marking dirty. will fix later.
    const old_hr = (s.min_digits[0] * 10) + s.min_digits[1];
    const old_min = (s.min_digits[2] * 10) + s.min_digits[3];
    if (old_hr == shown_hr and old_min == min) {
        return;
    }

    s.min_digits[0] = @divTrunc(shown_hr, 10);
    s.min_digits[1] = shown_hr % 10;

    s.min_digits[2] = @divTrunc(min, 10);
    s.min_digits[3] = min % 10;

    pebble.layer_mark_dirty(s.min_layer);
}

fn updateFaded(_: ?*pebble.Layer, ctx: ?*pebble.GContext) callconv(.c) void {
    pebble.graphics_context_set_compositing_mode(ctx, pebble.GCompOpSet);

    const large = pebble.GSize{ .h = MIN_DIGIT_HEIGHT, .w = MIN_DIGIT_WIDTH };
    const medium = pebble.GSize{ .h = SEC_DIGIT_HEIGHT, .w = SEC_DIGIT_WIDTH };

    // hours
    drawAt(ctx, s.l_digits_faded_bitmaps[if (s.is_24h) 1 else 0], HR_TENS.x, HR_TENS.y, large);
    drawAt(ctx, s.l_digits_faded_bitmaps[1], HR_ONES.x, HR_ONES.y, large);

    // minutes
    drawAt(ctx, s.l_digits_faded_bitmaps[1], MIN_TENS.x, MIN_TENS.y, large);
    drawAt(ctx, s.l_digits_faded_bitmaps[1], MIN_ONES.x, MIN_ONES.y, large);

    // seconds
    drawAt(ctx, s.m_digits_faded_bitmap, SEC_TENS.x, SEC_TENS.y, medium);
    drawAt(ctx, s.m_digits_faded_bitmap, SEC_ONES.x, SEC_ONES.y, medium);

    // date - a "1" is always in the tens slot for month
    const layout = dateLayout();
    const date_size = pebble.GSize{ .h = DATE_DIGIT_HEIGHT, .w = DATE_DIGIT_WIDTH };
    drawAt(ctx, s.s_digits_faded_bitmaps[0], layout.month_tens, DATE_Y, date_size);
    drawAt(ctx, s.s_digits_faded_bitmaps[1], layout.month_ones, DATE_Y, date_size);
    drawAt(ctx, s.s_digits_faded_bitmaps[1], layout.day_tens, DATE_Y, date_size);
    drawAt(ctx, s.s_digits_faded_bitmaps[1], layout.day_ones, DATE_Y, date_size);

    // pm indicator (12h only)
    if (!s.is_24h) {
        drawAt(ctx, s.pm_faded_bitmap, PM.x, PM.y, pebble.GSize{ .h = PM_HEIGHT, .w = PM_WIDTH });
    }
}

fn updateMap(_: ?*pebble.Layer, ctx: ?*pebble.GContext) callconv(.c) void {
    pebble.graphics_context_set_compositing_mode(ctx, pebble.GCompOpSet);

    const pos = pebble.GPoint{
        .x = 109,
        .y = 71,
    };
    const size = pebble.GSize{
        .h = MAP_HEIGHT,
        .w = MAP_WIDTH,
    };
    if (s.cur_map) |cur| pebble.graphics_draw_bitmap_in_rect(ctx, s.map_bitmaps[cur], pebble.GRect{ .origin = pos, .size = size });
}

fn forceUpdate() void {
    s.date_format = settings.settingsGetDateFormat();

    updateClock();

    pebble.layer_mark_dirty(s.faded_layer);
    pebble.layer_mark_dirty(s.bat_layer);
    pebble.layer_mark_dirty(s.date_layer);
    pebble.layer_mark_dirty(s.clock_layer);
    pebble.layer_mark_dirty(s.sec_layer);
    pebble.layer_mark_dirty(s.min_layer);

    pebble.tick_timer_service_unsubscribe();
    pebble.tick_timer_service_subscribe(if (settings.settingsGetSeconds() == .PerMinute) pebble.MINUTE_UNIT else pebble.SECOND_UNIT, handle_tick);

    s.cur_map = tz.mapIndex(settings.settingsGetTimeZone());
    pebble.layer_mark_dirty(s.map_layer);
}

fn window_load(window: ?*pebble.Window) callconv(.c) void {
    const window_layer = pebble.window_get_root_layer(window);
    const bounds = pebble.layer_get_bounds(window_layer);

    s.is_24h = settings.settingsIs24Hour();
    s.date_format = settings.settingsGetDateFormat();

    s.bg_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.IMAGE_BG));
    s.bg_bitmap_layer = pebble.bitmap_layer_create(bounds);

    pebble.bitmap_layer_set_compositing_mode(s.bg_bitmap_layer, pebble.GCompOpSet);
    pebble.bitmap_layer_set_bitmap(s.bg_bitmap_layer, s.bg_bitmap);

    pebble.layer_add_child(window_layer, pebble.bitmap_layer_get_layer(s.bg_bitmap_layer));

    // Faded/ghost LCD layer
    s.faded_layer = pebble.layer_create(bounds);
    pebble.layer_set_update_proc(s.faded_layer, updateFaded);
    pebble.layer_add_child(window_layer, s.faded_layer);

    s.pm_faded_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.SPRITE_PM_FADED));

    s.s_digits_faded_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.TYPE_S_FADED));
    for (0..2) |i| {
        const idx: i16 = @intCast(i);
        const coords: pebble.GRect = .{ .origin = .{ .x = idx * DATE_DIGIT_WIDTH, .y = 0 }, .size = .{ .h = DATE_DIGIT_HEIGHT, .w = DATE_DIGIT_WIDTH } };
        s.s_digits_faded_bitmaps[i] = pebble.gbitmap_create_as_sub_bitmap(s.s_digits_faded_bitmap, coords);
    }

    s.m_digits_faded_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.TYPE_M_FADED));

    s.l_digits_faded_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.TYPE_L_FADED));
    for (0..2) |i| {
        const idx: i16 = @intCast(i);
        const coords: pebble.GRect = .{ .origin = .{ .x = idx * MIN_DIGIT_WIDTH, .y = 0 }, .size = .{ .h = MIN_DIGIT_HEIGHT, .w = MIN_DIGIT_WIDTH } };
        s.l_digits_faded_bitmaps[i] = pebble.gbitmap_create_as_sub_bitmap(s.l_digits_faded_bitmap, coords);
    }

    s.bat_faded_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.SPRITE_BAT_FADED));
    for (0..3) |i| {
        const idx: i16 = @intCast(i);
        const coords: pebble.GRect = .{ .origin = .{ .x = idx * BAT_WIDTH, .y = 0 }, .size = .{ .h = BAT_HEIGHT, .w = BAT_WIDTH } };
        s.bat_faded_bitmaps[i] = pebble.gbitmap_create_as_sub_bitmap(s.bat_faded_bitmap, coords);
    }

    s.pm_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.SPRITE_PM));
    s.pm_bitmap_layer = pebble.bitmap_layer_create(.{ .origin = .{ .x = PM.x, .y = PM.y }, .size = .{ .h = PM_HEIGHT, .w = PM_WIDTH } });

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

    s.dash_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.SPRITE_DASH));

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

    s.bat_layer = pebble.layer_create(bounds);
    pebble.layer_set_update_proc(s.bat_layer, battery_update_proc);
    pebble.layer_add_child(window_layer, s.bat_layer);
    s.bat_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.SPRITE_BAT));
    for (0..3) |i| {
        const idx: i16 = @intCast(i);
        const coords: pebble.GRect = .{ .origin = .{ .x = idx * BAT_WIDTH, .y = 0 }, .size = .{ .h = BAT_HEIGHT, .w = BAT_WIDTH } };
        s.bat_bitmaps[i] = pebble.gbitmap_create_as_sub_bitmap(s.bat_bitmap, coords);
    }

    s.day_font = pebble.fonts_load_custom_font(pebble.resource_get_handle(@intFromEnum(presource.RESOURCE_IDS.FONT_DSEG_14)));

    // Day-of-week ghost
    s.day_faded_layer = pebble.text_layer_create(DAY_TEXT_RECT);
    pebble.text_layer_set_font(s.day_faded_layer, s.day_font);
    pebble.text_layer_set_background_color(s.day_faded_layer, pebble.GColorClear);
    pebble.text_layer_set_text_color(s.day_faded_layer, FADED_GREEN);
    pebble.text_layer_set_text_alignment(s.day_faded_layer, pebble.GTextAlignmentCenter);
    pebble.text_layer_set_text(s.day_faded_layer, "~~~");
    pebble.layer_add_child(window_layer, pebble.text_layer_get_layer(s.day_faded_layer));

    s.day_layer = pebble.text_layer_create(DAY_TEXT_RECT);
    pebble.text_layer_set_font(s.day_layer, s.day_font);
    pebble.text_layer_set_background_color(s.day_layer, pebble.GColorClear);
    pebble.text_layer_set_text_color(s.day_layer, pebble.GColorBlack);
    pebble.text_layer_set_text_alignment(s.day_layer, pebble.GTextAlignmentCenter);

    pebble.layer_add_child(window_layer, pebble.text_layer_get_layer(s.day_layer));

    s.clock_layer = pebble.layer_create(bounds);
    pebble.layer_set_update_proc(s.clock_layer, clock_update_proc);
    pebble.layer_add_child(window_layer, s.clock_layer);

    s.map_layer = pebble.layer_create(bounds);
    pebble.layer_set_update_proc(s.map_layer, updateMap);
    pebble.layer_add_child(window_layer, s.map_layer);
    s.map_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.SPRITE_MAP));
    for (0..20) |i| {
        const idx: i16 = @intCast(i);
        const coords: pebble.GRect = .{ .origin = .{ .x = idx * MAP_WIDTH, .y = 0 }, .size = .{ .h = MAP_HEIGHT, .w = MAP_WIDTH } };
        s.map_bitmaps[i] = pebble.gbitmap_create_as_sub_bitmap(s.map_bitmap, coords);
    }

    forceUpdate();
}

fn window_unload(_: ?*pebble.Window) callconv(.c) void {
    pebble.gbitmap_destroy(s.bg_bitmap);
    pebble.bitmap_layer_destroy(s.bg_bitmap_layer);

    pebble.gbitmap_destroy(s.pm_faded_bitmap);
    for (0..2) |i| {
        pebble.gbitmap_destroy(s.s_digits_faded_bitmaps[i]);
        pebble.gbitmap_destroy(s.l_digits_faded_bitmaps[i]);
    }
    pebble.gbitmap_destroy(s.s_digits_faded_bitmap);
    pebble.gbitmap_destroy(s.m_digits_faded_bitmap);
    pebble.gbitmap_destroy(s.l_digits_faded_bitmap);
    for (0..3) |i| {
        pebble.gbitmap_destroy(s.bat_faded_bitmaps[i]);
    }
    pebble.gbitmap_destroy(s.bat_faded_bitmap);
    pebble.layer_destroy(s.faded_layer);

    pebble.gbitmap_destroy(s.pm_bitmap);
    pebble.bitmap_layer_destroy(s.pm_bitmap_layer);

    pebble.gbitmap_destroy(s.dash_bitmap);

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

    for (0..3) |i| {
        pebble.gbitmap_destroy(s.bat_bitmaps[i]);
    }
    pebble.gbitmap_destroy(s.bat_bitmap);
    pebble.layer_destroy(s.bat_layer);

    pebble.fonts_unload_custom_font(s.day_font);
    pebble.text_layer_destroy(s.day_faded_layer);
    pebble.text_layer_destroy(s.day_layer);

    for (0..20) |i| {
        pebble.gbitmap_destroy(s.map_bitmaps[i]);
    }
    pebble.gbitmap_destroy(s.map_bitmap);
    pebble.layer_destroy(s.map_layer);
}

export fn main() void {
    messaging.messagingInit(forceUpdate);
    defer messaging.messagingDeinit();

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
    pebble.tick_timer_service_subscribe(if (settings.settingsGetSeconds() == .PerMinute) pebble.MINUTE_UNIT else pebble.SECOND_UNIT, handle_tick);

    // update battery
    pebble.battery_state_service_subscribe(battery_callback);
    battery_callback(pebble.battery_state_service_peek());

    pebble.app_event_loop();
}
