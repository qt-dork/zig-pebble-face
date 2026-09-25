const std = @import("std");

const pebble = @import("pebble");
const presource = @import("pebble_appids");

const pog = @import("pog.zig");
const settings = @import("settings.zig");

// const packet = @import("pebble_packet.zig");
const MessagingCallback = *const fn () void;

var on_update: MessagingCallback = undefined;

const TUPLE_INT: u8 = @intCast(pebble.TUPLE_INT);
const TUPLE_UINT: u8 = @intCast(pebble.TUPLE_UINT);
const TUPLE_CSTRING: u8 = @intCast(pebble.TUPLE_CSTRING);

fn lookupInt(iter: [*c]pebble.DictionaryIterator, key: u32) ?i32 {
    const tuple = pebble.dict_find(iter, key) orelse return null;
    if (tuple.*.type == TUPLE_INT) return tuple.*.value().*.int32;
    if (tuple.*.type == TUPLE_UINT) return std.math.cast(i32, tuple.*.value().*.uint32);
    if (tuple.*.type == TUPLE_CSTRING) return std.fmt.parseInt(i32, std.mem.span(tuple.*.value().*.cstring()), 10) catch null;
    return null;
}

fn inbox_received_handler(iter: [*c]pebble.DictionaryIterator, _: ?*anyopaque) callconv(.c) void {
    if (lookupInt(iter, @intFromEnum(presource.MESSAGE_KEYS.SettingsEnableSeconds))) |value| {
        if (std.enums.fromInt(settings.SecondsOptions, value)) |option| settings.settingsSetSeconds(option);
    }

    if (lookupInt(iter, @intFromEnum(presource.MESSAGE_KEYS.SettingsDateFormat))) |value| {
        if (std.enums.fromInt(settings.DateFormatOptions, value)) |option| settings.settingsSetDateFormat(option);
    }

    if (lookupInt(iter, @intFromEnum(presource.MESSAGE_KEYS.SettingsTimeZone))) |value| {
        if (std.enums.fromInt(settings.TimeZoneOptions, value)) |option| settings.settingsSetTimeZone(option);
    }

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
