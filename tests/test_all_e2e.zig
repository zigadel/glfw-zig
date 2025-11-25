const std = @import("std");

test "e2e suite" {
    _ = @import("e2e/window_open_close.zig");
    _ = @import("e2e/minimal_loop.zig");
}
