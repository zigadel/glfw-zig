const std = @import("std");
const c_bindings = @import("c_bindings");

const c = c_bindings.c;

/// Joystick identifier (GLFW uses small integers 0..15).
pub const JoystickId = c_int;

/// Maximum gamepad axes and buttons, derived from GLFW constants.
pub const MaxGamepadAxes = c.GLFW_GAMEPAD_AXIS_LAST + 1;
pub const MaxGamepadButtons = c.GLFW_GAMEPAD_BUTTON_LAST + 1;

/// High-level copy of GLFWgamepadstate.
///
/// We copy out of the C struct so users never have to touch c.GLFWgamepadstate.
pub const GamepadState = struct {
    axes: [MaxGamepadAxes]f32,
    buttons: [MaxGamepadButtons]u8,
};

/// Function pointer type for joystick connection callback.
///
/// The callback receives:
/// - `jid`: joystick id
/// - `event`: `c.GLFW_CONNECTED` or `c.GLFW_DISCONNECTED`
pub const JoystickCallback = c.GLFWjoystickfun;

// ─────────────────────────────────────────────────────────────────────────────
// Presence / basic info
// ─────────────────────────────────────────────────────────────────────────────

/// Returns whether a joystick with the given id is present.
pub fn joystickPresent(jid: JoystickId) bool {
    return c.glfwJoystickPresent(jid) == c.GLFW_TRUE;
}

/// Returns the joystick's human-readable name, if any.
pub fn getJoystickName(jid: JoystickId) ?[:0]const u8 {
    const ptr = c.glfwGetJoystickName(jid);
    if (ptr == null) return null;
    return std.mem.span(ptr);
}

/// Returns the joystick's GUID string, if any.
pub fn getJoystickGUID(jid: JoystickId) ?[:0]const u8 {
    const ptr = c.glfwGetJoystickGUID(jid);
    if (ptr == null) return null;
    return std.mem.span(ptr);
}

// ─────────────────────────────────────────────────────────────────────────────
// Axes / buttons / hats
// ─────────────────────────────────────────────────────────────────────────────

/// Returns a borrowed slice of joystick axes in range [-1, 1].
///
/// The underlying storage is owned by GLFW and is invalidated if the joystick
/// is disconnected or the gamepad mappings change.
pub fn getJoystickAxes(jid: JoystickId) ?[]const f32 {
    var count: c_int = 0;
    const raw = c.glfwGetJoystickAxes(jid, &count);
    if (raw == null or count <= 0) return null;

    const len = @as(usize, @intCast(count));
    // `raw` is a C pointer; slicing gives us a borrowed slice.
    return raw[0..len];
}

/// Returns a borrowed slice of joystick buttons.
///
/// Elements are typically GLFW_PRESS / GLFW_RELEASE style values (0 or 1),
/// but you should treat them as opaque bytes.
pub fn getJoystickButtons(jid: JoystickId) ?[]const u8 {
    var count: c_int = 0;
    const raw = c.glfwGetJoystickButtons(jid, &count);
    if (raw == null or count <= 0) return null;

    const len = @as(usize, @intCast(count));
    return raw[0..len];
}

/// Returns a borrowed slice of joystick hats.
///
/// Each hat is a combination of `c.GLFW_HAT_*` bitflags.
pub fn getJoystickHats(jid: JoystickId) ?[]const u8 {
    var count: c_int = 0;
    const raw = c.glfwGetJoystickHats(jid, &count);
    if (raw == null or count <= 0) return null;

    const len = @as(usize, @intCast(count));
    return raw[0..len];
}

// ─────────────────────────────────────────────────────────────────────────────
// User pointer
// ─────────────────────────────────────────────────────────────────────────────

pub fn setJoystickUserPointer(jid: JoystickId, ptr: ?*anyopaque) void {
    c.glfwSetJoystickUserPointer(jid, ptr);
}

pub fn getJoystickUserPointer(jid: JoystickId) ?*anyopaque {
    return c.glfwGetJoystickUserPointer(jid);
}

// ─────────────────────────────────────────────────────────────────────────────
// Gamepad helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Returns true if the joystick maps to a gamepad according to GLFW mappings.
pub fn joystickIsGamepad(jid: JoystickId) bool {
    return c.glfwJoystickIsGamepad(jid) == c.GLFW_TRUE;
}

/// Returns the human-readable gamepad name, if the joystick is recognized.
pub fn getGamepadName(jid: JoystickId) ?[:0]const u8 {
    const ptr = c.glfwGetGamepadName(jid);
    if (ptr == null) return null;
    return std.mem.span(ptr);
}

/// Attempts to fetch the gamepad state for the given joystick.
///
/// Returns null if the joystick is not present, not a recognized gamepad,
/// or if GLFW reports failure.
pub fn getGamepadState(jid: JoystickId) ?GamepadState {
    var state_c: c.GLFWgamepadstate = undefined;
    const ok = c.glfwGetGamepadState(jid, &state_c);
    if (ok != c.GLFW_TRUE) return null;

    var out: GamepadState = undefined;

    var i: usize = 0;
    while (i < out.axes.len) : (i += 1) {
        out.axes[i] = state_c.axes[i];
    }

    i = 0;
    while (i < out.buttons.len) : (i += 1) {
        out.buttons[i] = state_c.buttons[i];
    }

    return out;
}

/// Adds or updates gamepad mappings in SDL2 mapping format.
///
/// Returns true on success.
pub fn updateGamepadMappings(mappings: [:0]const u8) bool {
    const res = c.glfwUpdateGamepadMappings(mappings.ptr);
    return res == c.GLFW_TRUE;
}

// ─────────────────────────────────────────────────────────────────────────────
// Callback
// ─────────────────────────────────────────────────────────────────────────────

/// Set or clear the joystick connection callback.
///
/// Passing null clears the callback. Returns the previously set callback.
pub fn setJoystickCallback(cb: JoystickCallback) JoystickCallback {
    return c.glfwSetJoystickCallback(cb);
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline best-effort test (no joystick required)
// ─────────────────────────────────────────────────────────────────────────────

test "joystick API is callable without crashing" {
    // Joystick functions are allowed before glfw.init().
    const jid: JoystickId = 0;

    _ = joystickPresent(jid);
    _ = getJoystickAxes(jid);
    _ = getJoystickButtons(jid);
    _ = getJoystickHats(jid);
    _ = getJoystickName(jid);
    _ = getJoystickGUID(jid);
    _ = joystickIsGamepad(jid);
    _ = getGamepadName(jid);
    _ = getGamepadState(jid);

    setJoystickUserPointer(jid, null);
    _ = getJoystickUserPointer(jid);

    // Callback registration sanity.
    const cb: JoystickCallback = struct {
        pub fn handler(j: c_int, ev: c_int) callconv(.C) void {
            _ = j;
            _ = ev;
        }
    }.handler;

    const prev = setJoystickCallback(cb);
    _ = prev;
    _ = setJoystickCallback(null);
}
