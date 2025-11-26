const c_bindings = @import("c_bindings");
const core = @import("core");
const window = @import("window");
const monitor = @import("monitor");
const vulkan = @import("vulkan");
const joystick = @import("joystick");

pub const c = c_bindings.c;

// ─────────────────────────────────────────────────────────────────────────────
// Handle types (opaque GLFW objects)
// ─────────────────────────────────────────────────────────────────────────────

pub const Window = c_bindings.Window;
pub const Monitor = c_bindings.Monitor;
pub const Cursor = c_bindings.Cursor;

// Common key/action helpers
pub const KeyEscape = c.GLFW_KEY_ESCAPE;
pub const Press = c.GLFW_PRESS;
pub const Release = c.GLFW_RELEASE;

// ─────────────────────────────────────────────────────────────────────────────
// Error domain
// ─────────────────────────────────────────────────────────────────────────────

pub const GlfwError = core.GlfwError;
pub const ErrorInfo = core.ErrorInfo;
pub const ErrorCode = core.ErrorCode;
pub const errorCodeFromC = core.errorCodeFromC;

// ─────────────────────────────────────────────────────────────────────────────
// Initialization / shutdown
// ─────────────────────────────────────────────────────────────────────────────

pub const init = core.init;
pub const terminate = core.terminate;

pub const initHint = core.initHint;
pub const rawMouseMotionSupported = core.rawMouseMotionSupported;

// ─────────────────────────────────────────────────────────────────────────────
// Version API
// ─────────────────────────────────────────────────────────────────────────────

pub const Version = core.Version;
pub const getVersion = core.getVersion;
pub const getVersionString = core.getVersionString;
pub const getVersionStruct = core.getVersionStruct;

// ─────────────────────────────────────────────────────────────────────────────
// Error query
// ─────────────────────────────────────────────────────────────────────────────

pub const getLastError = core.getLastError;

// ─────────────────────────────────────────────────────────────────────────────
// Platform API
// ─────────────────────────────────────────────────────────────────────────────

pub const Platform = core.Platform;
pub const getPlatform = core.getPlatform;
pub const platformSupported = core.platformSupported;

// ─────────────────────────────────────────────────────────────────────────────
// Time / timers
// ─────────────────────────────────────────────────────────────────────────────

pub const getTime = core.getTime;
pub const setTime = core.setTime;
pub const getTimerValue = core.getTimerValue;
pub const getTimerFrequency = core.getTimerFrequency;

// ─────────────────────────────────────────────────────────────────────────────
// Window API (lifecycle + loop)
// ─────────────────────────────────────────────────────────────────────────────

pub const createWindow = window.createWindow;
pub const destroyWindow = window.destroyWindow;
pub const windowShouldClose = window.windowShouldClose;
pub const setWindowShouldClose = window.setWindowShouldClose;

pub const getKey = window.getKey;
pub const pollEvents = window.pollEvents;
pub const waitEventsTimeout = window.waitEventsTimeout;
pub const postEmptyEvent = window.postEmptyEvent;
pub const swapInterval = window.swapInterval;
pub const swapBuffers = window.swapBuffers;
pub const getMouseButton = window.getMouseButton;
pub const getKeyName = window.getKeyName;
pub const getKeyScancode = window.getKeyScancode;

// ─────────────────────────────────────────────────────────────────────────────
// Window hints & attributes
// ─────────────────────────────────────────────────────────────────────────────

pub const defaultWindowHints = window.defaultWindowHints;
pub const windowHint = window.windowHint;
pub const windowHintString = window.windowHintString;
pub const getWindowAttrib = window.getWindowAttrib;
pub const setWindowAttrib = window.setWindowAttrib;

// ─────────────────────────────────────────────────────────────────────────────
// Cursor position / input modes / cursor objects / clipboard
// ─────────────────────────────────────────────────────────────────────────────

pub const getCursorPos = window.getCursorPos;
pub const setCursorPos = window.setCursorPos;

pub const setInputMode = window.setInputMode;
pub const getInputMode = window.getInputMode;

pub const setCursor = window.setCursor;
pub const createStandardCursor = window.createStandardCursor;
pub const destroyCursor = window.destroyCursor;

pub const setClipboardString = window.setClipboardString;
pub const getClipboardString = window.getClipboardString;

// ─────────────────────────────────────────────────────────────────────────────
// Context API (OpenGL/EGL/OSMesa) — lives in core.zig
// ─────────────────────────────────────────────────────────────────────────────

pub const GlProc = core.GlProc;
pub const makeContextCurrent = core.makeContextCurrent;
pub const getCurrentContext = core.getCurrentContext;
pub const getProcAddress = core.getProcAddress;

// ─────────────────────────────────────────────────────────────────────────────
// Monitor API
// ─────────────────────────────────────────────────────────────────────────────

pub const VideoMode = monitor.VideoMode;
pub const MonitorPos = monitor.MonitorPos;
pub const MonitorWorkarea = monitor.MonitorWorkarea;
pub const MonitorPhysicalSize = monitor.MonitorPhysicalSize;
pub const MonitorContentScale = monitor.MonitorContentScale;

