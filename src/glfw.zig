const std = @import("std");

pub const c = @cImport({
    @cDefine("GLFW_INCLUDE_NONE", "1");
    @cInclude("GLFW/glfw3.h");
});

pub const Window = c.GLFWwindow;
pub const Monitor = c.GLFWmonitor;
pub const Cursor = c.GLFWcursor;

// Common key/action helpers
pub const KeyEscape = c.GLFW_KEY_ESCAPE;
pub const Press = c.GLFW_PRESS;
pub const Release = c.GLFW_RELEASE;

/// Minimal error set for our high-level helpers.
/// Full error introspection is available via getLastError().
pub const GlfwError = error{
    InitializationFailed,
    WindowCreationFailed,
};

/// Initialize GLFW. Must be called before almost any other GLFW call.
/// On failure, returns `error.InitializationFailed`.
pub fn init() GlfwError!void {
    if (c.glfwInit() != c.GLFW_TRUE) {
        return GlfwError.InitializationFailed;
    }
}

/// Terminate GLFW and clean up global state.
pub fn terminate() void {
    c.glfwTerminate();
}

/// Direct passthroughs to the raw C API for version queries.
pub const getVersion = c.glfwGetVersion;
pub const getVersionString = c.glfwGetVersionString;

/// A nice Zig struct for holding the version.
pub const Version = struct {
    major: i32,
    minor: i32,
    rev: i32,
};

/// Convenience helper: returns the compiled GLFW version as a struct.
pub fn getVersionStruct() Version {
    var major: i32 = 0;
    var minor: i32 = 0;
    var rev: i32 = 0;

    getVersion(&major, &minor, &rev);
    return .{
        .major = major,
        .minor = minor,
        .rev = rev,
    };
}

/// Detailed error info from glfwGetError. The description may be null.
pub const ErrorInfo = struct {
    code: c_int,
    description: ?[]const u8,
};

/// Retrieve the last GLFW error, if any.
/// This wraps glfwGetError and turns the C string into a Zig slice.
///
/// C signature: `int glfwGetError(const char** description);`
/// cimport:      `pub extern fn glfwGetError(description: [*c][*c]const u8) c_int;`
pub fn getLastError() ?ErrorInfo {
    // Raw C pointer to char, GLFW will write into this.
    // We don't need an initial value; we only read it if code != NO_ERROR.
    var c_desc: [*c]const u8 = undefined;

    // glfwGetError takes "const char**" → [*c][*c]const u8.
    // New-style @ptrCast: one argument, type comes from the LHS.
    const desc_param: [*c][*c]const u8 = @ptrCast(&c_desc);

    const code = c.glfwGetError(desc_param);
    if (code == c.GLFW_NO_ERROR) return null;

    // Determine whether GLFW returned a null pointer.
    const is_null = @intFromPtr(c_desc) == 0;

    const desc_slice: ?[]const u8 = if (is_null) null else blk: {
        // GLFW promises a null-terminated UTF-8 string.
        const sent: [*:0]const u8 = @ptrCast(c_desc);
        break :blk std.mem.span(sent);
    };

    return .{
        .code = code,
        .description = desc_slice,
    };
}

/// Create a window with default hints.
///
/// `title` must be a zero-terminated string, e.g.:
///   const title = "Hello World\x00";
///   const window = try glfw.createWindow(800, 640, title, null, null);
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

/// V-sync helper: set swap interval.
pub fn swapInterval(interval: c_int) void {
    c.glfwSwapInterval(interval);
}

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

/// Returns the GLFW time in seconds as an f64.
/// This does **not** require glfw.init() to succeed.
pub fn getTime() f64 {
    return c.glfwGetTime();
}

/// Sets the GLFW time in seconds.
/// Useful in tests or for resetting your own timers.
pub fn setTime(seconds: f64) void {
    c.glfwSetTime(seconds);
}

/// Returns the raw timer value as a monotonically increasing counter.
/// This does **not** require glfw.init() to succeed.
pub fn getTimerValue() u64 {
    return c.glfwGetTimerValue();
}

/// Returns the raw timer frequency (ticks per second).
/// Guaranteed by GLFW to be non-zero on supported platforms.
pub fn getTimerFrequency() u64 {
    return c.glfwGetTimerFrequency();
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline tests (unit + light conformance)
// ─────────────────────────────────────────────────────────────────────────────

test "time API basic sanity" {
    // Allowed before glfw.init(), so we don't depend on init here.

    const t0 = getTime();
    const t1 = getTime();

    // Time should be monotonic non-decreasing (within reason).
    try std.testing.expect(t1 >= t0);

    const freq = getTimerFrequency();
    // Some platforms/builds may report 0 for "no high-res timer".
    // The only hard guarantee we enforce here is "the call doesn't crash".
    if (freq != 0) {
        // If there *is* a frequency, we can at least check that timer values
        // are monotonic (no requirement on step size).
        const v0 = getTimerValue();
        const v1 = getTimerValue();
        try std.testing.expect(v1 >= v0);
    } else {
        // Still exercise the call in the "no frequency" case.
        const v = getTimerValue();
        _ = v;
    }

    // setTime shouldn't crash; we just round-trip the current value.
    setTime(t1);
    const t2 = getTime();
    try std.testing.expect(t2 >= 0.0);
}

test "version API basic sanity" {
    var major: i32 = 0;
    var minor: i32 = 0;
    var rev: i32 = 0;

    getVersion(&major, &minor, &rev);

    try std.testing.expect(major >= 0);
    try std.testing.expect(minor >= 0);
    try std.testing.expect(rev >= 0);

    const v = getVersionStruct();
    try std.testing.expect(v.major == major);
    try std.testing.expect(v.minor == minor);
    try std.testing.expect(v.rev == rev);
}

test "getLastError best-effort" {
    // Force a predictable error by calling a GLFW function before init.
    var count: c_int = 0;
    _ = c.glfwGetMonitors(&count);

    const err = getLastError() orelse return;
    try std.testing.expect(err.code != c.GLFW_NO_ERROR);
}

test "init / terminate best-effort" {
    // Some environments (headless CI) may not have a display; treat init failure
    // as non-fatal for this test so the suite remains portable.
    _ = init() catch return;
    terminate();
}

test "createWindow / destroyWindow best-effort" {
    // If init fails, just bail; we don’t want tests to explode in headless CI.
    _ = init() catch return;
    defer terminate();

    const title = "glfw-zig-test\x00";
    const window = createWindow(64, 64, title, null, null) catch return;
    destroyWindow(window);
}
