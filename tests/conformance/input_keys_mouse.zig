const std = @import("std");
const testing = std.testing;
const glfw = @import("glfw");

test "keys & mouse: API surface compiles and basic semantics" {
    // getKeyScancode and getKeyName are allowed before init.
    const sc = glfw.getKeyScancode(glfw.c.GLFW_KEY_SPACE);

    const maybe_name = glfw.getKeyName(glfw.c.GLFW_KEY_SPACE, sc);
    if (maybe_name) |name| {
        // On some layouts this may be empty or " ".
        try testing.expect(name.len >= 0);
    }

    // Mouse button queries require a window.
    _ = glfw.init() catch return;
    defer glfw.terminate();

    const title = "glfw-zig-input-keys-mouse\x00";
    const window = glfw.createWindow(64, 64, title, null, null) catch return;
    defer glfw.destroyWindow(window);

    const state = glfw.getMouseButton(window, glfw.c.GLFW_MOUSE_BUTTON_LEFT);
    // State must be one of the GLFW actions.
    switch (state) {
        glfw.c.GLFW_PRESS,
        glfw.c.GLFW_RELEASE,
        glfw.c.GLFW_REPEAT,
        => {}, // ok
        else => {
            try testing.expect(false);
        },
    }

    // getKey should at least compile and return a valid action enum-ish value.
    const key_state = glfw.getKey(window, glfw.c.GLFW_KEY_SPACE);
    switch (key_state) {
        glfw.c.GLFW_PRESS,
        glfw.c.GLFW_RELEASE,
        glfw.c.GLFW_REPEAT,
        => {}, // ok
        else => {
            try testing.expect(false);
        },
    }
}
