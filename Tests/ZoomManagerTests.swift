import XCTest
import AppKit
@testable import Magnify

final class ZoomManagerTests: XCTestCase {
    
    var zoomManager: ZoomManager!
    var preferencesManager: PreferencesManager!
    
    override func setUpWithError() throws {
        // Get shared instances for testing
        zoomManager = ZoomManager.shared
        preferencesManager = PreferencesManager.shared
        
        // Reset zoom state before each test
        zoomManager.stopZoom()
        zoomManager.setZoomLevel(1.0)
    }
    
    override func tearDownWithError() throws {
        // Clean up after each test
        zoomManager.stopZoom()
        zoomManager.setZoomLevel(1.0)
    }
    
    // MARK: - Initialization Tests
    
    func testSingletonInstance() throws {
        let instance1 = ZoomManager.shared
        let instance2 = ZoomManager.shared
        
        XCTAssertTrue(instance1 === instance2, "ZoomManager should be a singleton")
    }
    
    func testInitialState() throws {
        XCTAssertFalse(zoomManager.isZoomActive, "Zoom should not be active initially")
        XCTAssertEqual(zoomManager.currentZoomLevel, 1.0, "Initial zoom level should be 1.0")
        XCTAssertFalse(zoomManager.isAtMaxZoom, "Should not be at max zoom initially")
        XCTAssertTrue(zoomManager.isAtMinZoom, "Should be at min zoom initially")
    }
    
    // MARK: - Zoom Level Control Tests
    
    func testSetZoomLevel() throws {
        let testLevel: Float = 3.5
        zoomManager.setZoomLevel(testLevel)
        
        XCTAssertEqual(zoomManager.currentZoomLevel, testLevel, "Zoom level should be set correctly")
        XCTAssertEqual(zoomManager.zoomPercentage, 350, "Zoom percentage should be calculated correctly")
    }
    
    func testZoomLevelClamping() throws {
        // Test minimum clamping
        zoomManager.setZoomLevel(0.5)
        XCTAssertEqual(zoomManager.currentZoomLevel, 1.0, "Zoom level should be clamped to minimum")
        
        // Test maximum clamping
        zoomManager.setZoomLevel(15.0)
        XCTAssertEqual(zoomManager.currentZoomLevel, 10.0, "Zoom level should be clamped to maximum")
    }
    
    func testZoomIn() throws {
        let initialLevel = zoomManager.currentZoomLevel
        zoomManager.zoomIn()
        
        XCTAssertGreaterThan(zoomManager.currentZoomLevel, initialLevel, "Zoom level should increase")
        XCTAssertEqual(zoomManager.currentZoomLevel, initialLevel + 0.5, "Zoom should increase by 0.5")
    }
    
    func testZoomOut() throws {
        zoomManager.setZoomLevel(3.0)
        let initialLevel = zoomManager.currentZoomLevel
        zoomManager.zoomOut()
        
        XCTAssertLessThan(zoomManager.currentZoomLevel, initialLevel, "Zoom level should decrease")
        XCTAssertEqual(zoomManager.currentZoomLevel, initialLevel - 0.5, "Zoom should decrease by 0.5")
    }
    
    func testResetZoom() throws {
        zoomManager.setZoomLevel(5.0)
        zoomManager.resetZoom()
        
        XCTAssertEqual(zoomManager.currentZoomLevel, 1.0, "Zoom should reset to 1.0")
    }
    
    func testZoomAtLimits() throws {
        // Test at minimum zoom
        zoomManager.setZoomLevel(1.0)
        XCTAssertTrue(zoomManager.isAtMinZoom, "Should be at min zoom")
        XCTAssertFalse(zoomManager.isAtMaxZoom, "Should not be at max zoom")
        
        // Test zoom out from minimum (should stay at minimum)
        zoomManager.zoomOut()
        XCTAssertEqual(zoomManager.currentZoomLevel, 1.0, "Should stay at minimum when zooming out")
        
        // Test at maximum zoom
        zoomManager.setZoomLevel(10.0)
        XCTAssertFalse(zoomManager.isAtMinZoom, "Should not be at min zoom")
        XCTAssertTrue(zoomManager.isAtMaxZoom, "Should be at max zoom")
        
        // Test zoom in from maximum (should stay at maximum)
        zoomManager.zoomIn()
        XCTAssertEqual(zoomManager.currentZoomLevel, 10.0, "Should stay at maximum when zooming in")
    }
    
