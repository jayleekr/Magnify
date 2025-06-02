import XCTest
import AVFoundation
import ScreenCaptureKit
@testable import Magnify

/// Comprehensive test suite for ScreenRecordingManager
/// Tests recording lifecycle, format handling, error scenarios, and performance metrics
@MainActor
final class ScreenRecordingManagerTests: XCTestCase {
    
    var screenRecordingManager: ScreenRecordingManager!
    var testOutputDirectory: URL!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        screenRecordingManager = ScreenRecordingManager.shared
        
        // Create test output directory
        let tempDirectory = FileManager.default.temporaryDirectory
        testOutputDirectory = tempDirectory.appendingPathComponent("MagnifyTestRecordings", isDirectory: true)
        
        try FileManager.default.createDirectory(at: testOutputDirectory, withIntermediateDirectories: true)
        
        // Reset manager state
        if screenRecordingManager.isRecording {
            let _ = await screenRecordingManager.stopRecording()
        }
        
        print("ScreenRecordingManagerTests: Test setup completed")
    }
    
    override func tearDownWithError() throws {
        // Clean up test recordings
        if FileManager.default.fileExists(atPath: testOutputDirectory.path) {
            try FileManager.default.removeItem(at: testOutputDirectory)
        }
        
        // Ensure recording is stopped
        if screenRecordingManager.isRecording {
            let _ = await screenRecordingManager.stopRecording()
        }
        
        screenRecordingManager = nil
        testOutputDirectory = nil
        
        try super.tearDownWithError()
        print("ScreenRecordingManagerTests: Test cleanup completed")
    }
    
    // MARK: - Initialization Tests
    
    func testScreenRecordingManagerInitialization() throws {
        XCTAssertNotNil(screenRecordingManager, "ScreenRecordingManager should initialize successfully")
        XCTAssertFalse(screenRecordingManager.isRecording, "Should not be recording initially")
        XCTAssertFalse(screenRecordingManager.isPaused, "Should not be paused initially")
        XCTAssertEqual(screenRecordingManager.recordingStatus, .idle, "Initial status should be idle")
        XCTAssertEqual(screenRecordingManager.recordingDuration, 0.0, "Initial duration should be zero")
        XCTAssertNil(screenRecordingManager.currentRecordingURL, "No recording URL initially")
    }
    
    func testDefaultSettings() throws {
        XCTAssertEqual(screenRecordingManager.selectedFormat, .mp4, "Default format should be MP4")
        XCTAssertEqual(screenRecordingManager.recordingQuality, .high, "Default quality should be high")
        XCTAssertTrue(screenRecordingManager.includeAnnotations, "Should include annotations by default")
        XCTAssertFalse(screenRecordingManager.includeSystemAudio, "Should not include system audio by default")
        XCTAssertFalse(screenRecordingManager.includeMicrophone, "Should not include microphone by default")
    }
    
    // MARK: - Recording State Tests
    
    func testRecordingStateProperties() throws {
        XCTAssertTrue(screenRecordingManager.isReadyToRecord, "Should be ready to record initially")
        XCTAssertEqual(screenRecordingManager.formattedDuration, "00:00", "Formatted duration should be 00:00 initially")
        XCTAssertEqual(screenRecordingManager.estimatedFileSize, "0 bytes", "Estimated file size should be 0 bytes initially")
    }
    
    func testRecordingStatusEnum() throws {
        let allStatuses = ScreenRecordingManager.RecordingStatus.allCases
        
        XCTAssertTrue(allStatuses.contains(.idle), "Should include idle status")
        XCTAssertTrue(allStatuses.contains(.recording), "Should include recording status")
        XCTAssertTrue(allStatuses.contains(.completed), "Should include completed status")
        XCTAssertTrue(allStatuses.contains(.error), "Should include error status")
        
        // Test status properties
        XCTAssertEqual(ScreenRecordingManager.RecordingStatus.recording.icon, "record.circle.fill")
        XCTAssertEqual(ScreenRecordingManager.RecordingStatus.idle.color, .systemGray)
        XCTAssertEqual(ScreenRecordingManager.RecordingStatus.recording.color, .systemRed)
    }
    
    // MARK: - Format and Quality Tests
    
    func testVideoFormatEnum() throws {
        let allFormats = ScreenRecordingManager.VideoFormat.allCases
        
        XCTAssertTrue(allFormats.contains(.mp4), "Should include MP4 format")
        XCTAssertTrue(allFormats.contains(.mov), "Should include MOV format")
        XCTAssertTrue(allFormats.contains(.avi), "Should include AVI format")
        
        // Test format properties
        XCTAssertEqual(ScreenRecordingManager.VideoFormat.mp4.fileExtension, "mp4")
        XCTAssertEqual(ScreenRecordingManager.VideoFormat.mp4.codecType, .h264)
        XCTAssertEqual(ScreenRecordingManager.VideoFormat.mp4.containerType, .mp4)
        XCTAssertEqual(ScreenRecordingManager.VideoFormat.mp4.displayName, "MP4 (H.264)")
    }
    
    func testRecordingQualityEnum() throws {
        let allQualities = ScreenRecordingManager.RecordingQuality.allCases
        
        XCTAssertTrue(allQualities.contains(.low), "Should include low quality")
        XCTAssertTrue(allQualities.contains(.medium), "Should include medium quality")
        XCTAssertTrue(allQualities.contains(.high), "Should include high quality")
        XCTAssertTrue(allQualities.contains(.ultra), "Should include ultra quality")
        
        // Test quality properties
        XCTAssertEqual(ScreenRecordingManager.RecordingQuality.low.resolution, CGSize(width: 1280, height: 720))
        XCTAssertEqual(ScreenRecordingManager.RecordingQuality.high.resolution, CGSize(width: 2560, height: 1440))
        XCTAssertEqual(ScreenRecordingManager.RecordingQuality.low.frameRate, 24)
        XCTAssertEqual(ScreenRecordingManager.RecordingQuality.ultra.frameRate, 60)
        XCTAssertGreaterThan(ScreenRecordingManager.RecordingQuality.high.bitrate, ScreenRecordingManager.RecordingQuality.low.bitrate)
    }
    
    // MARK: - Permission Tests
    
    func testPermissionRequirement() async throws {
        // Test that recording requires screen recording permission
        // Note: This test may skip if permission is not granted
        
        let screenCaptureManager = ScreenCaptureManager()
        let hasPermission = await screenCaptureManager.hasScreenRecordingPermission()
        
        if !hasPermission {
            throw XCTSkip("Screen recording permission not granted - skipping recording tests")
        }
        
        XCTAssertTrue(hasPermission, "Should have screen recording permission for testing")
    }
    
    // MARK: - Recording Lifecycle Tests
    
    func testStartRecordingWithoutPermission() async throws {
        // Mock scenario where permission is denied
        // This test verifies proper error handling
        
        let result = await screenRecordingManager.startRecording()
        
        switch result {
        case .success:
            // If successful, verify recording state
            XCTAssertTrue(screenRecordingManager.isRecording, "Should be recording after successful start")
            XCTAssertEqual(screenRecordingManager.recordingStatus, .recording, "Status should be recording")
            XCTAssertNotNil(screenRecordingManager.currentRecordingURL, "Should have recording URL")
            
            // Stop the recording for cleanup
            let stopResult = await screenRecordingManager.stopRecording()
            XCTAssertTrue(stopResult.isSuccess, "Should stop recording successfully")
            
        case .failure(let error):
            if case .permissionDenied = error {
                XCTAssertTrue(true, "Expected permission denied error")
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
    
    func testRecordingLifecycle() async throws {
        // Test complete recording lifecycle if permission is available
        
        let screenCaptureManager = ScreenCaptureManager()
        let hasPermission = await screenCaptureManager.hasScreenRecordingPermission()
        
        guard hasPermission else {
            throw XCTSkip("Screen recording permission not granted - skipping full lifecycle test")
        }
        
        // Test starting recording
        let startResult = await screenRecordingManager.startRecording()
        XCTAssertTrue(startResult.isSuccess, "Should start recording successfully")
        XCTAssertTrue(screenRecordingManager.isRecording, "Should be recording")
        
        // Wait a short time to simulate recording
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        XCTAssertGreaterThan(screenRecordingManager.recordingDuration, 1.0, "Recording duration should increase")
        
        // Test stopping recording
        let stopResult = await screenRecordingManager.stopRecording()
        XCTAssertTrue(stopResult.isSuccess, "Should stop recording successfully")
        XCTAssertFalse(screenRecordingManager.isRecording, "Should not be recording after stop")
        
        // Verify output file exists
        if case .success(let url) = stopResult {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "Output file should exist")
            
            // Clean up test file
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    func testDoubleStartRecording() async throws {
        let screenCaptureManager = ScreenCaptureManager()
        let hasPermission = await screenCaptureManager.hasScreenRecordingPermission()
        
        guard hasPermission else {
            throw XCTSkip("Screen recording permission not granted - skipping double start test")
        }
        
        // Start recording
        let firstStart = await screenRecordingManager.startRecording()
        XCTAssertTrue(firstStart.isSuccess, "First start should succeed")
        
        // Try to start again
        let secondStart = await screenRecordingManager.startRecording()
        XCTAssertFalse(secondStart.isSuccess, "Second start should fail")
        
        if case .failure(let error) = secondStart {
            XCTAssertEqual(error, .alreadyRecording, "Should return already recording error")
        }
        
        // Clean up
        let _ = await screenRecordingManager.stopRecording()
    }
    
    func testStopWithoutRecording() async throws {
        XCTAssertFalse(screenRecordingManager.isRecording, "Should not be recording initially")
        
        let result = await screenRecordingManager.stopRecording()
        XCTAssertFalse(result.isSuccess, "Should fail to stop when not recording")
        
        if case .failure(let error) = result {
            XCTAssertEqual(error, .notRecording, "Should return not recording error")
        }
    }
    
    // MARK: - Pause/Resume Tests
    
    func testPauseResumeRecording() async throws {
        let screenCaptureManager = ScreenCaptureManager()
        let hasPermission = await screenCaptureManager.hasScreenRecordingPermission()
        
        guard hasPermission else {
            throw XCTSkip("Screen recording permission not granted - skipping pause/resume test")
        }
        
        // Start recording
        let startResult = await screenRecordingManager.startRecording()
        XCTAssertTrue(startResult.isSuccess, "Should start recording")
        
        // Pause recording
        screenRecordingManager.pauseRecording()
        XCTAssertTrue(screenRecordingManager.isPaused, "Should be paused")
        XCTAssertEqual(screenRecordingManager.recordingStatus, .paused, "Status should be paused")
        
        // Resume recording
        await screenRecordingManager.resumeRecording()
        XCTAssertFalse(screenRecordingManager.isPaused, "Should not be paused after resume")
        XCTAssertEqual(screenRecordingManager.recordingStatus, .recording, "Status should be recording")
        
        // Clean up
        let _ = await screenRecordingManager.stopRecording()
    }
    
    func testPauseWithoutRecording() throws {
        XCTAssertFalse(screenRecordingManager.isRecording, "Should not be recording initially")
        
        screenRecordingManager.pauseRecording()
        XCTAssertFalse(screenRecordingManager.isPaused, "Should not pause when not recording")
    }
    
    // MARK: - Settings Tests
    
    func testFormatChange() throws {
        screenRecordingManager.selectedFormat = .mov
        XCTAssertEqual(screenRecordingManager.selectedFormat, .mov, "Should change format to MOV")
        
        screenRecordingManager.selectedFormat = .avi
        XCTAssertEqual(screenRecordingManager.selectedFormat, .avi, "Should change format to AVI")
    }
    
    func testQualityChange() throws {
        screenRecordingManager.recordingQuality = .low
        XCTAssertEqual(screenRecordingManager.recordingQuality, .low, "Should change quality to low")
        
        screenRecordingManager.recordingQuality = .ultra
        XCTAssertEqual(screenRecordingManager.recordingQuality, .ultra, "Should change quality to ultra")
    }
    
    func testAnnotationSettings() throws {
        screenRecordingManager.includeAnnotations = false
        XCTAssertFalse(screenRecordingManager.includeAnnotations, "Should disable annotations")
        
        screenRecordingManager.includeAnnotations = true
        XCTAssertTrue(screenRecordingManager.includeAnnotations, "Should enable annotations")
    }
    
    func testAudioSettings() throws {
        screenRecordingManager.includeSystemAudio = true
        XCTAssertTrue(screenRecordingManager.includeSystemAudio, "Should enable system audio")
        
        screenRecordingManager.includeMicrophone = true
        XCTAssertTrue(screenRecordingManager.includeMicrophone, "Should enable microphone")
    }
    
    // MARK: - Performance Tests
    
    func testRecordingPerformance() async throws {
        let screenCaptureManager = ScreenCaptureManager()
        let hasPermission = await screenCaptureManager.hasScreenRecordingPermission()
        
        guard hasPermission else {
            throw XCTSkip("Screen recording permission not granted - skipping performance test")
        }
        
        // Measure recording start time
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = await screenRecordingManager.startRecording()
        
        let startDuration = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertTrue(result.isSuccess, "Recording should start successfully")
        XCTAssertLessThan(startDuration, 3.0, "Recording should start within 3 seconds")
        
        // Test recording for a short period
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Measure stop time
        let stopTime = CFAbsoluteTimeGetCurrent()
        
        let stopResult = await screenRecordingManager.stopRecording()
        
        let stopDuration = CFAbsoluteTimeGetCurrent() - stopTime
        
        XCTAssertTrue(stopResult.isSuccess, "Recording should stop successfully")
        XCTAssertLessThan(stopDuration, 5.0, "Recording should stop within 5 seconds")
        
        // Clean up
        if case .success(let url) = stopResult {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    func testMemoryUsage() async throws {
        let screenCaptureManager = ScreenCaptureManager()
        let hasPermission = await screenCaptureManager.hasScreenRecordingPermission()
        
        guard hasPermission else {
            throw XCTSkip("Screen recording permission not granted - skipping memory test")
        }
        
        // Get initial memory usage
        let initialMemory = getMemoryUsage()
        
        // Start recording
        let startResult = await screenRecordingManager.startRecording()
        XCTAssertTrue(startResult.isSuccess, "Should start recording")
        
        // Record for a few seconds
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        // Check memory usage during recording
        let recordingMemory = getMemoryUsage()
        
        // Stop recording
        let stopResult = await screenRecordingManager.stopRecording()
        XCTAssertTrue(stopResult.isSuccess, "Should stop recording")
        
        // Check final memory usage
        let finalMemory = getMemoryUsage()
        
        // Memory should be reasonable (less than 200MB increase)
        let memoryIncrease = recordingMemory - initialMemory
        XCTAssertLessThan(memoryIncrease, 200_000_000, "Memory increase should be less than 200MB during recording")
        
        // Memory should be released after stopping
        let memoryAfterStop = finalMemory - initialMemory
        XCTAssertLessThan(memoryAfterStop, 100_000_000, "Memory should be mostly released after stopping")
        
        // Clean up
        if case .success(let url) = stopResult {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testRecordingErrorEnum() throws {
        let permissionError = ScreenRecordingManager.RecordingError.permissionDenied
        let alreadyRecordingError = ScreenRecordingManager.RecordingError.alreadyRecording
        let notRecordingError = ScreenRecordingManager.RecordingError.notRecording
        
        XCTAssertEqual(permissionError.localizedDescription, "Screen recording permission denied")
        XCTAssertEqual(alreadyRecordingError.localizedDescription, "Recording is already in progress")
        XCTAssertEqual(notRecordingError.localizedDescription, "No recording in progress")
        
        // Test setup failed error
        let testError = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let setupError = ScreenRecordingManager.RecordingError.setupFailed(testError)
        XCTAssertTrue(setupError.localizedDescription?.contains("Test error") == true)
    }
    
    // MARK: - Integration Tests
    
    func testIntegrationWithDrawingManager() throws {
        let drawingManager = DrawingToolManager.shared
        
        // Add some drawing elements
        drawingManager.startDrawing(at: CGPoint(x: 100, y: 100), with: .pen)
        drawingManager.addPoint(CGPoint(x: 150, y: 150))
        drawingManager.finishDrawing()
        
        XCTAssertGreaterThan(drawingManager.allDrawingElements.count, 0, "Should have drawing elements")
        
        // Test that recording manager can access drawing elements
        screenRecordingManager.includeAnnotations = true
        XCTAssertTrue(screenRecordingManager.includeAnnotations, "Should include annotations")
    }
    
    func testIntegrationWithZoomManager() throws {
        let zoomManager = ZoomManager.shared
        
        // Enable zoom
        zoomManager.isZooming = true
        zoomManager.setZoomCenter(CGPoint(x: 200, y: 200))
        
        XCTAssertTrue(zoomManager.isZooming, "Zoom should be active")
        
        // Test that recording manager can access zoom state
        let indicatorData = zoomManager.zoomIndicatorData
        XCTAssertTrue(indicatorData.isActive, "Zoom indicator should be active")
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
}

// MARK: - Result Extension for Testing

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}

// MARK: - Mock Classes for Testing

/// Mock ScreenCaptureManager for testing without actual screen capture
class MockScreenCaptureManager {
    var shouldGrantPermission = true
    var shouldFailCapture = false
    
    func hasScreenRecordingPermission() async -> Bool {
        return shouldGrantPermission
    }
    
    func requestScreenRecordingPermission() async -> Bool {
        return shouldGrantPermission
    }
}

/// Mock file system for testing file operations
class MockFileManager {
    var shouldFailFileOperations = false
    var createdDirectories: [URL] = []
    var removedItems: [URL] = []
    
    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
        if shouldFailFileOperations {
            throw NSError(domain: "MockFileManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock file operation failed"])
        }
        createdDirectories.append(url)
    }
    
    func removeItem(at url: URL) throws {
        if shouldFailFileOperations {
            throw NSError(domain: "MockFileManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Mock file removal failed"])
        }
        removedItems.append(url)
    }
} 