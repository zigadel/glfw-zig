const std = @import("std");
const builtin = @import("builtin");
const c_bindings = @import("c_bindings");
const core = @import("core");

const c = c_bindings.c;

pub const Window = c_bindings.Window;
pub const Cursor = c_bindings.Cursor;
pub const Monitor = c_bindings.Monitor;

pub const GlfwError = core.GlfwError;

/// Logical window position in screen coordinates (pixels).
pub const WindowPos = struct {
    x: i32,
    y: i32,
};

/// Logical window size in screen coordinates (pixels).
pub const WindowSize = struct {
    width: i32,
    height: i32,
};

/// Size of the framebuffer in pixels (often different from WindowSize on HiDPI).
pub const FramebufferSize = struct {
    width: i32,
    height: i32,
};

/// Frame size in screen coordinates: distance from window edges to content area.
pub const FrameSize = struct {
    left: i32,
    top: i32,
    right: i32,
    bottom: i32,
};

/// Content scale factors on X/Y axes (for HiDPI handling).
pub const ContentScale = struct {
    x: f32,
    y: f32,
};

// ─────────────────────────────────────────────────────────────────────────────
// Window creation & lifecycle
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

// ─────────────────────────────────────────────────────────────────────────────
// Event loop, key state, vsync
// ─────────────────────────────────────────────────────────────────────────────

/// Get key state for a given key. Returns a GLFW action (`Press`, `Release`, etc.).
pub fn getKey(window: *Window, key: c_int) c_int {
    return c.glfwGetKey(window, key);
}

/// Pump the event queue (non-blocking).
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

/// Swap front and back buffers for the given window (OpenGL/OSMesa).
pub fn swapBuffers(window: *Window) void {
    c.glfwSwapBuffers(window);
}

// ─────────────────────────────────────────────────────────────────────────────
// Window geometry
// ─────────────────────────────────────────────────────────────────────────────

pub fn getWindowPos(window: *Window) WindowPos {
    var x: c_int = 0;
    var y: c_int = 0;
    c.glfwGetWindowPos(window, &x, &y);
    return .{
        .x = @intCast(x),
        .y = @intCast(y),
    };
}

pub fn setWindowPos(window: *Window, x: i32, y: i32) void {
    c.glfwSetWindowPos(window, @intCast(x), @intCast(y));
}

pub fn getWindowSize(window: *Window) WindowSize {
    var w: c_int = 0;
    var h: c_int = 0;
    c.glfwGetWindowSize(window, &w, &h);
    return .{
        .width = @intCast(w),
        .height = @intCast(h),
    };
}

pub fn setWindowSize(window: *Window, width: i32, height: i32) void {
    c.glfwSetWindowSize(window, @intCast(width), @intCast(height));
}

/// Set hard size limits for the window.
///
/// Use `glfw.c.GLFW_DONT_CARE` for any dimension you don't want to constrain.
pub fn setWindowSizeLimits(
    window: *Window,
    min_width: i32,
    min_height: i32,
    max_width: i32,
    max_height: i32,
) void {
    c.glfwSetWindowSizeLimits(
        window,
        @intCast(min_width),
        @intCast(min_height),
        @intCast(max_width),
        @intCast(max_height),
    );
}

/// Constrain window to maintain a given aspect ratio (numerator / denominator).
///
/// Use `0, 0` to clear any previously set ratio (GLFW_DONT_CARE semantics).
pub fn setWindowAspectRatio(
    window: *Window,
    numer: i32,
    denom: i32,
) void {
    c.glfwSetWindowAspectRatio(window, @intCast(numer), @intCast(denom));
}

pub fn getFramebufferSize(window: *Window) FramebufferSize {
    var w: c_int = 0;
    var h: c_int = 0;
    c.glfwGetFramebufferSize(window, &w, &h);
    return .{
        .width = @intCast(w),
        .height = @intCast(h),
    };
}

pub fn getWindowFrameSize(window: *Window) FrameSize {
    var left: c_int = 0;
    var top: c_int = 0;
    var right: c_int = 0;
    var bottom: c_int = 0;

    c.glfwGetWindowFrameSize(window, &left, &top, &right, &bottom);

    return .{
        .left = @intCast(left),
        .top = @intCast(top),
        .right = @intCast(right),
        .bottom = @intCast(bottom),
    };
}

