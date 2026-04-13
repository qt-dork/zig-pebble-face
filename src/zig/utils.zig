const std = @import("std");

const pebble = @import("pebble");

const pog = @import("pog.zig");

const TRIG_SCALE: f32 = 1.0 / @as(f32, @floatFromInt(pebble.TRIG_MAX_ANGLE));

pub fn addPoints(a: pebble.GPoint, b: pebble.GPoint) pebble.GPoint {
    return .{ .x = a.x + b.x, .y = a.y + b.y };
}

pub fn polarToPoint(angle: isize, distance: isize) pebble.GPoint {
    pog.debug(@src(), "distance = {d}", .{distance});
    pog.debug(@src(), "angle = {d}", .{angle});
    pog.debug(@src(), "cos angle = {d}", .{pebble.cos_lookup(pebble.DEG_TO_TRIGANGLE(angle))});
    pog.debug(@src(), "trig_scale = {d}", .{@as(isize, @intFromFloat(TRIG_SCALE))});
    pog.debug(@src(), "trig_scale = {d}", .{TRIG_SCALE});
    const x = @as(f32, @floatFromInt(distance)) * @as(f32, @floatFromInt(pebble.cos_lookup(pebble.DEG_TO_TRIGANGLE(angle)))) * TRIG_SCALE;
    const y = @as(f32, @floatFromInt(distance)) * @as(f32, @floatFromInt(pebble.sin_lookup(pebble.DEG_TO_TRIGANGLE(angle)))) * TRIG_SCALE;
    pog.debug(@src(), "polarToPoint: x = {d}, y = {d}", .{ x, y });
    return .{ .x = @intFromFloat(x), .y = @intFromFloat(y) };
}

pub fn polarToPointOffset(offset: pebble.GPoint, angle: isize, distance: isize) pebble.GPoint {
    return addPoints(offset, polarToPoint(angle, distance));
}
