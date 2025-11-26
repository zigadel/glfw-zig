const std = @import("std");
const builtin = @import("builtin");
const c_bindings = @import("c_bindings");
const core = @import("core");

const c = c_bindings.c;

pub const Window = c_bindings.Window;
pub const Cursor = c_bindings.Cursor;
pub const Monitor = c_bindings.Monitor;

pub const GlfwError = core.GlfwError;

// ─────────────────────────────────────────────────────────────────────────────
// Window API
// ─────────────────────────────────────────────────────────────────────────────

pub fn createWindow(
    width: i32,
    height: i32,
    title: [*:0]const u8,
    monitor: ?*Monitor,
    share: ?*Window,
) GlfwError!*Window {
    const w = c.glfwCreateWindow(
        @intCast(width),
        @intCast(height),
        title,
        monitor,
        share,
    );
    if (w == null) return GlfwError.WindowCreationFailed;
    return w.?;
}

/// Destroy a previously created window.
pub fn destroyWindow(window: *Window) void {
    c.glfwDestroyWindow(window);
}

/// Returns whether the window should close.
pub fn windowShouldClose(window: *Window) bool {
    return c.glfwWindowShouldClose(window) == c.GLFW_TRUE;
}

/// Set the "should close" flag on a window.
pub fn setWindowShouldClose(window: *Window, value: bool) void {
    c.glfwSetWindowShouldClose(window, if (value) c.GLFW_TRUE else c.GLFW_FALSE);
}

/// Get key state for a given key. Returns a GLFW action (`Press`, `Release`, etc.).
pub fn getKey(window: *Window, key: c_int) c_int {
    return c.glfwGetKey(window, key);
}

/// Pump the event queue.
pub fn pollEvents() void {
    c.glfwPollEvents();
}

/// Waits until at least one event has been placed in the event queue,
/// or until the given timeout elapses.
pub fn waitEventsTimeout(timeout_seconds: f64) void {
    c.glfwWaitEventsTimeout(timeout_seconds);
}

/// Posts an empty event to wake up a thread blocked in waitEvents*.
pub fn postEmptyEvent() void {
    c.glfwPostEmptyEvent();
}

/// V-sync helper: set swap interval.
pub fn swapInterval(interval: c_int) void {
    c.glfwSwapInterval(interval);
}

// ─────────────────────────────────────────────────────────────────────────────
// Window hints & attributes
// ─────────────────────────────────────────────────────────────────────────────

/// Reset all window hints to GLFW defaults.
pub fn defaultWindowHints() void {
    c.glfwDefaultWindowHints();
}

/// Set an integer window hint.
pub fn windowHint(hint: c_int, value: c_int) void {
    c.glfwWindowHint(hint, value);
}

/// Set a string window hint.
pub fn windowHintString(hint: c_int, value: [*:0]const u8) void {
    c.glfwWindowHintString(hint, value);
}

/// Get an integer window attribute.
pub fn getWindowAttrib(window: *Window, attrib: c_int) c_int {
    return c.glfwGetWindowAttrib(window, attrib);
}

/// Set a mutable window attribute.
pub fn setWindowAttrib(window: *Window, attrib: c_int, value: c_int) void {
    c.glfwSetWindowAttrib(window, attrib, value);
}

// ─────────────────────────────────────────────────────────────────────────────
// Cursor, input modes, clipboard
// ─────────────────────────────────────────────────────────────────────────────

/// Get the current cursor position in screen coordinates.
pub fn getCursorPos(window: *Window) struct { x: f64, y: f64 } {
    var x: f64 = 0;
    var y: f64 = 0;
    c.glfwGetCursorPos(window, &x, &y);
    return .{ .x = x, .y = y };
}

/// Set the current cursor position in screen coordinates.
pub fn setCursorPos(window: *Window, x: f64, y: f64) void {
    c.glfwSetCursorPos(window, x, y);
}

/// Set an input mode option for the specified window.
pub fn setInputMode(window: *Window, mode: c_int, value: c_int) void {
    c.glfwSetInputMode(window, mode, value);
}

/// Get the value of an input mode option for the specified window.
pub fn getInputMode(window: *Window, mode: c_int) c_int {
    return c.glfwGetInputMode(window, mode);
}

/// Set the cursor object for a window.
///
/// Passing `null` reverts to the default cursor.
pub fn setCursor(window: *Window, cursor: ?*Cursor) void {
    c.glfwSetCursor(window, cursor);
}

/// Create a standard cursor with the given shape (e.g. c.GLFW_ARROW_CURSOR).
pub fn createStandardCursor(shape: c_int) ?*Cursor {
    return c.glfwCreateStandardCursor(shape);
}

