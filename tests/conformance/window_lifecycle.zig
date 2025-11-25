const std = @import("std");
const glfw = @import("glfw");

test "window lifecycle best-effort" {
    _ = glfw.init() catch return;
    defer glfw.terminate();

    const title = "conformance-window\x00";
    const window = glfw.createWindow(64, 64, title, null, null) catch return;
    defer glfw.destroyWindow(window);

    try std.testing.expect(!glfw.windowShouldClose(window));
    glfw.setWindowShouldClose(window, true);
    try std.testing.expect(glfw.windowShouldClose(window));
}
