const std = @import("std");
const c_bindings = @import("c_bindings");
const core = @import("core");
const window = @import("window");

const c = c_bindings.c;

/// Alias of GLFW's function pointer type for GL procedures.
pub const GlProc = c.GLFWglproc;

/// Make the given window's context current on the calling thread.
///
/// Pass `null` to detach any current context (no context current).
pub fn makeContextCurrent(win: ?*core.Window) void {
    c.glfwMakeContextCurrent(win);
}

/// Return the window whose context is current on this thread, if any.
pub fn getCurrentContext() ?*core.Window {
    const raw = c.glfwGetCurrentContext();
    if (raw == null) return null;
    return raw.?;
}

/// Look up an OpenGL function pointer by name.
///
/// The `name` must be a zero-terminated UTF-8 string (e.g. "glGetError\x00").
/// Returns `null` if the symbol cannot be resolved.
pub fn getProcAddress(name: [:0]const u8) ?GlProc {
    return c.glfwGetProcAddress(name.ptr);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests (best-effort; tolerate headless / no-GL environments)
// ─────────────────────────────────────────────────────────────────────────────

test "context: makeCurrent / getCurrentContext best-effort" {
    // Some environments may not have a display; bail quietly on init failure.
    _ = core.init() catch return;
    defer core.terminate();

    const title = "glfw-zig-context-test\x00";
    const win = window.createWindow(32, 32, title, null, null) catch return;
    defer window.destroyWindow(win);

    // Attach context and verify round-trip, as far as GLFW lets us.
    makeContextCurrent(win);

    const current = getCurrentContext() orelse return;
    try std.testing.expect(@intFromPtr(win) == @intFromPtr(current));

    // Detach context; shouldn't crash.
    makeContextCurrent(null);
}

test "context: getProcAddress smoke (best-effort)" {
    // We don't require any particular symbol to exist; this is just a
    // wiring / ABI smoke test. It should not crash.
    _ = core.init() catch return;
    defer core.terminate();

    const title = "glfw-zig-context-proc-test\x00";
    const win = window.createWindow(32, 32, title, null, null) catch return;
    defer window.destroyWindow(win);

    makeContextCurrent(win);

    // Common GL entry point; may or may not resolve depending on drivers.
    const name: [:0]const u8 = "glGetError\x00";
    _ = getProcAddress(name);
}
