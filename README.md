# glfw-zig

A thin, well-tested, **idiomatic Zig wrapper** around [GLFW](https://www.glfw.org/), including a vendored C build and a clean Zig façade.

You get:

- No system GLFW dependency – C sources are pulled via `build.zig.zon` and built from source.
- A single Zig import: `const glfw = @import("glfw");`
- A **small, coherent API surface** that tracks GLFW’s mental model but feels like Zig.
- A serious test grid: inline unit tests + conformance + integration + e2e.

---

## Goals

- **Vendored, reproducible build**  
  GLFW is built from source via Zon; no “install libglfw somewhere and pray” step.

- **Idiomatic Zig façade**  
  Clear naming, small structs for geometry, Zig errors instead of raw error codes.

- **Raw escape hatch**  
  Full C API is still exposed under `glfw.c` if you need the exact GLFW surface.

- **Cross-platform**  
  - Windows (Win32 backend)  
  - macOS (Cocoa backend)  
  - Linux (X11 backend)

- **Trustworthy**  
  Tests exercise the real API surface across platforms: init/terminate, window lifecycle, monitor handling, input, clipboard, joystick, Vulkan helpers, etc.

---

## Platform support

| Platform | Backend | Status                          |
|----------|---------|---------------------------------|
| Windows  | Win32   | ✅ builds + tests green         |
| macOS    | Cocoa   | ✅ builds + tests green         |
| Linux    | X11     | ✅ builds + tests green (X11)   |

Notes for Linux:

- You’ll need dev packages for X11 and friends (`X11`, `Xi`, `Xrandr`, `Xinerama`, `Xcursor`, `Xxf86vm`, plus `pthread`, `dl`, `m`), typically via your distro’s `*-dev` packages.

---

## Getting it into your project

### 1. Add a dependency in `build.zig.zon`

Use the git/url/commit that you actually pin to; schematically:

```zig
.dependencies = .{
    .glfw_zig = .{
        .url = "https://github.com/your-org/glfw-zig/archive/<commit>.tar.gz",
        .hash = "<fill-me>",
    },
},
```

(Replace `url` and `hash` with whatever you’re actually using.)

### 2. Wire it in your `build.zig`

Assuming you’re building an executable:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Pull in glfw-zig dependency.
    const glfw_dep = b.dependency("glfw_zig", .{
        .target = target,
        .optimize = optimize,
    });

    // Public Zig façade module.
    const glfw_mod = b.createModule(.{
        .root_source_file = glfw_dep.path("src/glfw.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "my-app",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("glfw", glfw_mod);

    // Link against the vendored static GLFW C library built by glfw-zig.
    const glfw_lib = glfw_dep.artifact("glfw-zig");
    exe.linkLibrary(glfw_lib);

    b.installArtifact(exe);
}
```

Now inside your code you can:

```zig
const glfw = @import("glfw");
```

---

## Quick start

Minimal “Hello Window” using the Zig façade:

```zig
const std = @import("std");
const glfw = @import("glfw");

pub fn main() !void {
    // Initialize GLFW (idempotent; returns an error on failure).
    try glfw.init();
    defer glfw.terminate();

    const title = "glfw-zig example\x00"; // NUL-terminated!
    const window = try glfw.createWindow(800, 600, title, null, null);
    defer glfw.destroyWindow(window);

    // Make OpenGL context current (if you’re using GL).
    glfw.makeContextCurrent(window);
    // Enable vsync.
    glfw.swapInterval(1);

    while (!glfw.windowShouldClose(window)) {
        // TODO: issue GL / Vulkan / whatever draws here.

        glfw.swapBuffers(window);
        glfw.pollEvents();
    }
}
```

You can also run the bundled sample in this repo:

```bash
zig build run
```

(on platforms where creating a window is allowed / supported.)

---

## API overview

Everything below is available through:

```zig
const glfw = @import("glfw");
```

### Raw C API

```zig
const c = glfw.c; // `@cImport("GLFW/glfw3.h")` namespace
```

If you ever need the exact C names or constants, use `glfw.c.*`.

---

### Initialization, errors, platform

- `try glfw.init();`
- `glfw.terminate();`
- `glfw.initHint(hint: c_int, value: c_int)`: set init hints before `init`.
- `glfw.rawMouseMotionSupported() bool`

Error & version:

- `const err = glfw.getLastError();` → `?ErrorInfo`
- `glfw.ErrorCode` / `glfw.ErrorInfo` / `glfw.GlfwError`
- `glfw.getVersion() struct { major, minor, rev: c_int }`
- `glfw.getVersionString() [:0]const u8`
- `glfw.getVersionStruct() Version`

Platform & timers:

- `glfw.Platform` enum
- `glfw.getPlatform() Platform`
- `glfw.platformSupported(platform: Platform) bool`
- `glfw.getTime() f64`, `glfw.setTime(t: f64) void`
- `glfw.getTimerValue() u64`
- `glfw.getTimerFrequency() u64`

---

### Window lifecycle, loop & input

Handles:

- `glfw.Window`, `glfw.Cursor`, `glfw.Monitor`

Creation:

- `glfw.createWindow(width, height: i32, title: [*:0]const u8, monitor: ?*Monitor, share: ?*Window) GlfwError!*Window`
- `glfw.destroyWindow(window: *Window)`

Loop & input:

- `glfw.windowShouldClose(window: *Window) bool`
- `glfw.setWindowShouldClose(window: *Window, value: bool) void`
- `glfw.pollEvents()`
- `glfw.waitEventsTimeout(timeout_seconds: f64)`
- `glfw.postEmptyEvent()`
- `glfw.swapInterval(interval: c_int)`
- `glfw.swapBuffers(window: *Window)`

Key and mouse:

- `glfw.getKey(window: *Window, key: c_int) c_int`
- `glfw.getMouseButton(window: *Window, button: c_int) c_int`
- `glfw.getKeyScancode(key: c_int) c_int`
- `glfw.getKeyName(key: c_int, scancode: c_int) ?[:0]const u8`

Cursor & clipboard:

- `glfw.getCursorPos(window: *Window) struct { x: f64, y: f64 }`
- `glfw.setCursorPos(window: *Window, x: f64, y: f64)`
- `glfw.setInputMode(window: *Window, mode: c_int, value: c_int)`
- `glfw.getInputMode(window: *Window, mode: c_int) c_int`
- `glfw.createStandardCursor(shape: c_int) ?*Cursor`
- `glfw.setCursor(window: *Window, cursor: ?*Cursor)`
- `glfw.destroyCursor(cursor: *Cursor)`
- `glfw.setClipboardString(window: *Window, string: [:0]const u8)`
- `glfw.getClipboardString(window: *Window) ?[:0]const u8`

---

### Window geometry & state

Types:

- `glfw.WindowPos  { x: i32, y: i32 }`
- `glfw.WindowSize { width: i32, height: i32 }`
- `glfw.FramebufferSize { width: i32, height: i32 }`
- `glfw.FrameSize { left, top, right, bottom: i32 }`
- `glfw.ContentScale { x, y: f32 }`

Geometry:

- `glfw.getWindowPos(window) WindowPos`
- `glfw.setWindowPos(window, x, y)`
- `glfw.getWindowSize(window) WindowSize`
- `glfw.setWindowSize(window, width, height)`
- `glfw.setWindowSizeLimits(window, min_w, min_h, max_w, max_h)`
- `glfw.setWindowAspectRatio(window, numer, denom)`
- `glfw.getFramebufferSize(window) FramebufferSize`
- `glfw.getWindowFrameSize(window) FrameSize`
- `glfw.getWindowContentScale(window) ContentScale`

State:

- `glfw.showWindow(window)`
- `glfw.hideWindow(window)`
- `glfw.iconifyWindow(window)`
- `glfw.restoreWindow(window)`
- `glfw.maximizeWindow(window)`
- `glfw.focusWindow(window)`
- `glfw.requestWindowAttention(window)`
- `glfw.setWindowTitle(window, title: [:0]const u8)`

Boolean state helpers:

- `glfw.isVisible(window) bool`
- `glfw.isIconified(window) bool`
- `glfw.isMaximized(window) bool`
- `glfw.isFocused(window) bool`
- `glfw.isHovered(window) bool`

Monitor binding:

- `glfw.getWindowMonitor(window) ?*Monitor`
- `glfw.setWindowMonitor(window, monitor, xpos, ypos, width, height, refresh_rate)`

Opacity & user pointer:

- `glfw.getWindowOpacity(window) f32`
- `glfw.setWindowOpacity(window, opacity: f32)`
- `glfw.setWindowUserPointer(window, ptr: ?*anyopaque)`
- `glfw.getWindowUserPointer(window) ?*anyopaque`

---

### Monitors

Types:

- `glfw.VideoMode`
- `glfw.MonitorPos`
- `glfw.MonitorWorkarea`
- `glfw.MonitorPhysicalSize`
- `glfw.MonitorContentScale`

API:

- `glfw.getPrimaryMonitor() ?*Monitor`
- `glfw.getMonitors(allocator) ![]*Monitor`
- `glfw.getVideoMode(monitor) ?VideoMode`
- `glfw.getVideoModes(allocator, monitor) ![]VideoMode`
- `glfw.getMonitorName(monitor) ?[:0]const u8`
- `glfw.getMonitorPos(monitor) MonitorPos`
- `glfw.getMonitorWorkarea(monitor) MonitorWorkarea`
- `glfw.getMonitorPhysicalSize(monitor) MonitorPhysicalSize`
- `glfw.getMonitorContentScale(monitor) MonitorContentScale`
- `glfw.setMonitorUserPointer(monitor, ptr: ?*anyopaque)`
- `glfw.getMonitorUserPointer(monitor) ?*anyopaque`
- `glfw.setGamma(monitor, gamma: f32)`

---

### Context API (OpenGL / EGL / OSMesa)

- `glfw.GlProc = *const anyopaque`
- `glfw.makeContextCurrent(window: ?*Window)`
- `glfw.getCurrentContext() ?*Window`
- `glfw.getProcAddress(name: [:0]const u8) GlProc`

---

### Vulkan helpers

**Important:** These helpers are **agnostic** of any particular Vulkan Zig binding. Handles are modeled as `?*anyopaque`, and proc pointers use GLFW’s `GLFWvkproc`.

- `glfw.vulkanSupported() bool`
- `glfw.getRequiredInstanceExtensions(allocator: std.mem.Allocator) !?[][:0]const u8`
- `glfw.getInstanceProcAddress(instance: ?*anyopaque, name: [:0]const u8) VkProc`
- `glfw.getPhysicalDevicePresentationSupport(instance, physical_device: ?*anyopaque, queue_family_index: u32) bool`

You’re expected to cast opaque pointers to your Vulkan binding’s handle types.

---

### Joystick / gamepad

Types:

- `glfw.JoystickId` (alias of `c_int`)
- `glfw.GamepadState`
- `glfw.MaxGamepadAxes`
- `glfw.MaxGamepadButtons`
- `glfw.JoystickCallback` (GLFW callback function type)

API:

- `glfw.joystickPresent(id: JoystickId) bool`
- `glfw.getJoystickAxes(id) ?[]const f32`
- `glfw.getJoystickButtons(id) ?[]const u8`
- `glfw.getJoystickHats(id) ?[]const u8`
- `glfw.getJoystickName(id) ?[:0]const u8`
- `glfw.getJoystickGUID(id) ?[:0]const u8`
- `glfw.setJoystickUserPointer(id, ptr: ?*anyopaque)`
- `glfw.getJoystickUserPointer(id) ?*anyopaque`
- `glfw.joystickIsGamepad(id) bool`
- `glfw.getGamepadName(id) ?[:0]const u8`
- `glfw.getGamepadState(id) ?GamepadState`
- `glfw.updateGamepadMappings(mappings: [:0]const u8) c_int`
- `glfw.setJoystickCallback(cb: JoystickCallback) JoystickCallback`

---

### Callbacks

Error callback:

- `glfw.ErrorCallback`  
- `glfw.setErrorCallback(cb: ?ErrorCallback) ?ErrorCallback`

Window & input callbacks:

- `glfw.WindowPosCallback`
- `glfw.WindowSizeCallback`
- `glfw.WindowCloseCallback`
- `glfw.WindowRefreshCallback`
- `glfw.WindowFocusCallback`
- `glfw.WindowIconifyCallback`
- `glfw.WindowMaximizeCallback`
- `glfw.FramebufferSizeCallback`
- `glfw.WindowContentScaleCallback`
- `glfw.MouseButtonCallback`
- `glfw.CursorPosCallback`
- `glfw.CursorEnterCallback`
- `glfw.ScrollCallback`
- `glfw.KeyCallback`
- `glfw.CharCallback`
- `glfw.CharModsCallback`
- `glfw.DropCallback`

Setters (each returns the previously installed callback):

- `glfw.setWindowPosCallback(window, cb)`
- `glfw.setWindowSizeCallback(window, cb)`
- `glfw.setWindowCloseCallback(window, cb)`
- `glfw.setWindowRefreshCallback(window, cb)`
- `glfw.setWindowFocusCallback(window, cb)`
- `glfw.setWindowIconifyCallback(window, cb)`
- `glfw.setWindowMaximizeCallback(window, cb)`
- `glfw.setFramebufferSizeCallback(window, cb)`
- `glfw.setWindowContentScaleCallback(window, cb)`
- `glfw.setMouseButtonCallback(window, cb)`
- `glfw.setCursorPosCallback(window, cb)`
- `glfw.setCursorEnterCallback(window, cb)`
- `glfw.setScrollCallback(window, cb)`
- `glfw.setKeyCallback(window, cb)`
- `glfw.setCharCallback(window, cb)`
- `glfw.setCharModsCallback(window, cb)`
- `glfw.setDropCallback(window, cb)`

---

### Native platform handles

Currently:

- **Windows:** `glfw.getWin32Window(window: *Window) ?*anyopaque` (HWND)  
  Returns `null` on non-Windows platforms.

Other native handles (X11/Wayland/Cocoa-specific) can be added later in the same style, without contaminating the core façade.

---

## Error handling model

- Functions that can **fail due to environment or config** (e.g. `init`, `createWindow`, Vulkan helpers that allocate memory) return `GlfwError!T`.
- Functions that are “query-style” follow GLFW’s patterns:
  - Boolean predicates return `bool`.
  - Handles return `?*T` or `?Slice`.
- For more detailed error info, call `glfw.getLastError()`; you’ll get an `ErrorInfo` with code + optional message.

---

## Tests & development

Inside this repo:

- `zig build`  
  Runs **all** test suites (unit + conformance + integration + e2e).

Individual steps:

- `zig build test-unit`
- `zig build test-conformance`
- `zig build test-integration`
- `zig build test-e2e`
- `zig build run` – run the bundled sample (`src/sample.zig`).

Test layout:

- Inline unit tests live in each `src/glfw/*.zig`.
- `tests/`
  - `conformance/` – API surface + semantics checks.
  - `integration/` – small end-to-end sequences (event loops, lifecycle).
  - `e2e/` – “does this feel like a real app would use it?” flows.

---

## Licensing

This project is **deliberately license-free** in the spirit of SQLite.

- There is no `LICENSE` file.
- You may **use, copy, modify, and redistribute** this code, in source or binary form, for **any purpose** (including commercial) **without asking for permission**.
- Attribution is **appreciated but not required**.
- The code is provided **“as is”**, with **no warranty of any kind** and **no liability** for any damages that may arise from its use.

In practice: treat this as **public-domain-like software** — do whatever you want with it, just don’t expect support, guarantees, or legal backing from the author.
