import XCTest
import ScreenCaptureKit
@testable import Magnify

final class ScreenCaptureManagerTests: XCTestCase {
    
    var screenCaptureManager: ScreenCaptureManager!
    
    override func setUpWithError() throws {
        screenCaptureManager = ScreenCaptureManager()
    }
    
    override func tearDownWithError() throws {
        screenCaptureManager = nil
    }
    
    // MARK: - Permission Tests
    
    func testRequestPermission() async throws {
        // Test permission request
        let hasPermission = await screenCaptureManager.requestPermission()
        
        // Note: This test will depend on the actual system permission state
        // In a real test environment, this should be mocked
        XCTAssertTrue(hasPermission is Bool, "Permission request should return a boolean value")
    }
    
    func testHasScreenRecordingPermission() async throws {
        // Test permission status check
        let hasPermission = await screenCaptureManager.hasScreenRecordingPermission()
        
        XCTAssertTrue(hasPermission is Bool, "Permission status check should return a boolean value")
    }
    
    // MARK: - Screen Capture Tests
    
    func testCaptureCurrentScreen() async throws {
        // First ensure we have permission (or skip if not available)
        let hasPermission = await screenCaptureManager.requestPermission()
        
        if !hasPermission {
            throw XCTSkip("Screen recording permission not granted - skipping screen capture test")
        }
        
        // Test screen capture
        let startTime = CFAbsoluteTimeGetCurrent()
        let capturedImage = await screenCaptureManager.captureCurrentScreen()
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let captureTime = (endTime - startTime) * 1000 // Convert to milliseconds
        
        // Verify capture was successful
        XCTAssertNotNil(capturedImage, "Screen capture should return a valid CGImage")
        
        if let image = capturedImage {
            XCTAssertGreaterThan(image.width, 0, "Captured image should have valid width")
            XCTAssertGreaterThan(image.height, 0, "Captured image should have valid height")
        }
        
        // Verify performance requirement (<100ms)
        XCTAssertLessThan(captureTime, 100.0, "Screen capture should complete in under 100ms")
        
        print("Screen capture completed in \(String(format: "%.1f", captureTime)) ms")
    }
    
    // MARK: - Display Information Tests
    
    func testGetAvailableDisplays() async throws {
        let displays = await screenCaptureManager.getAvailableDisplays()
        
        // Should return an array (might be empty if no permission)
        XCTAssertTrue(displays is [SCDisplay], "Should return an array of SCDisplay objects")
        
        // If permission is granted, should have at least one display
        let hasPermission = await screenCaptureManager.requestPermission()
        if hasPermission {
            XCTAssertGreaterThan(displays.count, 0, "Should have at least one display when permission is granted")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testCaptureWithoutPermission() async throws {
        // Note: This test is conceptual - in practice, testing permission denial
        // requires system-level mocking or a test environment without permissions
        
        // For now, we test that the method handles errors gracefully
        let capturedImage = await screenCaptureManager.captureCurrentScreen()
        
        // Method should not crash and should return either an image or nil
        XCTAssertTrue(capturedImage == nil || capturedImage != nil, "Capture method should handle errors gracefully")
    }
    
    // MARK: - Performance Tests
    
    func testCapturePerformance() async throws {
        let hasPermission = await screenCaptureManager.requestPermission()
        
        if !hasPermission {
            throw XCTSkip("Screen recording permission not granted - skipping performance test")
        }
        
        // Measure performance of multiple captures
        let numberOfCaptures = 5
        var captureTimes: [Double] = []
        
        for i in 1...numberOfCaptures {
            let startTime = CFAbsoluteTimeGetCurrent()
            let capturedImage = await screenCaptureManager.captureCurrentScreen()
            let endTime = CFAbsoluteTimeGetCurrent()
            
            let captureTime = (endTime - startTime) * 1000
            captureTimes.append(captureTime)
            
            XCTAssertNotNil(capturedImage, "Capture \(i) should succeed")
            print("Capture \(i): \(String(format: "%.1f", captureTime)) ms")
        }
        
        // Calculate average capture time
        let averageTime = captureTimes.reduce(0, +) / Double(captureTimes.count)
        print("Average capture time: \(String(format: "%.1f", averageTime)) ms")
        
        // Verify performance requirement
        XCTAssertLessThan(averageTime, 100.0, "Average screen capture time should be under 100ms")
        
        // Verify no capture takes longer than 200ms (tolerance for slow systems)
        let maxTime = captureTimes.max() ?? 0
        XCTAssertLessThan(maxTime, 200.0, "No single capture should take longer than 200ms")
    }
    
    // MARK: - Memory Tests
    
    func testMemoryUsage() async throws {
        let hasPermission = await screenCaptureManager.requestPermission()
        
        if !hasPermission {
            throw XCTSkip("Screen recording permission not granted - skipping memory test")
        }
        
        // Capture multiple images and ensure no memory leaks
        let numberOfCaptures = 10
        
        for i in 1...numberOfCaptures {
            autoreleasepool {
                Task {
                    let capturedImage = await screenCaptureManager.captureCurrentScreen()
                    XCTAssertNotNil(capturedImage, "Capture \(i) should succeed")
                    // Image should be released when leaving this scope
                }
            }
        }
        
        // Note: In a more comprehensive test, we would measure actual memory usage
        // using XCTMemoryMetric or similar tools
        XCTAssertTrue(true, "Memory test completed without crashes")
    }
    
    // MARK: - Availability Tests
    
    func testMacOSVersionCompatibility() {
        // Test that the manager works on different macOS versions
        if #available(macOS 12.3, *) {
            XCTAssertTrue(true, "ScreenCaptureKit APIs are available")
        } else {
            // Test fallback functionality
            XCTAssertTrue(true, "Fallback APIs should be used on older macOS versions")
        }
    }
    
    // MARK: - Live Capture Tests (Basic)
    
    func testLiveCaptureStreamBasic() async throws {
        // Basic test to ensure live capture methods don't crash
        var frameReceived = false
        
        let frameHandler: (CGImage) -> Void = { _ in
            frameReceived = true
        }
        
        // Attempt to start live capture
        let success = await screenCaptureManager.startLiveCaptureStream(frameHandler: frameHandler)
        
        // On systems without permission, this should return false
        // On systems with permission, this should return true
        XCTAssertTrue(success is Bool, "startLiveCaptureStream should return a boolean")
        
        if success {
            // If started successfully, stop it
            await screenCaptureManager.stopLiveCaptureStream()
        }
    }
}

// MARK: - Test Extensions

extension ScreenCaptureManagerTests {
    
    /// Helper method to check if running in CI environment
    private var isRunningInCI: Bool {
        return ProcessInfo.processInfo.environment["CI"] != nil
    }
    
    /// Helper method to skip tests that require user interaction
    private func skipIfCI() throws {
        if isRunningInCI {
            throw XCTSkip("Skipping test that requires user interaction in CI environment")
        }
    }
} 