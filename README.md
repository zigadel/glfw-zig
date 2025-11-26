# glfw-zig

Zig (nightly) bindings for **GLFW 3.4** — the battle‑tested C library for cross‑platform windows, input, monitors, and Vulkan/OpenGL context creation.

`glfw-zig` vendors and builds GLFW for you via Zig’s build system, then exposes a clean Zig API on top. You get a **single dependency** that:

- builds GLFW from source (no system packages to chase),
- gives you a **raw C surface** when you want full control, and
- gives you a **Zig‑friendly façade** for everyday use.

If you can compile Zig, you can open a window and start rendering.

---

## Highlights

- **Thin, honest wrapper** – mirrors the GLFW API closely; no hidden magic.
- **Zig‑first API** – sentinel‑terminated slices instead of raw `[*c]const u8`, error sets instead of ad‑hoc error codes, small helper structs for geometry.
- **Vendored GLFW 3.4** – built from source via `build.zig.zon` (`glfw-c` dependency).
- **Cross‑platform** via one codebase:
  - ✅ Windows (Win32 backend)
  - ✅ macOS (Cocoa backend)
  - 🔜 Linux / X11 / Wayland (wiring is straightforward; see `build.zig` notes)
- **Vulkan‑ready** – helpers for required instance extensions, proc address lookup, and presentation support.
- **Joystick / gamepad support** – joystick presence, names, GUIDs, gamepad state, and callback wiring.
- **Tested** – conformance, integration, and end‑to‑end tests cover the public API surface and basic semantics.

This is meant to be a **production‑ready foundation** for engines, tools, and visualization stacks that want GLFW without C build drama.

---

## Directory layout

```text
glfw-zig/
|   build.zig
|   build.zig.zon
|   README.md
|   ideal-project-directory-structure.txt
|
+---src/
|   |   glfw.zig          # public façade: @import("glfw")
|   |   bindings.zig      # legacy/raw C bindings façade
|   |
|   \---glfw/
|       c_bindings.zig    # @cImport("GLFW/glfw3.h") + native handle externs
|       core.zig          # init/terminate, errors, version, time, platform API
|       window.zig        # window lifecycle, geometry, attributes, input, callbacks
|       monitor.zig       # monitors, video modes, scales, gamma, user pointer
|       vulkan.zig        # Vulkan helpers (support, extensions, proc addresses)
|       context.zig       # GL/EGL/OSMesa context helpers
|       joystick.zig      # joystick/gamepad helpers + callback type
|
\---tests/
    test_all_conformance.zig
    test_all_integration.zig
    test_all_e2e.zig
    |
    +---conformance/      # API surface & behavior contracts
    +---integration/      # “how you actually use it” flows
    \---e2e/              # tiny real‑world scenarios
```

---

## Using `glfw-zig` in your project

### 1. Add it as a dependency

Until this is published in a central registry, you typically add it as a **Zig dependency** (tarball, git tag, or local path). In `build.zig.zon` of your app:

```zig
.dependencies = .{
    .@"glfw-zig" = .{
        // Fill these according to how you vend the code:
        // .url  = "...",
        // .hash = "...",
    },
};
```

In `build.zig` of your app:

```zig
const target = b.standardTargetOptions(.{});
const optimize = b.standardOptimizeOption(.{});

const glfw_dep = b.dependency("glfw-zig", .{
    .target = target,
    .optimize = optimize,
});

const glfw_mod = glfw_dep.module("glfw");

// Example: attach to your main executable:
const exe = b.addExecutable(.{
    .name = "my-app",
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("glfw", glfw_mod);

b.installArtifact(exe);
```

After that, in your Zig code:

```zig
const glfw = @import("glfw");
```

If you want the **raw C API**, you can additionally:

```zig
const glfw = @import("glfw");
const c = glfw.c; // exposes the original GLFW C namespace
```

---

## Minimal example: open a window and loop

```zig
const std = @import("std");
const glfw = @import("glfw");

pub fn main() !void {
    // Initialize GLFW. If it fails, bail out with a clean error.
    _ = glfw.init() catch return error.GlfwInitFailed;
    defer glfw.terminate();

    const title = "glfw-zig example";

    const window = glfw.createWindow(800, 600, title, null, null)
        catch return error.CreateWindowFailed;
    defer glfw.destroyWindow(window);

    // Basic loop: poll events, swap buffers, quit when the user closes the window.
    while (!glfw.windowShouldClose(window)) {
        glfw.pollEvents();
        glfw.swapBuffers(window);
    }
}
```

Notes:

