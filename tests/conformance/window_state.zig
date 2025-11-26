const std = @import("std");
const testing = std.testing;
const glfw = @import("glfw");

fn withWindow(body: fn (*glfw.Window) anyerror!void) !void {
    // Best-effort init; skip test if GLFW cannot initialize.
    _ = glfw.init() catch return;
    defer glfw.terminate();

    const win = try glfw.createWindow(320, 240, "glfw-zig state\x00", null, null);
    defer glfw.destroyWindow(win);

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
            // Initial visibility is expected to be true on typical platforms.
            try testing.expect(glfw.isVisible(win));

            // Iconify
            glfw.iconifyWindow(win);
            pumpEvents(3);
            try testing.expect(glfw.isIconified(win));

            // Restore
            glfw.restoreWindow(win);
            pumpEvents(3);
            try testing.expect(!glfw.isIconified(win));

            // Maximize
            glfw.maximizeWindow(win);
            pumpEvents(3);
            try testing.expect(glfw.isMaximized(win));

            // Restore again
            glfw.restoreWindow(win);
            pumpEvents(3);
            try testing.expect(!glfw.isMaximized(win));
        }
    }.run);
}

test "window state: show / hide / focus / attention do not crash" {
    try withWindow(struct {
        fn run(win: *glfw.Window) !void {
            // Hide/show cycle
            glfw.hideWindow(win);
            pumpEvents(2);
            // Some platforms may still report visible = true here, so we don't assert.

            glfw.showWindow(win);
            pumpEvents(2);
            try testing.expect(glfw.isVisible(win));

            // Focus & attention should at least not crash.
            glfw.focusWindow(win);
            pumpEvents(2);

            glfw.requestWindowAttention(win);
            pumpEvents(2);

            // Focus / hover state may depend on user interaction; we only
            // assert that the helpers compile and can be called.
            _ = glfw.isFocused(win);
            _ = glfw.isHovered(win);
        }
    }.run);
}
