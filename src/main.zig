// src/main.zig
const std = @import("std");

const pebble = @import("pebble");

var s_window: ?*pebble.Window = null;
var s_time_layer: ?*pebble.TextLayer = null;

fn tick_handler(tick_time: ?*pebble.tm, units_changed: pebble.TimeUnits) callconv(.c) void {
    _ = tick_time; // autofix
    _ = units_changed; // autofix
    update_time();
}

fn update_time() void {
    // Get a tm structure
    var temp = pebble.time(null);
    const tick_time = pebble.localtime(&temp);

    // Write the current hours and minutes into a buffer
    var s_time_buffer = std.mem.zeroes([8:0]u8);
    _ = pebble.strftime(&s_time_buffer, s_time_buffer.len, if (pebble.clock_is_24h_style()) "%H:$M" else "%I:%M", tick_time);

    // Display this time on the TextLayer
    pebble.text_layer_set_text(s_time_layer, &s_time_buffer);
}

fn window_load(window: ?*pebble.Window) callconv(.c) void {
    // Get information about the window
    const window_layer = pebble.window_get_root_layer(window);
    const bounds = pebble.layer_get_bounds(window_layer);

    // Create the time TextLayer
    s_time_layer = pebble.text_layer_create(pebble.GRect{ .origin = .{
        .x = 0,
        .y = pebble.PBL_IF_ROUND_ELSE(58, 52),
    }, .size = .{
        .w = bounds.size.w,
        .h = 50,
    } });
    pebble.text_layer_set_background_color(s_time_layer, pebble.GColorClear);
    pebble.text_layer_set_text_color(s_time_layer, pebble.GColorWhite);
    pebble.text_layer_set_font(s_time_layer, pebble.fonts_get_system_font(pebble.FONT_KEY_BITHAM_42_BOLD));
    pebble.text_layer_set_text_alignment(s_time_layer, pebble.GTextAlignmentCenter);

    // Add it as a child layer to the Window's root layer
    pebble.layer_add_child(window_layer, pebble.text_layer_get_layer(s_time_layer));
}

fn window_unload(window: ?*pebble.Window) callconv(.c) void {
    _ = window; // autofix
    pebble.text_layer_destroy(s_time_layer);
}

fn init() void {
    // Create main window element and assign to pointer
    s_window = pebble.window_create();

    // Set the background color
    pebble.window_set_background_color(s_window, pebble.GColorBlack);

    // Set handlers to manage the elements inside the window
    pebble.window_set_window_handlers(s_window, .{ .load = window_load, .unload = window_unload });

    // Show the Window on the watch, with animated=true
    pebble.window_stack_push(s_window, true);

    // Make sure the time is displayed from the start
    update_time();

    // Register with TickTimerService
    pebble.tick_timer_service_subscribe(pebble.MINUTE_UNIT, tick_handler);
}

fn deinit() void {
    // Destroy window
    pebble.window_destroy(s_window);
}

export fn main() void {
    init();
    pebble.app_event_loop();
    deinit();
}
