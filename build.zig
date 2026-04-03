// build.zig
const std = @import("std");

const pebble_sdk = @import("pebble_sdk");

pub fn build(b: *std.Build) !void {
    pebble_sdk.addPebbleApplication(b, .{
        .name = "zig_watchface",
        .pebble = .{
            .displayName = "Zig Watchface",
            .author = "Evie Finch",
            .uuid = "F066C042-84E6-4A3E-AAA6-28C517AAFCD1", // Generate with uuidgen
            .version = .{ .major = 1, .minor = 0 },
            .targetPlatforms = &.{ .basalt, .emery, .gabbro }, // Pebble platforms to build for
            .watchapp = .{
                .watchface = true,
            },
            .resources = .{ .media = &.{
                .{ .font = .{
                    .name = "FONT_SLAPFACE_56",
                    .file = "slapface.ttf",
                } },
                .{ .font = .{
                    .name = "FONT_SLAPFACE_24",
                    .file = "slapface.ttf",
                } },
                .{ .bitmap = .{ .name = "IMAGE_BT", .file = "bt-icon.png" } },
            } },
        },
        // .pebble_sdk_path = "~/Library/Application Support/Pebble SDK/SDKs/current/",
        .root_source_file = b.path("src/main.zig"),
        .optimize = .ReleaseSmall,
    });
}
