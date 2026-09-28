const pb = @import("pebble");
const presource = @import("pebble_appids");
const pebble = @import("pebble.zig");

const messaging = @import("messaging.zig");
const settings = @import("settings.zig");
const tz = @import("tz.zig");
const utils = @import("utils.zig");

const State = struct {
    window: ?*pb.Window = null,
    ready: bool = false,
    init_done: bool = false,
    is_24h: bool = false,
    date_format: settings.DateFormatOptions = .MonthDay,
    bg_bitmap_layer: *pb.BitmapLayer = undefined,
    bg_bitmap: ?*pb.GBitmap = null,
    pm_bitmap_layer: *pb.BitmapLayer = undefined,
    pm_bitmap: ?*pb.GBitmap = null,

    date_layer: *pb.Layer = undefined,
    s_digits_bitmap: ?*pb.GBitmap = null,
    s_digits_bitmaps: [10]?*pb.GBitmap = undefined,
    date_digits: [4]usize = [_]usize{ 0, 0, 0, 0 },
    dash_bitmap: ?*pb.GBitmap = null,

    sec_layer: *pb.Layer = undefined,
    m_digits_bitmap: ?*pb.GBitmap = null,
    m_digits_bitmaps: [10]?*pb.GBitmap = undefined,
    sec_digits: [2]usize = [_]usize{ 0, 0 },

    min_layer: *pb.Layer = undefined,
    l_digits_bitmap: ?*pb.GBitmap = null,
    l_digits_bitmaps: [10]?*pb.GBitmap = undefined,
    min_digits: [4]usize = [_]usize{ 0, 0, 0, 0 },

    bat_layer: *pb.Layer = undefined,
    bat_bitmap: ?*pb.GBitmap = null,
    bat_bitmaps: [3]?*pb.GBitmap = undefined,
    bat_level: usize = 100,

    map_layer: *pb.Layer = undefined,
    map_bitmap: ?*pb.GBitmap = null,
    map_bitmaps: [20]?*pb.GBitmap = undefined,
    cur_map: ?usize = null,

    day_layer: *pb.TextLayer = undefined,
    day_faded_layer: *pb.TextLayer = undefined,
    day_font: pb.GFont = null,
    day_buffer: [6]u8 = undefined,

    faded_layer: *pb.Layer = undefined,
    pm_faded_bitmap: ?*pb.GBitmap = null,
    s_digits_faded_bitmap: ?*pb.GBitmap = null,
    s_digits_faded_bitmaps: [2]?*pb.GBitmap = undefined,
    m_digits_faded_bitmap: ?*pb.GBitmap = null,
    l_digits_faded_bitmap: ?*pb.GBitmap = null,
    l_digits_faded_bitmaps: [2]?*pb.GBitmap = undefined,
    bat_faded_bitmap: ?*pb.GBitmap = null,
    bat_faded_bitmaps: [3]?*pb.GBitmap = undefined,

    clock_layer: *pb.Layer = undefined,
};

const Pos = pb.GPoint;

const HR_TENS: Pos = .{ .x = 30, .y = 147 };
const HR_ONES: Pos = .{ .x = 56, .y = 147 };
const MIN_DIGIT_WIDTH: i16 = 23;
const MIN_DIGIT_HEIGHT: i16 = 37;
const MIN_TENS: Pos = .{ .x = 90, .y = 147 };
const MIN_ONES: Pos = .{ .x = 115, .y = 147 };

const SEC_DIGIT_SIZE: pb.GSize = .{ .w = 16, .h = 27 };
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

const DAY_TEXT_RECT: pb.GRect = .{ .origin = .{ .x = 22, .y = 125 }, .size = .{ .h = 60, .w = 200 } };

const FADED_GREEN: pb.GColor = .{ .argb = 0b11101110 };

const MAP_HEIGHT: i16 = 38;
const MAP_WIDTH: i16 = 69;

var s = State{};