pub fn getWindowContentScale(window: *Window) ContentScale {
    var xs: f32 = 0;
    var ys: f32 = 0;
    c.glfwGetWindowContentScale(window, &xs, &ys);
    return .{
        .x = xs,
        .y = ys,
    };
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
// Window state & visibility
// ─────────────────────────────────────────────────────────────────────────────

pub fn showWindow(window: *Window) void {
    c.glfwShowWindow(window);
}

pub fn hideWindow(window: *Window) void {
    c.glfwHideWindow(window);
}

pub fn iconifyWindow(window: *Window) void {
    c.glfwIconifyWindow(window);
}

pub fn restoreWindow(window: *Window) void {
    c.glfwRestoreWindow(window);
}

pub fn maximizeWindow(window: *Window) void {
    c.glfwMaximizeWindow(window);
}

pub fn focusWindow(window: *Window) void {
    c.glfwFocusWindow(window);
}

/// Request user attention (often flashes taskbar/dock).
pub fn requestWindowAttention(window: *Window) void {
    c.glfwRequestWindowAttention(window);
}

/// Change the window title. `title` must be UTF-8 + NUL-terminated.
pub fn setWindowTitle(window: *Window, title: [:0]const u8) void {
    c.glfwSetWindowTitle(window, title.ptr);
}

/// Returns true if GLFW considers the window visible (shown on screen).
pub fn isVisible(window: *Window) bool {
    return c.glfwGetWindowAttrib(window, c.GLFW_VISIBLE) == c.GLFW_TRUE;
}

/// Returns true if the window is minimized/iconified.
pub fn isIconified(window: *Window) bool {
    return c.glfwGetWindowAttrib(window, c.GLFW_ICONIFIED) == c.GLFW_TRUE;
}

/// Returns true if the window is maximized.
pub fn isMaximized(window: *Window) bool {
    return c.glfwGetWindowAttrib(window, c.GLFW_MAXIMIZED) == c.GLFW_TRUE;
}

/// Returns true if the window has input focus.
pub fn isFocused(window: *Window) bool {
    return c.glfwGetWindowAttrib(window, c.GLFW_FOCUSED) == c.GLFW_TRUE;
}

/// Returns true if the cursor is hovering over the content area of the window.
pub fn isHovered(window: *Window) bool {
    return c.glfwGetWindowAttrib(window, c.GLFW_HOVERED) == c.GLFW_TRUE;
}

// ─────────────────────────────────────────────────────────────────────────────
// Monitor binding & fullscreen
// ─────────────────────────────────────────────────────────────────────────────

pub fn getWindowMonitor(window: *Window) ?*Monitor {
    return c.glfwGetWindowMonitor(window);
}

/// Reconfigure window to use the given monitor (fullscreen or windowed).
///
/// - monitor = null: makes the window windowed.
/// - refresh_rate: use `glfw.c.GLFW_DONT_CARE` to let GLFW pick.
pub fn setWindowMonitor(
    window: *Window,
    monitor: ?*Monitor,
    xpos: i32,
    ypos: i32,
    width: i32,
    height: i32,
    refresh_rate: i32,
) void {
    c.glfwSetWindowMonitor(
        window,
        monitor,
        @intCast(xpos),
        @intCast(ypos),
        @intCast(width),
        @intCast(height),
        @intCast(refresh_rate),
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// Opacity & user pointer
// ─────────────────────────────────────────────────────────────────────────────

/// Window opacity in [0, 1]. May be unsupported on some platforms.
pub fn getWindowOpacity(window: *Window) f32 {
    return c.glfwGetWindowOpacity(window);
}

pub fn setWindowOpacity(window: *Window, opacity: f32) void {
    c.glfwSetWindowOpacity(window, opacity);
}

/// Attach an arbitrary user pointer to a window.
///
/// Typical pattern is to store a *opaque app struct here and recover it in
/// callbacks via `getWindowUserPointer`.
pub fn setWindowUserPointer(window: *Window, ptr: ?*anyopaque) void {
    c.glfwSetWindowUserPointer(window, ptr);
}

pub fn getWindowUserPointer(window: *Window) ?*anyopaque {
    return c.glfwGetWindowUserPointer(window);
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

// ─────────────────────────────────────────────────────────────────────────────
// Native Win32 handle (Windows-only at runtime)
// ─────────────────────────────────────────────────────────────────────────────

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

/// Get mouse button state for the given button on this window.
///
/// Returns one of GLFW_PRESS, GLFW_RELEASE, or GLFW_REPEAT (or 0 if unavailable).
pub fn getMouseButton(window: *Window, button: c_int) c_int {
    return c.glfwGetMouseButton(window, button);
}

/// Get human-readable key name for a key/scancode pair, if available.
///
/// Returns null if the key has no printable name on this keyboard layout.
pub fn getKeyName(key: c_int, scancode: c_int) ?[:0]const u8 {
    const ptr = c.glfwGetKeyName(key, scancode);
    if (ptr == null) return null;
    return std.mem.span(ptr);
}

/// Get the platform-specific scancode for a given key.
pub fn getKeyScancode(key: c_int) c_int {
    return c.glfwGetKeyScancode(key);
}

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
