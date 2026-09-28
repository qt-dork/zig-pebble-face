const std = @import("std");

const presource = @import("pebble_appids");

const pb = @import("pebble.zig");
const settings = @import("settings.zig");

const MessagingCallback = *const fn () void;

var on_update: MessagingCallback = undefined;

fn handleInbox(iter: ?*const pb.Iterator) void {
    if (pb.tuple.getInt(iter, @intFromEnum(presource.MESSAGE_KEYS.SettingsEnableSeconds))) |value| {
        if (std.enums.fromInt(settings.SecondsOptions, value)) |option| settings.settingsSetSeconds(option);
    }

    if (pb.tuple.getInt(iter, @intFromEnum(presource.MESSAGE_KEYS.SettingsDateFormat))) |value| {
        if (std.enums.fromInt(settings.DateFormatOptions, value)) |option| settings.settingsSetDateFormat(option);
    }

    if (pb.tuple.getInt(iter, @intFromEnum(presource.MESSAGE_KEYS.SettingsTimeZone))) |value| {
        if (std.enums.fromInt(settings.TimeZoneOptions, value)) |option| {
            settings.settingsSetTimeZone(option);
            settings.settingsClearTimeZoneOffsetMinutes();
        }
    }

    if (pb.tuple.getInt(iter, @intFromEnum(presource.MESSAGE_KEYS.SettingsTimeZoneOffsetMinutes))) |value| {
        if (std.math.cast(i16, value)) |minutes| settings.settingsSetTimeZoneOffsetMinutes(minutes);
    }

    on_update();
}

pub fn messagingInit(callback: MessagingCallback) pb.appMessage.OpenError!void {
    on_update = callback;
    pb.appMessage.onInboxReceived(handleInbox);
    try pb.appMessage.open(128, 128);
}

pub fn messagingDeinit() void {
    pb.appMessage.close();
}
