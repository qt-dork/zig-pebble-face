const std = @import("std");
const pb = @import("pebble");

pub const Iterator = pb.DictionaryIterator;
pub const Tuple = pb.Tuple;

pub const layer = struct {
    pub const LayerError = error{
        LayerDoesNotExist,
    };

    pub inline fn ofBitmap(bitmap_layer: *const pb.BitmapLayer) LayerError!*pb.Layer {
        return pb.bitmap_layer_get_layer(bitmap_layer) orelse LayerError.LayerDoesNotExist;
    }

    pub inline fn ofText(text_layer: *pb.TextLayer) LayerError!*pb.Layer {
        return pb.text_layer_get_layer(text_layer) orelse LayerError.LayerDoesNotExist;
    }

    pub inline fn addChild(parent: *pb.Layer, child: *pb.Layer) void {
        pb.layer_add_child(parent, child);
    }

    pub inline fn markDirty(l: *pb.Layer) void {
        pb.layer_mark_dirty(l);
    }

    pub inline fn setHidden(l: *pb.Layer, hidden: bool) void {
        pb.layer_set_hidden(l, hidden);
    }
};

pub const tuple = struct {
    const kind_int: u8 = @intCast(pb.TUPLE_INT);
    const kind_uint: u8 = @intCast(pb.TUPLE_UINT);
    const kind_cstring: u8 = @intCast(pb.TUPLE_CSTRING);

    /// The tuple stored under `key`. Is null when absent.
    pub fn find(iter: ?*const Iterator, key: u32) ?*Tuple {
        return pb.dict_find(iter orelse return null, key);
    }

    pub fn getInt(iter: ?*const Iterator, key: u32) ?i32 {
        const entry = find(iter, key) orelse return null;
        if (entry.type == kind_int) {
            return switch (entry.length) {
                1 => entry.*.value().*.int8,
                2 => entry.*.value().*.int16,
                4 => entry.*.value().*.int32,
                else => null,
            };
        }
        if (entry.type == kind_uint) {
            const magnitude: u32 = switch (entry.length) {
                1 => entry.*.value().*.uint8,
                2 => entry.*.value().*.uint16,
                4 => entry.*.value().*.uint32,
                else => return null,
            };
            return std.math.cast(i32, magnitude);
        }
        if (entry.type == kind_cstring) {
            return std.fmt.parseInt(i32, std.mem.span(entry.*.value().*.cstring()), 10) catch null;
        }
        return null;
    }

    pub fn getBool(iter: ?*const Iterator, key: u32) ?bool {
        return (getInt(iter, key) orelse return null) != 0;
    }

    pub fn getString(iter: ?*const Iterator, key: u32) ?[*:0]const u8 {
        const entry = find(iter, key) orelse return null;
        if (entry.type != kind_cstring) return null;
        return @ptrCast(entry.*.value().*.cstring());
    }
};

pub const appMessage = struct {
    pub const InboxReceived = *const fn (iter: ?*const Iterator) void;

    var inbox_received: ?InboxReceived = null;

    fn inboxReceivedTrampoline(iter: [*c]pb.DictionaryIterator, _: ?*anyopaque) callconv(.c) void {
        if (inbox_received) |handler| handler(iter);
    }

    pub fn onInboxReceived(handler: InboxReceived) void {
        inbox_received = handler;
        _ = pb.app_message_register_inbox_received(inboxReceivedTrampoline);
    }

    pub const OpenError = error{
        AlreadyReleased,
        InvalidArgs,
        OutOfMemory,
        InternalError,
        Unexpected,
    };

    pub fn open(inbox_bytes: u32, outbox_bytes: u32) OpenError!void {
        const result: c_int = @intCast(pb.app_message_open(inbox_bytes, outbox_bytes));
        switch (result) {
            pb.APP_MSG_OK => return,
            pb.APP_MSG_INVALID_ARGS => return error.InvalidArgs,
            pb.APP_MSG_ALREADY_RELEASED => return error.AlreadyReleased,
            pb.APP_MSG_OUT_OF_MEMORY => return error.OutOfMemory,
            pb.APP_MSG_INTERNAL_ERROR => return error.InternalError,
            else => return error.Unexpected,
        }
    }

    pub fn close() void {
        inbox_received = null;
        pb.app_message_deregister_callbacks();
    }
};
