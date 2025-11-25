const std = @import("std");

/// Thin Zig wrapper around the GLFW C library (3.4).
/// - Vendored C sources are built via build.zig (see build.zig.zon "glfw-c").
/// - This module exposes a small, idiomatic Zig surface,
///   plus access to the raw C API via `glfw.c` for escape hatches.
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
    var c_desc: [*c]const u8 = undefined;

    // glfwGetError takes "const char**" → [*c][*c]const u8.
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

// ─────────────────────────────────────────────────────────────────────────────
// Window API
// ─────────────────────────────────────────────────────────────────────────────

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

/// Swap buffers for a window's current context (typical render loop call).
pub fn swapBuffers(window: *Window) void {
    c.glfwSwapBuffers(window);
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

// ─────────────────────────────────────────────────────────────────────────────
// Time / timer API
// ─────────────────────────────────────────────────────────────────────────────

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
/// On most platforms this will be non-zero if a high-resolution timer is
/// available, but some environments may report 0; callers must handle both
/// cases (see tests).
pub fn getTimerFrequency() u64 {
    return c.glfwGetTimerFrequency();
}

// ─────────────────────────────────────────────────────────────────────────────
// Monitor API
// ─────────────────────────────────────────────────────────────────────────────

/// Describes a monitor video mode (resolution + format + refresh rate).
///
/// This is a Zig-native struct mirroring `GLFWvidmode`. Values are copied
/// out of GLFW’s internal structures and are safe to keep as long as you like.
pub const VideoMode = struct {
    width: i32,
    height: i32,
    red_bits: i32,
    green_bits: i32,
    blue_bits: i32,
    refresh_rate: i32,

    /// Build a `VideoMode` from the raw C struct.
    pub fn fromC(v: c.GLFWvidmode) VideoMode {
        return .{
            .width = v.width,
            .height = v.height,
            .red_bits = v.redBits,
            .green_bits = v.greenBits,
            .blue_bits = v.blueBits,
            .refresh_rate = v.refreshRate,
        };
    }
};

/// Returns the primary monitor, if GLFW reports one.
///
/// This is a thin wrapper around `glfwGetPrimaryMonitor` that returns a Zig
/// `?*Monitor` instead of a C pointer.
pub fn getPrimaryMonitor() ?*Monitor {
    const raw = c.glfwGetPrimaryMonitor();

    const addr = @intFromPtr(raw);
    if (addr == 0) {
        return null;
    }

    const mon: *Monitor = @ptrFromInt(addr);
    return mon;
}

/// High-level helper: returns a Zig-owned slice of monitor handles.
///
/// The slice must be freed by the caller with the same allocator.
/// This is a **snapshot** of the monitor list at call time; if the monitor
/// configuration changes, GLFW may invalidate the underlying C array, but this
/// copied slice remains valid as an array of opaque handles.
///
/// This function only fails on allocation failure.
pub fn getMonitors(allocator: std.mem.Allocator) ![]*Monitor {
    var count: c_int = 0;
    const raw = c.glfwGetMonitors(&count);

    // If there are no monitors, GLFW sets count to 0; we never touch `raw`.
    if (count <= 0) {
        return allocator.alloc(*Monitor, 0);
    }

    const len: usize = @intCast(count);

    // `raw` is some form of pointer to monitor pointers. We don't care about the
    // exact pointer flavor; we just reinterpret its address as `[ * ]*Monitor`
    // and copy `len` elements out.
    const addr = @intFromPtr(raw);
    if (addr == 0) {
        // Extremely defensive: treat as empty if address is somehow null.
        return allocator.alloc(*Monitor, 0);
    }

    const base: [*]*Monitor = @ptrFromInt(addr);
    const src = base[0..len];

    const dst = try allocator.alloc(*Monitor, len);
    @memcpy(dst, src);
    return dst;
}

/// Returns the current video mode for the given monitor, if GLFW reports one.
///
/// The returned `VideoMode` is a copy of GLFW’s internal mode and is safe
/// to keep independently of GLFW’s lifetime (until you terminate GLFW).
pub fn getVideoMode(monitor: *Monitor) ?VideoMode {
    const raw = c.glfwGetVideoMode(monitor);

    const addr = @intFromPtr(raw);
    if (addr == 0) {
        return null;
    }

    const base: [*]const c.GLFWvidmode = @ptrFromInt(addr);
    const mode_c = base[0];

    return VideoMode.fromC(mode_c);
}

/// Returns all video modes for the given monitor as a Zig-owned slice.
///
/// The returned slice must be freed by the caller using the same allocator.
/// Each entry corresponds to one `GLFWvidmode` entry at the time of the call.
pub fn getVideoModes(allocator: std.mem.Allocator, monitor: *Monitor) ![]VideoMode {
    var count: c_int = 0;
    const raw = c.glfwGetVideoModes(monitor, &count);

    if (count <= 0) {
        return allocator.alloc(VideoMode, 0);
    }

    const len: usize = @intCast(count);

    const addr = @intFromPtr(raw);
    if (addr == 0) {
        return allocator.alloc(VideoMode, 0);
    }

    const base: [*]const c.GLFWvidmode = @ptrFromInt(addr);
    const src = base[0..len];

    const dst = try allocator.alloc(VideoMode, len);
    for (src, 0..) |mode_c, i| {
        dst[i] = VideoMode.fromC(mode_c);
    }
    return dst;
}

/// Returns the UTF-8 name of a monitor as a sentinel-terminated slice.
///
/// The underlying string storage is owned by GLFW; you must **not** free it.
/// The returned slice is valid until the monitor is disconnected or GLFW is
/// terminated.
pub fn getMonitorName(monitor: *Monitor) ?[:0]const u8 {
    const raw = c.glfwGetMonitorName(monitor);

    const addr = @intFromPtr(raw);
    if (addr == 0) {
        return null;
    }

    const sent_ptr: [*:0]const u8 = @ptrFromInt(addr);
    return std.mem.span(sent_ptr);
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

test "monitor helpers best-effort" {
    // Some environments (headless CI) may not have any display attached;
    // treat init failure as a best-effort bail out.
    _ = init() catch return;
    defer terminate();

    const primary = getPrimaryMonitor();
    if (primary) |mon| {
        // Name helper should be safe to call and usually returns a non-empty name.
        if (getMonitorName(mon)) |name| {
            try std.testing.expect(name.len > 0);
        }

        // Video mode helper should be safe to call; when it returns something,
        // the resolution should be strictly positive.
        if (getVideoMode(mon)) |mode| {
            try std.testing.expect(mode.width > 0);
            try std.testing.expect(mode.height > 0);
        }
    }
}
