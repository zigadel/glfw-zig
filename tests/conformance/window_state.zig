const std = @import("std");
const builtin = @import("builtin");
const testing = std.testing;
const glfw = @import("glfw");

fn withWindow(body: anytype) !void {
    try glfw.init();
    defer glfw.terminate();

    const win = try glfw.createWindow(320, 240, "glfw-zig state", null, null);
    defer glfw.destroyWindow(win);

    // body is expected to be: fn (*glfw.Window) !void
    try body(win);
}

fn pumpEvents(iterations: usize) void {
    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        glfw.pollEvents();
    }
}

test "window state: iconify / restore / maximize basic semantics" {
    try withWindow(struct {
        fn run(win: *glfw.Window) !void {
            // Initial visibility:
            // - On Windows we assert the flag.
            // - On other platforms we only require that the call path works.
            if (builtin.os.tag == .windows) {
                try testing.expect(glfw.isVisible(win));
            } else {
                _ = glfw.isVisible(win);
            }

            // Iconify (minimize).
            glfw.iconifyWindow(win);
            pumpEvents(4);

            if (builtin.os.tag == .windows) {
                // Win32 should reliably report iconified=true here.
                try testing.expect(glfw.isIconified(win));
            } else {
                // Cocoa / some WMs may ignore or delay this; just ensure it’s callable.
                _ = glfw.isIconified(win);
            }

            // Restore.
            glfw.restoreWindow(win);
            pumpEvents(4);

            if (builtin.os.tag == .windows) {
                try testing.expect(!glfw.isIconified(win));
            } else {
                _ = glfw.isIconified(win);
            }

            // Maximize – semantics are WM-dependent; we just ensure call path works.
            glfw.maximizeWindow(win);
            pumpEvents(4);
            _ = glfw.isMaximized(win);

            // Restore again.
            glfw.restoreWindow(win);
            pumpEvents(4);
            _ = glfw.isMaximized(win);
        }
    }.run);
}

test "window state: show / hide / focus / attention do not crash" {
    try withWindow(struct {
        fn run(win: *glfw.Window) !void {
            // Hide/show cycle.
            glfw.hideWindow(win);
            pumpEvents(2);

            glfw.showWindow(win);
            pumpEvents(2);

            // On Win32 this is usually true; elsewhere we don’t assert.
            if (builtin.os.tag == .windows) {
                try testing.expect(glfw.isVisible(win));
            } else {
                _ = glfw.isVisible(win);
            }

            // Focus & attention should not crash.
            glfw.focusWindow(win);
            pumpEvents(2);

            glfw.requestWindowAttention(win);
            pumpEvents(2);

            // These are environment / user-interaction dependent; just ensure they compile.
            _ = glfw.isFocused(win);
            _ = glfw.isHovered(win);
        }
    }.run);
}
