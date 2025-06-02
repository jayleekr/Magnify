import SwiftUI
import AppKit

/// TimerControlsPanel provides a comprehensive SwiftUI interface for timer management
/// Includes timer setup, controls, history, and preferences
struct TimerControlsPanel: View {
    
    @ObservedObject private var timerManager = PresentationTimerManager.shared
    @ObservedObject private var preferencesManager = PreferencesManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTimerType: PresentationTimerManager.TimerType = .presentation
    @State private var selectedTimerMode: PresentationTimerManager.TimerMode = .countdown
    @State private var customDuration: TimeInterval = 25 * 60 // 25 minutes
    @State private var showHistory = false
    @State private var showSettings = false
    
    // Quick timer presets
    private let quickTimers: [(String, TimeInterval)] = [
        ("5 min", 5 * 60),
        ("15 min", 15 * 60),
        ("25 min", 25 * 60),
        ("45 min", 45 * 60),
        ("1 hour", 60 * 60)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Main timer content
                ScrollView {
                    VStack(spacing: 24) {
                        timerStatusSection
                        timerSetupSection
                        quickTimerSection
                        activeTimerControlsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                
                Divider()
                
                // Bottom toolbar
                HStack {
                    Button(action: { showHistory.toggle() }) {
                        Label("History", systemImage: "clock")
                    }
                    
                    Spacer()
                    
                    Button(action: { showSettings.toggle() }) {
                        Label("Settings", systemImage: "gear")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(NSColor.controlBackgroundColor))
            }
            .navigationTitle("Timer Controls")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 400, height: 600)
        .sheet(isPresented: $showHistory) {
            TimerHistoryView()
        }
        .sheet(isPresented: $showSettings) {
            TimerSettingsView()
        }
    }
    
    // MARK: - Timer Status Section
    
    private var timerStatusSection: some View {
        VStack(spacing: 16) {
            // Current timer display
            if timerManager.isTimerActive {
                VStack(spacing: 8) {
                    Text(timerManager.formatCurrentTime())
                        .font(.system(.largeTitle, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(timerStatusColor)
                    
                    HStack(spacing: 8) {
                        Image(systemName: timerManager.timerMode.systemImage)
                            .foregroundColor(timerStatusColor)
                        
                        Text("\(timerManager.timerType.displayName) Timer")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if timerManager.isPaused {
                            Text("• PAUSED")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    // Progress bar for countdown timers
                    if timerManager.timerMode == .countdown && timerManager.totalDuration > 0 {
                        ProgressView(value: timerManager.progressPercentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: timerStatusColor))
                            .frame(height: 8)
                    }
                }
                .padding()
                .background(timerStatusColor.opacity(0.1))
                .cornerRadius(12)
            } else {
                Text("No Active Timer")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Timer Setup Section
    
    private var timerSetupSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Setup Timer")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Timer type selection
                Picker("Timer Type", selection: $selectedTimerType) {
                    ForEach(PresentationTimerManager.TimerType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.systemImage)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)
                
                // Timer mode selection
                Picker("Timer Mode", selection: $selectedTimerMode) {
                    ForEach(PresentationTimerManager.TimerMode.allCases, id: \.self) { mode in
                        Label(mode.displayName, systemImage: mode.systemImage)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                
                // Custom duration input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Duration")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Stepper(
                            value: $customDuration,
                            in: 60...7200, // 1 minute to 2 hours
                            step: 60
                        ) {
                            Text(formatDuration(customDuration))
                                .font(.system(.body, design: .monospaced))
                        }
                        
                        Spacer()
                        
                        Button("Use Default") {
                            customDuration = selectedTimerType.defaultDuration
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            // Start timer button
            Button(action: startTimer) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Timer")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(timerManager.isReadyToStart ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!timerManager.isReadyToStart)
        }
    }
    
    // MARK: - Quick Timer Section
    
    private var quickTimerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Start")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(quickTimers, id: \.0) { name, duration in
                    Button(action: {
                        customDuration = duration
                        startTimer()
                    }) {
                        VStack(spacing: 4) {
                            Text(name)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(formatDuration(duration))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(!timerManager.isReadyToStart)
                }
            }
        }
    }
    
    // MARK: - Active Timer Controls
    
    private var activeTimerControlsSection: some View {
        Group {
            if timerManager.isTimerActive {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Timer Controls")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        // Pause/Resume
                        Button(action: {
                            if timerManager.isPaused {
                                timerManager.resumeTimer()
                            } else {
                                timerManager.pauseTimer()
                            }
                        }) {
                            HStack {
                                Image(systemName: timerManager.isPaused ? "play.fill" : "pause.fill")
                                Text(timerManager.isPaused ? "Resume" : "Pause")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        // Stop
                        Button(action: {
                            timerManager.stopTimer()
                        }) {
                            HStack {
                                Image(systemName: "stop.fill")
                                Text("Stop")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    
                    // Add time controls
                    HStack(spacing: 8) {
                        Text("Add Time:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ForEach([1, 5, 10], id: \.self) { minutes in
                            Button("+\(minutes)m") {
                                timerManager.addTime(TimeInterval(minutes * 60))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var timerStatusColor: Color {
        switch timerManager.currentStatus {
        case .running:
            return .green
        case .warning:
            return .orange
        case .finished, .expired:
            return .red
        case .paused:
            return .blue
        default:
            return .gray
        }
    }
    
    // MARK: - Actions
    
    private func startTimer() {
        timerManager.startTimer(
            duration: customDuration,
            mode: selectedTimerMode,
            type: selectedTimerType
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Timer History View

struct TimerHistoryView: View {
    
    @ObservedObject private var timerManager = PresentationTimerManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Statistics section
                timerStatisticsSection
                
                Divider()
                
                // History list
                List {
                    ForEach(timerManager.getTimerHistory(), id: \.id) { session in
                        TimerHistoryRow(session: session)
                    }
                }
                .listStyle(.inset)
                
                // Clear history button
                HStack {
                    Spacer()
                    
                    Button("Clear History", role: .destructive) {
                        timerManager.clearTimerHistory()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding()
            }
            .navigationTitle("Timer History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 600)
    }
    
    private var timerStatisticsSection: some View {
        let stats = timerManager.getTimerStatistics()
        
        return VStack(spacing: 16) {
            Text("Timer Statistics")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatisticView(
                    title: "Total Sessions",
                    value: "\(stats.totalSessions)",
                    icon: "clock"
                )
                
                StatisticView(
                    title: "Completed",
                    value: "\(stats.completedSessions)",
                    icon: "checkmark.circle"
                )
                
                StatisticView(
                    title: "Success Rate",
                    value: "\(Int(stats.completionRate * 100))%",
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
            
            HStack(spacing: 20) {
                StatisticView(
                    title: "Total Time",
                    value: formatDuration(stats.totalTimeSpent),
                    icon: "hourglass"
                )
                
                StatisticView(
                    title: "Average Session",
                    value: formatDuration(stats.averageSessionDuration),
                    icon: "timer"
                )
                
                StatisticView(
                    title: "Longest Session",
                    value: formatDuration(stats.longestSession),
                    icon: "crown"
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Timer History Row

struct TimerHistoryRow: View {
    let session: PresentationTimerManager.TimerSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: session.type.systemImage)
                        .foregroundColor(.accentColor)
                    
                    Text(session.type.displayName)
                        .font(.headline)
                    
                    Text("• \(session.mode.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if session.wasCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.orange)
                    }
                }
                
                HStack {
                    Text("Duration: \(formatDuration(session.actualDuration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• \(session.startTime.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

// MARK: - Statistic View

struct StatisticView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Timer Settings View

struct TimerSettingsView: View {
    
    @ObservedObject private var preferencesManager = PreferencesManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Timer Overlay") {
                    Picker("Position", selection: $preferencesManager.timerOverlayPosition) {
                        ForEach(TimerOverlayWindow.OverlayPosition.allCases, id: \.self) { position in
                            Label(position.rawValue, systemImage: position.systemImage)
                                .tag(position)
                        }
                    }
                    
                    HStack {
                        Text("Opacity")
                        Spacer()
                        Slider(value: $preferencesManager.timerOverlayOpacity, in: 0.2...1.0, step: 0.1)
                            .frame(width: 150)
                        Text("\(Int(preferencesManager.timerOverlayOpacity * 100))%")
                            .frame(width: 40)
                    }
                }
                
                Section("Notifications") {
                    Toggle("Show Timer Notifications", isOn: $preferencesManager.showTimerNotifications)
                    Toggle("Enable Timer Sounds", isOn: $preferencesManager.enableTimerSounds)
                    
                    HStack {
                        Text("Warning Threshold")
                        Spacer()
                        Picker("Warning Time", selection: $preferencesManager.timerWarningThreshold) {
                            Text("1 minute").tag(TimeInterval(60))
                            Text("2 minutes").tag(TimeInterval(120))
                            Text("5 minutes").tag(TimeInterval(300))
                            Text("10 minutes").tag(TimeInterval(600))
                        }
                    }
                }
                
                Section("Timer Defaults") {
                    Picker("Default Timer Mode", selection: $preferencesManager.defaultTimerMode) {
                        ForEach(PresentationTimerManager.TimerMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    
                    Picker("Default Timer Type", selection: $preferencesManager.defaultTimerType) {
                        ForEach(PresentationTimerManager.TimerType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
            }
            .navigationTitle("Timer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
    }
}

// MARK: - PreferencesManager Timer Extensions

extension PreferencesManager {
    var showTimerNotifications: Bool {
        get { UserDefaults.standard.bool(forKey: "showTimerNotifications") }
        set { UserDefaults.standard.set(newValue, forKey: "showTimerNotifications") }
    }
    
    var enableTimerSounds: Bool {
        get { UserDefaults.standard.bool(forKey: "enableTimerSounds") }
        set { UserDefaults.standard.set(newValue, forKey: "enableTimerSounds") }
    }
    
    var timerWarningThreshold: TimeInterval {
        get {
            let stored = UserDefaults.standard.double(forKey: "timerWarningThreshold")
            return stored > 0 ? stored : 300 // 5 minutes default
        }
        set { UserDefaults.standard.set(newValue, forKey: "timerWarningThreshold") }
    }
    
    var defaultTimerMode: PresentationTimerManager.TimerMode {
        get {
            let stored = UserDefaults.standard.string(forKey: "defaultTimerMode") ?? "countdown"
            return PresentationTimerManager.TimerMode(rawValue: stored) ?? .countdown
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "defaultTimerMode") }
    }
    
    var defaultTimerType: PresentationTimerManager.TimerType {
        get {
            let stored = UserDefaults.standard.string(forKey: "defaultTimerType") ?? "presentation"
            return PresentationTimerManager.TimerType(rawValue: stored) ?? .presentation
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "defaultTimerType") }
    }
}

// MARK: - Preview

struct TimerControlsPanel_Previews: PreviewProvider {
    static var previews: some View {
        TimerControlsPanel()
    }
} 