    // MARK: - Zoom State Management Tests
    
    func testStartStopZoom() throws {
        XCTAssertFalse(zoomManager.isZoomActive, "Zoom should not be active initially")
        
        zoomManager.startZoom()
        XCTAssertTrue(zoomManager.isZoomActive, "Zoom should be active after starting")
        
        zoomManager.stopZoom()
        XCTAssertFalse(zoomManager.isZoomActive, "Zoom should not be active after stopping")
    }
    
    func testToggleZoom() throws {
        let initialState = zoomManager.isZoomActive
        
        zoomManager.toggleZoom()
        XCTAssertNotEqual(zoomManager.isZoomActive, initialState, "Zoom state should toggle")
        
        zoomManager.toggleZoom()
        XCTAssertEqual(zoomManager.isZoomActive, initialState, "Zoom state should return to initial")
    }
    
    func testMultipleStartCalls() throws {
        zoomManager.startZoom()
        let firstState = zoomManager.isZoomActive
        
        // Second start call should have no effect
        zoomManager.startZoom()
        XCTAssertEqual(zoomManager.isZoomActive, firstState, "Multiple start calls should not change state")
    }
    
    func testMultipleStopCalls() throws {
        zoomManager.startZoom()
        zoomManager.stopZoom()
        let firstState = zoomManager.isZoomActive
        
        // Second stop call should have no effect
        zoomManager.stopZoom()
        XCTAssertEqual(zoomManager.isZoomActive, firstState, "Multiple stop calls should not change state")
    }
    
    // MARK: - Zoom Position and Size Tests
    
    func testSetZoomPosition() throws {
        let testPosition = CGPoint(x: 100, y: 200)
        zoomManager.setZoomPosition(testPosition)
        
        XCTAssertEqual(zoomManager.zoomPosition, testPosition, "Zoom position should be set correctly")
    }
    
    func testSetZoomWindowSize() throws {
        let testSize = CGSize(width: 500, height: 400)
        zoomManager.setZoomWindowSize(testSize)
        
        XCTAssertEqual(zoomManager.zoomWindowSize, testSize, "Zoom window size should be set correctly")
    }
    
    func testZoomWindowSizeClamping() throws {
        // Test minimum size clamping
        zoomManager.setZoomWindowSize(CGSize(width: 100, height: 100))
        XCTAssertGreaterThanOrEqual(zoomManager.zoomWindowSize.width, 200, "Width should be clamped to minimum")
        XCTAssertGreaterThanOrEqual(zoomManager.zoomWindowSize.height, 150, "Height should be clamped to minimum")
        
        // Test maximum size clamping
        zoomManager.setZoomWindowSize(CGSize(width: 1000, height: 1000))
        XCTAssertLessThanOrEqual(zoomManager.zoomWindowSize.width, 800, "Width should be clamped to maximum")
        XCTAssertLessThanOrEqual(zoomManager.zoomWindowSize.height, 600, "Height should be clamped to maximum")
    }
    
    // MARK: - Available Zoom Levels Tests
    
    func testAvailableZoomLevels() throws {
        let levels = zoomManager.availableZoomLevels
        
        XCTAssertFalse(levels.isEmpty, "Available zoom levels should not be empty")
        XCTAssertTrue(levels.contains(1.0), "Should contain minimum zoom level")
        XCTAssertTrue(levels.contains(10.0), "Should contain maximum zoom level")
        XCTAssertTrue(levels.contains(2.0), "Should contain intermediate zoom levels")
        
        // Check that levels are in ascending order
        for i in 1..<levels.count {
            XCTAssertLessThan(levels[i-1], levels[i], "Zoom levels should be in ascending order")
        }
    }
    
