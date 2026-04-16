// build.zig
const std = @import("std");

const pebble_sdk = @import("pebble_sdk");

pub fn build(b: *std.Build) !void {
    pebble_sdk.addPebbleApplication(b, .{
        .name = "royale",
        .pebble = .{
            .enableMultiJS = true,
            .capabilities = &.{.configurable},
            .messageKeys = &.{ .{ .key = "SettingsEnableSeconds", .value = 10000 }, .{ .key = "SettingsTimeZone", .value = 10001 } },
            .displayName = "Royale",
            .author = "Evie Finch",
            .uuid = "f066c042-84e6-4a3e-aaa6-28c517aafcd1", // Generate with uuidgen
            .version = .{ .major = 1, .minor = 1 },
            .targetPlatforms = &.{.emery}, // Pebble platforms to build for
            .watchapp = .{
                .watchface = true,
            },

            .resources = .{ .media = &.{ .{ .bitmap = .{ .name = "IMAGE_BT", .file = "bt-icon.png" } }, .{ .bitmap = .{ .name = "IMAGE_BG", .file = "images/bg.png" } }, .{ .bitmap = .{ .name = "SPRITE_PM", .file = "images/pm.png" } }, .{ .bitmap = .{ .name = "TYPE_S", .file = "images/type-small.png" } }, .{ .bitmap = .{ .name = "TYPE_M", .file = "images/type-med.png" } }, .{ .bitmap = .{ .name = "TYPE_L", .file = "images/type-lg.png" } }, .{ .bitmap = .{ .name = "SPRITE_BAT", .file = "images/bat.png" } }, .{ .bitmap = .{ .name = "SPRITE_MAP", .file = "images/map.png" } }, .{ .font = .{ .name = "FONT_DSEG_14", .file = "fonts/dseg14.ttf" } }, .{ .bitmap = .{ .name = "MENU_ICON", .file = "icon.png", .menuIcon = true } } } },
        },
        // .pebble_sdk_path = "~/Library/Application Support/Pebble SDK/SDKs/current/",
        .root_source_file = b.path("src/zig/main.zig"),
        .optimize = .ReleaseSafe,
    });
}
