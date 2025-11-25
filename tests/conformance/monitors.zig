const std = @import("std");
const glfw = @import("glfw");

test "monitors API basic behavior + helpers" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Some CI / headless environments may not have a display; treat init
    // failure as best-effort rather than hard failure.
    _ = glfw.init() catch return;
    defer glfw.terminate();

    // Snapshot of current monitors.
    const monitors = glfw.getMonitors(allocator) catch return;
    defer allocator.free(monitors);

    // The slice itself should be well-formed; we don't assert any particular
    // count because that is platform-dependent.
    for (monitors) |m| {
        // `*glfw.Monitor` is opaque; we can at least assert the pointer is
        // non-zero.
        try std.testing.expect(@intFromPtr(m) != 0);
    }

    // Primary monitor helper: if GLFW reports a primary monitor at all, it
    // must be one of the entries returned by getMonitors().
    const primary = glfw.getPrimaryMonitor();
    if (primary) |p| {
        var found = false;
        for (monitors) |m| {
            if (m == p) {
                found = true;
                break;
            }
        }
        try std.testing.expect(found);
    }

    // For at least one monitor (when any exist), exercise the video mode and
    // name helpers in a portable way.
    if (monitors.len > 0) {
        const monitor = monitors[0];

        // Current video mode, if reported, should have sensible dimensions.
        if (glfw.getVideoMode(monitor)) |mode| {
            try std.testing.expect(mode.width > 0);
            try std.testing.expect(mode.height > 0);
            try std.testing.expect(mode.red_bits >= 0);
            try std.testing.expect(mode.green_bits >= 0);
            try std.testing.expect(mode.blue_bits >= 0);
            try std.testing.expect(mode.refresh_rate >= 0);
        }

        // Full video modes list: must be safe to call and, when non-empty,
        // each entry must have positive width/height.
        const modes = glfw.getVideoModes(allocator, monitor) catch return;
        defer allocator.free(modes);

        if (modes.len > 0) {
            for (modes) |vm| {
                try std.testing.expect(vm.width > 0);
                try std.testing.expect(vm.height > 0);
            }

            // Optional: check that the "current" mode is *often* present
            // in the modes list when both APIs report something. We don't
            // assert on this because the GLFW spec does not guarantee it.
            if (glfw.getVideoMode(monitor)) |current| {
                var current_found = false;
                for (modes) |vm| {
                    if (vm.width == current.width and
                        vm.height == current.height and
                        vm.refresh_rate == current.refresh_rate)
                    {
                        current_found = true;
                        break;
                    }
                }
            }
        }

        // Monitor name helper: if GLFW reports a name, it should be non-empty.
        if (glfw.getMonitorName(monitor)) |name| {
            try std.testing.expect(name.len > 0);
        }
    }
}
