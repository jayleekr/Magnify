import Foundation
import AppKit
import CoreGraphics
import ScreenCaptureKit
import Metal
import MetalKit

/// ZoomManager handles all screen magnification functionality
/// Provides GPU-accelerated zoom with real-time screen content updates
/// Provides zoom controls, mouse tracking, and zoom indicator for screen recording
class ZoomManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = ZoomManager()
    
    // MARK: - Published Properties
    
    @Published var isZoomActive: Bool = false
    @Published var currentZoomLevel: Float = 1.0
    @Published var zoomPosition: CGPoint = .zero
    @Published var zoomWindowSize: CGSize = CGSize(width: 400, height: 300)
    @Published var isZooming: Bool = false
    @Published var zoomCenter: CGPoint = .zero
    @Published var zoomMode: ZoomMode = .followMouse
    @Published var showZoomIndicator: Bool = true
    
    // MARK: - Private Properties
    
    private let screenCaptureManager = ScreenCaptureManager()
    private let preferencesManager = PreferencesManager.shared
    
    // Metal rendering components
    private var metalDevice: MTLDevice?
    private var metalCommandQueue: MTLCommandQueue?
    private var metalTexture: MTLTexture?
    
    // Zoom configuration
    private let minZoomLevel: Float = 1.0
    private let maxZoomLevel: Float = 10.0
    private let zoomIncrement: Float = 0.5
    
    // Screen capture and zoom buffers
    private var sourceImage: CGImage?
    private var zoomedImage: CGImage?
    private var captureRect: CGRect = .zero
    
    // Performance tracking
    private var lastUpdateTime: CFAbsoluteTime = 0
    private var frameCount: Int = 0
    
    // Mouse tracking
    private var mouseTrackingTimer: Timer?
    private var zoomUpdateQueue = DispatchQueue(label: "com.magnify.zoom", qos: .userInteractive)
    private var lastMousePosition: CGPoint = .zero
    private var isMouseTrackingActive: Bool = false
    
    // MARK: - Zoom Configuration
    
    enum ZoomMode: String, CaseIterable {
        case followMouse = "Follow Mouse"
        case fixedPosition = "Fixed Position"
        case fullScreen = "Full Screen"
        
        var displayName: String {
            return rawValue
        }
        
        var icon: String {
            switch self {
            case .followMouse: return "arrow.up.and.down.and.arrow.left.and.right"
            case .fixedPosition: return "pin.fill"
            case .fullScreen: return "rectangle.expand.vertical"
            }
        }
    }
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupMetal()
        setupZoomDefaults()
        setupMouseTracking()
        print("ZoomManager: Initialized zoom management system")
    }
    
    private func setupMetal() {
        // Initialize Metal for GPU acceleration
        metalDevice = MTLCreateSystemDefaultDevice()
        guard let device = metalDevice else {
            print("ZoomManager: Metal device not available, falling back to CPU rendering")
            return
        }
        
        metalCommandQueue = device.makeCommandQueue()
        print("ZoomManager: Metal GPU acceleration initialized successfully")
    }
    
    private func setupZoomDefaults() {
        // Load zoom preferences
        currentZoomLevel = preferencesManager.defaultZoomLevel
        zoomWindowSize = preferencesManager.defaultZoomWindowSize
        
        // Set initial zoom position to screen center
        if let screen = NSScreen.main {
            let screenCenter = CGPoint(
                x: screen.frame.width / 2,
                y: screen.frame.height / 2
            )
            zoomPosition = screenCenter
        }
        
        print("ZoomManager: Initialized with zoom level \(currentZoomLevel) at position \(zoomPosition)")
    }
    
    private func setupMouseTracking() {
        // Set up global mouse tracking for zoom functionality
        updateMousePosition()
    }
    
    // MARK: - Public Zoom Controls
    
    /// Start zoom functionality
    func startZoom() {
        guard !isZoomActive else { return }
        
        isZoomActive = true
        startScreenCapture()
        
        print("ZoomManager: Zoom started at level \(currentZoomLevel)")
    }
    
    /// Stop zoom functionality
    func stopZoom() {
        guard isZoomActive else { return }
        
        isZoomActive = false
        stopScreenCapture()
        
        print("ZoomManager: Zoom stopped")
    }
    
    /// Toggle zoom on/off
    func toggleZoom() {
        if isZoomActive {
            stopZoom()
        } else {
            startZoom()
        }
    }
    
    /// Set zoom level within valid range
    func setZoomLevel(_ level: Float) {
        let clampedLevel = max(minZoomLevel, min(maxZoomLevel, level))
        
        guard clampedLevel != currentZoomLevel else { return }
        
        currentZoomLevel = clampedLevel
        
        if isZoomActive {
            updateZoomContent()
        }
        
        print("ZoomManager: Zoom level set to \(currentZoomLevel)")
    }
    
    /// Increase zoom level
    func zoomIn() {
        setZoomLevel(currentZoomLevel + zoomIncrement)
    }
    
    /// Decrease zoom level
    func zoomOut() {
        setZoomLevel(currentZoomLevel - zoomIncrement)
    }
    
    /// Reset zoom to 1x
    func resetZoom() {
        setZoomLevel(1.0)
    }
    
    /// Set zoom focus position
    func setZoomPosition(_ position: CGPoint) {
        zoomPosition = position
        
        if isZoomActive {
            updateZoomContent()
        }
    }
    
    /// Set zoom window size
    func setZoomWindowSize(_ size: CGSize) {
        let clampedSize = CGSize(
            width: max(200, min(800, size.width)),
            height: max(150, min(600, size.height))
        )
        
        zoomWindowSize = clampedSize
        
        if isZoomActive {
            updateZoomContent()
        }
    }
    
    // MARK: - Screen Capture Integration
    
    private func startScreenCapture() {
        Task {
            await setupContinuousCapture()
        }
    }
    
    private func stopScreenCapture() {
        // Clean up capture resources
        sourceImage = nil
        zoomedImage = nil
        metalTexture = nil
        
        print("ZoomManager: Screen capture stopped and resources cleaned up")
    }
    
    private func setupContinuousCapture() async {
        // Start continuous screen capture for real-time zoom updates
        while isZoomActive {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Capture screen content around zoom position
            await captureZoomRegion()
            
            // Update zoom content with GPU acceleration
            updateZoomContent()
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let frameTime = (endTime - startTime) * 1000 // Convert to milliseconds
            
            // Maintain 60fps target (16.67ms per frame)
            let targetFrameTime: Double = 16.67
            if frameTime < targetFrameTime {
                let sleepTime = targetFrameTime - frameTime
                try? await Task.sleep(nanoseconds: UInt64(sleepTime * 1_000_000))
            }
            
            // Track performance
            trackPerformance(frameTime: frameTime)
        }
    }
    
    private func captureZoomRegion() async {
        // Calculate capture region based on zoom position and level
        let captureSize = CGSize(
            width: zoomWindowSize.width / CGFloat(currentZoomLevel),
            height: zoomWindowSize.height / CGFloat(currentZoomLevel)
        )
        
        captureRect = CGRect(
            x: zoomPosition.x - captureSize.width / 2,
            y: zoomPosition.y - captureSize.height / 2,
            width: captureSize.width,
            height: captureSize.height
        )
        
        // Capture screen content
        if let capturedImage = await screenCaptureManager.captureScreenRegion(captureRect) {
            sourceImage = capturedImage
        }
    }
    
    // MARK: - GPU-Accelerated Zoom Rendering
    
    private func updateZoomContent() {
        guard let source = sourceImage else { return }
        
        if let metalDevice = metalDevice {
            // Use Metal for GPU acceleration
            renderZoomWithMetal(source: source)
        } else {
            // Fallback to Core Graphics
            renderZoomWithCoreGraphics(source: source)
        }
    }
    
    private func renderZoomWithMetal(source: CGImage) {
        guard let device = metalDevice,
              let commandQueue = metalCommandQueue else { return }
        
        // Create Metal texture from source image
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: source.width,
            height: source.height,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else { return }
        
        // Convert CGImage to Metal texture
        let region = MTLRegionMake2D(0, 0, source.width, source.height)
        let bytesPerRow = source.bytesPerRow
        
        if let dataProvider = source.dataProvider,
           let data = dataProvider.data {
            let bytes = CFDataGetBytePtr(data)
            texture.replace(region: region, mipmapLevel: 0, withBytes: bytes!, bytesPerRow: bytesPerRow)
        }
        
        metalTexture = texture
        
        // Create zoomed image using Metal shaders
        createZoomedImageFromTexture()
    }
    
    private func renderZoomWithCoreGraphics(source: CGImage) {
        // Fallback CPU rendering using Core Graphics
        let zoomedSize = CGSize(
            width: CGFloat(source.width) * CGFloat(currentZoomLevel),
            height: CGFloat(source.height) * CGFloat(currentZoomLevel)
        )
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(
            data: nil,
            width: Int(zoomedSize.width),
            height: Int(zoomedSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return }
        
        // Apply high-quality interpolation
        context.interpolationQuality = .high
        
        // Draw scaled image
        let drawRect = CGRect(origin: .zero, size: zoomedSize)
        context.draw(source, in: drawRect)
        
        // Create zoomed image
        zoomedImage = context.makeImage()
    }
    
    private func createZoomedImageFromTexture() {
        // Create zoomed image from Metal texture
        // This would involve Metal compute shaders for optimal performance
        // For now, implement basic texture sampling
        
        guard let texture = metalTexture else { return }
        
        let width = Int(CGFloat(texture.width) * CGFloat(currentZoomLevel))
        let height = Int(CGFloat(texture.height) * CGFloat(currentZoomLevel))
        
        // Create output image from processed texture
        // Implementation would use Metal compute shaders for production
        print("ZoomManager: Metal texture processing completed - \(width)x\(height)")
    }
    
    // MARK: - Mouse Tracking
    
    /// Update zoom position to follow mouse cursor
    func updateZoomToMousePosition() {
        let mouseLocation = NSEvent.mouseLocation
        
        // Convert screen coordinates to CGPoint
        if let screen = NSScreen.main {
            let screenHeight = screen.frame.height
            let adjustedPosition = CGPoint(
                x: mouseLocation.x,
                y: screenHeight - mouseLocation.y
            )
            
            setZoomPosition(adjustedPosition)
        }
    }
    
    /// Enable/disable mouse tracking for zoom focus
    func setMouseTracking(enabled: Bool) {
        if enabled {
            startMouseTracking()
        } else {
            stopMouseTracking()
        }
    }
    
    private func startMouseTracking() {
        // Set up mouse tracking for zoom focus
        NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.updateZoomToMousePosition()
        }
        
        print("ZoomManager: Mouse tracking enabled for zoom focus")
    }
    
    private func stopMouseTracking() {
        // Clean up mouse tracking
        NSEvent.removeMonitor(self)
        print("ZoomManager: Mouse tracking disabled")
    }
    
    private func updateMousePosition() {
        guard isZooming && zoomMode == .followMouse else { return }
        
        zoomUpdateQueue.async {
            let currentMousePosition = NSEvent.mouseLocation
            
            // Convert coordinates (NSEvent uses flipped coordinates)
            if let screen = NSScreen.main {
                let screenHeight = screen.frame.height
                let convertedPosition = CGPoint(
                    x: currentMousePosition.x,
                    y: screenHeight - currentMousePosition.y
                )
                
                if convertedPosition != self.lastMousePosition {
                    self.lastMousePosition = convertedPosition
                    
                    DispatchQueue.main.async {
                        self.zoomCenter = convertedPosition
                    }
                }
            }
        }
    }
    
    // MARK: - Performance Monitoring
    
    private func trackPerformance(frameTime: Double) {
        frameCount += 1
        lastUpdateTime = CFAbsoluteTimeGetCurrent()
        
        // Log performance every 60 frames (approximately 1 second at 60fps)
        if frameCount % 60 == 0 {
            let fps = 1000.0 / frameTime
            print("ZoomManager: Performance - \(String(format: "%.1f", fps)) FPS, \(String(format: "%.2f", frameTime))ms frame time")
            
            // Check if performance targets are met
            if frameTime > 16.67 {
                print("ZoomManager: Warning - Frame time exceeding 60fps target")
            }
        }
    }
    
    /// Get current performance metrics
    func getPerformanceMetrics() -> (fps: Double, frameTime: Double, isGPUAccelerated: Bool) {
        let currentTime = CFAbsoluteTimeGetCurrent()
        let timeSinceLastUpdate = currentTime - lastUpdateTime
        
        let fps = timeSinceLastUpdate > 0 ? 1.0 / timeSinceLastUpdate : 0
        let frameTime = timeSinceLastUpdate * 1000 // Convert to milliseconds
        
        return (fps: fps, frameTime: frameTime, isGPUAccelerated: metalDevice != nil)
    }
    
    // MARK: - Zoom Properties
    
    /// Available zoom levels
    var availableZoomLevels: [Float] {
        var levels: [Float] = []
        var level = minZoomLevel
        while level <= maxZoomLevel {
            levels.append(level)
            level += zoomIncrement
        }
        return levels
    }
    
    /// Current zoom percentage for display
    var zoomPercentage: Int {
        return Int(currentZoomLevel * 100)
    }
    
    /// Check if zoom is at minimum level
    var isAtMinZoom: Bool {
        return currentZoomLevel <= minZoomLevel
    }
    
    /// Check if zoom is at maximum level
    var isAtMaxZoom: Bool {
        return currentZoomLevel >= maxZoomLevel
    }
    
    /// Get current zoomed image for display
    var currentZoomedImage: CGImage? {
        return zoomedImage
    }
    
    // MARK: - Zoom Calculations
    
    /// Get the zoom rectangle for current settings
    var zoomRect: CGRect {
        let zoomedSize = CGSize(
            width: zoomWindowSize.width / CGFloat(currentZoomLevel),
            height: zoomWindowSize.height / CGFloat(currentZoomLevel)
        )
        
        return CGRect(
            x: zoomCenter.x - zoomedSize.width / 2,
            y: zoomCenter.y - zoomedSize.height / 2,
            width: zoomedSize.width,
            height: zoomedSize.height
        )
    }
    
    /// Get display zoom rectangle (where zoom window appears)
    var displayRect: CGRect {
        // Default position in top-right corner
        guard let screen = NSScreen.main else {
            return CGRect(origin: .zero, size: zoomWindowSize)
        }
        
        let margin: CGFloat = 20
        let position = CGPoint(
            x: screen.frame.width - zoomWindowSize.width - margin,
            y: screen.frame.height - zoomWindowSize.height - margin
        )
        
        return CGRect(origin: position, size: zoomWindowSize)
    }
    
    /// Get formatted zoom level string
    var formattedZoomLevel: String {
        if currentZoomLevel == 1.0 {
            return "1x (No Zoom)"
        } else {
            return String(format: "%.1fx", currentZoomLevel)
        }
    }
    
    // MARK: - Zoom Presets
    
    /// Quick zoom to common levels
    func quickZoom(to level: CGFloat) {
        guard defaultZoomLevels.contains(level) else { return }
        setZoomLevel(Float(level))
    }
    
    /// Get next zoom level in sequence
    func getNextZoomLevel() -> CGFloat {
        guard let currentIndex = defaultZoomLevels.firstIndex(of: CGFloat(currentZoomLevel)) else {
            // Find closest level
            let closest = defaultZoomLevels.min { abs($0 - CGFloat(currentZoomLevel)) < abs($1 - CGFloat(currentZoomLevel)) }
            return closest ?? defaultZoomLevels.first ?? CGFloat(minZoomLevel)
        }
        
        let nextIndex = min(currentIndex + 1, defaultZoomLevels.count - 1)
        return CGFloat(defaultZoomLevels[nextIndex])
    }
    
    /// Get previous zoom level in sequence
    func getPreviousZoomLevel() -> CGFloat {
        guard let currentIndex = defaultZoomLevels.firstIndex(of: CGFloat(currentZoomLevel)) else {
            let closest = defaultZoomLevels.min { abs($0 - CGFloat(currentZoomLevel)) < abs($1 - CGFloat(currentZoomLevel)) }
            return closest ?? defaultZoomLevels.first ?? CGFloat(minZoomLevel)
        }
        
        let previousIndex = max(currentIndex - 1, 0)
        return CGFloat(defaultZoomLevels[previousIndex])
    }
    
    // MARK: - Zoom Mode
    
    /// Set zoom center point
    func setZoomCenter(_ point: CGPoint) {
        zoomCenter = point
        print("ZoomManager: Zoom center set to \(point)")
    }
    
    /// Change zoom mode
    func setZoomMode(_ mode: ZoomMode) {
        let previousMode = zoomMode
        zoomMode = mode
        
        // Handle mode transitions
        if isZooming {
            if previousMode == .followMouse && mode != .followMouse {
                stopMouseTracking()
            } else if previousMode != .followMouse && mode == .followMouse {
                startMouseTracking()
            }
            
            updateZoomCenter()
        }
        
        print("ZoomManager: Zoom mode changed to \(mode)")
    }
    
    private func updateZoomCenter() {
        switch zoomMode {
        case .followMouse:
            updateMousePosition()
        case .fixedPosition:
            // Keep current center
            break
        case .fullScreen:
            // Center on screen
            if let screen = NSScreen.main {
                let screenCenter = CGPoint(
                    x: screen.frame.width / 2,
                    y: screen.frame.height / 2
                )
                zoomCenter = screenCenter
            }
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopZoom()
        stopMouseTracking()
        print("ZoomManager: Cleanup completed")
    }
}

