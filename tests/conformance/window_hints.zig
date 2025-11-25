const std = @import("std");
const glfw = @import("glfw");

test "window hints and attributes conformance" {
    // Best-effort: if init fails (e.g. headless CI), treat test as skipped.
    _ = glfw.init() catch return;
    defer glfw.terminate();

    // Ensure we can call the hint helpers without crashing.
    glfw.defaultWindowHints();

    // Toggle some common hints; these are cross-platform and should be valid
    // even if the window ultimately fails to be created.
    glfw.windowHint(glfw.c.GLFW_RESIZABLE, glfw.c.GLFW_FALSE);
    glfw.windowHint(glfw.c.GLFW_VISIBLE, glfw.c.GLFW_FALSE);
    glfw.windowHint(glfw.c.GLFW_DECORATED, glfw.c.GLFW_TRUE);

    const title = "hint conformance\x00";
    const window = glfw.createWindow(640, 480, title, null, null) catch return;
    defer glfw.destroyWindow(window);

    // For boolean attributes, GLFW specifies that the result is either
    // GLFW_TRUE or GLFW_FALSE. That is a strong enough invariant to assert.
    const resizable = glfw.getWindowAttrib(window, glfw.c.GLFW_RESIZABLE);
    const visible = glfw.getWindowAttrib(window, glfw.c.GLFW_VISIBLE);
    const decorated = glfw.getWindowAttrib(window, glfw.c.GLFW_DECORATED);

    try std.testing.expect(resizable == glfw.c.GLFW_TRUE or resizable == glfw.c.GLFW_FALSE);
    try std.testing.expect(visible == glfw.c.GLFW_TRUE or visible == glfw.c.GLFW_FALSE);
    try std.testing.expect(decorated == glfw.c.GLFW_TRUE or decorated == glfw.c.GLFW_FALSE);

    // If the backend respects the hints (which it should on mainstream
    // platforms), then the attributes should match what we asked for.
    // We assert this directly to keep the test meaningful.
    try std.testing.expectEqual(glfw.c.GLFW_FALSE, resizable);
    try std.testing.expectEqual(glfw.c.GLFW_FALSE, visible);
    try std.testing.expectEqual(glfw.c.GLFW_TRUE, decorated);

    // Exercise the mutating attribute helper as well.
    glfw.setWindowAttrib(window, glfw.c.GLFW_DECORATED, glfw.c.GLFW_FALSE);
    const decorated2 = glfw.getWindowAttrib(window, glfw.c.GLFW_DECORATED);
    try std.testing.expect(decorated2 == glfw.c.GLFW_TRUE or decorated2 == glfw.c.GLFW_FALSE);
}