// 55,83
// 52,52
// 54,52
const SEC_PATH_INFO: pb.GPathInfo = .{
    .num_points = 3,
    .points = [_]pb.GPoint{ .{ .x = 55, .y = 83 }, .{ .x = 52, .y = 60 }, .{ .x = 54, .y = 60 } },
};

fn battery_callback(state: pb.BatteryChargeState) callconv(.c) void {
    s.bat_level = state.charge_percent;
    pebble.layer.markDirty(s.bat_layer);
}

const BAT_HEIGHT = 16;
const BAT_WIDTH = 10;
const BAT_X = 108;
const BAT_Y = 45;
const BAT_MID = 115;
const BAT_GAP = 122 - BAT_MID;

fn battery_update_proc(_: ?*pb.Layer, ctx: ?*pb.GContext) callconv(.c) void {
    const count: usize = @divTrunc(s.bat_level + 5, 10);
    pb.graphics_context_set_compositing_mode(ctx, pb.GCompOpSet);

    // Draw all ten ghost segments, then light the charged ones on top
    // 0 means 5% or lower battery
    // 0 has no segments
    for (0..10) |i| {
        // get dest
        const x: i16 = if (i == 0) BAT_X else (BAT_MID + ((@as(i16, @intCast(i)) - 1) * BAT_GAP));
        const dest: pb.GRect = .{
            .origin = .{ .x = x, .y = BAT_Y },
            .size = .{ .h = BAT_HEIGHT, .w = BAT_WIDTH },
        };

        const ghost = if (i == 0) s.bat_faded_bitmaps[0] else if (i == 9) s.bat_faded_bitmaps[2] else s.bat_faded_bitmaps[1];
        if (ghost) |g| pb.graphics_draw_bitmap_in_rect(ctx, g, dest);

        if (i < count) {
            const lit = if (i == 0) s.bat_bitmaps[0] else if (i == 9) s.bat_bitmaps[2] else s.bat_bitmaps[1];
            if (lit) |l| pb.graphics_draw_bitmap_in_rect(ctx, l, dest);
        }
    }
}

fn handle_tick(_: ?*pb.tm, _: pb.TimeUnits) callconv(.c) void {
    updateClock();
}

