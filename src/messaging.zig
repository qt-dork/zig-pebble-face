const std = @import("std");

const pebble = @import("pebble");
const presource = @import("pebble_appids");

const pog = @import("pog.zig");
const settings = @import("settings.zig");

// const packet = @import("pebble_packet.zig");
const MessagingCallback = *const fn () void;

var on_update: MessagingCallback = undefined;

fn inbox_received_handler(iter: [*c]pebble.DictionaryIterator, _: ?*anyopaque) callconv(.c) void {
    const seconds_tuple = pebble.dict_find(iter, @intFromEnum(presource.MESSAGE_KEYS.SettingsEnableSeconds));
    const seconds: ?i32 = if (seconds_tuple) |t| blk: {
        const ptr: [*:0]u8 = @ptrCast(&t.*.value().*.cstring);
        const s = std.mem.span(ptr);
        break :blk std.fmt.parseInt(i32, s, 10) catch null;
    } else null;
    if (seconds) |t| settings.settingsSetSeconds(@enumFromInt(t));

    const timezone_tuple = pebble.dict_find(iter, @intFromEnum(presource.MESSAGE_KEYS.SettingsTimeZone));
    const timezone: ?i32 = if (timezone_tuple) |t| blk: {
        const ptr: [*:0]u8 = @ptrCast(&t.*.value().*.cstring);
        const s = std.mem.span(ptr);
        break :blk std.fmt.parseInt(i32, s, 10) catch null;
    } else null;
    if (timezone) |t| settings.settingsSetTimeZone(@enumFromInt(t));

    on_update();
}

pub fn messagingInit(callback: MessagingCallback) void {
    on_update = callback;
    _ = pebble.app_message_register_inbox_received(inbox_received_handler);
    _ = pebble.app_message_open(128, 128);
}

pub fn messagingDeinit() void {
    pebble.app_message_deregister_callbacks();
}
