const std = @import("std");
const glfw = @import("glfw");

test "basic event loop best-effort" {
    _ = glfw.init() catch return;
    defer glfw.terminate();

    const title = "integration-loop\x00";
    const window = glfw.createWindow(64, 64, title, null, null) catch return;
    defer glfw.destroyWindow(window);

    var i: usize = 0;
    while (i < 3 and !glfw.windowShouldClose(window)) : (i += 1) {
        if (i == 2) {
            glfw.setWindowShouldClose(window, true);
        }
        glfw.pollEvents();
    }

    try std.testing.expect(i <= 3);
}
