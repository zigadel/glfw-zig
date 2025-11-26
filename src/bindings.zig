// src/bindings.zig
// Low-level C bindings and opaque type aliases.

pub const c = @cImport({
    @cDefine("GLFW_INCLUDE_NONE", "1");
    @cInclude("GLFW/glfw3.h");
});

pub const Window = c.GLFWwindow;
pub const Monitor = c.GLFWmonitor;
pub const Cursor = c.GLFWcursor;
