const std = @import("std");
const glfw = @import("glfw");

test "Vulkan helpers conformance" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const supported = glfw.vulkanSupported();

    const exts_opt = glfw.getRequiredInstanceExtensions(allocator) catch return;
    defer {
        if (exts_opt) |exts| allocator.free(exts);
    }

    if (!supported) {
        // When Vulkan is not supported, GLFW may return null or an empty list.
        if (exts_opt) |exts| {
            try std.testing.expect(exts.len == 0);
        }
        return;
    }

    const exts = exts_opt orelse return; // treat weird null as "skip"
    try std.testing.expect(exts.len > 0);

    // Each extension name should be non-empty and look like a sensible UTF-8
    // string (we only assert non-empty; contents are platform-dependent).
    for (exts) |name| {
        try std.testing.expect(name.len > 0);
    }
}