pub const getPrimaryMonitor = monitor.getPrimaryMonitor;
pub const getMonitors = monitor.getMonitors;
pub const getVideoMode = monitor.getVideoMode;
pub const getVideoModes = monitor.getVideoModes;
pub const getMonitorName = monitor.getMonitorName;
pub const getMonitorPos = monitor.getMonitorPos;
pub const getMonitorWorkarea = monitor.getMonitorWorkarea;
pub const getMonitorPhysicalSize = monitor.getMonitorPhysicalSize;
pub const getMonitorContentScale = monitor.getMonitorContentScale;
pub const setMonitorUserPointer = monitor.setMonitorUserPointer;
pub const getMonitorUserPointer = monitor.getMonitorUserPointer;
pub const setGamma = monitor.setGamma;

// ─────────────────────────────────────────────────────────────────────────────
// Vulkan helpers
// ─────────────────────────────────────────────────────────────────────────────

pub const VkProc = vulkan.VkProc;
pub const vulkanSupported = vulkan.vulkanSupported;
pub const getRequiredInstanceExtensions = vulkan.getRequiredInstanceExtensions;
pub const getInstanceProcAddress = vulkan.getInstanceProcAddress;
pub const getPhysicalDevicePresentationSupport =
    vulkan.getPhysicalDevicePresentationSupport;

// ─────────────────────────────────────────────────────────────────────────────
// Native platform handles
// ─────────────────────────────────────────────────────────────────────────────

pub const getWin32Window = window.getWin32Window;

// ─────────────────────────────────────────────────────────────────────────────
// Window-related types
// ─────────────────────────────────────────────────────────────────────────────

pub const WindowPos = window.WindowPos;
pub const WindowSize = window.WindowSize;
pub const FramebufferSize = window.FramebufferSize;
pub const FrameSize = window.FrameSize;
pub const ContentScale = window.ContentScale;

// ─────────────────────────────────────────────────────────────────────────────
// Geometry
// ─────────────────────────────────────────────────────────────────────────────

pub const getWindowPos = window.getWindowPos;
pub const setWindowPos = window.setWindowPos;

pub const getWindowSize = window.getWindowSize;
pub const setWindowSize = window.setWindowSize;
pub const setWindowSizeLimits = window.setWindowSizeLimits;
pub const setWindowAspectRatio = window.setWindowAspectRatio;

pub const getFramebufferSize = window.getFramebufferSize;
pub const getWindowFrameSize = window.getWindowFrameSize;
pub const getWindowContentScale = window.getWindowContentScale;

// ─────────────────────────────────────────────────────────────────────────────
// State / visibility
// ─────────────────────────────────────────────────────────────────────────────

pub const showWindow = window.showWindow;
pub const hideWindow = window.hideWindow;
pub const iconifyWindow = window.iconifyWindow;
pub const restoreWindow = window.restoreWindow;
pub const maximizeWindow = window.maximizeWindow;
pub const focusWindow = window.focusWindow;
pub const requestWindowAttention = window.requestWindowAttention;
pub const setWindowTitle = window.setWindowTitle;

pub const isVisible = window.isVisible;
pub const isIconified = window.isIconified;
pub const isMaximized = window.isMaximized;
pub const isFocused = window.isFocused;
pub const isHovered = window.isHovered;

// ─────────────────────────────────────────────────────────────────────────────
// Monitor binding
// ─────────────────────────────────────────────────────────────────────────────

pub const getWindowMonitor = window.getWindowMonitor;
pub const setWindowMonitor = window.setWindowMonitor;

// ─────────────────────────────────────────────────────────────────────────────
// Opacity & user pointer
// ─────────────────────────────────────────────────────────────────────────────

pub const getWindowOpacity = window.getWindowOpacity;
pub const setWindowOpacity = window.setWindowOpacity;
pub const setWindowUserPointer = window.setWindowUserPointer;
pub const getWindowUserPointer = window.getWindowUserPointer;

// ─────────────────────────────────────────────────────────────────────────────
// Joystick / gamepad API
// ─────────────────────────────────────────────────────────────────────────────

pub const JoystickId = joystick.JoystickId;
pub const MaxGamepadAxes = joystick.MaxGamepadAxes;
pub const MaxGamepadButtons = joystick.MaxGamepadButtons;
pub const GamepadState = joystick.GamepadState;
pub const JoystickCallback = joystick.JoystickCallback;

pub const joystickPresent = joystick.joystickPresent;
pub const getJoystickName = joystick.getJoystickName;
pub const getJoystickGUID = joystick.getJoystickGUID;

pub const getJoystickAxes = joystick.getJoystickAxes;
pub const getJoystickButtons = joystick.getJoystickButtons;
pub const getJoystickHats = joystick.getJoystickHats;

pub const setJoystickUserPointer = joystick.setJoystickUserPointer;
pub const getJoystickUserPointer = joystick.getJoystickUserPointer;

pub const joystickIsGamepad = joystick.joystickIsGamepad;
pub const getGamepadName = joystick.getGamepadName;
pub const getGamepadState = joystick.getGamepadState;
pub const updateGamepadMappings = joystick.updateGamepadMappings;

pub const setJoystickCallback = joystick.setJoystickCallback;
