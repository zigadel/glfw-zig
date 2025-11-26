const c_bindings = @import("c_bindings");
const core = @import("core");
const window = @import("window");
const monitor = @import("monitor");
const vulkan = @import("vulkan");
const context = @import("context");

pub const c = c_bindings.c;

// Handle types (opaque GLFW objects)
pub const Window = c_bindings.Window;
pub const Monitor = c_bindings.Monitor;
pub const Cursor = c_bindings.Cursor;

// Common key/action helpers
pub const KeyEscape = c.GLFW_KEY_ESCAPE;
pub const Press = c.GLFW_PRESS;
pub const Release = c.GLFW_RELEASE;

// Error domain
pub const GlfwError = core.GlfwError;
pub const ErrorInfo = core.ErrorInfo;
pub const ErrorCode = core.ErrorCode;
pub const errorCodeFromC = core.errorCodeFromC;

// Initialization / shutdown
pub const init = core.init;
pub const terminate = core.terminate;

// Version API
pub const Version = core.Version;
pub const getVersion = core.getVersion;
pub const getVersionString = core.getVersionString;
pub const getVersionStruct = core.getVersionStruct;

// Error query
pub const getLastError = core.getLastError;

// Platform API
pub const Platform = core.Platform;
pub const getPlatform = core.getPlatform;
pub const platformSupported = core.platformSupported;

// Time / timers
pub const getTime = core.getTime;
pub const setTime = core.setTime;
pub const getTimerValue = core.getTimerValue;
pub const getTimerFrequency = core.getTimerFrequency;

// Window API
pub const createWindow = window.createWindow;
pub const destroyWindow = window.destroyWindow;
pub const windowShouldClose = window.windowShouldClose;
pub const setWindowShouldClose = window.setWindowShouldClose;
pub const getKey = window.getKey;
pub const pollEvents = window.pollEvents;
pub const waitEventsTimeout = window.waitEventsTimeout;
pub const postEmptyEvent = window.postEmptyEvent;
pub const swapInterval = window.swapInterval;

// Window hints & attributes
pub const defaultWindowHints = window.defaultWindowHints;
pub const windowHint = window.windowHint;
pub const windowHintString = window.windowHintString;
pub const getWindowAttrib = window.getWindowAttrib;
pub const setWindowAttrib = window.setWindowAttrib;

// Swap buffers
pub const swapBuffers = window.swapBuffers;

// Cursor position
pub const getCursorPos = window.getCursorPos;
pub const setCursorPos = window.setCursorPos;

// Input modes (cursor, sticky keys, raw mouse, etc.)
pub const setInputMode = window.setInputMode;
pub const getInputMode = window.getInputMode;

// Cursor objects
pub const setCursor = window.setCursor;
pub const createStandardCursor = window.createStandardCursor;
pub const destroyCursor = window.destroyCursor;

// Clipboard
pub const setClipboardString = window.setClipboardString;
pub const getClipboardString = window.getClipboardString;

// Context API (OpenGL/EGL/OSMesa)
pub const GlProc = context.GlProc;
pub const makeContextCurrent = context.makeContextCurrent;
pub const getCurrentContext = context.getCurrentContext;
pub const getProcAddress = context.getProcAddress;

// Monitor API
pub const VideoMode = monitor.VideoMode;
pub const getPrimaryMonitor = monitor.getPrimaryMonitor;
pub const getMonitors = monitor.getMonitors;
pub const getVideoMode = monitor.getVideoMode;
pub const getVideoModes = monitor.getVideoModes;
pub const getMonitorName = monitor.getMonitorName;

// Vulkan helpers
pub const vulkanSupported = vulkan.vulkanSupported;
pub const getRequiredInstanceExtensions = vulkan.getRequiredInstanceExtensions;

// Native platform handle(s)
pub const getWin32Window = c_bindings.getWin32Window;

// Types
pub const WindowPos = window.WindowPos;
pub const WindowSize = window.WindowSize;
pub const FramebufferSize = window.FramebufferSize;
pub const FrameSize = window.FrameSize;
pub const ContentScale = window.ContentScale;

// Geometry
pub const getWindowPos = window.getWindowPos;
pub const setWindowPos = window.setWindowPos;
pub const getWindowSize = window.getWindowSize;
pub const setWindowSize = window.setWindowSize;
pub const setWindowSizeLimits = window.setWindowSizeLimits;
pub const setWindowAspectRatio = window.setWindowAspectRatio;
pub const getFramebufferSize = window.getFramebufferSize;
pub const getWindowFrameSize = window.getWindowFrameSize;
pub const getWindowContentScale = window.getWindowContentScale;

// State / visibility
pub const showWindow = window.showWindow;
pub const hideWindow = window.hideWindow;
pub const iconifyWindow = window.iconifyWindow;
pub const restoreWindow = window.restoreWindow;
pub const maximizeWindow = window.maximizeWindow;
pub const focusWindow = window.focusWindow;
pub const requestWindowAttention = window.requestWindowAttention;
pub const setWindowTitle = window.setWindowTitle;

// Monitor binding
pub const getWindowMonitor = window.getWindowMonitor;
pub const setWindowMonitor = window.setWindowMonitor;

// Opacity & user pointer
pub const getWindowOpacity = window.getWindowOpacity;
pub const setWindowOpacity = window.setWindowOpacity;
pub const setWindowUserPointer = window.setWindowUserPointer;
pub const getWindowUserPointer = window.getWindowUserPointer;
