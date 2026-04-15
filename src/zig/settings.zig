const pebble = @import("pebble");
const presource = @import("pebble_appids");

// const SETTINGS_SECONDS_KEY = 1;
// const SETTINGS_TIMEZONE_KEY = 2;

// pub const ClaySettings = struct {
//     EnableSeconds: c_int,
//     TimeZone: c_int,

//     pub fn toSettings(self: @This()) Settings {
//         return .{
//             .seconds = @enumFromInt(self.EnableSeconds),
//             .tz = @enumFromInt(self.TimeZone),
//         };
//     }
// };

// const SECONDS_KEY = 1;
// const TIMEZONE_KEY = 2;

pub const SecondsOptions = enum(isize) {
    PerSecond = 0,
    PerFifteen = 1,
    PerMinute = 2,
};

pub const TimeZoneOptions = enum(isize) {
    None = -1,
    PagoPago = 0,
    Hololulu = 1,
    Anchorage = 2,
    Vancouver = 3,
    SanFran = 4,
    Edmonton = 5,
    Denver = 6,
    CDMX = 7,
    Chicago = 8,
    NYC = 9,
    Santiago = 10,
    Halifax = 11,
    StJohns = 12,
    Rio = 13,
    FdeNoronha = 14,
    Praia = 15,
    UTC = 16,
    Lisbon = 17,
    London = 18,
    Madrid = 19,
    Paris = 20,
    Rome = 21,
    Berlin = 22,
    Stockholm = 23,
    Athen = 24,
    Cairo = 25,
    Jerusalem = 26,
    Moscow = 27,
    Jeddah = 28,
    Tehran = 29,
    Dubai = 30,
    Kabul = 31,
    Delhi = 33,
    Kathmandu = 34,
    Dhaka = 35,
    Yangon = 36,
    Bangkok = 37,
    Singapore = 38,
    HongKong = 39,
    Beijing = 40,
    Taipei = 41,
    Seoul = 42,
    Tokyo = 43,
    Adelaide = 44,
    Guam = 45,
    Sydney = 46,
    Noumea = 47,
    Wellington = 48,
};

const DEFAULT = Settings{};

pub const Settings = struct {
    seconds: SecondsOptions = SecondsOptions.PerSecond,
    tz: TimeZoneOptions = TimeZoneOptions.None,

    // pub fn toClay(self: @This()) ClaySettings {
    //     return .{
    //         .EnableSeconds = self.seconds,
    //         .TimeZone = self.tz,
    //     };
    // }
};

pub fn settingsRead(key: usize) ?isize {
    return if (pebble.persist_exists(key)) @intCast(pebble.persist_read_int(key)) else null;
}

pub fn settingsSetSeconds(option: SecondsOptions) void {
    const value: i32 = @intCast(@intFromEnum(option));
    _ = pebble.persist_write_int(@intFromEnum(presource.MESSAGE_KEYS.SettingsEnableSeconds), value);
}

pub fn settingsGetSeconds() SecondsOptions {
    const read = settingsRead(@intFromEnum(presource.MESSAGE_KEYS.SettingsEnableSeconds));
    if (read == null) return DEFAULT.seconds else return @enumFromInt(read.?);
}

pub fn settingsSetTimeZone(option: TimeZoneOptions) void {
    const value: i32 = @intCast(@intFromEnum(option));

    _ = pebble.persist_write_int(@intFromEnum(presource.MESSAGE_KEYS.SettingsTimeZone), value);
}

pub fn settingsGetTimeZone() TimeZoneOptions {
    return settingsRead(@intFromEnum(presource.MESSAGE_KEYS.SettingsTimeZone)) orelse DEFAULT.tz;
}