- The title must be **NUL‑terminated**.
- `createWindow` returns `GlfwError!*Window`, so you can bubble or map errors as you prefer.

---

## Public Zig API surface

You normally only care about the façade in `src/glfw.zig`. At a glance, it exports:

- **Handles & raw C**

  - `pub const c = c_bindings.c;`
  - `pub const Window = c_bindings.Window;`
  - `pub const Monitor = c_bindings.Monitor;`
  - `pub const Cursor = c_bindings.Cursor;`

- **Error model**

  - `GlfwError`, `ErrorCode`, `ErrorInfo`, `errorCodeFromC`
  - `getLastError()` to query the latest error and message.

- **Lifecycle & platform**

  - `init`, `terminate`, `initHint`
  - `Platform`, `getPlatform`, `platformSupported`
  - `rawMouseMotionSupported`

- **Time / timers**

  - `getTime`, `setTime`
  - `getTimerValue`, `getTimerFrequency`

- **Window API (core)**

  - Creation & teardown: `createWindow`, `destroyWindow`, `windowShouldClose`, `setWindowShouldClose`
  - Loop helpers: `pollEvents`, `waitEventsTimeout`, `postEmptyEvent`
  - Swap: `swapInterval`, `swapBuffers`
  - Input: `getKey`, `getMouseButton`, `getKeyName`, `getKeyScancode`

- **Window hints & attributes**

  - `defaultWindowHints`, `windowHint`, `windowHintString`
  - `getWindowAttrib`, `setWindowAttrib`

- **Window geometry & content scale**

  - Types: `WindowPos`, `WindowSize`, `FramebufferSize`, `FrameSize`, `ContentScale`
  - Functions:
    - `getWindowPos`, `setWindowPos`
    - `getWindowSize`, `setWindowSize`, `setWindowSizeLimits`, `setWindowAspectRatio`
    - `getFramebufferSize`, `getWindowFrameSize`, `getWindowContentScale`

- **Window state & visibility**

  - `showWindow`, `hideWindow`, `iconifyWindow`, `restoreWindow`, `maximizeWindow`
  - `focusWindow`, `requestWindowAttention`, `setWindowTitle`
  - Queries: `isVisible`, `isIconified`, `isMaximized`, `isFocused`, `isHovered`

- **Monitor API**

  - Types: `VideoMode`, `MonitorPos`, `MonitorWorkarea`, `MonitorPhysicalSize`, `MonitorContentScale`
  - Functions:
    - `getPrimaryMonitor`, `getMonitors`
    - `getVideoMode`, `getVideoModes`, `getMonitorName`
    - `getMonitorPos`, `getMonitorWorkarea`, `getMonitorPhysicalSize`, `getMonitorContentScale`
    - `setMonitorUserPointer`, `getMonitorUserPointer`, `setGamma`

- **Monitor binding / fullscreen**

  - `getWindowMonitor`, `setWindowMonitor`

- **Opacity & user pointers**

  - `getWindowOpacity`, `setWindowOpacity`
  - `setWindowUserPointer`, `getWindowUserPointer`

- **Cursor / input modes / clipboard**

  - `getCursorPos`, `setCursorPos`
  - `setInputMode`, `getInputMode`
  - `setCursor`, `createStandardCursor`, `destroyCursor`
  - `setClipboardString`, `getClipboardString`

- **Native handles**

  - `getWin32Window` (HWND escape hatch on Windows; returns `null` elsewhere)

- **Vulkan helpers**

  - `VkProc` (GLFW’s `GLFWvkproc` type)
  - `vulkanSupported()`
  - `getRequiredInstanceExtensions(allocator) !?[][:0]const u8`
  - `getInstanceProcAddress(instance: ?*anyopaque, name: [:0]const u8) VkProc`
  - `getPhysicalDevicePresentationSupport(instance, physical_device, queue_family_index) bool`

- **Joystick / gamepad**

  - Types: `JoystickId`, `MaxGamepadAxes`, `MaxGamepadButtons`, `GamepadState`, `JoystickCallback`
  - Functions:
    - `joystickPresent`, `getJoystickName`, `getJoystickGUID`
    - `getJoystickAxes`, `getJoystickButtons`, `getJoystickHats`
    - `setJoystickUserPointer`, `getJoystickUserPointer`
    - `joystickIsGamepad`, `getGamepadName`, `getGamepadState`, `updateGamepadMappings`
    - `setJoystickCallback`