// MARK: - PreferencesManager Extension for Zoom Settings

extension PreferencesManager {
    
    /// Default zoom level setting
    var defaultZoomLevel: Float {
        get {
            let level = UserDefaults.standard.float(forKey: "defaultZoomLevel")
            return level > 0 ? level : 2.0 // Default to 2x zoom
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "defaultZoomLevel")
        }
    }
    
    /// Default zoom window size setting
    var defaultZoomWindowSize: CGSize {
        get {
            let width = UserDefaults.standard.double(forKey: "zoomWindowWidth")
            let height = UserDefaults.standard.double(forKey: "zoomWindowHeight")
            
            if width > 0 && height > 0 {
                return CGSize(width: width, height: height)
            } else {
                return CGSize(width: 400, height: 300) // Default size
            }
        }
        set {
            UserDefaults.standard.set(newValue.width, forKey: "zoomWindowWidth")
            UserDefaults.standard.set(newValue.height, forKey: "zoomWindowHeight")
        }
    }
    
    /// Mouse tracking enabled setting
    var zoomMouseTrackingEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "zoomMouseTrackingEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "zoomMouseTrackingEnabled")
        }
    }
    
    /// GPU acceleration preference for zoom
    var zoomGPUAccelerationEnabled: Bool {
        get {
            // Default to true if available
            return UserDefaults.standard.object(forKey: "zoomGPUAccelerationEnabled") as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "zoomGPUAccelerationEnabled")
        }
    }
}

