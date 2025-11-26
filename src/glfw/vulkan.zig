const std = @import("std");
const c_bindings = @import("c_bindings");

const c = c_bindings.c;

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
        return null;
    }

    const addr = @intFromPtr(raw);
    if (addr == 0) {
        return null;
    }

    const len: usize = @intCast(count);

    const base: [*][*:0]const u8 = @ptrFromInt(addr);
    const src = base[0..len];

    const out = try allocator.alloc([:0]const u8, len);
    for (src, 0..) |p, i| {
        out[i] = std.mem.span(p);
    }

    return out;
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline tests (Vulkan helpers)
// ─────────────────────────────────────────────────────────────────────────────

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
        if (exts_opt) |exts| {
            try std.testing.expect(exts.len == 0);
        }
        return;
    }

    const exts = exts_opt orelse return;
    try std.testing.expect(exts.len > 0);

    for (exts) |name| {
        try std.testing.expect(name.len > 0);
    }
}
