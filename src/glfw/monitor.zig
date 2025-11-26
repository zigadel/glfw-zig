const std = @import("std");
const c_bindings = @import("c_bindings");

const c = c_bindings.c;

pub const Monitor = c_bindings.Monitor;

/// High-level representation of GLFW's GLFWvidmode.
pub const VideoMode = struct {
    width: i32,
    height: i32,
    red_bits: i32,
    green_bits: i32,
    blue_bits: i32,
    refresh_rate: i32,
};

fn videoModeFromC(vm: c.GLFWvidmode) VideoMode {
    return .{
        .width = @as(i32, @intCast(vm.width)),
        .height = @as(i32, @intCast(vm.height)),
        .red_bits = @as(i32, @intCast(vm.redBits)),
        .green_bits = @as(i32, @intCast(vm.greenBits)),
        .blue_bits = @as(i32, @intCast(vm.blueBits)),
        .refresh_rate = @as(i32, @intCast(vm.refreshRate)),
    };
}

/// Logical monitor position in screen coordinates.
pub const MonitorPos = struct {
    x: i32,
    y: i32,
};

/// Work area rectangle in screen coordinates.
pub const MonitorWorkarea = struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
};

/// Physical monitor size in millimetres.
pub const MonitorPhysicalSize = struct {
    width_mm: i32,
    height_mm: i32,
};

/// Content scale factors for a monitor.
pub const MonitorContentScale = struct {
    x: f32,
    y: f32,
};

// ─────────────────────────────────────────────────────────────────────────────
// Primary monitor + monitor list
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the primary monitor, if any.
pub fn getPrimaryMonitor() ?*Monitor {
    return c.glfwGetPrimaryMonitor();
}

/// Returns a heap-owned slice of monitors.
///
/// The slice must be freed with the same allocator. The underlying GLFW
/// monitor objects are owned by GLFW and remain valid until `glfw.terminate()`.
pub fn getMonitors(allocator: std.mem.Allocator) ![]*Monitor {
    var count: c_int = 0;
    const raw = c.glfwGetMonitors(&count);

    if (count <= 0) {
        return try allocator.alloc(*Monitor, 0);
    }

    const addr = @intFromPtr(raw);
    if (addr == 0) {
        return try allocator.alloc(*Monitor, 0);
    }

    const len = @as(usize, @intCast(count));
    const base: [*]*Monitor = @ptrFromInt(addr);
    const src = base[0..len];

    const out = try allocator.alloc(*Monitor, len);
    // manual copy to avoid std.mem.copy API differences across Zig versions
    var i: usize = 0;
    while (i < len) : (i += 1) {
        out[i] = src[i];
    }

    return out;
}

// ─────────────────────────────────────────────────────────────────────────────
// Video modes
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the current video mode for the given monitor, if GLFW reports one.
pub fn getVideoMode(monitor: *Monitor) ?VideoMode {
    const ptr = c.glfwGetVideoMode(monitor);
    if (ptr == null) return null;
    return videoModeFromC(ptr.*);
}

/// Returns all video modes for a monitor as heap-owned copies.
///
/// The returned slice must be freed with the same allocator.
pub fn getVideoModes(
    allocator: std.mem.Allocator,
    monitor: *Monitor,
) ![]VideoMode {
    var count: c_int = 0;
    const raw = c.glfwGetVideoModes(monitor, &count);

    if (count <= 0) {
        return try allocator.alloc(VideoMode, 0);
    }

    const addr = @intFromPtr(raw);
    if (addr == 0) {
        return try allocator.alloc(VideoMode, 0);
    }

    const len = @as(usize, @intCast(count));
    const base: [*]c.GLFWvidmode = @ptrFromInt(addr);
    const src = base[0..len];

    const out = try allocator.alloc(VideoMode, len);
    var i: usize = 0;
    while (i < len) : (i += 1) {
        out[i] = videoModeFromC(src[i]);
    }
    return out;
}

/// Returns the human-readable name of the monitor, if GLFW provides one.
pub fn getMonitorName(monitor: *Monitor) ?[:0]const u8 {
    const ptr = c.glfwGetMonitorName(monitor);
    if (ptr == null) return null;
    return std.mem.span(ptr);
}

// ─────────────────────────────────────────────────────────────────────────────
// Monitor geometry, physical size, content scale
// ─────────────────────────────────────────────────────────────────────────────

pub fn getMonitorPos(monitor: *Monitor) MonitorPos {
    var x: c_int = 0;
    var y: c_int = 0;
    c.glfwGetMonitorPos(monitor, &x, &y);
    return .{
        .x = @as(i32, @intCast(x)),
        .y = @as(i32, @intCast(y)),
    };
}

pub fn getMonitorWorkarea(monitor: *Monitor) MonitorWorkarea {
    var x: c_int = 0;
    var y: c_int = 0;
    var w: c_int = 0;
    var h: c_int = 0;

    c.glfwGetMonitorWorkarea(monitor, &x, &y, &w, &h);

    return .{
        .x = @as(i32, @intCast(x)),
        .y = @as(i32, @intCast(y)),
        .width = @as(i32, @intCast(w)),
        .height = @as(i32, @intCast(h)),
    };
}

pub fn getMonitorPhysicalSize(monitor: *Monitor) MonitorPhysicalSize {
    var w_mm: c_int = 0;
    var h_mm: c_int = 0;
    c.glfwGetMonitorPhysicalSize(monitor, &w_mm, &h_mm);
    return .{
        .width_mm = @as(i32, @intCast(w_mm)),
        .height_mm = @as(i32, @intCast(h_mm)),
    };
}

pub fn getMonitorContentScale(monitor: *Monitor) MonitorContentScale {
    var xs: f32 = 0;
    var ys: f32 = 0;
    c.glfwGetMonitorContentScale(monitor, &xs, &ys);
    return .{
        .x = xs,
        .y = ys,
    };
}

// ─────────────────────────────────────────────────────────────────────────────
// User pointer + gamma
// ─────────────────────────────────────────────────────────────────────────────

pub fn setMonitorUserPointer(monitor: *Monitor, ptr: ?*anyopaque) void {
    c.glfwSetMonitorUserPointer(monitor, ptr);
}

pub fn getMonitorUserPointer(monitor: *Monitor) ?*anyopaque {
    return c.glfwGetMonitorUserPointer(monitor);
}

/// Convenience wrapper for `glfwSetGamma`.
pub fn setGamma(monitor: *Monitor, gamma: f32) void {
    c.glfwSetGamma(monitor, gamma);
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline best-effort tests
// ─────────────────────────────────────────────────────────────────────────────

test "monitors: primary + video mode best-effort" {
    const alloc = std.testing.allocator;

    const core = @import("core");
    _ = core.init() catch return;
    defer core.terminate();

    const primary = getPrimaryMonitor() orelse return;

    const vm_opt = getVideoMode(primary) orelse return;
    try std.testing.expect(vm_opt.width > 0);
    try std.testing.expect(vm_opt.height > 0);

    const modes = try getVideoModes(alloc, primary);
    defer alloc.free(modes);
    try std.testing.expect(modes.len >= 1);
}