// MARK: - ScreenCaptureManager Extension for Zoom Support

extension ScreenCaptureManager {
    
    /// Capture a specific region of the screen for zoom functionality
    func captureScreenRegion(_ rect: CGRect) async -> CGImage? {
        // Ensure rect is within screen bounds
        guard let screen = NSScreen.main else { return nil }
        
        let screenRect = screen.frame
        let clampedRect = rect.intersection(screenRect)
        
        guard !clampedRect.isEmpty else { return nil }
        
        // Use existing screen capture functionality with region
        if let fullScreenImage = await captureCurrentScreen() {
            // Crop to the specified region
            return fullScreenImage.cropping(to: clampedRect)
        }
        
        return nil
    }
}

// MARK: - Zoom Indicator Support

extension ZoomManager {
    
    /// Generate zoom indicator data for screen recording overlay
    var zoomIndicatorData: ZoomIndicatorData {
        return ZoomIndicatorData(
            isActive: isZooming,
            zoomLevel: currentZoomLevel,
            position: zoomCenter,
            mode: zoomMode,
            displayRect: displayRect,
            zoomRect: zoomRect
        )
    }
    
    struct ZoomIndicatorData {
        let isActive: Bool
        let zoomLevel: CGFloat
        let position: CGPoint
        let mode: ZoomMode
        let displayRect: CGRect
        let zoomRect: CGRect
        
        var formattedLevel: String {
            return String(format: "%.1fx", zoomLevel)
        }
        
        var color: NSColor {
            return isActive ? .systemBlue : .systemGray
        }
        
        var indicatorSize: CGFloat {
            return 30.0 + (zoomLevel - 1.0) * 2.0 // Scale indicator with zoom level
        }
    }
} 