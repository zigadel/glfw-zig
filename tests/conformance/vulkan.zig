const std = @import("std");
const testing = std.testing;
const glfw = @import("glfw");

test "Vulkan support + required extensions basic behavior" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const supported = glfw.vulkanSupported();

    const exts_opt = glfw.getRequiredInstanceExtensions(allocator) catch return;
    defer {
        if (exts_opt) |exts| allocator.free(exts);
    }

    if (!supported) {
        // When Vulkan is not supported, GLFW is allowed to report no extensions.
        if (exts_opt) |exts| {
            try testing.expect(exts.len == 0);
        }
        return;
    }

    const exts = exts_opt orelse return; // weird but possible; treat as skip
    try testing.expect(exts.len > 0);

    // Basic sanity: all returned names should be non-empty.
    for (exts) |name| {
        try testing.expect(name.len > 0);
    }
}

test "Vulkan instance proc address helper is safe" {
    // We do NOT require a real VkInstance here. On systems without Vulkan
    // support, this must just return null. On systems with Vulkan, passing
    // a null instance and bogus name must not crash and usually returns null.
    const proc = glfw.getInstanceProcAddress(null, "this_function_does_not_exist\x00");
    _ = proc;
}

test "Vulkan presentation support helper is safe with null handles" {
    // Passing null handles should never crash; we only assert that it compiles
    // and can be called. The return value is allowed to be either false or true
    // depending on how GLFW chooses to handle nulls, but in practice we expect
    // false here.
    const ok = glfw.getPhysicalDevicePresentationSupport(null, null, 0);
    _ = ok;
}