- **Callbacks (window / input / errors)**
  - Types:
    - `ErrorCallback`
    - `WindowPosCallback`, `WindowSizeCallback`, `WindowCloseCallback`, `WindowRefreshCallback`,  
      `WindowFocusCallback`, `WindowIconifyCallback`, `WindowMaximizeCallback`,  
      `FramebufferSizeCallback`, `WindowContentScaleCallback`
    - `MouseButtonCallback`, `CursorPosCallback`, `CursorEnterCallback`, `ScrollCallback`,  
      `KeyCallback`, `CharCallback`, `CharModsCallback`, `DropCallback`
  - Setters:
    - `setErrorCallback`
    - `setWindowPosCallback`, `setWindowSizeCallback`, `setWindowCloseCallback`,  
      `setWindowRefreshCallback`, `setWindowFocusCallback`, `setWindowIconifyCallback`,  
      `setWindowMaximizeCallback`, `setFramebufferSizeCallback`, `setWindowContentScaleCallback`
    - `setMouseButtonCallback`, `setCursorPosCallback`, `setCursorEnterCallback`,  
      `setScrollCallback`, `setKeyCallback`, `setCharCallback`,  
      `setCharModsCallback`, `setDropCallback`

If you ever forget a name, `src/glfw.zig` is small enough to skim in a few seconds.

---

## Testing & confidence

`glfw-zig` is designed to be **safe to lean on**:

- **Inline unit tests** live in the modules under `src/glfw/`.
- **Conformance tests** in `tests/conformance/` verify:
  - API surface presence (types, constants, functions),
  - lifecycle invariants (init/terminate, error behavior),
  - time, monitors, window geometry/state, clipboard, input modes,
  - Vulkan helpers, native handles, joystick/gamepad behavior, callbacks.
- **Integration tests** in `tests/integration/` exercise:
  - basic event loops,
  - practical window lifecycle flows.
- **End‑to‑end tests** in `tests/e2e/` run tiny real‑world scenarios
  (like opening a window, looping a few frames, and shutting down cleanly).

By default:

```bash
zig build
```

runs **all** test suites (unit + conformance + integration + e2e).

To run just the sample “hello window” executable:

```bash
zig build run
```

---

## Platform notes

- **Windows (Win32)**

  - Compiled with `_GLFW_WIN32` and Unicode flags.
  - Links against `user32`, `gdi32`, `shell32`, `advapi32`, `winmm`.
  - `getWin32Window` returns a valid `HWND` for bridge integration with other APIs.

- **macOS (Cocoa)**

  - Compiled with `_GLFW_COCOA`.
  - Links against `Cocoa`, `IOKit`, `CoreFoundation`, `CoreVideo`.
  - Behavior differences versus Win32 (e.g. iconify/visibility semantics) are handled
    in tests with platform‑aware expectations.

- **Linux / X11 / Wayland**
  - The C sources and flags needed for X11/Wayland are well understood; wiring them
    in is mostly a matter of extending `buildGlfwCLib` in `build.zig`.
  - Until that wiring lands, non‑Windows/non‑macOS targets will result in a build‑time
    panic in `buildGlfwCLib` with a clear message.

The goal is **“zero‑hassle GLFW”** once the platform wiring is in place: you depend on `glfw-zig`, and it Just Builds.

---

## Design philosophy

- **Minimal abstraction** – Every function maps closely to GLFW’s C API. If you know GLFW,
  you don’t have to re‑learn a new framework.
- **Ergonomic Zig surface** – Where it helps, the API uses:
  - Zig structs for positions, sizes, and content scales,
  - sentinel‑terminated slices instead of raw C strings,
  - error sets instead of ad‑hoc integer error codes.
- **No global mutable Zig state** – GLFW already has a global state model; the wrapper doesn’t add new globals on top.
- **First‑class “raw” access** – The entire C namespace is still exposed through `glfw.c` for advanced or experimental use.
- **Test‑driven** – The shape of the public API is locked in by tests, not by accident.

This is meant to be a **foundation piece**, not a framework: you bring your renderer, ECS, or engine; `glfw-zig` gives you predictable windows, input, and integration hooks.

---

## Licensing

This project is **deliberately license‑free**

- There is no `LICENSE` file.
- You may **use, copy, modify, and redistribute** this code, in source or binary form, for **any purpose** (including commercial) **without asking for permission**.
- Attribution is **appreciated but not required**.
- The code is provided **“as is”**, with **no warranty of any kind** and **no liability** for any damages that may arise from its use.

In practice: treat this as **public‑domain‑like software** — do whatever you want with it, just don’t expect support, guarantees, or legal backing from the author.
