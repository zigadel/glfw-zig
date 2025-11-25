const std = @import("std");
const glfw = @import("glfw");

test "conformance: version helpers are consistent" {
    var major: i32 = 0;
    var minor: i32 = 0;
    var rev: i32 = 0;

    glfw.getVersion(&major, &minor, &rev);
    const v = glfw.getVersionStruct();

    try std.testing.expect(v.major == major);
    try std.testing.expect(v.minor == minor);
    try std.testing.expect(v.rev == rev);

    const ver_str_c = glfw.getVersionString();
    const ver_str = blk: {
        const sent: [*:0]const u8 = @ptrCast(ver_str_c);
        break :blk std.mem.span(sent);
    };

    try std.testing.expect(ver_str.len > 0);
}
