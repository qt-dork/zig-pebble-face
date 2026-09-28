const pb = @import("pebble");

const TRIG_SCALE: f32 = 1.0 / @as(f32, @floatFromInt(pb.TRIG_MAX_ANGLE));

pub fn addPoints(a: pb.GPoint, b: pb.GPoint) pb.GPoint {
    return .{ .x = a.x + b.x, .y = a.y + b.y };
}

pub fn polarToPoint(angle: isize, distance: isize) pb.GPoint {
    const x = @as(f32, @floatFromInt(distance)) * @as(f32, @floatFromInt(pb.cos_lookup(pb.DEG_TO_TRIGANGLE(angle)))) * TRIG_SCALE;
    const y = @as(f32, @floatFromInt(distance)) * @as(f32, @floatFromInt(pb.sin_lookup(pb.DEG_TO_TRIGANGLE(angle)))) * TRIG_SCALE;
    return .{ .x = @intFromFloat(x), .y = @intFromFloat(y) };
}

pub fn polarToPointOffset(offset: pb.GPoint, angle: isize, distance: isize) pb.GPoint {
    return addPoints(offset, polarToPoint(angle, distance));
}
