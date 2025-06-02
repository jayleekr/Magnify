import XCTest
import Combine
@testable import Magnify

/// Comprehensive test suite for the Presentation Timer System
/// Tests timer functionality, UI components, and integration
class TimerSystemTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var timerManager: PresentationTimerManager!
    var timerOverlayWindow: TimerOverlayWindow!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Initialize timer system components
        timerManager = PresentationTimerManager.shared
        timerOverlayWindow = TimerOverlayWindow()
        cancellables = Set<AnyCancellable>()
        
        // Reset timer state for each test
        timerManager.stopTimer()
        XCTAssertFalse(timerManager.isTimerActive, "Timer should be stopped at test start")
        
        print("TimerSystemTests: Setup completed")
    }
    
    override func tearDownWithError() throws {
        // Clean up after each test
        timerManager.stopTimer()
        timerManager.clearTimerHistory()
        cancellables.removeAll()
        
        timerManager = nil
        timerOverlayWindow = nil
        cancellables = nil
        
        try super.tearDownWithError()
        print("TimerSystemTests: Teardown completed")
    }
    
    // MARK: - Timer Manager Tests
    
    func testTimerManagerInitialization() throws {
        XCTAssertNotNil(timerManager, "Timer manager should initialize")
        XCTAssertFalse(timerManager.isTimerActive, "Timer should not be active initially")
        XCTAssertFalse(timerManager.isPaused, "Timer should not be paused initially")
        XCTAssertEqual(timerManager.currentTimeRemaining, 0, "Time remaining should be zero initially")
        XCTAssertEqual(timerManager.timerMode, .countdown, "Default mode should be countdown")
        XCTAssertEqual(timerManager.timerType, .presentation, "Default type should be presentation")
    }
    
    func testCountdownTimerFunctionality() throws {
        let expectation = XCTestExpectation(description: "Countdown timer test")
        let duration: TimeInterval = 2.0 // 2 seconds for testing
        
        // Start countdown timer
        timerManager.startTimer(duration: duration, mode: .countdown, type: .presentation)
        
        XCTAssertTrue(timerManager.isTimerActive, "Timer should be active after start")
        XCTAssertEqual(timerManager.timerMode, .countdown, "Timer mode should be countdown")
        XCTAssertEqual(timerManager.currentTimeRemaining, duration, accuracy: 0.1, "Initial time should match duration")
        
        // Wait for timer to countdown
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Check that time is counting down
            XCTAssertLessThan(self.timerManager.currentTimeRemaining, duration, "Time should be counting down")
            XCTAssertGreaterThan(self.timerManager.currentTimeRemaining, 0, "Time should not be expired yet")
            
            // Wait for timer completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                XCTAssertFalse(self.timerManager.isTimerActive, "Timer should be stopped after completion")
                XCTAssertEqual(self.timerManager.currentStatus, .finished, "Timer status should be finished")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCountUpTimerFunctionality() throws {
        let expectation = XCTestExpectation(description: "Count-up timer test")
        let duration: TimeInterval = 2.0 // 2 seconds for testing
        
        // Start count-up timer
        timerManager.startTimer(duration: duration, mode: .countUp, type: .breakTime)
        
        XCTAssertTrue(timerManager.isTimerActive, "Timer should be active after start")
        XCTAssertEqual(timerManager.timerMode, .countUp, "Timer mode should be count-up")
        XCTAssertEqual(timerManager.currentTimeRemaining, 0, accuracy: 0.1, "Initial time should be zero for count-up")
        
        // Wait for timer to count up
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Check that time is counting up
            XCTAssertGreaterThan(self.timerManager.currentTimeRemaining, 0, "Time should be counting up")
            XCTAssertLessThan(self.timerManager.currentTimeRemaining, duration, "Time should not exceed duration yet")
            
            // Wait for timer completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                XCTAssertFalse(self.timerManager.isTimerActive, "Timer should be stopped after completion")
                XCTAssertEqual(self.timerManager.currentStatus, .finished, "Timer status should be finished")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testTimerPauseResumeFunctionality() throws {
        let expectation = XCTestExpectation(description: "Pause/Resume timer test")
        let duration: TimeInterval = 5.0 // 5 seconds for testing
        
        // Start timer
        timerManager.startTimer(duration: duration, mode: .countdown, type: .presentation)
        
        // Wait a bit then pause
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let timeBeforePause = self.timerManager.currentTimeRemaining
            self.timerManager.pauseTimer()
            
            XCTAssertTrue(self.timerManager.isPaused, "Timer should be paused")
            XCTAssertTrue(self.timerManager.isTimerActive, "Timer should still be active when paused")
            XCTAssertEqual(self.timerManager.currentStatus, .paused, "Timer status should be paused")
            
            // Wait and check that time doesn't change while paused
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                XCTAssertEqual(self.timerManager.currentTimeRemaining, timeBeforePause, accuracy: 0.1, "Time should not change while paused")
                
                // Resume timer
                self.timerManager.resumeTimer()
                XCTAssertFalse(self.timerManager.isPaused, "Timer should not be paused after resume")
                XCTAssertEqual(self.timerManager.currentStatus, .running, "Timer status should be running after resume")
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 8.0)
    }
    
    func testTimerStopFunctionality() throws {
        let duration: TimeInterval = 10.0 // 10 seconds
        
        // Start timer
        timerManager.startTimer(duration: duration, mode: .countdown, type: .presentation)
        XCTAssertTrue(timerManager.isTimerActive, "Timer should be active after start")
        
        // Stop timer
        timerManager.stopTimer()
        XCTAssertFalse(timerManager.isTimerActive, "Timer should not be active after stop")
        XCTAssertFalse(timerManager.isPaused, "Timer should not be paused after stop")
        XCTAssertEqual(timerManager.currentTimeRemaining, 0, "Time remaining should be zero after stop")
        XCTAssertEqual(timerManager.currentStatus, .stopped, "Timer status should be stopped")
    }
    
    func testTimerAddTimeFunctionality() throws {
        let duration: TimeInterval = 5.0 // 5 seconds
        let addTime: TimeInterval = 2.0 // Add 2 seconds
        
        // Start timer
        timerManager.startTimer(duration: duration, mode: .countdown, type: .presentation)
        
        // Add time
        timerManager.addTime(addTime)
        
        XCTAssertEqual(timerManager.totalDuration, duration + addTime, "Total duration should include added time")
        XCTAssertGreaterThan(timerManager.currentTimeRemaining, duration, "Current time should be greater than original duration")
    }
    
    func testTimerTypeAndModeConfiguration() throws {
        // Test all timer types
        for timerType in PresentationTimerManager.TimerType.allCases {
            timerManager.startTimer(duration: 1.0, mode: .countdown, type: timerType)
            XCTAssertEqual(timerManager.timerType, timerType, "Timer type should be set correctly")
            XCTAssertNotEqual(timerType.defaultDuration, 0, "Timer type should have default duration")
            timerManager.stopTimer()
        }
        
        // Test all timer modes
        for timerMode in PresentationTimerManager.TimerMode.allCases {
            timerManager.startTimer(duration: 1.0, mode: timerMode, type: .presentation)
            XCTAssertEqual(timerManager.timerMode, timerMode, "Timer mode should be set correctly")
            timerManager.stopTimer()
        }
    }
    
    func testTimerStatusTransitions() throws {
        let expectation = XCTestExpectation(description: "Timer status transitions")
        let duration: TimeInterval = 2.0
        
        // Initial status
        XCTAssertEqual(timerManager.currentStatus, .stopped, "Initial status should be stopped")
        
        // Start timer
        timerManager.startTimer(duration: duration, mode: .countdown, type: .presentation)
        XCTAssertEqual(timerManager.currentStatus, .running, "Status should be running after start")
        
        // Pause timer
        timerManager.pauseTimer()
        XCTAssertEqual(timerManager.currentStatus, .paused, "Status should be paused")
        
        // Resume timer
        timerManager.resumeTimer()
        XCTAssertEqual(timerManager.currentStatus, .running, "Status should be running after resume")
        
        // Wait for completion
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
            XCTAssertEqual(self.timerManager.currentStatus, .finished, "Status should be finished after completion")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Timer History Tests
    
    func testTimerHistoryTracking() throws {
        let expectation = XCTestExpectation(description: "Timer history tracking")
        let duration: TimeInterval = 1.0
        
        // Clear history first
        timerManager.clearTimerHistory()
        XCTAssertEqual(timerManager.getTimerHistory().count, 0, "History should be empty initially")
        
        // Start and complete timer
        timerManager.startTimer(duration: duration, mode: .countdown, type: .presentation)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
            let history = self.timerManager.getTimerHistory()
            XCTAssertEqual(history.count, 1, "History should contain one session")
            
            let session = history.first!
            XCTAssertEqual(session.type, .presentation, "Session type should match")
            XCTAssertEqual(session.mode, .countdown, "Session mode should match")
            XCTAssertTrue(session.wasCompleted, "Session should be marked as completed")
            XCTAssertGreaterThan(session.actualDuration, 0, "Session should have actual duration")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testTimerStatistics() throws {
        let expectation = XCTestExpectation(description: "Timer statistics")
        
        // Clear history and add test sessions
        timerManager.clearTimerHistory()
        
        // Simulate completed sessions
        timerManager.startTimer(duration: 1.0, mode: .countdown, type: .presentation)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            // First session completed
            
            self.timerManager.startTimer(duration: 2.0, mode: .countdown, type: .breakTime)
            self.timerManager.stopTimer() // Manually stop (incomplete session)
            
            let stats = self.timerManager.getTimerStatistics()
            
            XCTAssertEqual(stats.totalSessions, 2, "Should have 2 total sessions")
            XCTAssertEqual(stats.completedSessions, 1, "Should have 1 completed session")
            XCTAssertEqual(stats.completionRate, 0.5, accuracy: 0.1, "Completion rate should be 50%")
            XCTAssertGreaterThan(stats.totalTimeSpent, 0, "Should have total time spent")
            XCTAssertGreaterThan(stats.averageSessionDuration, 0, "Should have average session duration")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Timer Overlay Window Tests
    
    func testTimerOverlayWindowInitialization() throws {
        XCTAssertNotNil(timerOverlayWindow, "Timer overlay window should initialize")
        XCTAssertFalse(timerOverlayWindow.isVisible, "Overlay window should not be visible initially")
        XCTAssertEqual(timerOverlayWindow.level, .statusBar, "Overlay window should have status bar level")
        XCTAssertTrue(timerOverlayWindow.collectionBehavior.contains(.canJoinAllSpaces), "Overlay should join all spaces")
    }
    
    func testTimerOverlayPositioning() throws {
        let positions = TimerOverlayWindow.OverlayPosition.allCases
        
        for position in positions {
            timerOverlayWindow.setPosition(position)
            XCTAssertEqual(timerOverlayWindow.currentPosition, position, "Position should be set correctly")
            
            // Verify system image exists for position
            XCTAssertFalse(position.systemImage.isEmpty, "Position should have system image")
        }
    }
    
    func testTimerOverlayOpacity() throws {
        let testOpacities: [Double] = [0.2, 0.5, 0.8, 1.0]
        
        for opacity in testOpacities {
            timerOverlayWindow.setOpacity(opacity)
            XCTAssertEqual(timerOverlayWindow.currentOpacity, opacity, accuracy: 0.01, "Opacity should be set correctly")
        }
        
        // Test opacity bounds
        timerOverlayWindow.setOpacity(-0.1) // Below minimum
        XCTAssertGreaterThanOrEqual(timerOverlayWindow.currentOpacity, 0.2, "Opacity should not go below minimum")
        
        timerOverlayWindow.setOpacity(1.5) // Above maximum
        XCTAssertLessThanOrEqual(timerOverlayWindow.currentOpacity, 1.0, "Opacity should not go above maximum")
    }
    
    func testTimerOverlayVisibilityControl() throws {
        // Initially hidden
        XCTAssertFalse(timerOverlayWindow.isVisible, "Overlay should be hidden initially")
        
        // Show overlay
        timerOverlayWindow.showOverlay()
        XCTAssertTrue(timerOverlayWindow.isVisible, "Overlay should be visible after show")
        
        // Hide overlay
        timerOverlayWindow.hideOverlay()
        XCTAssertFalse(timerOverlayWindow.isVisible, "Overlay should be hidden after hide")
        
        // Toggle overlay
        timerOverlayWindow.toggleOverlay()
        XCTAssertTrue(timerOverlayWindow.isVisible, "Overlay should be visible after toggle from hidden")
        
        timerOverlayWindow.toggleOverlay()
        XCTAssertFalse(timerOverlayWindow.isVisible, "Overlay should be hidden after toggle from visible")
    }
    
    // MARK: - Integration Tests
    
    func testTimerAndOverlayIntegration() throws {
        let expectation = XCTestExpectation(description: "Timer and overlay integration")
        
        // Start timer should show overlay
        timerManager.startTimer(duration: 2.0, mode: .countdown, type: .presentation)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Timer should be active and overlay should be visible
            XCTAssertTrue(self.timerManager.isTimerActive, "Timer should be active")
            // Note: Overlay visibility is managed by AppDelegate, so we test the timer state
            
            // Stop timer should hide overlay
            self.timerManager.stopTimer()
            XCTAssertFalse(self.timerManager.isTimerActive, "Timer should be stopped")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testTimerFormatting() throws {
        // Test time formatting at different durations
        timerManager.startTimer(duration: 3661, mode: .countdown, type: .presentation) // 1:01:01
        let formattedTime = timerManager.formatCurrentTime()
        XCTAssertTrue(formattedTime.contains(":"), "Formatted time should contain colons")
        XCTAssertFalse(formattedTime.isEmpty, "Formatted time should not be empty")
        
        timerManager.stopTimer()
        
        // Test different time ranges
        let testDurations: [TimeInterval] = [59, 3599, 7200] // 59s, 59:59, 2:00:00
        
        for duration in testDurations {
            timerManager.startTimer(duration: duration, mode: .countdown, type: .presentation)
            let formatted = timerManager.formatCurrentTime()
            XCTAssertFalse(formatted.isEmpty, "Formatted time should not be empty for duration \(duration)")
            timerManager.stopTimer()
        }
    }
    
    func testTimerProgressCalculation() throws {
        let duration: TimeInterval = 10.0
        
        // Test countdown progress
        timerManager.startTimer(duration: duration, mode: .countdown, type: .presentation)
        
        let initialProgress = timerManager.progressPercentage
        XCTAssertEqual(initialProgress, 1.0, accuracy: 0.01, "Initial progress should be 100% for countdown")
        
        // Add some time and check progress
        timerManager.addTime(5.0) // Total becomes 15 seconds
        let progressAfterAdd = timerManager.progressPercentage
        XCTAssertGreaterThan(progressAfterAdd, initialProgress, "Progress should increase after adding time")
        
        timerManager.stopTimer()
        
        // Test count-up progress
        timerManager.startTimer(duration: duration, mode: .countUp, type: .presentation)
        let countUpProgress = timerManager.progressPercentage
        XCTAssertEqual(countUpProgress, 0.0, accuracy: 0.01, "Initial progress should be 0% for count-up")
        
        timerManager.stopTimer()
    }
    
    // MARK: - Performance Tests
    
    func testTimerPerformance() throws {
        measure {
            // Test timer start/stop performance
            for _ in 0..<100 {
                timerManager.startTimer(duration: 1.0, mode: .countdown, type: .presentation)
                timerManager.stopTimer()
            }
        }
    }
    
    func testTimerHistoryPerformance() throws {
        // Add many timer sessions
        for i in 0..<1000 {
            timerManager.startTimer(duration: Double(i % 10 + 1), mode: .countdown, type: .presentation)
            timerManager.stopTimer()
        }
        
        measure {
            // Test history retrieval performance
            let _ = timerManager.getTimerHistory()
            let _ = timerManager.getTimerStatistics()
        }
        
        // Clean up
        timerManager.clearTimerHistory()
    }
    
    func testOverlayWindowPerformance() throws {
        measure {
            // Test overlay show/hide performance
            for _ in 0..<100 {
                timerOverlayWindow.showOverlay()
                timerOverlayWindow.hideOverlay()
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testTimerWithZeroDuration() throws {
        // Test timer with zero duration
        timerManager.startTimer(duration: 0, mode: .countdown, type: .presentation)
        
        // Timer should handle zero duration gracefully
        XCTAssertTrue(timerManager.isTimerActive || timerManager.currentStatus == .finished, "Timer should handle zero duration")
        
        timerManager.stopTimer()
    }
    
    func testTimerWithNegativeDuration() throws {
        // Test timer with negative duration
        timerManager.startTimer(duration: -5.0, mode: .countdown, type: .presentation)
        
        // Timer should handle negative duration gracefully (likely by not starting or setting to 0)
        XCTAssertTrue(timerManager.currentTimeRemaining >= 0, "Timer should not have negative time")
        
        timerManager.stopTimer()
    }
    
    func testMultipleTimerOperations() throws {
        // Test rapid timer operations
        timerManager.startTimer(duration: 5.0, mode: .countdown, type: .presentation)
        timerManager.pauseTimer()
        timerManager.resumeTimer()
        timerManager.addTime(2.0)
        timerManager.pauseTimer()
        timerManager.stopTimer()
        
        // Should not crash and timer should be stopped
        XCTAssertFalse(timerManager.isTimerActive, "Timer should be stopped after multiple operations")
    }
    
    func testTimerStateConsistency() throws {
        let expectation = XCTestExpectation(description: "Timer state consistency")
        
        // Start timer
        timerManager.startTimer(duration: 2.0, mode: .countdown, type: .presentation)
        
        // Check state consistency during execution
        let stateCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            // Verify state consistency
            if self.timerManager.isTimerActive {
                XCTAssertGreaterThanOrEqual(self.timerManager.currentTimeRemaining, 0, "Time remaining should not be negative")
                
                if self.timerManager.timerMode == .countdown {
                    XCTAssertLessThanOrEqual(self.timerManager.currentTimeRemaining, self.timerManager.totalDuration, "Countdown time should not exceed total duration")
                }
            }
            
            // Stop checking when timer is no longer active
            if !self.timerManager.isTimerActive {
                timer.invalidate()
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - Test Utilities

extension TimerSystemTests {
    
    /// Helper method to wait for timer completion with timeout
    func waitForTimerCompletion(timeout: TimeInterval) -> Bool {
        let startTime = Date()
        
        while timerManager.isTimerActive && Date().timeIntervalSince(startTime) < timeout {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        
        return !timerManager.isTimerActive
    }
    
    /// Helper method to create test timer session
    func createTestTimerSession(duration: TimeInterval, type: PresentationTimerManager.TimerType, mode: PresentationTimerManager.TimerMode, completed: Bool = true) {
        timerManager.startTimer(duration: duration, mode: mode, type: type)
        
        if completed {
            let _ = waitForTimerCompletion(timeout: duration + 1.0)
        } else {
            timerManager.stopTimer()
        }
    }
} 