    func testZoomPercentageCalculation() throws {
        zoomManager.setZoomLevel(1.0)
        XCTAssertEqual(zoomManager.zoomPercentage, 100, "1.0 zoom should be 100%")
        
        zoomManager.setZoomLevel(2.5)
        XCTAssertEqual(zoomManager.zoomPercentage, 250, "2.5 zoom should be 250%")
        
        zoomManager.setZoomLevel(10.0)
        XCTAssertEqual(zoomManager.zoomPercentage, 1000, "10.0 zoom should be 1000%")
    }
    
    // MARK: - Performance Metrics Tests
    
    func testPerformanceMetrics() throws {
        let metrics = zoomManager.getPerformanceMetrics()
        
        XCTAssertGreaterThanOrEqual(metrics.fps, 0, "FPS should be non-negative")
        XCTAssertGreaterThanOrEqual(metrics.frameTime, 0, "Frame time should be non-negative")
        
        // GPU acceleration availability depends on system
        // Just verify the property is accessible
        _ = metrics.isGPUAccelerated
    }
    
    // MARK: - Mouse Tracking Tests
    
    func testMouseTrackingToggle() throws {
        // Test enabling mouse tracking
        zoomManager.setMouseTracking(enabled: true)
        // Note: We can't easily test the actual mouse tracking without UI automation
        // This mainly tests that the method doesn't crash
        
        // Test disabling mouse tracking
        zoomManager.setMouseTracking(enabled: false)
    }
    
    func testUpdateZoomToMousePosition() throws {
        let initialPosition = zoomManager.zoomPosition
        
        // Call the method (it will use current mouse position)
        zoomManager.updateZoomToMousePosition()
        
        // The position may or may not change depending on current mouse location
        // This mainly tests that the method doesn't crash
        _ = zoomManager.zoomPosition
    }
    
    // MARK: - Preferences Integration Tests
    
    func testDefaultZoomLevelPreference() throws {
        let testLevel: Float = 3.0
        preferencesManager.defaultZoomLevel = testLevel
        
        XCTAssertEqual(preferencesManager.defaultZoomLevel, testLevel, "Default zoom level should be stored in preferences")
    }
    
    func testDefaultZoomWindowSizePreference() throws {
        let testSize = CGSize(width: 600, height: 450)
        preferencesManager.defaultZoomWindowSize = testSize
        
        XCTAssertEqual(preferencesManager.defaultZoomWindowSize, testSize, "Default zoom window size should be stored in preferences")
    }
    
    func testMouseTrackingPreference() throws {
        preferencesManager.zoomMouseTrackingEnabled = true
        XCTAssertTrue(preferencesManager.zoomMouseTrackingEnabled, "Mouse tracking preference should be stored")
        
        preferencesManager.zoomMouseTrackingEnabled = false
        XCTAssertFalse(preferencesManager.zoomMouseTrackingEnabled, "Mouse tracking preference should be updated")
    }
    
    func testGPUAccelerationPreference() throws {
        preferencesManager.zoomGPUAccelerationEnabled = false
        XCTAssertFalse(preferencesManager.zoomGPUAccelerationEnabled, "GPU acceleration preference should be stored")
        
        preferencesManager.zoomGPUAccelerationEnabled = true
        XCTAssertTrue(preferencesManager.zoomGPUAccelerationEnabled, "GPU acceleration preference should be updated")
    }
    
    // MARK: - Integration Tests
    