fn updateClock() void {
    var raw_time: pb.time_t = undefined;
    var time_info: ?*pb.tm = undefined;

    _ = pb.time(&raw_time);
    time_info = pb.localtime(&raw_time);

    const is_24h = settings.settingsIs24Hour();
    const mode_changed = is_24h != s.is_24h;
    if (mode_changed) {
        s.is_24h = is_24h;
        pebble.layer.markDirty(s.faded_layer);
        pebble.layer.markDirty(s.min_layer);
    }

    if (s.init_done and settings.settingsGetSeconds() == .PerFifteen and @rem(time_info.?.tm_sec, 15) != 0 and !mode_changed) return;

    // am/pm (only in 12h mode)
    const pm_visible = !s.is_24h and time_info.?.tm_hour > 11;
    const pm_layer = pebble.layer.ofBitmap(s.pm_bitmap_layer) catch return;
    pebble.layer.setHidden(pm_layer, !pm_visible);

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

fn clock_update_proc(_: ?*pb.Layer, ctx: ?*pb.GContext) callconv(.c) void {
    var raw_time: pb.time_t = undefined;
    var time_info: ?*pb.tm = undefined;
    var utc: ?*pb.tm = undefined;

    _ = pb.time(&raw_time);
    time_info = pb.localtime(&raw_time);
    utc = pb.gmtime(&raw_time);

    var offset: pb.tm = undefined;
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

fn drawLine(ctx: ?*pb.GContext, angle: isize, length: isize) void {
    const origin: pb.GPoint = .{ .x = 53, .y = 83 };
    const p1 = origin;
    const p2 = utils.polarToPointOffset(origin, angle, length);

    pb.graphics_context_set_antialiased(ctx, false);
    pb.graphics_context_set_fill_color(ctx, pb.GColorBlack);
    pb.graphics_context_set_stroke_color(ctx, pb.GColorBlack);
    pb.graphics_context_set_stroke_width(ctx, 3);
    pb.graphics_draw_line(ctx, p1, p2);
}

fn drawOffsetLine(ctx: ?*pb.GContext, angle: i32, length: i32, end_length: i32) void {
    const origin: pb.GPoint = .{ .x = 53, .y = 83 };
    const p1 = utils.polarToPointOffset(origin, angle, end_length);
    const p2 = utils.polarToPointOffset(origin, angle, length);

    pb.graphics_context_set_antialiased(ctx, false);
    pb.graphics_context_set_fill_color(ctx, pb.GColorBlack);
    pb.graphics_context_set_stroke_color(ctx, pb.GColorBlack);
    pb.graphics_context_set_stroke_width(ctx, 3);
    pb.graphics_draw_line(ctx, p1, p2);
}

fn setDay(_: usize) void {
    var raw_time: pb.time_t = undefined;
    var time_info: ?*pb.tm = undefined;

    _ = pb.time(&raw_time);
    time_info = pb.localtime(&raw_time);
    _ = pb.strftime(&s.day_buffer, s.day_buffer.len, "%a", time_info);
    pb.text_layer_set_text(s.day_layer, &s.day_buffer);
}

fn dateLayout() DateLayout {
    return if (s.date_format == .DayMonth) DATE_DD_MM else DATE_MM_DD;
}

fn drawAt(ctx: ?*pb.GContext, bmp: ?*pb.GBitmap, x: i16, y: i16, size: pb.GSize) void {
    if (bmp == null) return;
    const dest: pb.GRect = .{ .origin = .{ .x = x, .y = y }, .size = size };
    pb.graphics_draw_bitmap_in_rect(ctx, bmp, dest);
}

fn updateDate(_: ?*pb.Layer, ctx: ?*pb.GContext) callconv(.c) void {
    pb.graphics_context_set_compositing_mode(ctx, pb.GCompOpSet);

    const layout = dateLayout();
    const size = pb.GSize{ .h = DATE_DIGIT_HEIGHT, .w = DATE_DIGIT_WIDTH };

    if (s.date_digits[0] != 0) {
        drawAt(ctx, s.s_digits_bitmaps[s.date_digits[0]], layout.month_tens, DATE_Y, size);
    }
    drawAt(ctx, s.s_digits_bitmaps[s.date_digits[1]], layout.month_ones, DATE_Y, size);
    drawAt(ctx, s.s_digits_bitmaps[s.date_digits[2]], layout.day_tens, DATE_Y, size);
    drawAt(ctx, s.s_digits_bitmaps[s.date_digits[3]], layout.day_ones, DATE_Y, size);

    const dash_dest: pb.GRect = .{
        .origin = .{ .x = layout.dash, .y = DATE_DASH_Y },
        .size = .{ .h = DATE_DASH_HEIGHT, .w = DATE_DASH_WIDTH },
    };
    if (s.dash_bitmap) |dash| pb.graphics_draw_bitmap_in_rect(ctx, dash, dash_dest);
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

    pebble.layer.markDirty(s.date_layer);
}

fn updateSec(_: ?*pb.Layer, ctx: ?*pb.GContext) callconv(.c) void {
    pb.graphics_context_set_compositing_mode(ctx, pb.GCompOpSet);

    drawAt(ctx, s.m_digits_bitmaps[s.sec_digits[0]], SEC_TENS.x, SEC_TENS.y, SEC_DIGIT_SIZE);
    drawAt(ctx, s.m_digits_bitmaps[s.sec_digits[1]], SEC_ONES.x, SEC_ONES.y, SEC_DIGIT_SIZE);
}

fn setSec(sec: usize) void {
    s.sec_digits[0] = @divTrunc(sec, 10);
    s.sec_digits[1] = sec % 10;
    if (settings.settingsGetSeconds() == .PerFifteen and sec % 15 != 0) return;
    pebble.layer.markDirty(s.sec_layer);
    pebble.layer.markDirty(s.clock_layer);
}

fn updateMin(_: ?*pb.Layer, ctx: ?*pb.GContext) callconv(.c) void {
    pb.graphics_context_set_compositing_mode(ctx, pb.GCompOpSet);

    const size = pb.GSize{ .h = MIN_DIGIT_HEIGHT, .w = MIN_DIGIT_WIDTH };

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

    pebble.layer.markDirty(s.min_layer);
}

fn updateFaded(_: ?*pb.Layer, ctx: ?*pb.GContext) callconv(.c) void {
    pb.graphics_context_set_compositing_mode(ctx, pb.GCompOpSet);

    const large = pb.GSize{ .h = MIN_DIGIT_HEIGHT, .w = MIN_DIGIT_WIDTH };

    // hours
    drawAt(ctx, s.l_digits_faded_bitmaps[if (s.is_24h) 1 else 0], HR_TENS.x, HR_TENS.y, large);
    drawAt(ctx, s.l_digits_faded_bitmaps[1], HR_ONES.x, HR_ONES.y, large);

    // minutes
    drawAt(ctx, s.l_digits_faded_bitmaps[1], MIN_TENS.x, MIN_TENS.y, large);
    drawAt(ctx, s.l_digits_faded_bitmaps[1], MIN_ONES.x, MIN_ONES.y, large);

    // seconds
    drawAt(ctx, s.m_digits_faded_bitmap, SEC_TENS.x, SEC_TENS.y, SEC_DIGIT_SIZE);
    drawAt(ctx, s.m_digits_faded_bitmap, SEC_ONES.x, SEC_ONES.y, SEC_DIGIT_SIZE);

    // date - a "1" is always in the tens slot for month
    const layout = dateLayout();
    const date_size = pb.GSize{ .h = DATE_DIGIT_HEIGHT, .w = DATE_DIGIT_WIDTH };
    drawAt(ctx, s.s_digits_faded_bitmaps[0], layout.month_tens, DATE_Y, date_size);
    drawAt(ctx, s.s_digits_faded_bitmaps[1], layout.month_ones, DATE_Y, date_size);
    drawAt(ctx, s.s_digits_faded_bitmaps[1], layout.day_tens, DATE_Y, date_size);
    drawAt(ctx, s.s_digits_faded_bitmaps[1], layout.day_ones, DATE_Y, date_size);

    // pm indicator (12h only)
    if (!s.is_24h) {
        drawAt(ctx, s.pm_faded_bitmap, PM.x, PM.y, pb.GSize{ .h = PM_HEIGHT, .w = PM_WIDTH });
    }
}

fn updateMap(_: ?*pb.Layer, ctx: ?*pb.GContext) callconv(.c) void {
    pb.graphics_context_set_compositing_mode(ctx, pb.GCompOpSet);

    const dest: pb.GRect = .{
        .origin = .{ .x = 109, .y = 71 },
        .size = .{ .h = MAP_HEIGHT, .w = MAP_WIDTH },
    };
    if (s.cur_map) |cur| {
        if (s.map_bitmaps[cur]) |map| pb.graphics_draw_bitmap_in_rect(ctx, map, dest);
    }
}

fn forceUpdate() void {
    s.date_format = settings.settingsGetDateFormat();

    updateClock();

    pebble.layer.markDirty(s.faded_layer);
    pebble.layer.markDirty(s.bat_layer);
    pebble.layer.markDirty(s.date_layer);
    pebble.layer.markDirty(s.clock_layer);
    pebble.layer.markDirty(s.sec_layer);
    pebble.layer.markDirty(s.min_layer);

    pb.tick_timer_service_unsubscribe();
    pb.tick_timer_service_subscribe(if (settings.settingsGetSeconds() == .PerMinute) pb.MINUTE_UNIT else pb.SECOND_UNIT, handle_tick);

    s.cur_map = tz.mapIndex(settings.settingsGetTimeZone());
    pebble.layer.markDirty(s.map_layer);
}

fn buildUi(window: ?*pb.Window) void {
    const window_layer = pb.window_get_root_layer(window) orelse return;
    const bounds = pb.layer_get_bounds(window_layer);

    s.is_24h = settings.settingsIs24Hour();
    s.date_format = settings.settingsGetDateFormat();

    s.bg_bitmap = pb.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.IMAGE_BG));
    s.bg_bitmap_layer = pb.bitmap_layer_create(bounds) orelse return;

    pb.bitmap_layer_set_compositing_mode(s.bg_bitmap_layer, pb.GCompOpSet);
    pb.bitmap_layer_set_bitmap(s.bg_bitmap_layer, s.bg_bitmap);

    const bg_layer = pebble.layer.ofBitmap(s.bg_bitmap_layer) catch return;
    pebble.layer.addChild(window_layer, bg_layer);

    // Faded/ghost LCD layer
    s.faded_layer = pb.layer_create(bounds) orelse return;
    pb.layer_set_update_proc(s.faded_layer, updateFaded);
    pebble.layer.addChild(window_layer, s.faded_layer);

    s.pm_faded_bitmap = pb.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.SPRITE_PM_FADED));

    s.s_digits_faded_bitmap = pb.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.TYPE_S_FADED));
    for (0..2) |i| {
        const idx: i16 = @intCast(i);
        const coords: pb.GRect = .{ .origin = .{ .x = idx * DATE_DIGIT_WIDTH, .y = 0 }, .size = .{ .h = DATE_DIGIT_HEIGHT, .w = DATE_DIGIT_WIDTH } };
        s.s_digits_faded_bitmaps[i] = pb.gbitmap_create_as_sub_bitmap(s.s_digits_faded_bitmap, coords);
    }

    s.m_digits_faded_bitmap = pb.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.TYPE_M_FADED));

    s.l_digits_faded_bitmap = pb.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.TYPE_L_FADED));
    for (0..2) |i| {
        const idx: i16 = @intCast(i);
        const coords: pb.GRect = .{ .origin = .{ .x = idx * MIN_DIGIT_WIDTH, .y = 0 }, .size = .{ .h = MIN_DIGIT_HEIGHT, .w = MIN_DIGIT_WIDTH } };
        s.l_digits_faded_bitmaps[i] = pb.gbitmap_create_as_sub_bitmap(s.l_digits_faded_bitmap, coords);
    }

    s.bat_faded_bitmap = pb.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.SPRITE_BAT_FADED));
    for (0..3) |i| {
        const idx: i16 = @intCast(i);
        const coords: pb.GRect = .{ .origin = .{ .x = idx * BAT_WIDTH, .y = 0 }, .size = .{ .h = BAT_HEIGHT, .w = BAT_WIDTH } };
        s.bat_faded_bitmaps[i] = pb.gbitmap_create_as_sub_bitmap(s.bat_faded_bitmap, coords);
    }

    s.pm_bitmap = pb.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.SPRITE_PM));
    const pm_rect: pb.GRect = .{
        .origin = .{ .x = PM.x, .y = PM.y },
        .size = .{ .h = PM_HEIGHT, .w = PM_WIDTH },
    };
    s.pm_bitmap_layer = pb.bitmap_layer_create(pm_rect) orelse return;

    pb.bitmap_layer_set_compositing_mode(s.pm_bitmap_layer, pb.GCompOpSet);
    pb.bitmap_layer_set_bitmap(s.pm_bitmap_layer, s.pm_bitmap);

    const pm_layer = pebble.layer.ofBitmap(s.pm_bitmap_layer) catch return;
    pebble.layer.addChild(window_layer, pm_layer);

    s.date_layer = pb.layer_create(bounds) orelse return;
    pb.layer_set_update_proc(s.date_layer, updateDate);
    pebble.layer.addChild(window_layer, s.date_layer);
    s.s_digits_bitmap = pb.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.TYPE_S));
    for (0..10) |i| {
        const idx: i16 = @intCast(i);
        const coords: pb.GRect = .{ .origin = .{ .x = idx * DATE_DIGIT_WIDTH, .y = 0 }, .size = .{ .h = DATE_DIGIT_HEIGHT, .w = DATE_DIGIT_WIDTH } }; // error from grect being bad?

        s.s_digits_bitmaps[i] = pb.gbitmap_create_as_sub_bitmap(s.s_digits_bitmap, coords);
    }

    s.dash_bitmap = pb.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.SPRITE_DASH));

    s.sec_layer = pb.layer_create(bounds) orelse return;
    pb.layer_set_update_proc(s.sec_layer, updateSec);
    pebble.layer.addChild(window_layer, s.sec_layer);
    s.m_digits_bitmap = pb.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.TYPE_M));
    for (0..10) |i| {
        const idx: i16 = @intCast(i);
        const coords: pb.GRect = .{ .origin = .{ .x = idx * SEC_DIGIT_SIZE.w, .y = 0 }, .size = SEC_DIGIT_SIZE }; // error from grect being bad?
        s.m_digits_bitmaps[i] = pb.gbitmap_create_as_sub_bitmap(s.m_digits_bitmap, coords);
    }

    s.min_layer = pb.layer_create(bounds) orelse return;
    pb.layer_set_update_proc(s.min_layer, updateMin);
    pebble.layer.addChild(window_layer, s.min_layer);
    s.l_digits_bitmap = pb.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.TYPE_L));
    for (0..10) |i| {
        const idx: i16 = @intCast(i);
        const coords: pb.GRect = .{ .origin = .{ .x = idx * MIN_DIGIT_WIDTH, .y = 0 }, .size = .{ .h = MIN_DIGIT_HEIGHT, .w = MIN_DIGIT_WIDTH } }; // error from grect being bad?
        s.l_digits_bitmaps[i] = pb.gbitmap_create_as_sub_bitmap(s.l_digits_bitmap, coords);
    }

    s.bat_layer = pb.layer_create(bounds) orelse return;
    pb.layer_set_update_proc(s.bat_layer, battery_update_proc);
    pebble.layer.addChild(window_layer, s.bat_layer);
    s.bat_bitmap = pb.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.SPRITE_BAT));
    for (0..3) |i| {
        const idx: i16 = @intCast(i);
        const coords: pb.GRect = .{ .origin = .{ .x = idx * BAT_WIDTH, .y = 0 }, .size = .{ .h = BAT_HEIGHT, .w = BAT_WIDTH } };
        s.bat_bitmaps[i] = pb.gbitmap_create_as_sub_bitmap(s.bat_bitmap, coords);
    }

    s.day_font = pb.fonts_load_custom_font(pb.resource_get_handle(@intFromEnum(presource.RESOURCE_IDS.FONT_DSEG_14)));

    // Day-of-week ghost
    s.day_faded_layer = pb.text_layer_create(DAY_TEXT_RECT) orelse return;
    pb.text_layer_set_font(s.day_faded_layer, s.day_font);
    pb.text_layer_set_background_color(s.day_faded_layer, pb.GColorClear);
    pb.text_layer_set_text_color(s.day_faded_layer, FADED_GREEN);
    pb.text_layer_set_text_alignment(s.day_faded_layer, pb.GTextAlignmentCenter);
    pb.text_layer_set_text(s.day_faded_layer, "~~~");
    const day_faded_layer = pebble.layer.ofText(s.day_faded_layer) catch return;
    pebble.layer.addChild(window_layer, day_faded_layer);

    s.day_layer = pb.text_layer_create(DAY_TEXT_RECT) orelse return;
    pb.text_layer_set_font(s.day_layer, s.day_font);
    pb.text_layer_set_background_color(s.day_layer, pb.GColorClear);
    pb.text_layer_set_text_color(s.day_layer, pb.GColorBlack);
    pb.text_layer_set_text_alignment(s.day_layer, pb.GTextAlignmentCenter);

    const day_layer = pebble.layer.ofText(s.day_layer) catch return;
    pebble.layer.addChild(window_layer, day_layer);

    s.clock_layer = pb.layer_create(bounds) orelse return;
    pb.layer_set_update_proc(s.clock_layer, clock_update_proc);
    pebble.layer.addChild(window_layer, s.clock_layer);

    s.map_layer = pb.layer_create(bounds) orelse return;
    pb.layer_set_update_proc(s.map_layer, updateMap);
    pebble.layer.addChild(window_layer, s.map_layer);
    s.map_bitmap = pb.gbitmap_create_with_resource(@intFromEnum(presource.RESOURCE_IDS.SPRITE_MAP));
    for (0..20) |i| {
        const idx: i16 = @intCast(i);
        const coords: pb.GRect = .{ .origin = .{ .x = idx * MAP_WIDTH, .y = 0 }, .size = .{ .h = MAP_HEIGHT, .w = MAP_WIDTH } };
        s.map_bitmaps[i] = pb.gbitmap_create_as_sub_bitmap(s.map_bitmap, coords);
    }

    s.ready = true;
}

