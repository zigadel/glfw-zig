const std = @import("std");

const GlfwCBuild = struct {
    lib: *std.Build.Step.Compile,
    include_dir: std.Build.LazyPath,
};

fn addCommonSources(
    glfw_c: *std.Build.Step.Compile,
    glfw_dep: *std.Build.Dependency,
    flags: []const []const u8,
) void {
    const common_rel = [_][]const u8{
        "src/context.c",
        "src/init.c",
        "src/input.c",
        "src/monitor.c",
        "src/platform.c",
        "src/vulkan.c",
        "src/window.c",
        "src/egl_context.c",
        "src/osmesa_context.c",
        "src/null_init.c",
        "src/null_monitor.c",
        "src/null_window.c",
        "src/null_joystick.c",
    };

    for (common_rel) |rel| {
        glfw_c.addCSourceFile(.{
            .file = glfw_dep.path(rel),
            .flags = flags,
        });
    }
}

fn buildGlfwCLib(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) GlfwCBuild {
    const os_tag = target.result.os.tag;

    // Fetch GLFW C source via Zon dependency "glfw-c".
    const glfw_dep = b.dependency("glfw-c", .{
        .target = target,
        .optimize = optimize,
    });

    const include_dir = glfw_dep.path("include");

    // C-only module + library for GLFW.
    const glfw_c_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });

    const glfw_c = b.addLibrary(.{
        .name = "glfw_c",
        .root_module = glfw_c_mod,
    });

    glfw_c.addIncludePath(include_dir);
    glfw_c.addIncludePath(glfw_dep.path("src"));

    switch (os_tag) {
        .windows => {
            const win_flags = &[_][]const u8{
                "-D_GLFW_WIN32",
                "-DUNICODE",
                "-D_UNICODE",
            };

            addCommonSources(glfw_c, glfw_dep, win_flags);

            const win_rel = [_][]const u8{
                "src/win32_init.c",
                "src/win32_joystick.c",
                "src/win32_module.c",
                "src/win32_monitor.c",
                "src/win32_time.c",
                "src/win32_thread.c",
                "src/win32_window.c",
                "src/wgl_context.c",
            };

            for (win_rel) |rel| {
                glfw_c.addCSourceFile(.{
                    .file = glfw_dep.path(rel),
                    .flags = win_flags,
                });
            }

            glfw_c.linkLibC();
            glfw_c.linkSystemLibrary("user32");
            glfw_c.linkSystemLibrary("gdi32");
            glfw_c.linkSystemLibrary("shell32");
            glfw_c.linkSystemLibrary("advapi32");
            glfw_c.linkSystemLibrary("winmm");
        },
        .linux => {
            // X11 backend by default (works fine via XWayland on Wayland setups).
            const linux_flags = &[_][]const u8{
                "-D_GLFW_X11",
            };

            addCommonSources(glfw_c, glfw_dep, linux_flags);

            const linux_rel = [_][]const u8{
                "src/x11_init.c",
                "src/x11_monitor.c",
                "src/x11_window.c",
                "src/xkb_unicode.c",
                "src/glx_context.c",
                "src/posix_time.c",
                "src/posix_thread.c",
                "src/posix_module.c",
                "src/posix_poll.c",
                "src/linux_joystick.c",
            };

            for (linux_rel) |rel| {
                glfw_c.addCSourceFile(.{
                    .file = glfw_dep.path(rel),
                    .flags = linux_flags,
                });
            }

            glfw_c.linkLibC();

            const linux_libs = [_][]const u8{
                "X11",
                "Xrandr",
                "Xinerama",
                "Xcursor",
                "Xi",
                "Xxf86vm",
                "dl",
                "pthread",
                "m",
            };
            for (linux_libs) |name| {
                glfw_c.linkSystemLibrary(name);
            }
        },
        .macos => {
            const cocoa_flags = &[_][]const u8{
                "-D_GLFW_COCOA",
            };

            addCommonSources(glfw_c, glfw_dep, cocoa_flags);

            const cocoa_rel = [_][]const u8{
                "src/cocoa_init.c",
                "src/cocoa_monitor.c",
                "src/cocoa_window.c",
                "src/cocoa_joystick.c",
                "src/cocoa_time.c",
                "src/nsgl_context.c",
                "src/posix_thread.c",
                "src/posix_module.c",
            };

            for (cocoa_rel) |rel| {
                glfw_c.addCSourceFile(.{
                    .file = glfw_dep.path(rel),
                    .flags = cocoa_flags,
                });
            }

            glfw_c.linkLibC();
            glfw_c.linkFramework("Cocoa");
            glfw_c.linkFramework("IOKit");
            glfw_c.linkFramework("CoreFoundation");
            glfw_c.linkFramework("CoreVideo");
        },
        else => {
            @panic("glfw-zig: unsupported target OS for GLFW C backend (extend buildGlfwCLib as needed).");
        },
    }

    return .{
        .lib = glfw_c,
        .include_dir = include_dir,
    };
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 1) Build vendored GLFW C static lib + get its include dir.
    const glfw_c_build = buildGlfwCLib(b, target, optimize);
    const glfw_c = glfw_c_build.lib;
    const glfw_include = glfw_c_build.include_dir;

    // 2) Internal Zig modules (wired via named imports, Zigadel-style).
    const c_bindings_mod = b.createModule(.{
        .root_source_file = b.path("src/glfw/c_bindings.zig"),
        .target = target,
        .optimize = optimize,
    });
    // c_import lives here, so it needs the C include path.
    c_bindings_mod.addIncludePath(glfw_include);

    const core_mod = b.createModule(.{
        .root_source_file = b.path("src/glfw/core.zig"),
        .target = target,
        .optimize = optimize,
    });
    core_mod.addImport("c_bindings", c_bindings_mod);

    const window_mod = b.createModule(.{
        .root_source_file = b.path("src/glfw/window.zig"),
        .target = target,
        .optimize = optimize,
    });
    window_mod.addImport("c_bindings", c_bindings_mod);
    window_mod.addImport("core", core_mod);

    const context_mod = b.createModule(.{
        .root_source_file = b.path("src/glfw/context.zig"),
        .target = target,
        .optimize = optimize,
    });
    context_mod.addImport("c_bindings", c_bindings_mod);
    context_mod.addImport("core", core_mod);
    context_mod.addImport("window", window_mod);

    const monitor_mod = b.createModule(.{
        .root_source_file = b.path("src/glfw/monitor.zig"),
        .target = target,
        .optimize = optimize,
    });
    monitor_mod.addImport("c_bindings", c_bindings_mod);
    monitor_mod.addImport("core", core_mod);

    const joystick_mod = b.createModule(.{
        .root_source_file = b.path("src/glfw/joystick.zig"),
        .target = target,
        .optimize = optimize,
    });
    joystick_mod.addImport("c_bindings", c_bindings_mod);

    const vulkan_mod = b.createModule(.{
        .root_source_file = b.path("src/glfw/vulkan.zig"),
        .target = target,
        .optimize = optimize,
    });
    vulkan_mod.addImport("c_bindings", c_bindings_mod);

    // 3) Public façade module (what users import as @import("glfw")).
    const glfw_mod = b.createModule(.{
        .root_source_file = b.path("src/glfw.zig"),
        .target = target,
        .optimize = optimize,
    });
    glfw_mod.addIncludePath(glfw_include);
    glfw_mod.addImport("c_bindings", c_bindings_mod);
    glfw_mod.addImport("core", core_mod);
    glfw_mod.addImport("window", window_mod);
    glfw_mod.addImport("monitor", monitor_mod);
    glfw_mod.addImport("vulkan", vulkan_mod);
    glfw_mod.addImport("context", context_mod);
    glfw_mod.addImport("joystick", joystick_mod);

    // 4) Library artifact for the Zig wrapper: libglfw-zig.
    const lib = b.addLibrary(.{
        .name = "glfw-zig",
        .root_module = glfw_mod,
    });
    lib.linkLibrary(glfw_c);
    b.installArtifact(lib);

    // 5) Sample executable (src/sample.zig).
    const sample_mod = b.createModule(.{
        .root_source_file = b.path("src/sample.zig"),
        .target = target,
        .optimize = optimize,
    });
    sample_mod.addImport("glfw", glfw_mod);

    const exe = b.addExecutable(.{
        .name = "sample",
        .root_module = sample_mod,
    });
    exe.linkLibrary(glfw_c);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Run GLFW sample");
    run_step.dependOn(&run_cmd.step);

    // ─────────────────────────────────────────────────────────────────────
    // 6) Tests: unit (inline), conformance, integration, e2e
    // ─────────────────────────────────────────────────────────────────────

    // Unit tests: inline `test {}` blocks in src/glfw.zig + submodules.
    const unit_step = b.step("test-unit", "Run unit tests (glfw façade + submodules)");
    {
        const unit_tests = b.addTest(.{
            .root_module = glfw_mod,
        });
        unit_tests.linkLibrary(glfw_c);

        const run_unit = b.addRunArtifact(unit_tests);
        unit_step.dependOn(&run_unit.step);
    }

    // Conformance tests: tests/test_all_conformance.zig (optional)
    const conformance_step = b.step("test-conformance", "Run conformance tests");
    const have_conformance = blk: {
        _ = std.fs.cwd().statFile("tests/test_all_conformance.zig") catch break :blk false;
        break :blk true;
    };
    if (have_conformance) {
        const conf_mod = b.createModule(.{
            .root_source_file = b.path("tests/test_all_conformance.zig"),
            .target = target,
            .optimize = optimize,
        });
        conf_mod.addImport("glfw", glfw_mod);

        const conf_tests = b.addTest(.{
            .root_module = conf_mod,
        });
        conf_tests.linkLibrary(glfw_c);

        const conf_run = b.addRunArtifact(conf_tests);
        conformance_step.dependOn(&conf_run.step);
    }

    // Integration tests: tests/test_all_integration.zig (optional)
    const integration_step = b.step("test-integration", "Run integration tests");
    const have_integration = blk: {
        _ = std.fs.cwd().statFile("tests/test_all_integration.zig") catch break :blk false;
        break :blk true;
    };
    if (have_integration) {
        const integ_mod = b.createModule(.{
            .root_source_file = b.path("tests/test_all_integration.zig"),
            .target = target,
            .optimize = optimize,
        });
        integ_mod.addImport("glfw", glfw_mod);

        const integ_tests = b.addTest(.{
            .root_module = integ_mod,
        });
        integ_tests.linkLibrary(glfw_c);

        const integ_run = b.addRunArtifact(integ_tests);
        integration_step.dependOn(&integ_run.step);
    }

    // E2E tests: tests/test_all_e2e.zig (optional)
    const e2e_step = b.step("test-e2e", "Run end-to-end tests");
    const have_e2e = blk: {
        _ = std.fs.cwd().statFile("tests/test_all_e2e.zig") catch break :blk false;
        break :blk true;
    };
    if (have_e2e) {
        const e2e_mod = b.createModule(.{
            .root_source_file = b.path("tests/test_all_e2e.zig"),
            .target = target,
            .optimize = optimize,
        });
        e2e_mod.addImport("glfw", glfw_mod);

        const e2e_tests = b.addTest(.{
            .root_module = e2e_mod,
        });
        e2e_tests.linkLibrary(glfw_c);

        const e2e_run = b.addRunArtifact(e2e_tests);
        e2e_step.dependOn(&e2e_run.step);
    }

    // Aggregate step: run everything.
    const test_step = b.step(
        "test",
        "Run all GLFW test suites (unit + conformance + integration + e2e)",
    );
    test_step.dependOn(unit_step);
    test_step.dependOn(conformance_step);
    test_step.dependOn(integration_step);
    test_step.dependOn(e2e_step);

    // Make plain `zig build` run the full test suite by default.
    b.default_step = test_step;
}
