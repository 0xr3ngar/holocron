import AppKit

// Custom window class to ensure it can receive keyboard input
class InputReadyWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
}

