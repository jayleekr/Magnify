import Foundation
import ScreenCaptureKit
import CoreGraphics

/// Manages screen capture functionality using ScreenCaptureKit
/// Provides async methods for permission handling and screen capture operations
class ScreenCaptureManager {
    
    // MARK: - Properties
    
    private var captureSession: SCStreamSession?
    private var isCapturing = false
    
    // MARK: - Permission Management
    
    /// Request screen recording permission from the user
    /// - Returns: Boolean indicating if permission was granted
    func requestPermission() async -> Bool {
        guard #available(macOS 12.3, *) else {
            // Fallback for older macOS versions
            return await requestPermissionFallback()
        }
        
        do {
            // Try to get shareable content to test permissions
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            // If we can get displays, permission is granted
            return !content.displays.isEmpty
        } catch {
            print("Screen capture permission error: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Fallback permission request for macOS < 12.3
    private func requestPermissionFallback() async -> Bool {
        // Use CGWindowListCreateImage as a permission test
        let imageRef = CGWindowListCreateImage(
            CGRect.null,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .nominalResolution
        )
        
        return imageRef != nil
    }
    
    // MARK: - Screen Capture
    
    /// Capture the current screen as a CGImage
    /// - Returns: CGImage of the captured screen, or nil if capture fails
    func captureCurrentScreen() async -> CGImage? {
        guard #available(macOS 12.3, *) else {
            return await captureCurrentScreenFallback()
        }
        
        do {
            // Get available displays
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            guard let display = content.displays.first else {
                print("No displays available for capture")
                return nil
            }
            
            // Create screen capture configuration
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let configuration = SCStreamConfiguration()
            
            // Configure for high quality capture
            configuration.width = Int(display.width)
            configuration.height = Int(display.height)
            configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60) // 60 FPS
            configuration.queueDepth = 5
            
            // Capture single frame
            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: configuration
            )
            
            return image
        } catch {
            print("Screen capture error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Fallback screen capture for macOS < 12.3
    private func captureCurrentScreenFallback() async -> CGImage? {
        return CGWindowListCreateImage(
            CGRect.null,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        )
    }
    
    // MARK: - Live Capture Stream
    
    /// Start a live capture stream for real-time screen updates
    /// - Parameter frameHandler: Callback for each captured frame
    func startLiveCaptureStream(frameHandler: @escaping (CGImage) -> Void) async -> Bool {
        guard #available(macOS 12.3, *) else {
            print("Live capture stream requires macOS 12.3 or later")
            return false
        }
        
        guard !isCapturing else {
            print("Capture stream already running")
            return false
        }
        
        do {
            // Get display content
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            guard let display = content.displays.first else {
                print("No displays available for live capture")
                return false
            }
            
            // Create content filter and configuration
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let configuration = SCStreamConfiguration()
            
            // Configure for real-time performance
            configuration.width = Int(display.width)
            configuration.height = Int(display.height)
            configuration.minimumFrameInterval = CMTime(value: 1, timescale: 30) // 30 FPS for performance
            configuration.queueDepth = 3
            
            // Create stream delegate
            let streamDelegate = ScreenCaptureStreamDelegate(frameHandler: frameHandler)
            
            // Create and start stream
            let stream = SCStream(filter: filter, configuration: configuration, delegate: streamDelegate)
            
            try await stream.startCapture()
            
            isCapturing = true
            print("Live capture stream started successfully")
            return true
            
        } catch {
            print("Failed to start live capture stream: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Stop the live capture stream
    func stopLiveCaptureStream() async {
        guard isCapturing else {
            print("No capture stream running")
            return
        }
        
        // Note: In a full implementation, we would store the SCStream reference
        // and call stopCapture() here. For now, we just update the flag.
        isCapturing = false
        print("Live capture stream stopped")
    }
    
    // MARK: - Utility Methods
    
    /// Check if the app currently has screen recording permission
    /// - Returns: Boolean indicating permission status
    func hasScreenRecordingPermission() async -> Bool {
        return await requestPermission()
    }
    
    /// Get information about available displays
    /// - Returns: Array of display information
    func getAvailableDisplays() async -> [SCDisplay] {
        guard #available(macOS 12.3, *) else {
            return []
        }
        
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            return content.displays
        } catch {
            print("Failed to get available displays: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Stream Delegate

/// Delegate for handling live capture stream frames
@available(macOS 12.3, *)
private class ScreenCaptureStreamDelegate: NSObject, SCStreamDelegate {
    
    private let frameHandler: (CGImage) -> Void
    
    init(frameHandler: @escaping (CGImage) -> Void) {
        self.frameHandler = frameHandler
        super.init()
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        // Process video frame
        guard type == .screen,
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // Convert CVPixelBuffer to CGImage
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            DispatchQueue.main.async {
                self.frameHandler(cgImage)
            }
        }
    }
    
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("Stream stopped with error: \(error.localizedDescription)")
    }
} 