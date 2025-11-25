const glfw = @import("glfw");

test "conformance: getLastError is safe before and after init/terminate" {
    // Before init: should be safe (typically returns null).
    const before = glfw.getLastError();
    _ = before;

    // init() may fail in headless CI; treat that as a skip.
    if (glfw.init()) |_| {
        // ok
    } else |_| {
        return;
    }
    defer glfw.terminate();

    // After init: still safe.
    const mid = glfw.getLastError();
    _ = mid;

    // Explicit terminate call should not break getLastError.
    glfw.terminate();

    const after = glfw.getLastError();
    _ = after;
}
