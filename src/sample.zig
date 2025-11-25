const std = @import("std");
const glfw = @import("glfw");

pub fn main() void {
    // Print GLFW version + platform string
    const ver = glfw.getVersionStruct();
    const ver_str_c = glfw.getVersionString();

    const ver_str = blk: {
        const sent: [*:0]const u8 = @ptrCast(ver_str_c);
        break :blk std.mem.span(sent);
    };

    std.debug.print(
        "GLFW version: {}.{}.{} ({s})\n",
        .{ ver.major, ver.minor, ver.rev, ver_str },
    );

    // Initialize GLFW
    if (glfw.init()) |_| {
        // ok
    } else |err| {
        const info_opt = glfw.getLastError();
        if (info_opt) |info| {
            std.debug.print(
                "glfw.init() failed ({any}) — GLFW error code {d}, description: {s}\n",
                .{
                    err,
                    info.code,
                    info.description orelse "(no description)",
                },
            );
        } else {
            std.debug.print(
                "glfw.init() failed ({any}); no GLFW error description available\n",
                .{err},
            );
        }
        return;
    }
    // IMPORTANT: this defer is now at function scope, not inside the if
    defer glfw.terminate();

    // Create a window
    const title = "Hello World\x00";
    const window = glfw.createWindow(800, 640, title, null, null) catch |err| {
        const info_opt = glfw.getLastError();
        if (info_opt) |info| {
            std.debug.print(
                "glfw.createWindow() failed ({any}) — GLFW error code {d}, description: {s}\n",
                .{
                    err,
                    info.code,
                    info.description orelse "(no description)",
                },
            );
        } else {
            std.debug.print(
                "glfw.createWindow() failed ({any}); no GLFW error description available\n",
                .{err},
            );
        }
        return;
    };
    defer glfw.destroyWindow(window);

    // Basic event loop: ESC closes the window.
    while (!glfw.windowShouldClose(window)) {
        if (glfw.getKey(window, glfw.KeyEscape) == glfw.Press) {
            glfw.setWindowShouldClose(window, true);
        }

        glfw.pollEvents();
    }

    std.debug.print("Sample finished cleanly.\n", .{});
}
