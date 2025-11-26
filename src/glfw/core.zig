const std = @import("std");
const builtin = @import("builtin");
const c_bindings = @import("c_bindings");

const c = c_bindings.c;

/// Minimal error set for our high-level helpers.
/// Full error introspection is available via getLastError().
pub const GlfwError = error{
    InitializationFailed,
    WindowCreationFailed,
};

/// A nice Zig struct for holding the version.
pub const Version = struct {
    major: i32,
    minor: i32,
    rev: i32,
};

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

/// Supported GLFW platform identifiers for glfwGetPlatform / glfwPlatformSupported.
pub const Platform = enum(c_int) {
    any = c.GLFW_ANY_PLATFORM,
    win32 = c.GLFW_PLATFORM_WIN32,
    cocoa = c.GLFW_PLATFORM_COCOA,
    wayland = c.GLFW_PLATFORM_WAYLAND,
    x11 = c.GLFW_PLATFORM_X11,
    null = c.GLFW_PLATFORM_NULL,
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

pub fn initHint(hint: c_int, value: c_int) void {
    // Thin wrapper over glfwInitHint.
    // Safe to call before glfw.init().
    c.glfwInitHint(hint, value);
}

/// Returns whether raw mouse motion is supported on this platform.
///
/// Safe to call before or after glfw.init().
pub fn rawMouseMotionSupported() bool {
    return c.glfwRawMouseMotionSupported() == c.GLFW_TRUE;
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline tests (core)
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
