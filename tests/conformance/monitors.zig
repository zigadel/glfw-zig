const std = @import("std");
const testing = std.testing;
const glfw = @import("glfw");

fn withMonitors(body: fn (*glfw.Monitor, []*glfw.Monitor) anyerror!void) !void {
    try glfw.init();
    defer glfw.terminate();

    const alloc = testing.allocator;
    const list = try glfw.getMonitors(alloc);
    defer alloc.free(list);

    if (list.len == 0) return;

    const primary = glfw.getPrimaryMonitor() orelse list[0];

    try body(primary, list);
}

test "monitors: primary + list + video modes" {
    try withMonitors(struct {
        fn run(primary: *glfw.Monitor, list: []*glfw.Monitor) !void {
            try testing.expect(list.len >= 1);

            const name_opt = glfw.getMonitorName(primary);
            if (name_opt) |name| {
                try testing.expect(name.len > 0);
            }

            const alloc = testing.allocator;

            const vm_opt = glfw.getVideoMode(primary) orelse return;
            try testing.expect(vm_opt.width > 0);
            try testing.expect(vm_opt.height > 0);

            const modes = try glfw.getVideoModes(alloc, primary);
            defer alloc.free(modes);

            try testing.expect(modes.len >= 1);
        }
    }.run);
}

test "monitors: geometry, physical size, content scale, user pointer, gamma no-crash" {
    try withMonitors(struct {
        fn run(primary: *glfw.Monitor, _: []*glfw.Monitor) !void {
            const pos = glfw.getMonitorPos(primary);
            _ = pos;

            const wa = glfw.getMonitorWorkarea(primary);
            try testing.expect(wa.width >= 0);
            try testing.expect(wa.height >= 0);

            const phys = glfw.getMonitorPhysicalSize(primary);
            // These can legitimately be zero on some setups; just ensure not negative.
            try testing.expect(phys.width_mm >= 0);
            try testing.expect(phys.height_mm >= 0);

            const scale = glfw.getMonitorContentScale(primary);
            try testing.expect(scale.x > 0);
            try testing.expect(scale.y > 0);

            // User pointer round-trip.
            glfw.setMonitorUserPointer(primary, null);
            try testing.expect(glfw.getMonitorUserPointer(primary) == null);

            var dummy: u8 = 0;
            glfw.setMonitorUserPointer(primary, &dummy);
            const got = glfw.getMonitorUserPointer(primary);
            try testing.expect(got != null);
            // Best-effort identity check.
            try testing.expect(@intFromPtr(got.?) == @intFromPtr(&dummy));

            // Gamma 1.0 should effectively be "no-op" on most systems.
            glfw.setGamma(primary, 1.0);
        }
    }.run);
}
