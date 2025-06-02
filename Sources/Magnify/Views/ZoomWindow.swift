import AppKit
import Foundation
import SwiftUI

/// ZoomWindow displays magnified screen content with real-time updates
/// Provides a dedicated window for zoom functionality with controls and status
class ZoomWindow: NSWindow {
    
    // MARK: - Properties
    
    private let zoomManager = ZoomManager.shared
    private let preferencesManager = PreferencesManager.shared
    private var zoomContentView: ZoomContentView!
    private var isZoomWindowVisible = false
    
    // Window configuration
    private let defaultWindowSize = CGSize(width: 500, height: 400)
    private let minWindowSize = CGSize(width: 300, height: 250)
    private let maxWindowSize = CGSize(width: 1000, height: 800)
    
    // MARK: - Initialization
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        setupWindow()
    }
    
    /// Initialize zoom window with default configuration
    convenience init() {
        let windowRect = NSRect(origin: .zero, size: CGSize(width: 500, height: 400))
        
        self.init(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
    }
    
    // MARK: - Window Setup
    
    private func setupWindow() {
        // Window configuration
        self.title = "Magnify - Zoom View"
        self.backgroundColor = NSColor.windowBackgroundColor
        self.isOpaque = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Set size constraints
        self.minSize = minWindowSize
        self.maxSize = maxWindowSize
        
        // Create and set content view
        zoomContentView = ZoomContentView(frame: self.contentRect(forFrameRect: self.frame))
        zoomContentView.zoomManager = zoomManager
        self.contentView = zoomContentView
        
        // Set up window delegate
        self.delegate = self
        
        // Initial window positioning
        centerWindowOnScreen()
        
        // Load saved window position if preferences allow
        if let savedFrame = preferencesManager.loadWindowFrame(for: "zoom_window") {
            self.setFrame(savedFrame, display: false)
        }
        
        print("ZoomWindow: Initialized with size \(self.frame.size)")
    }
    
    private func centerWindowOnScreen() {
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowSize = self.frame.size
            
            let centeredRect = NSRect(
                x: screenFrame.origin.x + (screenFrame.width - windowSize.width) / 2,
                y: screenFrame.origin.y + (screenFrame.height - windowSize.height) / 2,
                width: windowSize.width,
                height: windowSize.height
            )
            
            self.setFrame(centeredRect, display: false)
        }
    }
    
    // MARK: - Public Methods
    
    /// Show the zoom window
    func showZoomWindow() {
        guard !isZoomWindowVisible else { return }
        
        // Start zoom functionality
        zoomManager.startZoom()
        
        // Show window
        self.makeKeyAndOrderFront(nil)
        self.isZoomWindowVisible = true
        
        // Update content view
        zoomContentView.startDisplayUpdates()
        
        print("ZoomWindow: Zoom window shown")
    }
    
    /// Hide the zoom window
    func hideZoomWindow() {
        guard isZoomWindowVisible else { return }
        
        // Stop zoom functionality
        zoomManager.stopZoom()
        
        // Hide window
        self.orderOut(nil)
        self.isZoomWindowVisible = false
        
        // Stop content updates
        zoomContentView.stopDisplayUpdates()
        
        print("ZoomWindow: Zoom window hidden")
    }
    
    /// Toggle zoom window visibility
    func toggleZoomWindow() {
        if isZoomWindowVisible {
            hideZoomWindow()
        } else {
            showZoomWindow()
        }
    }
    
    /// Check if zoom window is currently visible
    var isVisible: Bool {
        return isZoomWindowVisible && self.isVisible
    }
    
    // MARK: - Window Event Handling
    
    override func keyDown(with event: NSEvent) {
        let keyCode = event.keyCode
        let modifierFlags = event.modifierFlags
        
        // Handle zoom control keyboard shortcuts
        if modifierFlags.contains(.command) {
            switch keyCode {
            case 24: // + key
                zoomManager.zoomIn()
                return
            case 27: // - key
                zoomManager.zoomOut()
                return
            case 29: // 0 key
                zoomManager.resetZoom()
                return
            default:
                break
            }
        }
        
        // Handle escape key to hide zoom window
        if keyCode == 53 { // Escape key
            hideZoomWindow()
            return
        }
        
        super.keyDown(with: event)
    }
    
    override func mouseDown(with event: NSEvent) {
        // Allow window dragging
        super.mouseDown(with: event)
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

// MARK: - NSWindowDelegate

extension ZoomWindow: NSWindowDelegate {
    
    func windowWillClose(_ notification: Notification) {
        // Save window position if preferences allow
        preferencesManager.saveWindowFrame(self.frame, for: "zoom_window")
        
        // Stop zoom when window closes
        hideZoomWindow()
        
        print("ZoomWindow: Window will close")
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        print("ZoomWindow: Window became key")
    }
    
    func windowDidResignKey(_ notification: Notification) {
        print("ZoomWindow: Window resigned key")
    }
    
    func windowDidResize(_ notification: Notification) {
        // Update zoom window size in manager
        let newSize = self.frame.size
        zoomManager.setZoomWindowSize(newSize)
        
        print("ZoomWindow: Window resized to \(newSize)")
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }
}

// MARK: - Zoom Content View

/// ZoomContentView handles the display of magnified content and zoom controls
class ZoomContentView: NSView {
    
    // MARK: - Properties
    
    var zoomManager: ZoomManager?
    
    private var imageView: NSImageView!
    private var controlsView: ZoomControlsView!
    private var statusLabel: NSTextField!
    
    private var displayTimer: Timer?
    private var isUpdating = false
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
        setupControls()
        setupImageView()
        setupStatusDisplay()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupControls()
        setupImageView()
        setupStatusDisplay()
    }
    
    private func setupView() {
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }
    
    private func setupImageView() {
        // Create image view for displaying zoomed content
        let imageFrame = NSRect(
            x: 10,
            y: 50,
            width: frame.width - 20,
            height: frame.height - 100
        )
        
        imageView = NSImageView(frame: imageFrame)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        imageView.wantsLayer = true
        imageView.layer?.borderWidth = 1
        imageView.layer?.borderColor = NSColor.separatorColor.cgColor
        imageView.layer?.cornerRadius = 4
        
        // Set placeholder image
        imageView.image = createPlaceholderImage()
        
        addSubview(imageView)
    }
    
    private func setupControls() {
        // Create controls view for zoom level and options
        let controlsFrame = NSRect(
            x: 10,
            y: 10,
            width: frame.width - 20,
            height: 35
        )
        
        controlsView = ZoomControlsView(frame: controlsFrame)
        controlsView.zoomManager = zoomManager
        addSubview(controlsView)
    }
    
    private func setupStatusDisplay() {
        // Create status label for performance and info display
        statusLabel = NSTextField(labelWithString: "Zoom Status: Ready")
        statusLabel.frame = NSRect(
            x: 10,
            y: frame.height - 25,
            width: frame.width - 20,
            height: 20
        )
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.alignment = .left
        
        addSubview(statusLabel)
    }
    
    private func createPlaceholderImage() -> NSImage {
        let size = NSSize(width: 300, height: 200)
        let image = NSImage(size: size)
        
        image.lockFocus()
        NSColor.controlBackgroundColor.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        let text = "Zoom content will appear here"
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
    
    // MARK: - Display Updates
    
    func startDisplayUpdates() {
        guard !isUpdating else { return }
        
        isUpdating = true
        
        // Start timer for regular content updates
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.updateZoomDisplay()
        }
        
        print("ZoomContentView: Started display updates at 60fps")
    }
    
    func stopDisplayUpdates() {
        guard isUpdating else { return }
        
        isUpdating = false
        
        // Stop timer
        displayTimer?.invalidate()
        displayTimer = nil
        
        // Clear display
        imageView.image = createPlaceholderImage()
        statusLabel.stringValue = "Zoom Status: Stopped"
        
        print("ZoomContentView: Stopped display updates")
    }
    
    private func updateZoomDisplay() {
        guard let manager = zoomManager, manager.isZoomActive else { return }
        
        // Update zoomed image
        if let zoomedImage = manager.currentZoomedImage {
            let nsImage = NSImage(cgImage: zoomedImage, size: NSSize(width: zoomedImage.width, height: zoomedImage.height))
            imageView.image = nsImage
        }
        
        // Update status information
        let metrics = manager.getPerformanceMetrics()
        let zoomLevel = manager.zoomPercentage
        let acceleration = metrics.isGPUAccelerated ? "GPU" : "CPU"
        
        statusLabel.stringValue = String(format: 
            "Zoom: %d%% | FPS: %.1f | Frame: %.1fms | %@",
            zoomLevel, metrics.fps, metrics.frameTime, acceleration
        )
        
        // Update controls
        controlsView.updateControls()
    }
    
    // MARK: - Layout
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        
        // Update image view frame
        imageView.frame = NSRect(
            x: 10,
            y: 50,
            width: frame.width - 20,
            height: frame.height - 100
        )
        
        // Update controls frame
        controlsView.frame = NSRect(
            x: 10,
            y: 10,
            width: frame.width - 20,
            height: 35
        )
        
        // Update status label frame
        statusLabel.frame = NSRect(
            x: 10,
            y: frame.height - 25,
            width: frame.width - 20,
            height: 20
        )
    }
}

