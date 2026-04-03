// src/main.zig
const std = @import("std");

const pebble = @import("pebble");
const pebble_appids = @import("pebble_appids");

var s_window: ?*pebble.Window = null;
var s_time_layer: ?*pebble.TextLayer = null;
// Write the current hours and minutes into a buffer
var s_time_buffer = std.mem.zeroes([8:0]u8);

var s_date_layer: ?*pebble.TextLayer = null;
var s_date_buffer = std.mem.zeroes([16:0]u8);

var s_time_font: pebble.GFont = null;
var s_date_font: pebble.GFont = null;

var s_battery_layer: ?*pebble.Layer = null;
var s_battery_level: u8 = undefined;

var s_bt_icon_layer: ?*pebble.BitmapLayer = null;
var s_bt_icon_bitmap: ?*pebble.GBitmap = null;

fn bluetooth_callback(connected: bool) callconv(.c) void {
    // Show icon if disconnected
    pebble.layer_set_hidden(pebble.bitmap_layer_get_layer(s_bt_icon_layer), connected);

    if (!connected) {
        // Issue a vibrating alert
        pebble.vibes_double_pulse();
    }
}

fn battery_callback(state: pebble.BatteryChargeState) callconv(.c) void {
    // Record the new battery level
    s_battery_level = state.charge_percent;

    // Update the meter
    pebble.layer_mark_dirty(s_battery_layer);
}

fn battery_update_proc(layer: ?*pebble.Layer, ctx: ?*pebble.GContext) callconv(.c) void {
    const bounds = pebble.layer_get_bounds(layer);

    // Find the width of the bar (inside the border)
    const bar_width = @divTrunc((s_battery_level * (bounds.size.w - 4)), 100);

    // Draw the border
    pebble.graphics_context_set_stroke_color(ctx, pebble.GColorWhite);
    pebble.graphics_draw_round_rect(ctx, bounds, 2);

    // Choose color based on battery level
    var bar_color: pebble.GColor = undefined;
    if (s_battery_level <= 20) {
        bar_color = pebble.PBL_IF_COLOR_ELSE(pebble.GColorRed, pebble.GColorWhite);
    } else if (s_battery_level <= 40) {
        bar_color = pebble.PBL_IF_COLOR_ELSE(pebble.GColorChromeYellow, pebble.GColorWhite);
    } else {
        bar_color = pebble.PBL_IF_COLOR_ELSE(pebble.GColorGreen, pebble.GColorWhite);
    }

    // Draw the filled bar inside the border
    pebble.graphics_context_set_fill_color(ctx, bar_color);
    pebble.graphics_fill_rect(ctx, pebble.GRect{ .origin = .{
        .x = 2,
        .y = 2,
    }, .size = .{
        .w = bar_width,
        .h = bounds.size.h - 4,
    } }, 1, pebble.GCornerNone);
}

fn tick_handler(tick_time: ?*pebble.tm, units_changed: pebble.TimeUnits) callconv(.c) void {
    _ = tick_time; // autofix
    _ = units_changed; // autofix
    update_time();
}

fn update_time() void {
    // Get a tm structure
    var temp = pebble.time(null);
    const tick_time = pebble.localtime(&temp);

    _ = pebble.strftime(&s_time_buffer, s_time_buffer.len, if (pebble.clock_is_24h_style()) "%H:%M" else "%I:%M", tick_time);

    // Display this time on the TextLayer
    pebble.text_layer_set_text(s_time_layer, &s_time_buffer);

    // Write the current date into a  buffer
    _ = pebble.strftime(&s_date_buffer, s_date_buffer.len, "%a %b %d", tick_time);

    // Display the date
    pebble.text_layer_set_text(s_date_layer, &s_date_buffer);
}

