// build.zig
const std = @import("std");

const pebble_sdk = @import("pebble_sdk");

pub fn build(b: *std.Build) !void {
    pebble_sdk.addPebbleApplication(b, .{
        .name = "royale",
        .pebble = .{
            .enableMultiJS = true,
            .capabilities = &.{.configurable},
            .messageKeys = &.{ .{ .key = "SettingsEnableSeconds", .value = 1 }, .{ .key = "SettingsTimeZone", .value = 2 } },
            .displayName = "Royale",
            .author = "Evie Finch",
            .uuid = "F066C042-84E6-4A3E-AAA6-28C517AAFCD1", // Generate with uuidgen
            .version = .{ .major = 1, .minor = 0 },
            .targetPlatforms = &.{.emery}, // Pebble platforms to build for
            .watchapp = .{
                .watchface = true,
            },

            .resources = .{ .media = &.{ .{ .bitmap = .{ .name = "IMAGE_BT", .file = "bt-icon.png" } }, .{ .bitmap = .{ .name = "IMAGE_BG", .file = "images/bg.png" } }, .{ .bitmap = .{ .name = "SPRITE_PM", .file = "images/pm.png" } }, .{ .bitmap = .{ .name = "TYPE_S", .file = "images/type-small.png" } }, .{ .bitmap = .{ .name = "TYPE_M", .file = "images/type-med.png" } }, .{ .bitmap = .{ .name = "TYPE_L", .file = "images/type-lg.png" } }, .{ .bitmap = .{ .name = "SPRITE_BAT", .file = "images/bat.png" } }, .{ .font = .{ .name = "FONT_DSEG_14", .file = "fonts/dseg14.ttf" } } } },
        },
        // .pebble_sdk_path = "~/Library/Application Support/Pebble SDK/SDKs/current/",
        .root_source_file = b.path("src/zig/main.zig"),
        .optimize = .ReleaseSafe,
    });
}
