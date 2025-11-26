const std = @import("std");

test "conformance suite" {
    _ = @import("conformance/api_surface.zig");
    _ = @import("conformance/version.zig");
    _ = @import("conformance/init_terminate.zig");
    _ = @import("conformance/error_safety.zig");
    _ = @import("conformance/window_lifecycle.zig");
    _ = @import("conformance/time.zig");
    _ = @import("conformance/monitors.zig");
    _ = @import("conformance/window_hints.zig");
    _ = @import("conformance/vulkan.zig");
    _ = @import("conformance/input_modes.zig");
    _ = @import("conformance/clipboard.zig");
    _ = @import("conformance/native_handles.zig");
    _ = @import("conformance/event_wait.zig");
    _ = @import("conformance/window_geometry.zig");
    _ = @import("conformance/window_state.zig");
    _ = @import("conformance/clipboard.zig");
    _ = @import("conformance/joystick.zig");
    _ = @import("conformance/api_surface.zig");
}
