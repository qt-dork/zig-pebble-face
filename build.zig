// build.zig
const std = @import("std");

const pebble_sdk = @import("pebble_sdk");

pub fn build(b: *std.Build) !void {
    pebble_sdk.addPebbleApplication(b, .{
        .name = "watchface_example",
        .pebble = .{
            .displayName = "Watchface Example",
            .author = "Example",
            .uuid = "A7F9C152-2C37-43C6-918C-C4A06E58E4E9", // Generate with uuidgen
            .version = .{ .major = 1, .minor = 0 },
            .targetPlatforms = &.{ .emery, .gabbro }, // Pebble platforms to build for
            .watchapp = .{
                .watchface = true,
            },
        },
        // .pebble_sdk_path = "~/Library/Application Support/Pebble SDK/SDKs/current/",
        .root_source_file = b.path("src/main.zig"),
        .optimize = .ReleaseSmall,
    });
}
