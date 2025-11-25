const std = @import("std");

test "integration suite" {
    _ = @import("integration/event_loop_basic.zig");
    _ = @import("integration/window_lifecycle.zig");
}
