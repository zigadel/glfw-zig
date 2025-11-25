const std = @import("std");
const glfw = @import("glfw");

test "glfw.init / terminate best-effort" {
    _ = glfw.init() catch return;
    glfw.terminate();
}
