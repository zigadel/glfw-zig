const std = @import("std");
const builtin = @import("builtin");

/// Thin Zig wrapper around the GLFW C library (3.4).
/// - Vendored C sources are built via build.zig (see build.zig.zon "glfw-c").
/// - This module exposes a small, idiomatic Zig surface,
///   plus access to the raw C API via `glfw.c` for escape hatches.
pub const c = @cImport({
    @cDefine("GLFW_INCLUDE_NONE", "1");
    @cInclude("GLFW/glfw3.h");
});

/// Native Win32 helper symbol from GLFW.
///
/// We declare this ourselves instead of pulling in <glfw3native.h> and
/// Windows headers, to keep `glfw-zig` lightweight and header-independent.
/// This is only actually defined by GLFW on Win32 builds.
extern fn glfwGetWin32Window(window: ?*c.GLFWwindow) ?*anyopaque;

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
    /// Raw GLFW error code as returned by glfwGetError.
    code: c_int,

    /// Optional UTF-8 description, owned by GLFW (do not free).
    description: ?[]const u8,

    /// Attempt to map the raw error code to a strongly-typed GLFW error code.
    /// Returns null if the code is not one of the known GLFW error constants.
    pub fn codeEnum(self: ErrorInfo) ?ErrorCode {
        return errorCodeFromC(self.code);
    }
};

/// All documented GLFW error codes as of GLFW 3.4, mapped 1:1 to their C values.
pub const ErrorCode = enum(c_int) {
    no_error = c.GLFW_NO_ERROR,
    not_initialized = c.GLFW_NOT_INITIALIZED,
    no_current_context = c.GLFW_NO_CURRENT_CONTEXT,
    invalid_enum = c.GLFW_INVALID_ENUM,
    invalid_value = c.GLFW_INVALID_VALUE,
    out_of_memory = c.GLFW_OUT_OF_MEMORY,
    api_unavailable = c.GLFW_API_UNAVAILABLE,
    version_unavailable = c.GLFW_VERSION_UNAVAILABLE,
    platform_error = c.GLFW_PLATFORM_ERROR,
    format_unavailable = c.GLFW_FORMAT_UNAVAILABLE,
    no_window_context = c.GLFW_NO_WINDOW_CONTEXT,
    cursor_unavailable = c.GLFW_CURSOR_UNAVAILABLE,
    feature_unavailable = c.GLFW_FEATURE_UNAVAILABLE,
    feature_unimplemented = c.GLFW_FEATURE_UNIMPLEMENTED,
    platform_unavailable = c.GLFW_PLATFORM_UNAVAILABLE,
};

/// Best-effort mapping from a raw GLFW error code to an ErrorCode enum.
/// Returns null if the code is not a known GLFW error constant.
pub fn errorCodeFromC(code: c_int) ?ErrorCode {
    return std.meta.intToEnum(ErrorCode, code) catch null;
}

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

/// Waits until at least one event has been placed in the event queue,
/// or until the given timeout elapses.
///
/// This is a direct wrapper over `glfwWaitEventsTimeout`. It requires
/// that `glfw.init()` has been called.
pub fn waitEventsTimeout(timeout_seconds: f64) void {
    c.glfwWaitEventsTimeout(timeout_seconds);
}

/// Posts an empty event to wake up a thread blocked in waitEvents*.
///
/// Thin wrapper over `glfwPostEmptyEvent`.
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
///
/// Thin wrapper over `glfwDefaultWindowHints`.
pub fn defaultWindowHints() void {
    c.glfwDefaultWindowHints();
}

/// Set an integer window hint.
///
/// This is a direct wrapper over `glfwWindowHint`. You are expected to pass
/// GLFW hint/boolean constants from `glfw.c`, e.g.:
///
///   glfw.windowHint(glfw.c.GLFW_RESIZABLE, glfw.c.GLFW_FALSE);
///
/// Hints affect **subsequent** window creations.
pub fn windowHint(hint: c_int, value: c_int) void {
    c.glfwWindowHint(hint, value);
}

