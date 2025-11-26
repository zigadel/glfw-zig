const std = @import("std");
const c_bindings = @import("c_bindings");
const core = @import("core");

const c = c_bindings.c;

pub const Monitor = c_bindings.Monitor;

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
pub fn getMonitors(allocator: std.mem.Allocator) ![]*Monitor {
    var count: c_int = 0;
    const raw = c.glfwGetMonitors(&count);

    if (count <= 0) {
        return allocator.alloc(*Monitor, 0);
    }

    const len: usize = @intCast(count);

    const addr = @intFromPtr(raw);
    if (addr == 0) {
        return allocator.alloc(*Monitor, 0);
    }

    const base: [*]*Monitor = @ptrFromInt(addr);
    const src = base[0..len];

    const dst = try allocator.alloc(*Monitor, len);
    @memcpy(dst, src);
    return dst;
}

/// Returns the current video mode for the given monitor, if GLFW reports one.
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
// Inline tests (monitor-level)
// ─────────────────────────────────────────────────────────────────────────────

test "monitor helpers best-effort" {
    _ = core.init() catch return;
    defer core.terminate();

    const primary = getPrimaryMonitor();
    if (primary) |mon| {
        if (getMonitorName(mon)) |name| {
            try std.testing.expect(name.len > 0);
        }

        if (getVideoMode(mon)) |mode| {
            try std.testing.expect(mode.width > 0);
            try std.testing.expect(mode.height > 0);
        }
    }
}
