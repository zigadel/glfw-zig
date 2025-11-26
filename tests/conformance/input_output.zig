const std = @import("std");
const testing = std.testing;
const glfw = @import("glfw");

test "input extras: initHint + raw mouse motion + key/mouse helpers basic semantics" {
    // initHint + rawMouseMotionSupported must be safe pre-init.
    glfw.initHint(glfw.c.GLFW_JOYSTICK_HAT_BUTTONS, glfw.c.GLFW_TRUE);
    _ = glfw.rawMouseMotionSupported();

    try glfw.init();
    defer glfw.terminate();

    const win = try glfw.createWindow(320, 240, "glfw-zig input extras", null, null);
    defer glfw.destroyWindow(win);

    // Mouse button query should not crash; result is env-dependent.
    const mb_state = glfw.getMouseButton(win, glfw.c.GLFW_MOUSE_BUTTON_LEFT);
    _ = mb_state;

    // Key scancode + name: name may be null depending on layout.
    const key = glfw.c.GLFW_KEY_A;
    const scancode = glfw.getKeyScancode(key);

    if (glfw.getKeyName(key, scancode)) |name| {
        // If a name exists, it should be non-empty.
        try testing.expect(name.len > 0);
    }

    // Calling rawMouseMotionSupported after init should still be fine.
    _ = glfw.rawMouseMotionSupported();
}
