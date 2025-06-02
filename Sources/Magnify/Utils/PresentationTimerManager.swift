import Foundation
import AppKit
import SwiftUI

/// PresentationTimerManager provides comprehensive timing functionality for presentations
/// Supports countdown/count-up timers, break timers, and alarm notifications
class PresentationTimerManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = PresentationTimerManager()
    
    // MARK: - Published Properties
    
    @Published var isTimerActive: Bool = false
    @Published var isPaused: Bool = false
    @Published var currentTimeRemaining: TimeInterval = 0
    @Published var totalDuration: TimeInterval = 0
    @Published var timerMode: TimerMode = .countdown
    @Published var timerType: TimerType = .presentation
    @Published var elapsedTime: TimeInterval = 0
    @Published var warningThreshold: TimeInterval = 300 // 5 minutes default
    @Published var isWarningActive: Bool = false
    @Published var isAlarmActive: Bool = false
    
    // MARK: - Timer Modes and Types
    
    enum TimerMode: String, CaseIterable {
        case countdown = "Countdown"
        case countUp = "Count Up"
        
        var displayName: String { rawValue }
        var systemImage: String {
            switch self {
            case .countdown: return "timer"
            case .countUp: return "stopwatch"
            }
        }
    }
    
    enum TimerType: String, CaseIterable {
        case presentation = "Presentation"
        case breakTime = "Break"
        case pomodoro = "Pomodoro"
        case custom = "Custom"
        
        var displayName: String { rawValue }
        var defaultDuration: TimeInterval {
            switch self {
            case .presentation: return 25 * 60 // 25 minutes
            case .breakTime: return 15 * 60 // 15 minutes
            case .pomodoro: return 25 * 60 // 25 minutes
            case .custom: return 10 * 60 // 10 minutes
            }
        }
        var systemImage: String {
            switch self {
            case .presentation: return "person.wave.2"
            case .breakTime: return "cup.and.saucer"
            case .pomodoro: return "clock.badge.checkmark"
            case .custom: return "timer.square"
            }
        }
    }
    
    enum TimerStatus: String {
        case idle = "Ready"
        case running = "Running"
        case paused = "Paused"
        case warning = "Warning"
        case finished = "Finished"
        case expired = "Expired"
        
        var color: NSColor {
            switch self {
            case .idle: return .systemBlue
            case .running: return .systemGreen
            case .paused: return .systemOrange
            case .warning: return .systemYellow
            case .finished: return .systemRed
            case .expired: return .systemRed
            }
        }
    }
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0
    private let preferencesManager = PreferencesManager.shared
    
    // Timer history and statistics
    private var timerHistory: [TimerSession] = []
    private var sessionStartTime: Date?
    
    // Notification and alarm settings
    private var notificationQueue = DispatchQueue(label: "com.magnify.timer.notifications", qos: .userInitiated)
    private var soundPlayer: NSSound?
    
    // MARK: - Timer Session Data
    
    struct TimerSession {
        let id = UUID()
        let type: TimerType
        let mode: TimerMode
        let startTime: Date
        let endTime: Date
        let plannedDuration: TimeInterval
        let actualDuration: TimeInterval
        let wasCompleted: Bool
        let interruptions: Int
    }
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        loadTimerHistory()
        setupNotifications()
        loadPreferences()
        print("PresentationTimerManager: Initialized comprehensive timer system")
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }
    
    private func loadPreferences() {
        // Load user preferences for timer settings
        timerMode = preferencesManager.defaultTimerMode
        warningThreshold = preferencesManager.timerWarningThreshold
    }
    
    // MARK: - Timer Control Methods
    
    /// Start the timer with specified duration and mode
    func startTimer(duration: TimeInterval, mode: TimerMode = .countdown, type: TimerType = .presentation) {
        guard !isTimerActive else {
            print("PresentationTimerManager: Timer is already active")
            return
        }
        
        // Setup timer configuration
        self.timerMode = mode
        self.timerType = type
        self.totalDuration = duration
        self.currentTimeRemaining = mode == .countdown ? duration : 0
        self.elapsedTime = 0
        self.pausedTime = 0
        
        // Reset state
        self.isWarningActive = false
        self.isAlarmActive = false
        self.isPaused = false
        self.isTimerActive = true
        
        // Record session start
        self.startTime = Date()
        self.sessionStartTime = Date()
        
        // Start the timer
        startTimerLoop()
        
        print("PresentationTimerManager: Started \(mode.displayName) timer for \(formatDuration(duration))")
        
        // Send notification
        sendNotification(title: "Timer Started", message: "Started \(type.displayName) timer for \(formatDuration(duration))")
    }
    
    /// Pause the currently running timer
    func pauseTimer() {
        guard isTimerActive && !isPaused else { return }
        
        stopTimerLoop()
        isPaused = true
        
        print("PresentationTimerManager: Timer paused")
        sendNotification(title: "Timer Paused", message: "Timer paused at \(formatCurrentTime())")
    }
    
    /// Resume the paused timer
    func resumeTimer() {
        guard isTimerActive && isPaused else { return }
        
        isPaused = false
        startTimerLoop()
        
        print("PresentationTimerManager: Timer resumed")
        sendNotification(title: "Timer Resumed", message: "Timer resumed")
    }
    
    /// Stop the timer completely
    func stopTimer() {
        guard isTimerActive else { return }
        
        stopTimerLoop()
        recordTimerSession(completed: false)
        resetTimerState()
        
        print("PresentationTimerManager: Timer stopped")
        sendNotification(title: "Timer Stopped", message: "Timer stopped manually")
    }
    
    /// Reset timer to initial state
    func resetTimer() {
        stopTimerLoop()
        resetTimerState()
        
        print("PresentationTimerManager: Timer reset")
    }
    
    /// Add time to the current timer (useful for presentations)
    func addTime(_ additionalTime: TimeInterval) {
        guard isTimerActive else { return }
        
        if timerMode == .countdown {
            currentTimeRemaining += additionalTime
            totalDuration += additionalTime
        }
        
        print("PresentationTimerManager: Added \(formatDuration(additionalTime)) to timer")
        sendNotification(title: "Time Added", message: "Added \(formatDuration(additionalTime)) to timer")
    }
    
    // MARK: - Private Timer Loop
    
    private func startTimerLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    private func stopTimerLoop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimer() {
        guard let startTime = startTime else { return }
        
        let now = Date()
        let totalElapsed = now.timeIntervalSince(startTime) - pausedTime
        
        elapsedTime = totalElapsed
        
        switch timerMode {
        case .countdown:
            currentTimeRemaining = max(0, totalDuration - totalElapsed)
            
            // Check for completion
            if currentTimeRemaining <= 0 {
                timerFinished()
                return
            }
            
            // Check for warning threshold
            if currentTimeRemaining <= warningThreshold && !isWarningActive {
                activateWarning()
            }
            
        case .countUp:
            currentTimeRemaining = totalElapsed
            
            // For count-up timers, check if we've exceeded planned duration
            if totalDuration > 0 && totalElapsed >= totalDuration {
                activateWarning()
            }
        }
    }
    
    private func timerFinished() {
        stopTimerLoop()
        isAlarmActive = true
        
        recordTimerSession(completed: true)
        playAlarmSound()
        
        print("PresentationTimerManager: Timer finished")
        sendNotification(title: "Timer Finished", message: "\(timerType.displayName) timer has finished!")
        
        // Keep timer active for a few seconds to show finished state
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.resetTimerState()
        }
    }
    
    private func activateWarning() {
        guard !isWarningActive else { return }
        
        isWarningActive = true
        playWarningSound()
        
        let remainingTime = timerMode == .countdown ? currentTimeRemaining : (totalDuration - elapsedTime)
        print("PresentationTimerManager: Warning activated - \(formatDuration(remainingTime)) remaining")
        
        sendNotification(
            title: "Timer Warning",
            message: "Only \(formatDuration(remainingTime)) remaining!"
        )
    }
    
    private func resetTimerState() {
        isTimerActive = false
        isPaused = false
        isWarningActive = false
        isAlarmActive = false
        currentTimeRemaining = 0
        elapsedTime = 0
        pausedTime = 0
        startTime = nil
        sessionStartTime = nil
    }
    
    // MARK: - Session Recording
    
    private func recordTimerSession(completed: Bool) {
        guard let sessionStart = sessionStartTime else { return }
        
        let session = TimerSession(
            type: timerType,
            mode: timerMode,
            startTime: sessionStart,
            endTime: Date(),
            plannedDuration: totalDuration,
            actualDuration: elapsedTime,
            wasCompleted: completed,
            interruptions: 0 // TODO: Track pause/resume cycles
        )
        
        timerHistory.append(session)
        saveTimerHistory()
        
        print("PresentationTimerManager: Recorded timer session - completed: \(completed)")
    }
    
    // MARK: - Sound and Notifications
    
    private func playAlarmSound() {
        guard preferencesManager.enableTimerSounds else { return }
        
        notificationQueue.async { [weak self] in
            if let soundPath = Bundle.main.path(forResource: "timer_alarm", ofType: "mp3") {
                self?.soundPlayer = NSSound(contentsOfFile: soundPath, byReference: false)
            } else {
                // Fallback to system sound
                self?.soundPlayer = NSSound(named: .init("Funk"))
            }
            
            DispatchQueue.main.async {
                self?.soundPlayer?.play()
            }
        }
    }
    
    private func playWarningSound() {
        guard preferencesManager.enableTimerSounds else { return }
        
        notificationQueue.async {
            let warningSound = NSSound(named: .init("Ping"))
            DispatchQueue.main.async {
                warningSound?.play()
            }
        }
    }
    
    private func sendNotification(title: String, message: String) {
        guard preferencesManager.showTimerNotifications else { return }
        
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = preferencesManager.enableTimerSounds ? NSUserNotificationDefaultSoundName : nil
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    // MARK: - Formatting and Display
    
    func formatCurrentTime() -> String {
        let timeToFormat = timerMode == .countdown ? currentTimeRemaining : elapsedTime
        return formatDuration(timeToFormat)
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    func formatDurationWithMilliseconds(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let milliseconds = Int((duration.truncatingRemainder(dividingBy: 1)) * 100)
        
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    // MARK: - Public Properties
    
    var currentStatus: TimerStatus {
        if !isTimerActive {
            return .idle
        } else if isAlarmActive {
            return .finished
        } else if isWarningActive {
            return .warning
        } else if isPaused {
            return .paused
        } else {
            return .running
        }
    }
    
    var progressPercentage: Double {
        guard totalDuration > 0 else { return 0 }
        
        switch timerMode {
        case .countdown:
            return max(0, min(1, (totalDuration - currentTimeRemaining) / totalDuration))
        case .countUp:
            return min(1, elapsedTime / totalDuration)
        }
    }
    
    var isReadyToStart: Bool {
        return !isTimerActive
    }
    
    // MARK: - Timer History Management
    
    func getTimerHistory() -> [TimerSession] {
        return timerHistory.sorted { $0.startTime > $1.startTime }
    }
    
    func getTimerStatistics() -> TimerStatistics {
        let completedSessions = timerHistory.filter { $0.wasCompleted }
        let totalSessions = timerHistory.count
        let totalTimeSpent = timerHistory.reduce(0) { $0 + $1.actualDuration }
        let averageSessionDuration = totalSessions > 0 ? totalTimeSpent / Double(totalSessions) : 0
        
        let sessionsByType = Dictionary(grouping: timerHistory, by: { $0.type })
        let completionRate = totalSessions > 0 ? Double(completedSessions.count) / Double(totalSessions) : 0
        
        return TimerStatistics(
            totalSessions: totalSessions,
            completedSessions: completedSessions.count,
            totalTimeSpent: totalTimeSpent,
            averageSessionDuration: averageSessionDuration,
            completionRate: completionRate,
            sessionsByType: sessionsByType.mapValues { $0.count },
            longestSession: timerHistory.max { $0.actualDuration < $1.actualDuration }?.actualDuration ?? 0
        )
    }
    
    struct TimerStatistics {
        let totalSessions: Int
        let completedSessions: Int
        let totalTimeSpent: TimeInterval
        let averageSessionDuration: TimeInterval
        let completionRate: Double
        let sessionsByType: [TimerType: Int]
        let longestSession: TimeInterval
    }
    
    func clearTimerHistory() {
        timerHistory.removeAll()
        saveTimerHistory()
        print("PresentationTimerManager: Cleared timer history")
    }
    
    // MARK: - Persistence
    
    private func saveTimerHistory() {
        do {
            let data = try JSONEncoder().encode(timerHistory)
            UserDefaults.standard.set(data, forKey: "timer_history")
            print("PresentationTimerManager: Saved timer history (\(timerHistory.count) sessions)")
        } catch {
            print("PresentationTimerManager: Failed to save timer history: \(error)")
        }
    }
    
    private func loadTimerHistory() {
        guard let data = UserDefaults.standard.data(forKey: "timer_history") else {
            print("PresentationTimerManager: No timer history found")
            return
        }
        
        do {
            timerHistory = try JSONDecoder().decode([TimerSession].self, from: data)
            print("PresentationTimerManager: Loaded timer history (\(timerHistory.count) sessions)")
        } catch {
            print("PresentationTimerManager: Failed to load timer history: \(error)")
            timerHistory = []
        }
    }
    
    // MARK: - Cleanup
    
    @objc private func applicationWillTerminate() {
        if isTimerActive {
            recordTimerSession(completed: false)
        }
        stopTimerLoop()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopTimerLoop()
    }
}

// MARK: - TimerSession Codable Conformance

extension PresentationTimerManager.TimerSession: Codable {
    enum CodingKeys: String, CodingKey {
        case id, type, mode, startTime, endTime, plannedDuration, actualDuration, wasCompleted, interruptions
    }
}

// MARK: - TimerMode Codable Conformance

extension PresentationTimerManager.TimerMode: Codable {}

// MARK: - TimerType Codable Conformance

extension PresentationTimerManager.TimerType: Codable {}

// MARK: - Notification Names

extension Notification.Name {
    static let presentationTimerStarted = Notification.Name("presentationTimerStarted")
    static let presentationTimerFinished = Notification.Name("presentationTimerFinished")
    static let presentationTimerWarning = Notification.Name("presentationTimerWarning")
} 