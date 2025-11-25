const glfw = @import("glfw");

test "conformance: public API surface compiles" {
    // Functions must be present and callable.
    _ = glfw.init;
    _ = glfw.terminate;
    _ = glfw.getVersion;
    _ = glfw.getVersionString;
    _ = glfw.getVersionStruct;
    _ = glfw.getLastError;
    _ = glfw.createWindow;
    _ = glfw.destroyWindow;
    _ = glfw.windowShouldClose;
    _ = glfw.setWindowShouldClose;
    _ = glfw.getKey;
    _ = glfw.pollEvents;
    _ = glfw.swapInterval;
    _ = glfw.getCursorPos;
    _ = glfw.setCursorPos;

    // NEW:
    _ = glfw.setInputMode;
    _ = glfw.getInputMode;
    _ = glfw.setCursor;
    _ = glfw.createStandardCursor;
    _ = glfw.destroyCursor;
    _ = glfw.setClipboardString;
    _ = glfw.getClipboardString;

    // Types must exist.
    _ = glfw.Window;
    _ = glfw.Monitor;
    _ = glfw.Cursor;

    // Constants must exist.
    _ = glfw.KeyEscape;
    _ = glfw.Press;
    _ = glfw.Release;
}
