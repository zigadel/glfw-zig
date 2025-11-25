const std = @import("std");
const glfw = @import("glfw");

test "time API is available without glfw.init" {
    // All of these are allowed before glfw.init() and must not crash.

    const t0 = glfw.getTime();
    _ = t0;

    const freq = glfw.getTimerFrequency();
    _ = freq;

    const value = glfw.getTimerValue();
    _ = value;

    // setTime should also be legal pre-init; we don't assert semantics,
    // just that the call is safe.
    glfw.setTime(0.0);
}
