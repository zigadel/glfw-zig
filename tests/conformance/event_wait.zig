const std = @import("std");
const glfw = @import("glfw");

test "conformance: waitEventsTimeout + postEmptyEvent" {
    // API surface must exist.
    _ = glfw.waitEventsTimeout;
    _ = glfw.postEmptyEvent;

    _ = glfw.init() catch return;
    defer glfw.terminate();

    // We don't strictly need a window for this, but creating one makes sure
    // the platform backend is fully initialized.
    const title = "glfw-zig-event-wait-conformance\x00";
    const window = try glfw.createWindow(32, 32, title, null, null);
    defer glfw.destroyWindow(window);

    // Wake ourselves up and then wait with a small timeout. Main invariant:
    // call does not crash or hang forever.
    glfw.postEmptyEvent();
    glfw.waitEventsTimeout(0.05);
}
