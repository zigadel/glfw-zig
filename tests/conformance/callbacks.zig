const std = @import("std");
const testing = std.testing;
const glfw = @import("glfw");

const c = glfw.c;

test "callbacks: error callback can be set and cleared" {
    const cb: glfw.ErrorCallback = struct {
        pub fn handler(code: c_int, desc: [*c]const u8) callconv(.c) void {
            _ = code;
            _ = desc;
        }
    }.handler;

    const prev = glfw.setErrorCallback(cb);
    _ = prev;

    // Clear again; should be safe pre- or post-init.
    _ = glfw.setErrorCallback(null);

    try testing.expect(true);
}

test "callbacks: window & input callbacks can be installed and cleared" {
    try glfw.init();
    defer glfw.terminate();

    const win = try glfw.createWindow(320, 240, "glfw-zig callbacks", null, null);
    defer glfw.destroyWindow(win);

    const Handlers = struct {
        pub fn windowPos(w: ?*c.GLFWwindow, x: c_int, y: c_int) callconv(.c) void {
            _ = w;
            _ = x;
            _ = y;
        }
        pub fn windowSize(w: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.c) void {
            _ = w;
            _ = width;
            _ = height;
        }
        pub fn windowClose(w: ?*c.GLFWwindow) callconv(.c) void {
            _ = w;
        }
        pub fn windowRefresh(w: ?*c.GLFWwindow) callconv(.c) void {
            _ = w;
        }
        pub fn windowFocus(w: ?*c.GLFWwindow, focused: c_int) callconv(.c) void {
            _ = w;
            _ = focused;
        }
        pub fn windowIconify(w: ?*c.GLFWwindow, iconified: c_int) callconv(.c) void {
            _ = w;
            _ = iconified;
        }
        pub fn windowMaximize(w: ?*c.GLFWwindow, maximized: c_int) callconv(.c) void {
            _ = w;
            _ = maximized;
        }
        pub fn framebufferSize(w: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.c) void {
            _ = w;
            _ = width;
            _ = height;
        }
        pub fn windowContentScale(w: ?*c.GLFWwindow, xs: f32, ys: f32) callconv(.c) void {
            _ = w;
            _ = xs;
            _ = ys;
        }

        pub fn mouseButton(
            w: ?*c.GLFWwindow,
            button: c_int,
            action: c_int,
            mods: c_int,
        ) callconv(.c) void {
            _ = w;
            _ = button;
            _ = action;
            _ = mods;
        }

        pub fn cursorPos(w: ?*c.GLFWwindow, xpos: f64, ypos: f64) callconv(.c) void {
            _ = w;
            _ = xpos;
            _ = ypos;
        }

        pub fn cursorEnter(w: ?*c.GLFWwindow, entered: c_int) callconv(.c) void {
            _ = w;
            _ = entered;
        }

        pub fn scroll(w: ?*c.GLFWwindow, xoff: f64, yoff: f64) callconv(.c) void {
            _ = w;
            _ = xoff;
            _ = yoff;
        }

        pub fn onKey(
            w: ?*c.GLFWwindow,
            key_code: c_int,
            scancode: c_int,
            action: c_int,
            mods: c_int,
        ) callconv(.c) void {
            _ = w;
            _ = key_code;
            _ = scancode;
            _ = action;
            _ = mods;
        }

        pub fn ch(w: ?*c.GLFWwindow, codepoint: c_uint) callconv(.c) void {
            _ = w;
            _ = codepoint;
        }

        pub fn charMods(
            w: ?*c.GLFWwindow,
            codepoint: c_uint,
            mods: c_int,
        ) callconv(.c) void {
            _ = w;
            _ = codepoint;
            _ = mods;
        }
    };

    // Window callbacks
    _ = glfw.setWindowPosCallback(win, Handlers.windowPos);
    _ = glfw.setWindowPosCallback(win, null);

    _ = glfw.setWindowSizeCallback(win, Handlers.windowSize);
    _ = glfw.setWindowSizeCallback(win, null);

    _ = glfw.setWindowCloseCallback(win, Handlers.windowClose);
    _ = glfw.setWindowCloseCallback(win, null);

    _ = glfw.setWindowRefreshCallback(win, Handlers.windowRefresh);
    _ = glfw.setWindowRefreshCallback(win, null);

    _ = glfw.setWindowFocusCallback(win, Handlers.windowFocus);
    _ = glfw.setWindowFocusCallback(win, null);

    _ = glfw.setWindowIconifyCallback(win, Handlers.windowIconify);
    _ = glfw.setWindowIconifyCallback(win, null);

    _ = glfw.setWindowMaximizeCallback(win, Handlers.windowMaximize);
    _ = glfw.setWindowMaximizeCallback(win, null);

    _ = glfw.setFramebufferSizeCallback(win, Handlers.framebufferSize);
    _ = glfw.setFramebufferSizeCallback(win, null);

    _ = glfw.setWindowContentScaleCallback(win, Handlers.windowContentScale);
    _ = glfw.setWindowContentScaleCallback(win, null);

    // Input callbacks
    _ = glfw.setMouseButtonCallback(win, Handlers.mouseButton);
    _ = glfw.setMouseButtonCallback(win, null);

    _ = glfw.setCursorPosCallback(win, Handlers.cursorPos);
    _ = glfw.setCursorPosCallback(win, null);

    _ = glfw.setCursorEnterCallback(win, Handlers.cursorEnter);
    _ = glfw.setCursorEnterCallback(win, null);

    _ = glfw.setScrollCallback(win, Handlers.scroll);
    _ = glfw.setScrollCallback(win, null);

    _ = glfw.setKeyCallback(win, Handlers.onKey);
    _ = glfw.setKeyCallback(win, null);

    _ = glfw.setCharCallback(win, Handlers.ch);
    _ = glfw.setCharCallback(win, null);

    _ = glfw.setCharModsCallback(win, Handlers.charMods);
    _ = glfw.setCharModsCallback(win, null);

    // Drop callback: just ensure we can clear it.
    _ = glfw.setDropCallback(win, null);

    try testing.expect(true);
}
