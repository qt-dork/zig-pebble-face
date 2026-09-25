const std = @import("std");

const pebble_sdk = @import("pebble_sdk");

pub fn build(b: *std.Build) !void {
    pebble_sdk.addPebbleApplication(b, .{
        .name = "royale",
        .pebble = .{
            .displayName = "Royale",
            .author = "Evie Finch",
            .uuid = "f066c042-84e6-4a3e-aaa6-28c517aafcd1",
            .version = .{ .major = 1, .minor = 2 },
            .targetPlatforms = &.{.emery},
            .watchapp = .{
                .watchface = true,
            },
            .resources = .{ .media = &.{
                .{ .bitmap = .{ .name = "IMAGE_BT", .file = "bt-icon.png" } },
                .{ .bitmap = .{ .name = "IMAGE_BG", .file = "images/bg.png" } },
                .{ .bitmap = .{ .name = "SPRITE_PM", .file = "images/pm.png" } },
                .{ .bitmap = .{ .name = "SPRITE_PM_FADED", .file = "images/pm-faded.png" } },
                .{ .bitmap = .{ .name = "TYPE_S", .file = "images/type-small.png" } },
                .{ .bitmap = .{ .name = "TYPE_M", .file = "images/type-med.png" } },
                .{ .bitmap = .{ .name = "TYPE_L", .file = "images/type-lg.png" } },
                .{ .bitmap = .{ .name = "TYPE_S_FADED", .file = "images/type-small-faded.png" } },
                .{ .bitmap = .{ .name = "TYPE_M_FADED", .file = "images/type-med-faded.png" } },
                .{ .bitmap = .{ .name = "TYPE_L_FADED", .file = "images/type-lg-faded.png" } },
                .{ .bitmap = .{ .name = "SPRITE_BAT", .file = "images/bat.png" } },
                .{ .bitmap = .{ .name = "SPRITE_BAT_FADED", .file = "images/bat-faded.png" } },
                .{ .bitmap = .{ .name = "SPRITE_MAP", .file = "images/map.png" } },
                .{ .bitmap = .{ .name = "SPRITE_DASH", .file = "images/dash.png" } },
                .{ .font = .{ .name = "FONT_DSEG_14", .file = "fonts/dseg14.ttf" } },
                .{ .bitmap = .{ .name = "MENU_ICON", .file = "icon.png", .menuIcon = true } },
            } },
            .messageKeys = &.{ .{ .key = "SettingsEnableSeconds", .value = 10000 }, .{ .key = "SettingsTimeZone", .value = 10001 }, .{ .key = "SettingsTimeZoneOffsetMinutes", .value = 10002 }, .{ .key = "SettingsDateFormat", .value = 10003 } },
            .capabilities = &.{.configurable},
        },
        .root_source_file = b.path("src/main.zig"),
        .pebblekit_js_file = b.path("js/bundle.js"),
        .optimize = .ReleaseFast,
    });
}
