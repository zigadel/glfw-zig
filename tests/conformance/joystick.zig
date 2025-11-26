const std = @import("std");
const testing = std.testing;
const glfw = @import("glfw");

test "joystick/gamepad API surface compiles and basic semantics" {
    // Joystick APIs are valid even before glfw.init() according to GLFW docs.
    const jid: glfw.JoystickId = 0;

    // Presence query should not crash.
    _ = glfw.joystickPresent(jid);

    // Borrowed slices; may be null if not present.
    _ = glfw.getJoystickAxes(jid);
    _ = glfw.getJoystickButtons(jid);
    _ = glfw.getJoystickHats(jid);

    // Names / GUIDs are optional.
    _ = glfw.getJoystickName(jid);
    _ = glfw.getJoystickGUID(jid);

    // User pointer should round-trip without crashing.
    glfw.setJoystickUserPointer(jid, null);
    _ = glfw.getJoystickUserPointer(jid);

    // Gamepad helpers: they should be callable; results are env-dependent.
    _ = glfw.joystickIsGamepad(jid);
    _ = glfw.getGamepadName(jid);
    _ = glfw.getGamepadState(jid);

    // Mapping update: pass an empty string; GLFW should just ignore/fail politely.
    const empty: [:0]const u8 = "";
    _ = glfw.updateGamepadMappings(empty);

    // Callback registration sanity: install and then clear.
    const cb: glfw.JoystickCallback = struct {
        pub fn handler(j: c_int, ev: c_int) callconv(.c) void {
            _ = j;
            _ = ev;
        }
    }.handler;

    const prev = glfw.setJoystickCallback(cb);
    _ = prev;
    _ = glfw.setJoystickCallback(null);

    // If we got here without UB or a crash, the surface is sound.
    try testing.expect(true);
}
