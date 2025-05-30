import AppKit
import ScreenCaptureKit

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var mainWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainWindow()
        checkScreenCapturePermission()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Window Setup
    
    private func setupMainWindow() {
        let contentRect = NSRect(x: 0, y: 0, width: 480, height: 320)
        
        mainWindow = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        mainWindow?.title = "Magnify"
        mainWindow?.center()
        mainWindow?.makeKeyAndOrderFront(nil)
        
        // Set up basic content view
        let contentView = NSView(frame: contentRect)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        mainWindow?.contentView = contentView
        
        // Add a simple label for now
        let label = NSTextField(labelWithString: "Magnify - Screen Annotation Tool")
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 16)
        label.frame = NSRect(x: 50, y: 150, width: 380, height: 30)
        contentView.addSubview(label)
    }
    
    // MARK: - Screen Capture Permission
    
    private func checkScreenCapturePermission() {
        if #available(macOS 12.3, *) {
            Task {
                do {
                    // Request permission for screen capture
                    let isAuthorized = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                    
                    DispatchQueue.main.async {
                        if isAuthorized.displays.isEmpty {
                            self.showPermissionAlert()
                        } else {
                            print("Screen capture permission granted")
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.showPermissionAlert()
                    }
                }
            }
        } else {
            // Fallback for older macOS versions
            showPermissionAlert()
        }
    }
    
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "Magnify needs screen recording permission to capture and annotate your screen. Please grant permission in System Preferences > Privacy & Security > Screen Recording."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Preferences
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
        }
    }
} 