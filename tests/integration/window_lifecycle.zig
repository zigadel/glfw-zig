const std = @import("std");
const glfw = @import("glfw");

test "integration: basic window lifecycle and flags" {
    if (glfw.init()) |_| {
        // ok
    } else |_| {
        // Headless / no display: skip.
        return;
    }
    defer glfw.terminate();

    const title = "zglfw-integration\x00";
    const window = glfw.createWindow(320, 240, title, null, null) catch return;
    defer glfw.destroyWindow(window);

    // Default should be "not should close".
    try std.testing.expect(!glfw.windowShouldClose(window));

    glfw.setWindowShouldClose(window, true);
    try std.testing.expect(glfw.windowShouldClose(window));

    // One event pump just to exercise the loop.
    glfw.pollEvents();
}
