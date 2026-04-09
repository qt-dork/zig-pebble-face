// Pebble lOGging
// Thank you for coming to my ted talk

pub const std = @import("std");
const level = std.options.log_level;
const scope_levels = std.options.log_scope_levels;
pub const builtin = @import("builtin");

pub const pebble = @import("pebble");

pub const Level = enum(c_int) {
    err = pebble.APP_LOG_LEVEL_ERROR,
    warn = pebble.APP_LOG_LEVEL_WARNING,
    info = pebble.APP_LOG_LEVEL_INFO,
    debug = pebble.APP_LOG_LEVEL_DEBUG,
    debug_verbose = pebble.APP_LOG_LEVEL_DEBUG_VERBOSE,

    pub fn asText(comptime self: Level) []const u8 {
        return switch (self) {
            .err => "error",
            .warn => "warning",
            .info => "info",
            .debug => "debug",
            .debug_verbose => "debug verbose",
        };
    }
};

/// The default log level is based on build mode.
pub const default_level: Level = switch (builtin.mode) {
    .Debug => .debug,
    .ReleaseSafe, .ReleaseFast, .ReleaseSmall => .info,
};

pub const ScopeLevel = struct {
    scope: @Type(.enum_literal),
    level: Level,
};

/// Use like `log(@src(), "fmt", .{});
pub fn defaultLog(comptime src: std.builtin.SourceLocation, comptime message_level: Level, comptime _: @Type(.enum_literal), comptime format: []const u8, args: anytype) void {
    // pebbleOS buffer is 128 bytes, so maybe i can increase this.
    var buffer: [64]u8 = undefined;
    const res = std.fmt.bufPrintZ(&buffer, format, args) catch return;
    pebble.app_log(@intFromEnum(message_level), src.fn_name, src.line, res);
}

/// Returns a scoped logging namespace that logs all messages using the scope
/// provided here.
pub fn scoped(comptime scope: @Type(.enum_literal)) type {
    return struct {
        /// Log an error message. This log level is intended to be used
        /// when something has gone wrong. This might be recoverable or might
        /// be followed by the program exiting.
        pub fn err(
            comptime src: std.builtin.SourceLocation,
            comptime format: []const u8,
            args: anytype,
        ) void {
            @branchHint(.cold);
            defaultLog(src, .err, scope, format, args);
        }

        /// Log a warning message. This log level is intended to be used if
        /// it is uncertain whether something has gone wrong or not, but the
        /// circumstances would be worth investigating.
        pub fn warn(
            comptime src: std.builtin.SourceLocation,
            comptime format: []const u8,
            args: anytype,
        ) void {
            defaultLog(src, .warn, scope, format, args);
        }

        /// Log an info message. This log level is intended to be used for
        /// general messages about the state of the program.
        pub fn info(
            comptime src: std.builtin.SourceLocation,
            comptime format: []const u8,
            args: anytype,
        ) void {
            defaultLog(src, .info, scope, format, args);
        }

        /// Log a debug message. This log level is intended to be used for
        /// messages which are only useful for debugging.
        pub fn debug(
            comptime src: std.builtin.SourceLocation,
            comptime format: []const u8,
            args: anytype,
        ) void {
            defaultLog(src, .debug, scope, format, args);
        }
    };
}

pub const default_log_scope = .default;

/// The default scoped logging namespace.
pub const default = scoped(default_log_scope);

/// Log an error message using the default scope. This log level is intended to
/// be used when something has gone wrong. This might be recoverable or might
/// be followed by the program exiting.
pub const err = default.err;

/// Log a warning message using the default scope. This log level is intended
/// to be used if it is uncertain whether something has gone wrong or not, but
/// the circumstances would be worth investigating.
pub const warn = default.warn;

/// Log an info message using the default scope. This log level is intended to
/// be used for general messages about the state of the program.
pub const info = default.info;

/// Log a debug message using the default scope. This log level is intended to
/// be used for messages which are only useful for debugging.
pub const debug = default.debug;
