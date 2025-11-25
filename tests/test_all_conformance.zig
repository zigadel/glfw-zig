const std = @import("std");

test "conformance suite" {
    _ = @import("conformance/api_surface.zig");
    _ = @import("conformance/version.zig");
    _ = @import("conformance/init_terminate.zig");
    _ = @import("conformance/error_safety.zig");
    _ = @import("conformance/window_lifecycle.zig");
    _ = @import("conformance/time.zig");
}
