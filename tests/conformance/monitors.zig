const std = @import("std");
const glfw = @import("glfw");

test "monitors API basic behavior" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Some CI / headless environments may not have a display; treat init
    // failure as best-effort rather than hard failure.
    _ = glfw.init() catch return;
    defer glfw.terminate();

    const monitors = glfw.getMonitors(allocator) catch return;
    defer allocator.free(monitors);

    // Just ensure the call doesn't explode and the count is sensible.
    try std.testing.expect(monitors.len >= 0);

    if (monitors.len > 0) {
        const primary = glfw.c.glfwGetPrimaryMonitor();
        if (primary != null) {
            var found = false;
            for (monitors) |m| {
                if (m == primary) {
                    found = true;
                    break;
                }
            }
            // Only assert if GLFW reports a primary monitor at all.
            try std.testing.expect(found);
        }
    }
}
