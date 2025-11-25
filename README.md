# zglfw — Thin Zig Wrapper for GLFW 3.4

`zglfw` is a **thin, idiomatic Zig wrapper** around the C GLFW library (3.4).  
It keeps the **full power of GLFW** while giving you:

- Zig-style types and error sets
- Vendored C sources via `build.zig.zon` (no system GLFW required)
- A clean test pyramid (unit + conformance + integration + e2e)
- A simple `sample.zig` you can use as a starting point

The goal is a **“forever good”** building block for graphics / game engines:
Zig nightly, full GLFW access, and future-ready for Vulkan, OpenXR, and WebGPU.

---

## Status

- ✅ Vendored GLFW 3.4 C sources (fetched via `build.zig.zon` as `glfw-c`)
- ✅ Windows (Win32 + WGL) backend wired and working
- ✅ Thin wrapper in `src/glfw.zig` with:
  - `init/terminate`
  - version helpers
  - window lifecycle
  - key input, cursor position, event pump
  - structured error reporting (`getLastError`)
- ✅ Inline unit tests inside `src/glfw.zig`
- ✅ Test suites:
  - Conformance (`tests/conformance/*`)
  - Integration (`tests/integration/*`)
  - End-to-end (`tests/e2e/*`)
- ✅ `src/sample.zig` that opens a window and handles `ESC` to quit

Planned (scaffolding already reflected in the directory layout):

- 🔶 More wrapper modules (`monitor`, `input`, `time`, `vulkan`, `openxr`, etc.)
- 🔶 Vulkan and OpenXR examples (using `vulkan-zig` and `openxr-zig`)
- 🔶 Linux / macOS backends (X11/Wayland, Cocoa)
- 🔶 Higher-level “App/Context” helper around init/terminate + main loop

---

## Requirements

- **Zig**: nightly `0.16.0-dev` (tested with `0.16.0-dev.1399+7b325e08c`)
- A working C toolchain (e.g. MSVC/clang on Windows)
- On Windows: typical system libs are linked automatically:
  - `user32`, `gdi32`, `shell32`, `advapi32`, `winmm`

You do *not* need a system-installed GLFW; the C sources are pulled from GitHub and built as part of the Zig build.

---

## Directory Layout

Current + planned structure (abridged):

```txt
glfw-zig-wrapper/
|   build.zig
|   build.zig.zon
|   README.md
|   .gitignore
|   .gitattributes
|
+---src/
|   glfw.zig          # main wrapper facade; re-exports cimport + safe helpers + inline tests
|   sample.zig        # "Hello Window" demo; used by `zig build run`
|   # [future]
|   # context.zig     # App/Context wrapper (init/terminate + main loop)
|   # monitor.zig     # monitors, video modes, gamma ramps
|   # input.zig       # key/mouse/gamepad helpers, callback wiring
|   # time.zig        # glfwGetTime / timers
|   # vulkan.zig      # helpers for vulkan-zig (surface creation, extensions)
|   # openxr.zig      # helpers for openxr-zig in combination with GLFW
|
+---tests/
|   test_all_conformance.zig   # aggregator: pulls tests/conformance/*.zig
|   test_all_integration.zig   # aggregator: pulls tests/integration/*.zig
|   test_all_e2e.zig           # aggregator: pulls tests/e2e/*.zig
|
|   +---conformance/
|   |   api_surface.zig        # public API presence / types / constants
|   |   version.zig            # version helpers consistency
|   |   error_safety.zig       # getLastError safety before/after init/terminate
|   |   init_terminate.zig     # (optional) extra init/terminate checks
|   |   window_lifecycle.zig   # (optional) extra lifecycle checks
|   |
|   +---integration/
|   |   window_lifecycle.zig   # init → create window → flags → pollEvents → teardown
|   |   event_loop_basic.zig   # minimal loop semantics, ESC handling, etc.
|   |
|   +---e2e/
|       minimal_loop.zig       # smoke test: create window + a few event iterations
|       window_open_close.zig  # open window, toggle shouldClose, clean teardown
|
# [future]
# +---examples/
# |   triangle_vulkan.zig      # glfw + vulkan-zig: basic triangle
# |   cube_openxr.zig          # glfw + vulkan-zig + openxr-zig: minimal VR scene
```

## Building & Running (Standalone)

If you clone this repo directly:

```bash
# Build the library + tests
zig build

# Run all tests (inline + conformance + integration + e2e)
zig build test

# Run the sample "Hello Window" executable
zig build run
```

On success, you should see output similar to:

```txt
GLFW version: 3.4.0 (3.4.0 Win32 WGL Null EGL OSMesa MinGW-w64)
Sample finished cleanly.
```

…and an actual GLFW window that closes when you press ESC.

## Using zglfw in Your Own Project

### 1. Add as a dependency (Zon)

In your project’s `build.zig.zon`, add a dependency pointing to this repo (URL/hash are examples):

```zig
.{
    .name = "my-project",
    .version = "0.1.0",
    .dependencies = .{
        .zglfw = .{
            .url = "https://github.com/<you-or-org>/glfw-zig-wrapper/archive/refs/tags/v0.1.0.tar.gz",
            .hash = "<replace-with-zon-hash>",
        },
    },
}
```

### 2. Wire the module in build.zig

In your `build.zig`, pull in the dependency and import the `glfw` module for your executable:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Dependency on zglfw
    const zglfw_dep = b.dependency("zglfw", .{
        .target = target,
        .optimize = optimize,
    });

    // Depending on how zglfw is exported, you have two common options:
    //
    // (A) The "wrapper as module" style (recommended long-term):
    // const glfw_mod = zglfw_dep.module("glfw");
    //
    // (B) The "addImport" style (same pattern this repo uses for src/sample.zig):
    const glfw_mod = b.createModule(.{
        .root_source_file = zglfw_dep.path("src/glfw.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("glfw", glfw_mod);

    const exe = b.addExecutable(.{
        .name = "my-app",
        .root_module = exe_mod,
    });

    // Link the vendored GLFW C lib from zglfw
    const glfw_c_lib = zglfw_dep.artifact("glfw_c") catch
        @panic("zglfw must expose a 'glfw_c' static library artifact");
    exe.linkLibrary(glfw_c_lib);

    b.installArtifact(exe);
}
```

> **Note**: The packaging/export story may evolve slightly as Zig’s build system stabilizes. The intent is that eventually you can treat `zglfw` as a normal Zig module (`zglfw_dep.module("glfw")`) without having to know about its internal layout.

### 3. Use it from Zig

In your app’s `src/main.zig`:

```zig
const std = @import("std");
const glfw = @import("glfw");

pub fn main() void {
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

    if (glfw.init()) |_| {} else |_| {
        std.debug.print("glfw.init() failed\n", .{});
        return;
    }
    defer glfw.terminate();

    const title = "My App\x00";
    const window = glfw.createWindow(800, 600, title, null, null) catch {
        std.debug.print("createWindow() failed\n", .{});
        return;
    };
    defer glfw.destroyWindow(window);

    while (!glfw.windowShouldClose(window)) {
        if (glfw.getKey(window, glfw.KeyEscape) == glfw.Press) {
            glfw.setWindowShouldClose(window, true);
        }
        glfw.pollEvents();
    }
}
```

## Design Notes

**Vendored C via Zon**

- build.zig.zon fetches the official GLFW 3.4 release tarball and compiles:

    - Common sources: `context.c`, `init.c`, `input.c`, `monitor.c`, platform.c, vulkan.c, window.c, and null backends.
  - Windows-specific sources: `win32_*.c`, `wgl_context.c`, with `_GLFW_WIN32`, `UNICODE`, `_UNICODE` defined.

**Thin wrapper, not a rewrite**

`src/glfw.zig` is intentionally close to the C API, adding:

- Zig error sets (GlfwError) for common failures
- A safe getLastError() that translates glfwGetError + description into a Zig struct
- Tiny convenience helpers (e.g. getVersionStruct)

**Test strategy**

- Inline test blocks inside src/glfw.zig for unit-level guarantees.

- `tests/test_all_*.zig` aggregator roots:

  - `tests/conformance/*` — API surface + version + error safety contracts

  - `tests/integration/*` — window lifecycle & basic event loop semantics

  - `tests/e2e/*` — “real” usage scenarios (minimal loops, open/close flows)

This mirrors the pattern used in larger Zigadel projects (like ZTable) but scaled to the size of this library.

## Roadmap

Planned future work:

**Platform support**

- Linux (X11 / Wayland)

- macOS (Cocoa)

**More wrapper surface**

- Monitors, video modes, gamma

- Input callbacks, joystick/gamepad, cursor modes

- Timing (glfwGetTime, timers)

**Interop helpers**

- Vulkan integration (vulkan-zig): instance extensions, surface creation from Window

- OpenXR integration (openxr-zig): using GLFW-created windows as XR composition targets

**Examples**

- Triangle (GL/Vulkan)

- Simple VR scene (OpenXR)

- UI integration (ImGui, etc.)