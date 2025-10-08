import AppKit
import SwiftUI
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var eventMonitor: Any?
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "AI Chat")
            button.action = #selector(statusItemClicked)
        }
        
        let window = InputReadyWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 550),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hasShadow = true
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.contentView = NSHostingView(rootView: ContentView(windowManager: WindowManager(window: window)))
        
        self.window = window
        registerGlobalHotkey()
    }
    
    @objc func statusItemClicked() {
        toggleWindow()
    }
    
    func registerGlobalHotkey() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if modifiers == [.option, .command] && event.keyCode == 49 {
                DispatchQueue.main.async {
                    self.toggleWindow()
                }
            }
        }
    }
    
    func toggleWindow() {
        guard let window = window else { return }
        
        if window.isVisible {
            window.orderOut(nil)
        } else {
            centerWindow()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func centerWindow() {
        guard let window = window, let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame
        let x = screenFrame.midX - windowFrame.width / 2
        let y = screenFrame.midY - windowFrame.height / 2 + 80
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

