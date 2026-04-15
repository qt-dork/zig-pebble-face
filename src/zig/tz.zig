// bad solution. will move to doing it on the phone later, when i can do better testing
// doesn't support dst (sorry)

const pebble = @import("pebble");

const settings = @import("settings.zig");

// time must be in utc
pub fn offsetTime(from: pebble.tm, tz: settings.TimeZoneOptions) pebble.tm {
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
        .Tehran => return newTm(from, 2, 30),
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

fn newTm(from: pebble.tm, gmtoff: c_int, minoff: c_int) pebble.tm {
    var mod = from;
    mod.tm_gmtoff = gmtoff;
    mod.tm_hour = wrappingAddHour(mod.tm_hour, gmtoff);
    mod.tm_min = wrappingAddMin(mod.tm_min, minoff);
    return mod;
}

fn wrappingAddHour(lhs: c_int, rhs: c_int) c_int {
    return @rem((lhs + 24) + rhs, 24);
}

fn wrappingAddMin(lhs: c_int, rhs: c_int) c_int {
    return @rem((lhs + 24) + rhs, 24);
}
