// Legacy time-zone table. This table is only used before getting the offset from settings.

const pb = @import("pebble");

const settings = @import("settings.zig");

// time must be in utc
pub fn offsetTime(from: pb.tm, tz: settings.TimeZoneOptions) pb.tm {
    if (settings.settingsGetTimeZoneOffsetMinutes()) |minutes| {
        return newTmOffset(from, minutes);
    }

    switch (tz) {
        .PagoPago => return newTm(from, -11, 0),
        .Hololulu => return newTm(from, -10, 0),
        .Anchorage => return newTm(from, -9, 0),
        .Vancouver, .SanFran => return newTm(from, -8, 0),
        .Edmonton, .Denver => return newTm(from, -7, 0),
        .CDMX, .Chicago => return newTm(from, -6, 0),
        .NYC => return newTm(from, -5, 0),
        .Santiago, .Halifax => return newTm(from, -4, 0),
        .StJohns => return newTm(from, -3, 30),
        .Rio => return newTm(from, -3, 0),
        .FdeNoronha => return newTm(from, -2, 0),
        .Praia => return newTm(from, -1, 0),
        .UTC, .Lisbon, .London => return from,
        .Madrid, .Paris, .Rome, .Berlin, .Stockholm => return newTm(from, 1, 0),
        .Athen, .Cairo, .Jerusalem => return newTm(from, 2, 0),
        .Moscow, .Jeddah => return newTm(from, 3, 0),
        .Tehran => return newTm(from, 3, 30),
        .Dubai => return newTm(from, 4, 0),
        .Kabul => return newTm(from, 4, 30),
        .Karachi => return newTm(from, 5, 0),
        .Delhi => return newTm(from, 5, 30),
        .Kathmandu => return newTm(from, 5, 45),
        .Dhaka => return newTm(from, 6, 0),
        .Yangon => return newTm(from, 6, 30),
        .Bangkok => return newTm(from, 7, 0),
        .Singapore, .HongKong, .Beijing, .Taipei => return newTm(from, 8, 0),
        .Seoul, .Tokyo => return newTm(from, 9, 0),
        .Adelaide => return newTm(from, 9, 30),
        .Guam, .Sydney => return newTm(from, 10, 0),
        .Noumea => return newTm(from, 11, 0),
        .Wellington => return newTm(from, 12, 0),
        else => return from,
    }
}

pub fn mapIndex(tz: settings.TimeZoneOptions) ?usize {
    switch (tz) {
        .PagoPago, .Hololulu, .Anchorage => return 0,
        .Vancouver, .SanFran => return 1,
        .Edmonton, .Denver => return 2,
        .CDMX, .Chicago => return 3,
        .NYC => return 4,
        .Santiago, .Halifax, .StJohns => return 5,
        .Rio, .FdeNoronha => return 6,
        .Praia, .UTC, .Lisbon, .London => return 7,
        .Madrid, .Paris, .Rome, .Berlin, .Stockholm => return 8,
        .Athen, .Cairo, .Jerusalem => return 9,
        .Moscow, .Jeddah, .Tehran => return 10,
        .Dubai, .Kabul => return 11,
        .Karachi, .Delhi, .Kathmandu => return 12,
        .Dhaka => return 13,
        .Yangon, .Bangkok => return 14,
        .Singapore, .HongKong, .Beijing, .Taipei => return 15,
        .Seoul, .Tokyo, .Adelaide => return 16,
        .Guam, .Sydney => return 17,
        .Noumea => return 18,
        .Wellington => return 19,
        else => return null,
    }
}

fn shiftMinutes(from: pb.tm, offset_minutes: c_int) pb.tm {
    const day_minutes = 24 * 60;
    const minute_of_day = @mod(from.tm_hour * 60 + from.tm_min + offset_minutes, day_minutes);

    var mod = from;
    mod.tm_gmtoff = offset_minutes * 60;
    mod.tm_hour = @divTrunc(minute_of_day, 60);
    mod.tm_min = @rem(minute_of_day, 60);
    return mod;
}

fn newTm(from: pb.tm, gmtoff_hours: c_int, minoff: c_int) pb.tm {
    return shiftMinutes(from, gmtoff_hours * 60 + minoff);
}

fn newTmOffset(from: pb.tm, minutes: i16) pb.tm {
    return shiftMinutes(from, @intCast(minutes));
}