    func testZoomManagerIntegration() throws {
        // Test complete zoom workflow
        
        // 1. Set preferences
        preferencesManager.defaultZoomLevel = 2.0
        preferencesManager.defaultZoomWindowSize = CGSize(width: 500, height: 400)
        
        // 2. Start zoom
        zoomManager.startZoom()
        XCTAssertTrue(zoomManager.isZoomActive, "Zoom should be active")
        
        // 3. Change zoom level
        zoomManager.setZoomLevel(4.0)
        XCTAssertEqual(zoomManager.currentZoomLevel, 4.0, "Zoom level should be updated")
        
        // 4. Change position and size
        let testPosition = CGPoint(x: 300, y: 300)
        let testSize = CGSize(width: 600, height: 500)
        zoomManager.setZoomPosition(testPosition)
        zoomManager.setZoomWindowSize(testSize)
        
        XCTAssertEqual(zoomManager.zoomPosition, testPosition, "Position should be updated")
        XCTAssertEqual(zoomManager.zoomWindowSize, testSize, "Size should be updated")
        
        // 5. Stop zoom
        zoomManager.stopZoom()
        XCTAssertFalse(zoomManager.isZoomActive, "Zoom should be stopped")
    }
    
    // MARK: - Performance Tests
    
    func testZoomPerformance() throws {
        measure {
            // Test zoom level changes performance
            for i in 0..<100 {
                let level = Float(i % 19 + 1) / 2.0 // Cycle through 1.0 to 10.0
                zoomManager.setZoomLevel(level)
            }
        }
    }
    
    func testZoomPositionPerformance() throws {
        measure {
            // Test zoom position changes performance
            for i in 0..<100 {
                let position = CGPoint(x: CGFloat(i * 10), y: CGFloat(i * 10))
                zoomManager.setZoomPosition(position)
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testZoomWithNaNValues() throws {
        // Test with NaN values (should be handled gracefully)
        zoomManager.setZoomLevel(Float.nan)
        XCTAssertFalse(zoomManager.currentZoomLevel.isNaN, "Zoom level should not be NaN")
        
        zoomManager.setZoomPosition(CGPoint(x: CGFloat.nan, y: CGFloat.nan))
        XCTAssertFalse(zoomManager.zoomPosition.x.isNaN, "Zoom position should not contain NaN")
        XCTAssertFalse(zoomManager.zoomPosition.y.isNaN, "Zoom position should not contain NaN")
    }
    
    func testZoomWithInfiniteValues() throws {
        // Test with infinite values (should be handled gracefully)
        zoomManager.setZoomLevel(Float.infinity)
        XCTAssertTrue(zoomManager.currentZoomLevel.isFinite, "Zoom level should be finite")
        
        zoomManager.setZoomPosition(CGPoint(x: CGFloat.infinity, y: CGFloat.infinity))
        XCTAssertTrue(zoomManager.zoomPosition.x.isFinite, "Zoom position should be finite")
        XCTAssertTrue(zoomManager.zoomPosition.y.isFinite, "Zoom position should be finite")
    }
    
    func testZoomStateConsistency() throws {
        // Test that zoom state remains consistent across operations
        
        zoomManager.startZoom()
        let initialState = zoomManager.isZoomActive
        
        // Perform various operations
        zoomManager.setZoomLevel(5.0)
        zoomManager.setZoomPosition(CGPoint(x: 100, y: 100))
        zoomManager.setZoomWindowSize(CGSize(width: 400, height: 300))
        zoomManager.zoomIn()
        zoomManager.zoomOut()
        
        // State should remain consistent
        XCTAssertEqual(zoomManager.isZoomActive, initialState, "Zoom state should remain consistent")
        
        zoomManager.stopZoom()
        XCTAssertFalse(zoomManager.isZoomActive, "Zoom should be stopped")
    }
    
    // MARK: - Memory Management Tests
    
    func testZoomManagerMemoryUsage() throws {
        // Test that starting and stopping zoom doesn't cause memory leaks
        let initialMemory = getCurrentMemoryUsage()
        
        for _ in 0..<10 {
            zoomManager.startZoom()
            zoomManager.setZoomLevel(Float.random(in: 1.0...10.0))
            zoomManager.setZoomPosition(CGPoint(x: Double.random(in: 0...1000), y: Double.random(in: 0...1000)))
            zoomManager.stopZoom()
        }
        
        let finalMemory = getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Allow for some memory growth but not excessive
        XCTAssertLessThan(memoryIncrease, 10_000_000, "Memory usage should not increase excessively") // 10MB limit
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
} 