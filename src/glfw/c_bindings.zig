const std = @import("std");
const builtin = @import("builtin");

/// Raw C bindings for GLFW (3.4).
///
/// We define GLFW_INCLUDE_NONE to keep control of which graphics headers
/// are pulled in by downstream code (e.g. user chooses OpenGL/Vulkan/etc.).
pub const c = @cImport({
    @cDefine("GLFW_INCLUDE_NONE", "1");
    @cInclude("GLFW/glfw3.h");
});

/// Native Win32 helper symbol from GLFW.
///
/// We declare this ourselves instead of pulling in <glfw3native.h> and
/// Windows headers, to keep glfw-zig lightweight and header-independent.
/// This is only actually defined by GLFW on Win32 builds.
extern fn glfwGetWin32Window(window: ?*c.GLFWwindow) ?*anyopaque;

/// Opaque handle aliases, mirroring GLFW’s typedefs.
pub const Window = c.GLFWwindow;
pub const Monitor = c.GLFWmonitor;
pub const Cursor = c.GLFWcursor;

/// Return the native Win32 `HWND` for a GLFW window (Windows only).
///
/// On non-Windows platforms this always returns null; we do not attempt to
/// emulate or fake a handle type there.
pub fn getWin32Window(window: *Window) ?*anyopaque {
    if (builtin.os.tag != .windows) return null;
    return glfwGetWin32Window(window);
}

// Tiny smoke test so this file participates in `zig build test`.
test "c_bindings: basic sanity" {
    _ = c.GLFW_TRUE;
}
