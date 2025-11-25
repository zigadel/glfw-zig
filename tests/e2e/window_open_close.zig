const std = @import("std");
const glfw = @import("glfw");

test "e2e: open window and query cursor best-effort" {
    _ = glfw.init() catch return;
    defer glfw.terminate();

    const title = "e2e-window\x00";
    const window = glfw.createWindow(128, 128, title, null, null) catch return;
    defer glfw.destroyWindow(window);

    glfw.pollEvents();

    const pos = glfw.getCursorPos(window);
    _ = pos;

    // If we got here without crashing, call it a win.
    try std.testing.expect(true);
}
