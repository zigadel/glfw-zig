const glfw = @import("glfw");

test "e2e: tiny event loop runs without crashing" {
    if (glfw.init()) |_| {
        // ok
    } else |_| {
        // Headless / no display: skip.
        return;
    }
    defer glfw.terminate();

    const title = "glfw-zig-e2e\x00";
    const window = glfw.createWindow(128, 128, title, null, null) catch return;
    defer glfw.destroyWindow(window);

    var i: usize = 0;
    while (i < 3 and !glfw.windowShouldClose(window)) : (i += 1) {
        glfw.pollEvents();
    }
}
