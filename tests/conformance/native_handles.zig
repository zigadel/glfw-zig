const std = @import("std");
const builtin = @import("builtin");
const glfw = @import("glfw");

test "conformance: native Win32 handle escape hatch (Windows only)" {
    if (builtin.os.tag != .windows) return;

    // API symbol must exist.
    _ = glfw.getWin32Window;

    _ = glfw.init() catch return;
    defer glfw.terminate();

    const title = "glfw-zig-native-handle-conformance\x00";
    const window = try glfw.createWindow(32, 32, title, null, null);
    defer glfw.destroyWindow(window);

    const hwnd = glfw.getWin32Window(window) orelse return;
    try std.testing.expect(@intFromPtr(hwnd) != 0);
}
