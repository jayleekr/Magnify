import AppKit
import ScreenCaptureKit

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var mainWindow: NSWindow?
    private let screenCaptureManager = ScreenCaptureManager()
    private var imageView: NSImageView?
    private var overlayWindow: OverlayWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainWindow()
        checkScreenCapturePermission()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Window Setup
    
    private func setupMainWindow() {
        let contentRect = NSRect(x: 0, y: 0, width: 600, height: 500)
        
        mainWindow = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        mainWindow?.title = "Magnify - Screen Capture Test"
        mainWindow?.center()
        mainWindow?.makeKeyAndOrderFront(nil)
        
        setupTestUI()
    }
    
    private func setupTestUI() {
        guard let window = mainWindow else { return }
        
        let contentView = NSView(frame: window.contentView?.bounds ?? NSRect.zero)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        window.contentView = contentView
        
        // Title label
        let titleLabel = NSTextField(labelWithString: "Magnify - ScreenCaptureKit Test")
        titleLabel.alignment = .center
        titleLabel.font = NSFont.boldSystemFont(ofSize: 18)
        titleLabel.frame = NSRect(x: 50, y: 440, width: 500, height: 30)
        contentView.addSubview(titleLabel)
        
        // Permission status label
        let permissionLabel = NSTextField(labelWithString: "Permission Status: Checking...")
        permissionLabel.alignment = .center
        permissionLabel.font = NSFont.systemFont(ofSize: 14)
        permissionLabel.frame = NSRect(x: 50, y: 410, width: 500, height: 20)
        permissionLabel.textColor = .secondaryLabelColor
        contentView.addSubview(permissionLabel)
        
        // Store reference for updates
        permissionLabel.identifier = NSUserInterfaceItemIdentifier("permissionLabel")
        
        // Capture button
        let captureButton = NSButton(frame: NSRect(x: 250, y: 370, width: 100, height: 30))
        captureButton.title = "Capture Screen"
        captureButton.bezelStyle = .rounded
        captureButton.target = self
        captureButton.action = #selector(captureButtonPressed)
        contentView.addSubview(captureButton)
        
        // Overlay test buttons
        let showOverlayButton = NSButton(frame: NSRect(x: 150, y: 330, width: 100, height: 30))
        showOverlayButton.title = "Show Overlay"
        showOverlayButton.bezelStyle = .rounded
        showOverlayButton.target = self
        showOverlayButton.action = #selector(showOverlayPressed)
        contentView.addSubview(showOverlayButton)
        
        let hideOverlayButton = NSButton(frame: NSRect(x: 260, y: 330, width: 100, height: 30))
        hideOverlayButton.title = "Hide Overlay"
        hideOverlayButton.bezelStyle = .rounded
        hideOverlayButton.target = self
        hideOverlayButton.action = #selector(hideOverlayPressed)
        contentView.addSubview(hideOverlayButton)
        
        let clearDrawingButton = NSButton(frame: NSRect(x: 370, y: 330, width: 100, height: 30))
        clearDrawingButton.title = "Clear Drawing"
        clearDrawingButton.bezelStyle = .rounded
        clearDrawingButton.target = self
        clearDrawingButton.action = #selector(clearDrawingPressed)
        contentView.addSubview(clearDrawingButton)
        
        // Image view for displaying captured screen
        let imageFrame = NSRect(x: 50, y: 50, width: 500, height: 300)
        imageView = NSImageView(frame: imageFrame)
        imageView?.imageScaling = .scaleProportionallyUpOrDown
        imageView?.wantsLayer = true
        imageView?.layer?.borderWidth = 1
        imageView?.layer?.borderColor = NSColor.separatorColor.cgColor
        imageView?.layer?.cornerRadius = 8
        
        // Placeholder image
        imageView?.image = createPlaceholderImage()
        
        if let imageView = imageView {
            contentView.addSubview(imageView)
        }
        
        // Instructions label
        let instructionsLabel = NSTextField(labelWithString: "Test screen capture and transparent overlay window with drawing capabilities")
        instructionsLabel.alignment = .center
        instructionsLabel.font = NSFont.systemFont(ofSize: 12)
        instructionsLabel.frame = NSRect(x: 50, y: 20, width: 500, height: 20)
        instructionsLabel.textColor = .tertiaryLabelColor
        contentView.addSubview(instructionsLabel)
    }
    
    private func createPlaceholderImage() -> NSImage {
        let size = NSSize(width: 400, height: 200)
        let image = NSImage(size: size)
        
        image.lockFocus()
        NSColor.controlBackgroundColor.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        let text = "Screen capture will appear here"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        
        let textSize = text.size(withAttributes: attributes)
        let textRect = NSRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        text.draw(in: textRect, withAttributes: attributes)
        image.unlockFocus()
        
        return image
    }
    
    // MARK: - Actions
    
    @objc private func captureButtonPressed() {
        Task {
            await captureScreen()
        }
    }
    
    private func captureScreen() async {
        // Update UI to show capturing state
        DispatchQueue.main.async {
            if let button = self.mainWindow?.contentView?.subviews.first(where: { $0 is NSButton }) as? NSButton {
                button.title = "Capturing..."
                button.isEnabled = false
            }
        }
        
        // Capture screen using ScreenCaptureManager
        let startTime = CFAbsoluteTimeGetCurrent()
        
        if let capturedImage = await screenCaptureManager.captureCurrentScreen() {
            let endTime = CFAbsoluteTimeGetCurrent()
            let captureTime = (endTime - startTime) * 1000 // Convert to milliseconds
            
            // Update UI with captured image
            DispatchQueue.main.async {
                self.displayCapturedImage(capturedImage, captureTime: captureTime)
            }
        } else {
            // Handle capture failure
            DispatchQueue.main.async {
                self.showCaptureError()
            }
        }
        
        // Reset button state
        DispatchQueue.main.async {
            if let button = self.mainWindow?.contentView?.subviews.first(where: { $0 is NSButton }) as? NSButton {
                button.title = "Capture Screen"
                button.isEnabled = true
            }
        }
    }
    
    private func displayCapturedImage(_ cgImage: CGImage, captureTime: Double) {
        // Convert CGImage to NSImage
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        
        // Update image view
        imageView?.image = nsImage
        
        // Update instructions to show capture time
        if let instructionsLabel = mainWindow?.contentView?.subviews.last as? NSTextField {
            instructionsLabel.stringValue = String(format: "✅ Screen captured successfully! Response time: %.1f ms", captureTime)
            instructionsLabel.textColor = .systemGreen
        }
        
        print("Screen capture completed in \(String(format: "%.1f", captureTime)) ms")
    }
    
    private func showCaptureError() {
        if let instructionsLabel = mainWindow?.contentView?.subviews.last as? NSTextField {
            instructionsLabel.stringValue = "❌ Screen capture failed. Check permissions in System Preferences."
            instructionsLabel.textColor = .systemRed
        }
        
        // Show alert
        let alert = NSAlert()
        alert.messageText = "Screen Capture Failed"
        alert.informativeText = "Unable to capture screen. Please ensure screen recording permission is granted in System Preferences > Privacy & Security > Screen Recording."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "OK")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
        }
    }
    
    // MARK: - Screen Capture Permission
    
    private func checkScreenCapturePermission() {
        Task {
            let hasPermission = await screenCaptureManager.requestPermission()
            
            DispatchQueue.main.async {
                self.updatePermissionStatus(hasPermission: hasPermission)
            }
            
            if !hasPermission {
                DispatchQueue.main.async {
                    self.showPermissionAlert()
                }
            }
        }
    }
    
    private func updatePermissionStatus(hasPermission: Bool) {
        guard let contentView = mainWindow?.contentView,
              let permissionLabel = contentView.viewWithTag(0) as? NSTextField ??
              contentView.subviews.first(where: { $0.identifier?.rawValue == "permissionLabel" }) as? NSTextField else {
            return
        }
        
        if hasPermission {
            permissionLabel.stringValue = "Permission Status: ✅ Granted"
            permissionLabel.textColor = .systemGreen
        } else {
            permissionLabel.stringValue = "Permission Status: ❌ Not Granted"
            permissionLabel.textColor = .systemRed
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
    
    // MARK: - Overlay Window Actions
    
    @objc private func showOverlayPressed() {
        if overlayWindow == nil {
            overlayWindow = OverlayWindow()
        }
        overlayWindow?.showOverlay()
        print("AppDelegate: Overlay window shown for testing")
    }
    
    @objc private func hideOverlayPressed() {
        overlayWindow?.hideOverlay()
        print("AppDelegate: Overlay window hidden")
    }
    
    @objc private func clearDrawingPressed() {
        if let contentView = overlayWindow?.contentView as? OverlayContentView {
            contentView.clearDrawing()
            print("AppDelegate: Overlay drawing cleared")
        }
    }
} 