fn window_load(window: ?*pebble.Window) callconv(.c) void {
    // Get information about the window
    const window_layer = pebble.window_get_root_layer(window);
    const bounds = pebble.layer_get_bounds(window_layer);

    s_time_font = pebble.fonts_load_custom_font(pebble.resource_get_handle(@intFromEnum(pebble_appids.RESOURCE_IDS.FONT_SLAPFACE_56)));
    s_date_font = pebble.fonts_load_custom_font(pebble.resource_get_handle(@intFromEnum(pebble_appids.RESOURCE_IDS.FONT_SLAPFACE_24)));

    const date_height = 30;
    const block_height = 56 + date_height;
    const time_y = @divTrunc(bounds.size.h, 2) - @divTrunc(block_height, 2) - 10;
    const date_y = time_y + 56;

    // Create the time TextLayer
    s_time_layer = pebble.text_layer_create(pebble.GRect{ .origin = .{
        .x = 0,
        .y = time_y,
    }, .size = .{
        .w = bounds.size.w,
        .h = 60,
    } });
    pebble.text_layer_set_background_color(s_time_layer, pebble.GColorClear);
    pebble.text_layer_set_text_color(s_time_layer, pebble.GColorWhite);
    pebble.text_layer_set_font(s_time_layer, s_time_font);
    pebble.text_layer_set_text_alignment(s_time_layer, pebble.GTextAlignmentCenter);

    // Add it as a child layer to the Window's root layer
    pebble.layer_add_child(window_layer, pebble.text_layer_get_layer(s_time_layer));

    // Create the date TextLayer
    s_date_layer = pebble.text_layer_create(pebble.GRect{ .origin = .{
        .x = 0,
        .y = date_y,
    }, .size = .{
        .h = 30,
        .w = bounds.size.w,
    } });
    pebble.text_layer_set_background_color(s_date_layer, pebble.GColorClear);
    pebble.text_layer_set_text_color(s_date_layer, pebble.GColorWhite);
    pebble.text_layer_set_font(s_date_layer, s_date_font);
    pebble.text_layer_set_text_alignment(s_date_layer, pebble.GTextAlignmentCenter);

    // Create battery meter Layer - visible bar near the top
    const bar_width = @as(i16, @divTrunc(bounds.size.w, 2));
    const bar_x = @as(i16, @divTrunc((bounds.size.w - bar_width), 2));
    const bar_y = @as(i16, pebble.PBL_IF_ROUND_ELSE(@divTrunc(bounds.size.h, 8), @divTrunc(bounds.size.h, 28)));
    s_battery_layer = pebble.layer_create(pebble.GRect{
        .origin = .{
            .x = bar_x,
            .y = bar_y,
        },
        .size = .{
            .h = 8,
            .w = bar_width,
        },
    });
    pebble.layer_set_update_proc(s_battery_layer, battery_update_proc);

    // Create the Bluetooth icon GBitmap
    s_bt_icon_bitmap = pebble.gbitmap_create_with_resource(@intFromEnum(pebble_appids.RESOURCE_IDS.IMAGE_BT));

    // Create the BitmapLayer to display the GBitmap - below the battery bar, centered
    const bt_y = bar_y + 12;
    s_bt_icon_layer = pebble.bitmap_layer_create(.{
        .origin = .{ .x = @divTrunc(bounds.size.w - 30, 2), .y = bt_y },
        .size = .{ .h = 30, .w = 30 },
    });
    pebble.bitmap_layer_set_bitmap(s_bt_icon_layer, s_bt_icon_bitmap);
    pebble.bitmap_layer_set_compositing_mode(s_bt_icon_layer, pebble.GCompOpSet);

    // Add to Window
    pebble.layer_add_child(window_layer, pebble.text_layer_get_layer(s_date_layer));

    pebble.layer_add_child(window_layer, s_battery_layer);

    pebble.layer_add_child(window_layer, pebble.bitmap_layer_get_layer(s_bt_icon_layer));

    bluetooth_callback(pebble.connection_service_peek_pebble_app_connection());
}

fn window_unload(window: ?*pebble.Window) callconv(.c) void {
    _ = window; // autofix
    pebble.text_layer_destroy(s_time_layer);
    pebble.text_layer_destroy(s_date_layer);
    pebble.gbitmap_destroy(s_bt_icon_bitmap);
    pebble.layer_destroy(s_battery_layer);
    pebble.bitmap_layer_destroy(s_bt_icon_layer);
    pebble.fonts_unload_custom_font(s_time_font);
    pebble.fonts_unload_custom_font(s_date_font);
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

    // Register with TickTimerService
    pebble.tick_timer_service_subscribe(pebble.MINUTE_UNIT, tick_handler);

    // Make sure the time is displayed from the start
    update_time();

    // Register for battery level updates
    pebble.battery_state_service_subscribe(battery_callback);
    // Register for Bluetooth connection updates
    pebble.connection_service_subscribe(pebble.ConnectionHandlers{ .pebble_app_connection_handler = bluetooth_callback });

    // Ensure battery level is displayed from the start
    battery_callback(pebble.battery_state_service_peek());
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
