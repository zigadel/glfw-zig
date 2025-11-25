const std = @import("std");
const glfw = @import("glfw");

test "conformance: input modes basic usage" {
    // API surface must exist.
    _ = glfw.setInputMode;
    _ = glfw.getInputMode;

    // Runtime best-effort.
    _ = glfw.init() catch return;
    defer glfw.terminate();

    const title = "glfw-zig-conformance-input-modes\x00";
    const window = try glfw.createWindow(32, 32, title, null, null);
    defer glfw.destroyWindow(window);

    const prev = glfw.getInputMode(window, glfw.c.GLFW_STICKY_KEYS);
    glfw.setInputMode(window, glfw.c.GLFW_STICKY_KEYS, glfw.c.GLFW_TRUE);
    const now = glfw.getInputMode(window, glfw.c.GLFW_STICKY_KEYS);

    try std.testing.expect(now == glfw.c.GLFW_TRUE);

    // Restore original value for cleanliness.
    glfw.setInputMode(window, glfw.c.GLFW_STICKY_KEYS, prev);
}