/// Destroy a cursor created with `createStandardCursor` or any custom cursor.
pub fn destroyCursor(cursor: *Cursor) void {
    c.glfwDestroyCursor(cursor);
}

/// Set the system clipboard to the specified UTF-8 string.
pub fn setClipboardString(window: *Window, string: [:0]const u8) void {
    c.glfwSetClipboardString(window, string.ptr);
}

/// Get the current contents of the system clipboard as UTF-8, if available.
pub fn getClipboardString(window: *Window) ?[:0]const u8 {
    const ptr = c.glfwGetClipboardString(window);
    if (ptr == null) return null;
    return std.mem.span(ptr);
}

/// Return the native Win32 HWND for a GLFW window (Windows only).
///
/// On non-Windows platforms this function returns null.
pub fn getWin32Window(window: *Window) ?*anyopaque {
    if (builtin.os.tag != .windows) {
        return null;
    }

    return glfwGetWin32Window(window);
}

// Redeclare symbol instead of pulling in glfw3native.h + Win32 headers.
extern fn glfwGetWin32Window(window: ?*c.GLFWwindow) ?*anyopaque;

// ─────────────────────────────────────────────────────────────────────────────
// Inline tests (window-level)
// ─────────────────────────────────────────────────────────────────────────────

test "createWindow / destroyWindow best-effort" {
    _ = core.init() catch return;
    defer core.terminate();

    const title = "glfw-zig-test\x00";
    const window = createWindow(64, 64, title, null, null) catch return;
    destroyWindow(window);
}

test "window hints + attributes best-effort" {
    _ = core.init() catch return;
    defer core.terminate();

    defaultWindowHints();
    windowHint(c.GLFW_RESIZABLE, c.GLFW_FALSE);

    const title = "hint test\x00";
    const window = createWindow(640, 480, title, null, null) catch return;
    defer destroyWindow(window);

    const resizable = getWindowAttrib(window, c.GLFW_RESIZABLE);
    if (resizable == c.GLFW_TRUE or resizable == c.GLFW_FALSE) {
        try std.testing.expectEqual(c.GLFW_FALSE, resizable);

        setWindowAttrib(window, c.GLFW_RESIZABLE, c.GLFW_TRUE);
        const resizable2 = getWindowAttrib(window, c.GLFW_RESIZABLE);
        try std.testing.expectEqual(c.GLFW_TRUE, resizable2);
    }
}

test "input mode: sticky keys round-trip best-effort" {
    _ = core.init() catch return;
    defer core.terminate();

    const title = "glfw-zig-input-mode-test\x00";
    const window = createWindow(64, 64, title, null, null) catch return;
    defer destroyWindow(window);

    const prev = getInputMode(window, c.GLFW_STICKY_KEYS);
    setInputMode(window, c.GLFW_STICKY_KEYS, c.GLFW_TRUE);
    const now = getInputMode(window, c.GLFW_STICKY_KEYS);

    try std.testing.expect(now == c.GLFW_TRUE);

    setInputMode(window, c.GLFW_STICKY_KEYS, prev);
}

test "cursor + standard cursor best-effort" {
    _ = core.init() catch return;
    defer core.terminate();

    const title = "glfw-zig-cursor-test\x00";
    const window = createWindow(64, 64, title, null, null) catch return;
    defer destroyWindow(window);

    const cursor = createStandardCursor(c.GLFW_ARROW_CURSOR) orelse return;
    defer destroyCursor(cursor);

    setCursor(window, cursor);
    setCursor(window, null);
}

test "clipboard round-trip best-effort" {
    _ = core.init() catch return;
    defer core.terminate();

    const title = "glfw-zig-clipboard-test\x00";
    const window = createWindow(64, 64, title, null, null) catch return;
    defer destroyWindow(window);

    const msg: [:0]const u8 = "glfw-zig clipboard test";

    setClipboardString(window, msg);

    if (getClipboardString(window)) |got| {
        try std.testing.expect(std.mem.startsWith(u8, got, msg[0 .. msg.len - 1]));
    }
}

test "native Win32 window handle best-effort" {
    if (builtin.os.tag != .windows) return;

    _ = core.init() catch return;
    defer core.terminate();

    const title = "glfw-zig-win32-handle-test\x00";
    const window = createWindow(64, 64, title, null, null) catch return;
    defer destroyWindow(window);

    const hwnd = getWin32Window(window) orelse return;
    try std.testing.expect(@intFromPtr(hwnd) != 0);
}

test "waitEventsTimeout + postEmptyEvent basic smoke" {
    _ = core.init() catch return;
    defer core.terminate();

    const title = "glfw-zig-wait-test\x00";
    const window = createWindow(32, 32, title, null, null) catch return;
    defer destroyWindow(window);

    postEmptyEvent();
    waitEventsTimeout(0.05);
}
