import AppKit
import Foundation

/// Transparent overlay window for screen-wide annotations
/// Designed to appear above all other windows and across all Spaces
class OverlayWindow: NSWindow {
    
    // MARK: - Properties
    
    private var overlayContentView: OverlayContentView!
    
    // MARK: - Initialization
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        setupTransparentOverlay()
    }
    
    /// Initialize overlay window with screen bounds
    convenience init() {
        // Get main screen bounds
        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        
        self.init(
            contentRect: screenRect,
            styleMask: [.borderless], // Remove window decorations
            backing: .buffered,
            defer: false
        )
    }
    
    // MARK: - Setup
    
    private func setupTransparentOverlay() {
        // Configure window properties for overlay behavior
        
        // Remove window decorations and make borderless
        self.styleMask = [.borderless]
        
        // Make window transparent
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.hasShadow = false
        
        // Set window level to appear above all other windows
        self.level = .statusBar // High priority level that stays above most apps
        
        // Configure window behavior for all Spaces
        self.collectionBehavior = [
            .canJoinAllSpaces,        // Display on all Spaces
            .stationary,              // Don't move when switching Spaces
            .ignoresCycle            // Don't appear in Cmd+Tab cycling
        ]
        
        // Enable mouse events
        self.acceptsMouseMovedEvents = true
        self.ignoresMouseEvents = false
        
        // Create and set content view
        overlayContentView = OverlayContentView(frame: self.contentRect(forFrameRect: self.frame))
        overlayContentView.autoresizingMask = [.width, .height]
        self.contentView = overlayContentView
        
        // Configure window behavior
        self.isReleasedWhenClosed = false // Keep window instance alive
        self.hidesOnDeactivate = false   // Don't hide when app loses focus
        
        print("OverlayWindow: Transparent overlay configured with screen bounds: \(self.frame)")
    }
    
    // MARK: - Public Methods
    
    /// Show the overlay window on top of all other windows
    func showOverlay() {
        self.orderFrontRegardless() // Force window to front regardless of app focus
        self.makeKeyAndOrderFront(nil)
        print("OverlayWindow: Overlay shown")
    }
    
    /// Hide the overlay window
    func hideOverlay() {
        self.orderOut(nil)
        print("OverlayWindow: Overlay hidden")
    }
    
    /// Bring overlay to front (useful when window gets buried)
    func bringToFront() {
        self.level = .statusBar
        self.orderFrontRegardless()
        print("OverlayWindow: Brought to front")
    }
    
    /// Check if overlay is currently visible
    var isOverlayVisible: Bool {
        return self.isVisible
    }
    
    // MARK: - Window Event Handling
    
    override func canBecomeKey() -> Bool {
        return true // Allow window to become key for event handling
    }
    
    override func canBecomeMain() -> Bool {
        return false // Don't become main window to avoid interfering with other apps
    }
    
    override func acceptsFirstResponder() -> Bool {
        return true // Accept first responder status for keyboard events
    }
    
    // Handle window resizing when screen configuration changes
    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        super.setFrame(frameRect, display: flag)
        
        // Update content view frame to match
        if let contentView = self.contentView {
            contentView.frame = self.contentRect(forFrameRect: frameRect)
        }
        
        print("OverlayWindow: Frame updated to \(frameRect)")
    }
}

// MARK: - Content View for Drawing

/// Content view for the overlay window that handles drawing and mouse events
class OverlayContentView: NSView {
    
    // MARK: - Properties
    
    private var currentDrawingPath: NSBezierPath?
    private var completedPaths: [NSBezierPath] = []
    private var isDrawing = false
    
    // Drawing properties
    private var strokeColor: NSColor = .red
    private var strokeWidth: CGFloat = 3.0
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // Enable layer backing for better performance
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
        
        // Accept mouse events
        self.acceptsTouchEvents = true
        
        print("OverlayContentView: Initialized with frame \(self.frame)")
    }
    
    // MARK: - Drawing
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Clear the background (transparent)
        NSColor.clear.setFill()
        dirtyRect.fill()
        
        // Draw completed paths
        strokeColor.setStroke()
        for path in completedPaths {
            path.lineWidth = strokeWidth
            path.stroke()
        }
        
        // Draw current path being drawn
        if let currentPath = currentDrawingPath {
            strokeColor.setStroke()
            currentPath.lineWidth = strokeWidth
            currentPath.stroke()
        }
    }
    
    // MARK: - Mouse Event Handling
    
    override func mouseDown(with event: NSEvent) {
        let point = self.convert(event.locationInWindow, from: nil)
        
        // Start new drawing path
        currentDrawingPath = NSBezierPath()
        currentDrawingPath?.move(to: point)
        isDrawing = true
        
        print("OverlayContentView: Mouse down at \(point)")
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard isDrawing, let path = currentDrawingPath else { return }
        
        let point = self.convert(event.locationInWindow, from: nil)
        path.line(to: point)
        
        // Trigger redraw for the area around the new line segment
        let redrawRect = NSRect(
            x: point.x - strokeWidth * 2,
            y: point.y - strokeWidth * 2,
            width: strokeWidth * 4,
            height: strokeWidth * 4
        )
        self.setNeedsDisplay(redrawRect)
        
        // For real-time drawing, also trigger immediate display
        self.displayIfNeeded()
    }
    
    override func mouseUp(with event: NSEvent) {
        guard isDrawing, let path = currentDrawingPath else { return }
        
        // Finish the current path
        completedPaths.append(path)
        currentDrawingPath = nil
        isDrawing = false
        
        let point = self.convert(event.locationInWindow, from: nil)
        print("OverlayContentView: Mouse up at \(point), path completed")
        
        // Trigger full redraw
        self.needsDisplay = true
    }
    
    // MARK: - Public Methods
    
    /// Clear all drawn paths
    func clearDrawing() {
        completedPaths.removeAll()
        currentDrawingPath = nil
        isDrawing = false
        self.needsDisplay = true
        print("OverlayContentView: Drawing cleared")
    }
    
    /// Set stroke color for drawing
    func setStrokeColor(_ color: NSColor) {
        strokeColor = color
    }
    
    /// Set stroke width for drawing
    func setStrokeWidth(_ width: CGFloat) {
        strokeWidth = width
    }
    
    /// Get the number of completed drawing paths
    var pathCount: Int {
        return completedPaths.count
    }
    
    // MARK: - View Properties
    
    override var isFlipped: Bool {
        return false // Use standard Cocoa coordinate system
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true // Accept mouse events even when app is not active
    }
} 