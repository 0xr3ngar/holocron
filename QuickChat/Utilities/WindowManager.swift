import AppKit
import SwiftUI

class WindowManager: ObservableObject {
    let window: NSWindow
    
    init(window: NSWindow) {
        self.window = window
    }
    
    func hide() {
        window.orderOut(nil)
    }
}