fn window_load(window: ?*pb.Window) callconv(.c) void {
    buildUi(window);
    if (!s.ready) {
        return;
    }

    messaging.messagingInit(forceUpdate) catch {};

    pb.battery_state_service_subscribe(battery_callback);
    battery_callback(pb.battery_state_service_peek());

    forceUpdate();
}

fn window_unload(_: ?*pb.Window) callconv(.c) void {
    pb.tick_timer_service_unsubscribe();
    pb.battery_state_service_unsubscribe();
    messaging.messagingDeinit();

    if (!s.ready) {
        return;
    }
    s.ready = false;

    pb.gbitmap_destroy(s.bg_bitmap);
    pb.bitmap_layer_destroy(s.bg_bitmap_layer);

    pb.gbitmap_destroy(s.pm_faded_bitmap);
    for (0..2) |i| {
        pb.gbitmap_destroy(s.s_digits_faded_bitmaps[i]);
        pb.gbitmap_destroy(s.l_digits_faded_bitmaps[i]);
    }
    pb.gbitmap_destroy(s.s_digits_faded_bitmap);
    pb.gbitmap_destroy(s.m_digits_faded_bitmap);
    pb.gbitmap_destroy(s.l_digits_faded_bitmap);
    for (0..3) |i| {
        pb.gbitmap_destroy(s.bat_faded_bitmaps[i]);
    }
    pb.gbitmap_destroy(s.bat_faded_bitmap);
    pb.layer_destroy(s.faded_layer);

    pb.gbitmap_destroy(s.pm_bitmap);
    pb.bitmap_layer_destroy(s.pm_bitmap_layer);

    pb.gbitmap_destroy(s.dash_bitmap);

    for (0..10) |i| {
        pb.gbitmap_destroy(s.s_digits_bitmaps[i]);
        pb.gbitmap_destroy(s.m_digits_bitmaps[i]);
        pb.gbitmap_destroy(s.l_digits_bitmaps[i]);
    }
    pb.gbitmap_destroy(s.s_digits_bitmap);
    pb.gbitmap_destroy(s.m_digits_bitmap);
    pb.gbitmap_destroy(s.l_digits_bitmap);
    pb.layer_destroy(s.date_layer);
    pb.layer_destroy(s.sec_layer);
    pb.layer_destroy(s.min_layer);

    for (0..3) |i| {
        pb.gbitmap_destroy(s.bat_bitmaps[i]);
    }
    pb.gbitmap_destroy(s.bat_bitmap);
    pb.layer_destroy(s.bat_layer);

    pb.fonts_unload_custom_font(s.day_font);
    pb.text_layer_destroy(s.day_faded_layer);
    pb.text_layer_destroy(s.day_layer);

    for (0..20) |i| {
        pb.gbitmap_destroy(s.map_bitmaps[i]);
    }
    pb.gbitmap_destroy(s.map_bitmap);
    pb.layer_destroy(s.map_layer);
}

export fn main() void {
    s.window = pb.window_create();
    if (s.window == null) {
        unreachable;
    }
    defer pb.window_destroy(s.window);

    pb.window_set_window_handlers(s.window, .{
        .load = window_load,
        .unload = window_unload,
    });

    pb.window_stack_push(s.window, true);

    pb.app_event_loop();
}
