const std = @import("std");
const testing = std.testing;
const glfw = @import("glfw");

fn withWindow(body: fn (*glfw.Window) anyerror!void) !void {
    try glfw.init();
    defer glfw.terminate();

    const win = try glfw.createWindow(320, 240, "glfw-zig geometry\x00", null, null);
    defer glfw.destroyWindow(win);

    try body(win);
}

test "window geometry: size and position round-trip" {
    try withWindow(struct {
        fn run(win: *glfw.Window) !void {
            // Size round-trip
            glfw.setWindowSize(win, 400, 300);
            const sz = glfw.getWindowSize(win);
            try testing.expectEqual(@as(i32, 400), sz.width);
            try testing.expectEqual(@as(i32, 300), sz.height);

            // Position round-trip.
            glfw.setWindowPos(win, 50, 80);
            const pos = glfw.getWindowPos(win);
            try testing.expectEqual(@as(i32, 50), pos.x);
            try testing.expectEqual(@as(i32, 80), pos.y);

            // Framebuffer size should be positive.
            const fb = glfw.getFramebufferSize(win);
            try testing.expect(fb.width > 0);
            try testing.expect(fb.height > 0);

            // Frame size should be non-negative; usually > 0 for decorated windows.
            const frame = glfw.getWindowFrameSize(win);
            try testing.expect(frame.left >= 0);
            try testing.expect(frame.top >= 0);
            try testing.expect(frame.right >= 0);
            try testing.expect(frame.bottom >= 0);

            // Content scale should be positive.
            const scale = glfw.getWindowContentScale(win);
            try testing.expect(scale.x > 0);
            try testing.expect(scale.y > 0);
        }
    }.run);
}

test "window geometry: size limits and aspect ratio do not crash" {
    try withWindow(struct {
        fn run(win: *glfw.Window) !void {
            // Set concrete limits.
            glfw.setWindowSizeLimits(win, 200, 150, 800, 600);

            // Clear limits using GLFW_DONT_CARE for all dimensions.
            glfw.setWindowSizeLimits(
                win,
                glfw.c.GLFW_DONT_CARE,
                glfw.c.GLFW_DONT_CARE,
                glfw.c.GLFW_DONT_CARE,
                glfw.c.GLFW_DONT_CARE,
            );

            // Aspect ratio: fixed, then "don't care".
            glfw.setWindowAspectRatio(win, 16, 9);
            glfw.setWindowAspectRatio(
                win,
                glfw.c.GLFW_DONT_CARE,
                glfw.c.GLFW_DONT_CARE,
            );

            // If we got here, we’re good: this test is purely “no crash”.
        }
    }.run);
}
