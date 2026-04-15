const pebble = @import("pebble");

const pog = @import("pog.zig");

const TAG = "pebble-packet";

var s_outbox: ?*pebble.DictionaryIterator = null;

fn resultToString(result: pebble.AppMessageResult) []const u8 {
    switch (result) {
        pebble.APP_MSG_OK => return "Success",
        pebble.APP_MSG_SEND_TIMEOUT => return "Send timeout",
        pebble.APP_MSG_SEND_REJECTED => return "Send rejected",
        pebble.APP_MSG_NOT_CONNECTED => return "Not connected",
        pebble.APP_MSG_APP_NOT_RUNNING => return "App not running",
        pebble.APP_MSG_INVALID_ARGS => return "Invalid arguments",
        pebble.APP_MSG_BUSY => return "Busy",
        pebble.APP_MSG_BUFFER_OVERFLOW => return "Buffer overflow",
        pebble.APP_MSG_CLOSED => return "Closed",
        pebble.APP_MSG_INTERNAL_ERROR => return "Internal error",
        pebble.APP_MSG_INVALID_STATE => return "Invalid state. Iss AppMessage open?",
        _ => {
            var s_buff: [32]u8 = undefined;
            pebble.snprintf(s_buff, s_buff.len, "Unknown error (%d)", result);
            return &s_buff;
        },
    }
}

pub fn begin() bool {
    const r = pebble.app_message_outbox_begin(&s_outbox);
    if (r != pebble.APP_MSG_OK) {
        pog.err(@src(), TAG ++ ": Error opening outbox! Reason: {s}", .{resultToString(r)});
        return false;
    }
    return true;
}

pub fn putInteger(key: u32, value: usize) bool {
    const r = pebble.dict_write_int32(s_outbox, key, value);
    if (r != pebble.DICT_OK) {
        pog.err(@src(), TAG ++ ": Error adding integer to outbox!", .{});
        return false;
    }
    return true;
}

pub fn putString(key: u32, string: [*:0]const u8) bool {
    const r = pebble.dict_write_cstring(s_outbox, key, string);
    if (r != pebble.DICT_OK) {
        pog.err(@src(), TAG ++ ": Error adding string to outbox!", .{});
        return false;
    }
    return true;
}

pub fn putBool(key: u32, b: bool) bool {
    return putInteger(key, @intFromBool(b));
}

// pub fn packetGetSize(inbox_iter: ?*pebble.DictionaryIterator) usize {
//     return inbox_iter.?.end - inbox_iter.?.dictionary;
// }

pub fn containsKey(inbox_iter: ?*pebble.DictionaryIterator, key: u32) bool {
    return pebble.dict_find(inbox_iter, key) != null;
}

pub fn getInteger(inbox_iter: ?*pebble.DictionaryIterator, key: u32) ?usize {
    if (!containsKey(inbox_iter, key)) return null;
    const out = pebble.dict_find(inbox_iter, key).*.value();
    return out.*.int32;
}

pub fn getString(inbox_iter: ?*pebble.DictionaryIterator, key: u32) ?[*:0]const u8 {
    if (!containsKey(inbox_iter, key)) {
        return null;
    }
    const out = pebble.dict_find(inbox_iter, key).*.value();
    return @as(?[*:0]const u8, @ptrCast(&out.*.cstring));
}

pub fn getBoolean(inbox_iter: ?*pebble.DictionaryIterator, key: u32) bool {
    return getInteger(inbox_iter, key) == 1;
}