/// Set a string window hint.
///
/// Thin wrapper over `glfwWindowHintString`. The `value` must be a
/// zero-terminated UTF-8 string.
pub fn windowHintString(hint: c_int, value: [*:0]const u8) void {
    c.glfwWindowHintString(hint, value);
}

/// Get an integer window attribute.
///
/// Thin wrapper over `glfwGetWindowAttrib`. Returns the raw GLFW integer
/// (often `GLFW_TRUE` / `GLFW_FALSE`), so callers can either compare against
/// those, or map to `bool` themselves.
pub fn getWindowAttrib(window: *Window, attrib: c_int) c_int {
    return c.glfwGetWindowAttrib(window, attrib);
}

/// Set a mutable window attribute.
///
/// Thin wrapper over `glfwSetWindowAttrib`. Not all attributes are mutable;
/// see the GLFW docs for which ones are supported. Typical usage:
///
///   glfw.setWindowAttrib(window, glfw.c.GLFW_RESIZABLE, glfw.c.GLFW_FALSE);
pub fn setWindowAttrib(window: *Window, attrib: c_int, value: c_int) void {
    c.glfwSetWindowAttrib(window, attrib, value);
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

/// Supported GLFW platform identifiers for glfwGetPlatform / glfwPlatformSupported.
pub const Platform = enum(c_int) {
    any = c.GLFW_ANY_PLATFORM,
    win32 = c.GLFW_PLATFORM_WIN32,
    cocoa = c.GLFW_PLATFORM_COCOA,
    wayland = c.GLFW_PLATFORM_WAYLAND,
    x11 = c.GLFW_PLATFORM_X11,
    null = c.GLFW_PLATFORM_NULL,
};

/// Query the currently selected platform.
///
/// Returns null if GLFW reports an unknown or unsupported platform value.
pub fn getPlatform() ?Platform {
    const raw: c_int = c.glfwGetPlatform();
    if (raw == 0) return null;

    return std.meta.intToEnum(Platform, raw) catch null;
}

/// Query whether the given platform is supported by this GLFW build.
pub fn platformSupported(platform: Platform) bool {
    return c.glfwPlatformSupported(@intFromEnum(platform)) == c.GLFW_TRUE;
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

/// Set an input mode option for the specified window.
///
/// Mode must be one of:
/// - c.GLFW_CURSOR
/// - c.GLFW_STICKY_KEYS
/// - c.GLFW_STICKY_MOUSE_BUTTONS
/// - c.GLFW_LOCK_KEY_MODS
/// - c.GLFW_RAW_MOUSE_MOTION
pub fn setInputMode(window: *Window, mode: c_int, value: c_int) void {
    c.glfwSetInputMode(window, mode, value);
}

/// Get the value of an input mode option for the specified window.
///
/// See `setInputMode` for valid `mode` values.
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
///
/// Returns `null` on failure; use `getLastError()` for details if desired.
pub fn createStandardCursor(shape: c_int) ?*Cursor {
    return c.glfwCreateStandardCursor(shape);
}

/// Destroy a cursor created with `createStandardCursor` or any custom cursor.
///
/// Any window using this cursor will revert to the default cursor.
pub fn destroyCursor(cursor: *Cursor) void {
    c.glfwDestroyCursor(cursor);
}

/// Set the system clipboard to the specified UTF-8 string.
///
/// The string is copied by GLFW; it is safe to free or modify it after this call.
/// This is a thin wrapper around `glfwSetClipboardString`.
pub fn setClipboardString(window: *Window, string: [:0]const u8) void {
    c.glfwSetClipboardString(window, string.ptr);
}

/// Get the current contents of the system clipboard as UTF-8, if available.
///
/// Returns:
/// - `null` if the clipboard is empty, cannot be converted to UTF-8, or an error occurred.
/// - A slice of a NUL-terminated string whose lifetime is managed by GLFW.
///   The data remains valid until the next clipboard change or GLFW termination.
pub fn getClipboardString(window: *Window) ?[:0]const u8 {
    const ptr = c.glfwGetClipboardString(window);
    if (ptr == null) return null;
    return std.mem.span(ptr);
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
// Vulkan helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Returns whether GLFW reports Vulkan support on this platform.
///
/// This is a thin wrapper over `glfwVulkanSupported` and can be called
/// before `glfw.init()`.
pub fn vulkanSupported() bool {
    const result = c.glfwVulkanSupported();
    return result == c.GLFW_TRUE;
}

/// Returns the list of required Vulkan instance extensions.
///
/// This is a thin wrapper over `glfwGetRequiredInstanceExtensions`.
///
/// - On success, returns a slice of sentinel-terminated UTF-8 names.
/// - The slice itself is allocated with `allocator` and must be freed by
///   the caller using the same allocator.
/// - The strings **borrow** storage from GLFW and remain valid until
///   `glfw.terminate()` is called.
/// - Returns `null` if Vulkan is not supported or GLFW reports none.
pub fn getRequiredInstanceExtensions(
    allocator: std.mem.Allocator,
) !?[][:0]const u8 {
    var count: u32 = 0;
    const raw = c.glfwGetRequiredInstanceExtensions(&count);

    if (count == 0) {
        // Either Vulkan is not supported or no extensions are required.
        return null;
    }

    const addr = @intFromPtr(raw);
    if (addr == 0) {
        return null;
    }

    const len: usize = @intCast(count);

    // `raw` is effectively `const char**`. We reinterpret the address as
    // a pointer to an array of sentinel-terminated C strings.
    const base: [*][*:0]const u8 = @ptrFromInt(addr);
    const src = base[0..len];

    // Allocate the outer slice; each element is a sentinel-terminated slice
    // borrowing GLFW-managed storage.
    const out = try allocator.alloc([:0]const u8, len);
    for (src, 0..) |p, i| {
        out[i] = std.mem.span(p);
    }

    return out;
}

// ─────────────────────────────────────────────────────────────────────────────
// Native platform handles (Win32)
// ─────────────────────────────────────────────────────────────────────────────

/// Return the native Win32 HWND for a GLFW window (Windows only).
///
/// This is a thin wrapper around `glfwGetWin32Window`. The return type is
/// an opaque pointer so that `glfw-zig` does not need to pull in Win32
/// headers; downstream code (e.g. Vulkan/OpenXR layers) can cast it to the
/// appropriate handle type.
///
/// On non-Windows platforms this function is not meaningful and may always
/// return null; `glfw-zig` currently targets Win32 + WGL.
pub fn getWin32Window(window: *Window) ?*anyopaque {
    if (builtin.os.tag != .windows) {
        // Defensive; on non-Windows builds we don't expect this to be usable.
        return null;
    }

    return glfwGetWin32Window(window);
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

test "window hints + attributes best-effort" {
    // Headless/CI environments may not have a usable display; treat both init
    // and window creation as best-effort.
    _ = init() catch return;
    defer terminate();

    // Start from clean defaults.
    defaultWindowHints();

    // Make window non-resizable via hint, then verify via attribute.
    windowHint(c.GLFW_RESIZABLE, c.GLFW_FALSE);

    const title = "hint test\x00";
    const window = createWindow(640, 480, title, null, null) catch return;
    defer destroyWindow(window);

    // Attribute should reflect the hint when the platform supports it.
    const resizable = getWindowAttrib(window, c.GLFW_RESIZABLE);
    if (resizable == c.GLFW_TRUE or resizable == c.GLFW_FALSE) {
        try std.testing.expectEqual(c.GLFW_FALSE, resizable);

        // Flip it back on using setWindowAttrib, and re-check.
        setWindowAttrib(window, c.GLFW_RESIZABLE, c.GLFW_TRUE);
        const resizable2 = getWindowAttrib(window, c.GLFW_RESIZABLE);
        try std.testing.expectEqual(c.GLFW_TRUE, resizable2);
    }
}

test "Vulkan helpers basic behavior" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const supported = vulkanSupported();

    const exts_opt = getRequiredInstanceExtensions(allocator) catch return;
    defer {
        if (exts_opt) |exts| allocator.free(exts);
    }

    if (!supported) {
        // If Vulkan is not supported, GLFW is allowed to return null or an
        // empty list. We only assert that we don't crash.
        if (exts_opt) |exts| {
            try std.testing.expect(exts.len == 0);
        }
        return;
    }

    const exts = exts_opt orelse return; // strange but possible; treat as skip
    try std.testing.expect(exts.len > 0);

    // Basic sanity: all returned names should be non-empty.
    for (exts) |name| {
        try std.testing.expect(name.len > 0);
    }
}

test "input mode: sticky keys round-trip best-effort" {
    _ = init() catch return;
    defer terminate();

    const title = "glfw-zig-input-mode-test\x00";
    const window = createWindow(64, 64, title, null, null) catch return;
    defer destroyWindow(window);

    const prev = getInputMode(window, c.GLFW_STICKY_KEYS);
    setInputMode(window, c.GLFW_STICKY_KEYS, c.GLFW_TRUE);
    const now = getInputMode(window, c.GLFW_STICKY_KEYS);

    // On GLFW 3.4 this should always work; if it ever doesn't, we still
    // want a clear signal.
    try std.testing.expect(now == c.GLFW_TRUE);

    // Restore original state so tests don’t perturb app behavior.
    setInputMode(window, c.GLFW_STICKY_KEYS, prev);
}

test "cursor + standard cursor best-effort" {
    _ = init() catch return;
    defer terminate();

    const title = "glfw-zig-cursor-test\x00";
    const window = createWindow(64, 64, title, null, null) catch return;
    defer destroyWindow(window);

    // Ensure the symbols exist and calls don’t blow up.
    const cursor = createStandardCursor(c.GLFW_ARROW_CURSOR) orelse return;
    defer destroyCursor(cursor);

    // Setting a cursor should not crash; we don't assert visual behavior here.
    setCursor(window, cursor);
    setCursor(window, null); // revert to default cursor
}

test "clipboard round-trip best-effort" {
    _ = init() catch return;
    defer terminate();

    const title = "glfw-zig-clipboard-test\x00";
    const window = createWindow(64, 64, title, null, null) catch return;
    defer destroyWindow(window);

    const msg: [:0]const u8 = "glfw-zig clipboard test";

    // Best-effort: some headless or unusual environments might not have a
    // usable clipboard; we treat failures as non-fatal.
    setClipboardString(window, msg);

    if (getClipboardString(window)) |got| {
        // We only require that our message appears as a prefix; platforms
        // may append or transform slightly.
        try std.testing.expect(std.mem.startsWith(u8, got, msg[0 .. msg.len - 1]));
    }
}

test "errorCodeFromC round-trip for known values" {
    const values = std.enums.values(ErrorCode);
    for (values) |code| {
        const raw: c_int = @intFromEnum(code);
        const mapped = errorCodeFromC(raw).?;
        try std.testing.expectEqual(code, mapped);
    }
}

test "ErrorInfo.codeEnum best-effort" {
    // Force a GLFW error by calling a GLFW function before init.
    var count: c_int = 0;
    _ = c.glfwGetMonitors(&count);

    const info_opt = getLastError() orelse return;
    // We don't assert which error it is, only that mapping does not crash.
    _ = info_opt.codeEnum();
}

test "platform API best-effort" {
    const plat_opt = getPlatform();
    if (plat_opt) |plat| {
        // On any sane build, the current platform should be supported.
        try std.testing.expect(platformSupported(plat));
    }
}

test "native Win32 window handle best-effort" {
    if (builtin.os.tag != .windows) return;

    _ = init() catch return;
    defer terminate();

    const title = "glfw-zig-win32-handle-test\x00";
    const window = createWindow(64, 64, title, null, null) catch return;
    defer destroyWindow(window);

    const hwnd = getWin32Window(window) orelse return;
    // Just sanity: pointer should be non-null.
    try std.testing.expect(@intFromPtr(hwnd) != 0);
}

test "waitEventsTimeout + postEmptyEvent basic smoke" {
    _ = init() catch return;
    defer terminate();

    const title = "glfw-zig-wait-test\x00";
    const window = createWindow(32, 32, title, null, null) catch return;
    defer destroyWindow(window);

    // Schedule a wake-up and then wait with a small timeout. We don't assert
    // anything beyond "does not deadlock or crash".
    postEmptyEvent();
    waitEventsTimeout(0.05);
}