// MARK: - Zoom Controls View

/// ZoomControlsView provides UI controls for zoom functionality
class ZoomControlsView: NSView {
    
    // MARK: - Properties
    
    var zoomManager: ZoomManager?
    
    private var zoomOutButton: NSButton!
    private var zoomInButton: NSButton!
    private var resetButton: NSButton!
    private var zoomLevelSlider: NSSlider!
    private var zoomLevelLabel: NSTextField!
    private var mouseTrackingCheckbox: NSButton!
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupControls()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupControls()
    }
    
    private func setupControls() {
        // Zoom out button
        zoomOutButton = NSButton(frame: NSRect(x: 0, y: 0, width: 30, height: 25))
        zoomOutButton.title = "−"
        zoomOutButton.bezelStyle = .rounded
        zoomOutButton.target = self
        zoomOutButton.action = #selector(zoomOutPressed)
        addSubview(zoomOutButton)
        
        // Zoom level slider
        zoomLevelSlider = NSSlider(frame: NSRect(x: 35, y: 5, width: 150, height: 20))
        zoomLevelSlider.minValue = 1.0
        zoomLevelSlider.maxValue = 10.0
        zoomLevelSlider.doubleValue = 2.0
        zoomLevelSlider.target = self
        zoomLevelSlider.action = #selector(zoomLevelChanged)
        addSubview(zoomLevelSlider)
        
        // Zoom in button
        zoomInButton = NSButton(frame: NSRect(x: 190, y: 0, width: 30, height: 25))
        zoomInButton.title = "+"
        zoomInButton.bezelStyle = .rounded
        zoomInButton.target = self
        zoomInButton.action = #selector(zoomInPressed)
        addSubview(zoomInButton)
        
        // Reset button
        resetButton = NSButton(frame: NSRect(x: 225, y: 0, width: 50, height: 25))
        resetButton.title = "1:1"
        resetButton.bezelStyle = .rounded
        resetButton.target = self
        resetButton.action = #selector(resetZoomPressed)
        addSubview(resetButton)
        
        // Zoom level label
        zoomLevelLabel = NSTextField(labelWithString: "200%")
        zoomLevelLabel.frame = NSRect(x: 280, y: 5, width: 50, height: 20)
        zoomLevelLabel.alignment = .center
        zoomLevelLabel.font = NSFont.systemFont(ofSize: 12)
        addSubview(zoomLevelLabel)
        
        // Mouse tracking checkbox
        mouseTrackingCheckbox = NSButton(checkboxWithTitle: "Follow Mouse", target: self, action: #selector(mouseTrackingToggled))
        mouseTrackingCheckbox.frame = NSRect(x: 340, y: 5, width: 120, height: 20)
        mouseTrackingCheckbox.state = .off
        addSubview(mouseTrackingCheckbox)
    }
    
    // MARK: - Actions
    
    @objc private func zoomOutPressed() {
        zoomManager?.zoomOut()
        updateControls()
    }
    
    @objc private func zoomInPressed() {
        zoomManager?.zoomIn()
        updateControls()
    }
    
    @objc private func resetZoomPressed() {
        zoomManager?.resetZoom()
        updateControls()
    }
    
    @objc private func zoomLevelChanged() {
        let newZoomLevel = Float(zoomLevelSlider.doubleValue)
        zoomManager?.setZoomLevel(newZoomLevel)
        updateControls()
    }
    
    @objc private func mouseTrackingToggled() {
        let isEnabled = mouseTrackingCheckbox.state == .on
        zoomManager?.setMouseTracking(enabled: isEnabled)
        print("ZoomControlsView: Mouse tracking \(isEnabled ? "enabled" : "disabled")")
    }
    
    // MARK: - Updates
    
    func updateControls() {
        guard let manager = zoomManager else { return }
        
        // Update slider value
        zoomLevelSlider.doubleValue = Double(manager.currentZoomLevel)
        
        // Update zoom level label
        zoomLevelLabel.stringValue = "\(manager.zoomPercentage)%"
        
        // Update button states
        zoomOutButton.isEnabled = !manager.isAtMinZoom
        zoomInButton.isEnabled = !manager.isAtMaxZoom
        resetButton.isEnabled = manager.currentZoomLevel != 1.0
    }
    
    // MARK: - Layout
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        
        // Adjust slider width based on available space
        let availableWidth = frame.width - 350 // Space for buttons and labels
        if availableWidth > 100 {
            zoomLevelSlider.frame = NSRect(
                x: 35,
                y: 5,
                width: max(100, availableWidth),
                height: 20
            )
            
            // Adjust positions of subsequent controls
            zoomInButton.frame.origin.x = zoomLevelSlider.frame.maxX + 5
            resetButton.frame.origin.x = zoomInButton.frame.maxX + 5
            zoomLevelLabel.frame.origin.x = resetButton.frame.maxX + 5
            mouseTrackingCheckbox.frame.origin.x = zoomLevelLabel.frame.maxX + 10
        }
    }
} 