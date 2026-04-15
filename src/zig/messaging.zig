const pebble = @import("pebble");
const presource = @import("pebble_appids");

const packet = @import("pebble_packet.zig");
const pog = @import("pog.zig");
const settings = @import("settings.zig");

const MessagingCallback = *const fn () void;

var on_update: MessagingCallback = undefined;

fn inbox_received_handler(iter: [*c]pebble.DictionaryIterator, context: ?*anyopaque) callconv(.c) void {
    _ = context; // autofix
    pog.debug(@src(), "!!! Message Logged !!!", .{});
    if (packet.containsKey(iter, @intFromEnum(presource.MESSAGE_KEYS.SettingsEnableSeconds))) {
        const string = packet.getString(iter, @intFromEnum(presource.MESSAGE_KEYS.SettingsEnableSeconds));
        const int: settings.SecondsOptions = @enumFromInt(pebble.atoi(string));
        settings.settingsSetSeconds(int);
    }

    if (packet.containsKey(iter, @intFromEnum(presource.MESSAGE_KEYS.SettingsTimeZone))) {
        const string = packet.getString(iter, @intFromEnum(presource.MESSAGE_KEYS.SettingsTimeZone));
        const int: settings.TimeZoneOptions = @enumFromInt(pebble.atoi(string));
        settings.settingsSetTimeZone(int);
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
