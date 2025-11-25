const std = @import("std");
const glfw = @import("glfw");

test "conformance: clipboard basic round-trip best-effort" {
    // API surface must exist.
    _ = glfw.setClipboardString;
    _ = glfw.getClipboardString;

    _ = glfw.init() catch return;
    defer glfw.terminate();

    const title = "glfw-zig-conformance-clipboard\x00";
    const window = try glfw.createWindow(32, 32, title, null, null);
    defer glfw.destroyWindow(window);

    const msg: [:0]const u8 = "glfw-zig clipboard conformance";

    glfw.setClipboardString(window, msg);

    if (glfw.getClipboardString(window)) |got| {
        // Same best-effort behavior as the inline test.
        try std.testing.expect(std.mem.startsWith(u8, got, msg[0 .. msg.len - 1]));
    }
}
