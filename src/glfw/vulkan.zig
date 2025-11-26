const std = @import("std");
const c_bindings = @import("c_bindings");

const c = c_bindings.c;

/// Vulkan-related helpers around GLFW's Vulkan support.
///
/// Design:
/// - This module is **agnostic** to any specific Vulkan Zig binding.
/// - Vulkan handles are modeled as `?*anyopaque` (you cast from/to your own types).
/// - Procedure pointers use GLFW's own `GLFWvkproc` typedef.
/// - All functions are safe to call even when Vulkan is unavailable on the system.
/// Raw Vulkan procedure pointer type as seen by GLFW.
pub const VkProc = c.GLFWvkproc;

// ─────────────────────────────────────────────────────────────────────────────
// Extern declarations for Vulkan helpers
// Some builds of the GLFW headers / cimport pipeline may omit these
// prototypes unless Vulkan headers are pulled in. We declare them here
// explicitly and link against the glfw_c static lib built in build.zig.
// ─────────────────────────────────────────────────────────────────────────────

extern fn glfwGetInstanceProcAddress(
    instance: ?*anyopaque,
    name: [*:0]const u8,
) VkProc;

extern fn glfwGetPhysicalDevicePresentationSupport(
    instance: ?*anyopaque,
    physical_device: ?*anyopaque,
    queue_family_index: u32,
) c_int;

// ─────────────────────────────────────────────────────────────────────────────
// Basic Vulkan support query
// ─────────────────────────────────────────────────────────────────────────────

/// Returns whether GLFW reports Vulkan support on this platform.
///
/// This can be called before `glfw.init()`.
pub fn vulkanSupported() bool {
    const res = c.glfwVulkanSupported();
    return res == c.GLFW_TRUE;
}

// ─────────────────────────────────────────────────────────────────────────────
// Required instance extensions
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the list of required Vulkan instance extensions for GLFW.
///
/// Behavior:
/// - On success, returns a Zig-owned slice of sentinel-terminated UTF-8 names.
///   The outer slice must be freed with the same allocator.
///   The underlying string storage is owned by GLFW and remains valid until
///   `glfw.terminate()`.
/// - Returns `null` if Vulkan is not supported or GLFW reports no extensions.
///
/// This is a thin wrapper over `glfwGetRequiredInstanceExtensions`.
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
// Instance proc address
// ─────────────────────────────────────────────────────────────────────────────

/// Wrapper around `glfwGetInstanceProcAddress`.
///
/// Parameters:
/// - `instance`: opaque Vulkan instance handle (typically cast from your
///   Vulkan binding's `vk.Instance`).
/// - `name`: zero-terminated ASCII function name.
///
/// Behavior:
/// - If Vulkan is not supported, always returns `null`.
/// - Otherwise, returns a raw procedure pointer (`GLFWvkproc`) or `null` if
///   the loader cannot provide that symbol.
pub fn getInstanceProcAddress(
    instance: ?*anyopaque,
    name: [:0]const u8,
) VkProc {
    if (!vulkanSupported()) return null;
    return glfwGetInstanceProcAddress(instance, name);
}

// ─────────────────────────────────────────────────────────────────────────────
// Presentation support
// ─────────────────────────────────────────────────────────────────────────────

/// Wrapper around `glfwGetPhysicalDevicePresentationSupport`.
///
/// Parameters:
/// - `instance`: opaque Vulkan instance handle.
/// - `physical_device`: opaque Vulkan physical device handle.
/// - `queue_family_index`: queue family index.
///
/// Behavior:
/// - If Vulkan is not supported, returns `false`.
/// - Otherwise, returns `true` iff GLFW reports presentation support for
///   the given device + queue family on the current platform.
pub fn getPhysicalDevicePresentationSupport(
    instance: ?*anyopaque,
    physical_device: ?*anyopaque,
    queue_family_index: u32,
) bool {
    if (!vulkanSupported()) return false;

    const res = glfwGetPhysicalDevicePresentationSupport(
        instance,
        physical_device,
        queue_family_index,
    );
    return res == c.GLFW_TRUE;
}
