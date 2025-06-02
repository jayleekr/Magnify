import AppKit
import Foundation
import SwiftUI
import Combine

/// OverlayWindow provides a transparent, borderless window for screen annotation
/// Displays on all Spaces and maintains top-most visibility for drawing tools
class OverlayWindow: NSWindow {
    
    var isOverlayVisible = false
    private let preferencesManager = PreferencesManager.shared
    private let drawingToolManager = DrawingToolManager.shared
    
    // MARK: - Properties
    
    private var overlayContentView: OverlayContentView!
    private var toolPaletteHostingView: NSHostingView<ToolPalette>?
    
    // MARK: - Initialization
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        setupWindow()
    }
    
    /// Initialize overlay window with screen bounds
    convenience init() {
        // Use full screen bounds for overlay
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        
        self.init(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
    }
    
    // MARK: - Setup
    
    private func setupWindow() {
        // Window configuration for transparent overlay
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.ignoresMouseEvents = false
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        // Create and set content view
        overlayContentView = OverlayContentView(frame: self.frame)
        overlayContentView.preferencesManager = preferencesManager
        overlayContentView.drawingToolManager = drawingToolManager
        self.contentView = overlayContentView
        
        // Setup tool palette
        setupToolPalette()
        
        print("OverlayWindow: Initialized with transparent overlay configuration and advanced drawing tools")
    }
    
    private func setupToolPalette() {
        let toolPalette = ToolPalette()
        toolPaletteHostingView = NSHostingView(rootView: toolPalette)
        
        if let hostingView = toolPaletteHostingView {
            hostingView.frame = NSRect(x: 20, y: 20, width: 280, height: 600)
            hostingView.isHidden = !drawingToolManager.isToolPaletteVisible
            overlayContentView.addSubview(hostingView)
        }
        
        // Observe tool palette visibility changes
        drawingToolManager.$isToolPaletteVisible
            .sink { [weak self] isVisible in
                DispatchQueue.main.async {
                    self?.toolPaletteHostingView?.isHidden = !isVisible
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    /// Show the overlay window
    func showOverlay() {
        // Update to current screen frame in case resolution changed
        if let screenFrame = NSScreen.main?.frame {
            self.setFrame(screenFrame, display: true)
            if let contentView = self.contentView as? OverlayContentView {
                contentView.frame = screenFrame
            }
        }
        
        // Apply current preferences
        if let contentView = self.contentView as? OverlayContentView {
            contentView.updateFromPreferences()
        }
        
        // Update tool palette visibility
        toolPaletteHostingView?.isHidden = !drawingToolManager.isToolPaletteVisible
        
        self.makeKeyAndOrderFront(nil)
        self.isOverlayVisible = true
        
        print("OverlayWindow: Overlay shown with advanced drawing tools")
    }
    
    /// Hide the overlay window
    func hideOverlay() {
        self.orderOut(nil)
        self.isOverlayVisible = false
        
        // Hide tool palette when overlay is hidden
        drawingToolManager.hideToolPalette()
        
        print("OverlayWindow: Overlay hidden")
    }
    
    /// Toggle overlay visibility
    func toggleOverlay() {
        if isOverlayVisible {
            hideOverlay()
        } else {
            showOverlay()
        }
    }
    
    /// Toggle tool palette visibility
    func toggleToolPalette() {
        drawingToolManager.toggleToolPalette()
        print("OverlayWindow: Tool palette toggled")
    }
    
    /// Handle escape key to hide overlay if preference is enabled
    override func keyDown(with event: NSEvent) {
        // Handle keyboard shortcuts for drawing tools
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers {
            case "t": // Cmd+T to toggle tool palette
                toggleToolPalette()
                return
            case "z": // Cmd+Z for undo
                if event.modifierFlags.contains(.shift) {
                    drawingToolManager.redo()
                } else {
                    drawingToolManager.undo()
                }
                return
            case "c": // Cmd+C to clear all
                if event.modifierFlags.contains(.shift) {
                    drawingToolManager.clearAllDrawings()
                    overlayContentView.needsDisplay = true
                }
                return
            default:
                break
            }
        }
        
        // Tool selection shortcuts (1-8 keys)
        if let chars = event.charactersIgnoringModifiers,
           let firstChar = chars.first,
           let number = Int(String(firstChar)),
           number >= 1 && number <= 8 {
            let tools = DrawingToolManager.DrawingTool.allCases
            if number <= tools.count {
                drawingToolManager.selectTool(tools[number - 1])
                return
            }
        }
        
        if preferencesManager.hideOverlayOnEscape && event.keyCode == 53 { // Escape key
            hideOverlay()
            return
        }
        
        super.keyDown(with: event)
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    // MARK: - Window Event Handling
    
    override func canBecomeMain() -> Bool {
        return false // Don't become main window to avoid interfering with other apps
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
    
    // MARK: - Cleanup
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Content View for Drawing

/// OverlayContentView handles the drawing functionality within the overlay window
/// Provides real-time mouse tracking and advanced drawing capabilities with tool support
class OverlayContentView: NSView {
    
    // MARK: - Properties
    
    private var currentPath: NSBezierPath?
    private var allPaths: [(path: NSBezierPath, color: NSColor, width: CGFloat, opacity: Double)] = []
    private var isDrawing = false
    
    // Reference to managers
    var preferencesManager: PreferencesManager?
    var drawingToolManager: DrawingToolManager?
    
    // Legacy drawing properties (for backward compatibility)
    private var currentStrokeColor: NSColor = .systemRed
    private var currentStrokeWidth: CGFloat = 3.0
    private var currentOpacity: Double = 1.0
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
        updateFromPreferences()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        updateFromPreferences()
    }
    
    private func setupView() {
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
        
        print("OverlayContentView: Initialized with advanced drawing capabilities")
    }
    
    /// Update drawing properties from preferences
    func updateFromPreferences() {
        guard let preferences = preferencesManager else { return }
        
        currentStrokeColor = preferences.defaultStrokeColor
        currentStrokeWidth = preferences.defaultStrokeWidth
        currentOpacity = preferences.defaultOpacity
        
        // Redraw with new settings
        self.needsDisplay = true
        
        print("OverlayContentView: Updated from preferences - Color: \(currentStrokeColor), Width: \(currentStrokeWidth), Opacity: \(currentOpacity)")
    }
    
    // MARK: - Drawing
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Get current graphics context
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Draw advanced drawing tool elements first
        if let drawingToolManager = drawingToolManager {
            drawingToolManager.renderAllElements(in: context)
        }
        
        // Draw legacy paths for backward compatibility
        for pathData in allPaths {
            pathData.color.withAlphaComponent(pathData.opacity).setStroke()
            pathData.path.lineWidth = pathData.width
            pathData.path.lineCapStyle = .round
            pathData.path.lineJoinStyle = .round
            pathData.path.stroke()
        }
        
        // Draw current path being created (legacy mode)
        if let currentPath = currentPath, drawingToolManager?.currentTool == .freehand {
            currentStrokeColor.withAlphaComponent(currentOpacity).setStroke()
            currentPath.lineWidth = currentStrokeWidth
            currentPath.lineCapStyle = .round
            currentPath.lineJoinStyle = .round
            currentPath.stroke()
        }
    }
    
    // MARK: - Mouse Events
    
    override func mouseDown(with event: NSEvent) {
        let locationInView = self.convert(event.locationInWindow, from: nil)
        
        // Check if click is on tool palette
        if let toolPaletteHostingView = findToolPaletteHostingView(),
           toolPaletteHostingView.frame.contains(locationInView) {
            // Let the tool palette handle the event
            return
        }
        
        // Update cursor for current tool
        drawingToolManager?.updateCursor()
        
        // Use advanced drawing tools if available
        if let drawingToolManager = drawingToolManager {
            drawingToolManager.startDrawing(at: locationInView, in: self)
            self.needsDisplay = true
            return
        }
        
        // Fallback to legacy drawing
        updateFromPreferences()
        currentPath = NSBezierPath()
        currentPath?.move(to: locationInView)
        isDrawing = true
        
        print("OverlayContentView: Started drawing at \(locationInView)")
    }
    
    override func mouseDragged(with event: NSEvent) {
        let locationInView = self.convert(event.locationInWindow, from: nil)
        
        // Use advanced drawing tools if available
        if let drawingToolManager = drawingToolManager {
            drawingToolManager.continueDrawing(to: locationInView, in: self)
            self.needsDisplay = true
            return
        }
        
        // Fallback to legacy drawing
        guard isDrawing, let currentPath = currentPath else { return }
        
        currentPath.line(to: locationInView)
        
        // Optimize redraw to only the area being drawn
        let invalidRect = currentPath.bounds.insetBy(dx: -currentStrokeWidth - 1, dy: -currentStrokeWidth - 1)
        self.setNeedsDisplay(invalidRect)
    }
    
    override func mouseUp(with event: NSEvent) {
        let locationInView = self.convert(event.locationInWindow, from: nil)
        
        // Use advanced drawing tools if available
        if let drawingToolManager = drawingToolManager {
            drawingToolManager.finishDrawing(at: locationInView, in: self)
            self.needsDisplay = true
            return
        }
        
        // Fallback to legacy drawing
        guard isDrawing, let currentPath = currentPath else { return }
        
        currentPath.line(to: locationInView)
        
        // Store the completed path with current drawing properties
        allPaths.append((
            path: currentPath.copy() as! NSBezierPath,
            color: currentStrokeColor,
            width: currentStrokeWidth,
            opacity: currentOpacity
        ))
        
        // Clear current path and stop drawing
        self.currentPath = nil
        isDrawing = false
        
        // Redraw the entire view to ensure everything is displayed correctly
        self.needsDisplay = true
        
        print("OverlayContentView: Completed drawing path with \(allPaths.count) total legacy paths")
    }
    
    override func mouseMoved(with event: NSEvent) {
        // Update cursor based on current tool
        drawingToolManager?.updateCursor()
    }
    
    private func findToolPaletteHostingView() -> NSView? {
        return subviews.first { $0 is NSHostingView<ToolPalette> }
    }
    
    // MARK: - Path Management
    
    /// Clear all drawing paths (both legacy and advanced)
    func clearDrawing() {
        allPaths.removeAll()
        currentPath = nil
        isDrawing = false
        drawingToolManager?.clearAllDrawings()
        self.needsDisplay = true
        
        print("OverlayContentView: Cleared all drawing paths")
    }
    
    /// Undo the last drawn path
    func undoLastPath() {
        // Try advanced drawing tools first
        if let drawingToolManager = drawingToolManager, drawingToolManager.canUndo() {
            drawingToolManager.undo()
            self.needsDisplay = true
            return
        }
        
        // Fallback to legacy undo
        if !allPaths.isEmpty {
            allPaths.removeLast()
            self.needsDisplay = true
            print("OverlayContentView: Undid last legacy path, \(allPaths.count) paths remaining")
        }
    }
    
    /// Redo the last undone path
    func redoLastPath() {
        if let drawingToolManager = drawingToolManager, drawingToolManager.canRedo() {
            drawingToolManager.redo()
            self.needsDisplay = true
        }
    }
    
    /// Get the total number of drawn paths
    var pathCount: Int {
        let advancedCount = drawingToolManager?.elementCount ?? 0
        return allPaths.count + advancedCount
    }
    
    /// Check if currently drawing
    var isCurrentlyDrawing: Bool {
        return isDrawing
    }
    
    // MARK: - View Properties
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override var isFlipped: Bool {
        return false
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true // Accept mouse events even when app is not active
    }
    
    // Enable mouse tracking for cursor updates
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        // Remove existing tracking areas
        for trackingArea in trackingAreas {
            removeTrackingArea(trackingArea)
        }
        
        // Add new tracking area for the entire view
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
} 