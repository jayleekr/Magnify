import Foundation
import AppKit

/// PreferencesManager handles all application settings and user preferences
/// Provides persistent storage and real-time preference updates for screen recording
class PreferencesManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = PreferencesManager()
    
    // MARK: - Published Properties
    
    // Recording Preferences
    @Published var defaultRecordingFormat: ScreenRecordingManager.VideoFormat = .mp4
    @Published var defaultRecordingQuality: ScreenRecordingManager.RecordingQuality = .high
    @Published var includeSystemAudioByDefault: Bool = false
    @Published var includeMicrophoneByDefault: Bool = false
    @Published var includeAnnotationsByDefault: Bool = true
    @Published var showRecordingIndicator: Bool = true
    @Published var autoSaveRecordings: Bool = true
    @Published var recordingDirectory: URL
    
    // Zoom Preferences
    @Published var defaultZoomMode: ZoomManager.ZoomMode = .followMouse
    @Published var showZoomIndicatorInRecording: Bool = true
    @Published var zoomIndicatorOpacity: Double = 0.8
    @Published var maxZoomLevel: Float = 20.0
    @Published var zoomStep: Float = 0.5
    
    // Drawing Preferences
    @Published var defaultStrokeWidth: CGFloat = 3.0
    @Published var defaultStrokeColor: NSColor = .systemRed
    @Published var showDrawingToolsInRecording: Bool = true
    @Published var enableDrawingSounds: Bool = false
    @Published var autoSaveDrawings: Bool = true
    
    // Hotkey Preferences
    @Published var enableGlobalHotkeys: Bool = true
    @Published var recordingStartHotkey: HotkeyConfiguration = HotkeyConfiguration(keyCode: 15, modifiers: [.command, .shift]) // Cmd+Shift+R
    @Published var recordingStopHotkey: HotkeyConfiguration = HotkeyConfiguration(keyCode: 15, modifiers: [.command, .shift]) // Same key toggles
    @Published var zoomToggleHotkey: HotkeyConfiguration = HotkeyConfiguration(keyCode: 44, modifiers: [.command]) // Cmd+Z
    @Published var drawingToggleHotkey: HotkeyConfiguration = HotkeyConfiguration(keyCode: 2, modifiers: [.command]) // Cmd+D
    
    // General Preferences
    @Published var launchAtLogin: Bool = false
    @Published var showMenuBarIcon: Bool = true
    @Published var minimizeToMenuBar: Bool = true
    @Published var showNotifications: Bool = true
    @Published var enableTelemetry: Bool = false
    
    // Performance Preferences
    @Published var enableGPUAcceleration: Bool = true
    @Published var maxFrameRate: Int = 30
    @Published var compressionQuality: Double = 0.8
    @Published var enableBackgroundRecording: Bool = false
    
    // MARK: - Hotkey Configuration
    
    struct HotkeyConfiguration: Codable, Equatable {
        let keyCode: UInt32
        let modifiers: Set<NSEvent.ModifierFlags>
        
        var displayString: String {
            var components: [String] = []
            
            if modifiers.contains(.command) { components.append("⌘") }
            if modifiers.contains(.option) { components.append("⌥") }
            if modifiers.contains(.control) { components.append("⌃") }
            if modifiers.contains(.shift) { components.append("⇧") }
            
            // Convert key code to readable key
            let keyString = keyCodeToString(keyCode)
            components.append(keyString)
            
            return components.joined()
        }
        
        private func keyCodeToString(_ keyCode: UInt32) -> String {
            switch keyCode {
            case 0: return "A"
            case 1: return "S"
            case 2: return "D"
            case 3: return "F"
            case 4: return "H"
            case 5: return "G"
            case 6: return "Z"
            case 7: return "X"
            case 8: return "C"
            case 9: return "V"
            case 11: return "B"
            case 12: return "Q"
            case 13: return "W"
            case 14: return "E"
            case 15: return "R"
            case 16: return "Y"
            case 17: return "T"
            case 18: return "1"
            case 19: return "2"
            case 20: return "3"
            case 21: return "4"
            case 22: return "6"
            case 23: return "5"
            case 24: return "="
            case 25: return "9"
            case 26: return "7"
            case 27: return "-"
            case 28: return "8"
            case 29: return "0"
            case 30: return "]"
            case 31: return "O"
            case 32: return "U"
            case 33: return "["
            case 34: return "I"
            case 35: return "P"
            case 36: return "↵"
            case 37: return "L"
            case 38: return "J"
            case 39: return "'"
            case 40: return "K"
            case 41: return ";"
            case 42: return "\\"
            case 43: return ","
            case 44: return "/"
            case 45: return "N"
            case 46: return "M"
            case 47: return "."
            case 48: return "⇥"
            case 49: return "Space"
            case 51: return "⌫"
            case 53: return "⎋"
            case 76: return "↵"
            case 123: return "←"
            case 124: return "→"
            case 125: return "↓"
            case 126: return "↑"
            default: return "Key\(keyCode)"
            }
        }
    }
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        // Recording
        static let defaultRecordingFormat = "DefaultRecordingFormat"
        static let defaultRecordingQuality = "DefaultRecordingQuality"
        static let includeSystemAudioByDefault = "IncludeSystemAudioByDefault"
        static let includeMicrophoneByDefault = "IncludeMicrophoneByDefault"
        static let includeAnnotationsByDefault = "IncludeAnnotationsByDefault"
        static let showRecordingIndicator = "ShowRecordingIndicator"
        static let autoSaveRecordings = "AutoSaveRecordings"
        static let recordingDirectory = "RecordingDirectory"
        
        // Zoom
        static let defaultZoomMode = "DefaultZoomMode"
        static let showZoomIndicatorInRecording = "ShowZoomIndicatorInRecording"
        static let zoomIndicatorOpacity = "ZoomIndicatorOpacity"
        static let maxZoomLevel = "MaxZoomLevel"
        static let zoomStep = "ZoomStep"
        
        // Drawing
        static let defaultStrokeWidth = "DefaultStrokeWidth"
        static let defaultStrokeColor = "DefaultStrokeColor"
        static let showDrawingToolsInRecording = "ShowDrawingToolsInRecording"
        static let enableDrawingSounds = "EnableDrawingSounds"
        static let autoSaveDrawings = "AutoSaveDrawings"
        
        // Hotkeys
        static let enableGlobalHotkeys = "EnableGlobalHotkeys"
        static let recordingStartHotkey = "RecordingStartHotkey"
        static let recordingStopHotkey = "RecordingStopHotkey"
        static let zoomToggleHotkey = "ZoomToggleHotkey"
        static let drawingToggleHotkey = "DrawingToggleHotkey"
        
        // General
        static let launchAtLogin = "LaunchAtLogin"
        static let showMenuBarIcon = "ShowMenuBarIcon"
        static let minimizeToMenuBar = "MinimizeToMenuBar"
        static let showNotifications = "ShowNotifications"
        static let enableTelemetry = "EnableTelemetry"
        
        // Performance
        static let enableGPUAcceleration = "EnableGPUAcceleration"
        static let maxFrameRate = "MaxFrameRate"
        static let compressionQuality = "CompressionQuality"
        static let enableBackgroundRecording = "EnableBackgroundRecording"
    }
    
    // MARK: - Initialization
    
    private override init() {
        // Set default recording directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        recordingDirectory = documentsPath.appendingPathComponent("Magnify Recordings", isDirectory: true)
        
        super.init()
        
        loadPreferences()
        setupNotifications()
        createRecordingDirectoryIfNeeded()
        
        print("PreferencesManager: Initialized with default settings")
    }
    
    private func setupNotifications() {
        // Listen for preferences changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    @objc private func preferencesDidChange() {
        // Handle external preference changes if needed
        print("PreferencesManager: External preferences change detected")
    }
    
    private func createRecordingDirectoryIfNeeded() {
        do {
            try FileManager.default.createDirectory(at: recordingDirectory, withIntermediateDirectories: true)
        } catch {
            print("PreferencesManager: Failed to create recording directory: \(error)")
        }
    }
    
    // MARK: - Load/Save Preferences
    
    private func loadPreferences() {
        let defaults = UserDefaults.standard
        
        // Recording preferences
        if let formatString = defaults.object(forKey: Keys.defaultRecordingFormat) as? String,
           let format = ScreenRecordingManager.VideoFormat(rawValue: formatString) {
            defaultRecordingFormat = format
        }
        
        if let qualityString = defaults.object(forKey: Keys.defaultRecordingQuality) as? String,
           let quality = ScreenRecordingManager.RecordingQuality(rawValue: qualityString) {
            defaultRecordingQuality = quality
        }
        
        includeSystemAudioByDefault = defaults.bool(forKey: Keys.includeSystemAudioByDefault)
        includeMicrophoneByDefault = defaults.bool(forKey: Keys.includeMicrophoneByDefault)
        includeAnnotationsByDefault = defaults.object(forKey: Keys.includeAnnotationsByDefault) as? Bool ?? true
        showRecordingIndicator = defaults.object(forKey: Keys.showRecordingIndicator) as? Bool ?? true
        autoSaveRecordings = defaults.object(forKey: Keys.autoSaveRecordings) as? Bool ?? true
        
        if let directoryData = defaults.data(forKey: Keys.recordingDirectory),
           let url = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSURL.self, from: directoryData) as URL? {
            recordingDirectory = url
        }
        
        // Zoom preferences
        if let zoomModeString = defaults.object(forKey: Keys.defaultZoomMode) as? String,
           let zoomMode = ZoomManager.ZoomMode(rawValue: zoomModeString) {
            defaultZoomMode = zoomMode
        }
        
        showZoomIndicatorInRecording = defaults.object(forKey: Keys.showZoomIndicatorInRecording) as? Bool ?? true
        zoomIndicatorOpacity = defaults.object(forKey: Keys.zoomIndicatorOpacity) as? Double ?? 0.8
        maxZoomLevel = defaults.object(forKey: Keys.maxZoomLevel) as? Float ?? 20.0
        zoomStep = defaults.object(forKey: Keys.zoomStep) as? Float ?? 0.5
        
        // Drawing preferences
        defaultStrokeWidth = defaults.object(forKey: Keys.defaultStrokeWidth) as? CGFloat ?? 3.0
        
        if let colorData = defaults.data(forKey: Keys.defaultStrokeColor),
           let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) {
            defaultStrokeColor = color
        }
        
        showDrawingToolsInRecording = defaults.object(forKey: Keys.showDrawingToolsInRecording) as? Bool ?? true
        enableDrawingSounds = defaults.bool(forKey: Keys.enableDrawingSounds)
        autoSaveDrawings = defaults.object(forKey: Keys.autoSaveDrawings) as? Bool ?? true
        
        // Hotkey preferences
        enableGlobalHotkeys = defaults.object(forKey: Keys.enableGlobalHotkeys) as? Bool ?? true
        
        // Load hotkey configurations
        if let hotkeyData = defaults.data(forKey: Keys.recordingStartHotkey),
           let hotkey = try? JSONDecoder().decode(HotkeyConfiguration.self, from: hotkeyData) {
            recordingStartHotkey = hotkey
        }
        
        if let hotkeyData = defaults.data(forKey: Keys.zoomToggleHotkey),
           let hotkey = try? JSONDecoder().decode(HotkeyConfiguration.self, from: hotkeyData) {
            zoomToggleHotkey = hotkey
        }
        
        if let hotkeyData = defaults.data(forKey: Keys.drawingToggleHotkey),
           let hotkey = try? JSONDecoder().decode(HotkeyConfiguration.self, from: hotkeyData) {
            drawingToggleHotkey = hotkey
        }
        
        // General preferences
        launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        showMenuBarIcon = defaults.object(forKey: Keys.showMenuBarIcon) as? Bool ?? true
        minimizeToMenuBar = defaults.object(forKey: Keys.minimizeToMenuBar) as? Bool ?? true
        showNotifications = defaults.object(forKey: Keys.showNotifications) as? Bool ?? true
        enableTelemetry = defaults.bool(forKey: Keys.enableTelemetry)
        
        // Performance preferences
        enableGPUAcceleration = defaults.object(forKey: Keys.enableGPUAcceleration) as? Bool ?? true
        maxFrameRate = defaults.object(forKey: Keys.maxFrameRate) as? Int ?? 30
        compressionQuality = defaults.object(forKey: Keys.compressionQuality) as? Double ?? 0.8
        enableBackgroundRecording = defaults.bool(forKey: Keys.enableBackgroundRecording)
        
        print("PreferencesManager: Loaded all preferences from UserDefaults")
    }
    
    func savePreferences() {
        let defaults = UserDefaults.standard
        
        // Recording preferences
        defaults.set(defaultRecordingFormat.rawValue, forKey: Keys.defaultRecordingFormat)
        defaults.set(defaultRecordingQuality.rawValue, forKey: Keys.defaultRecordingQuality)
        defaults.set(includeSystemAudioByDefault, forKey: Keys.includeSystemAudioByDefault)
        defaults.set(includeMicrophoneByDefault, forKey: Keys.includeMicrophoneByDefault)
        defaults.set(includeAnnotationsByDefault, forKey: Keys.includeAnnotationsByDefault)
        defaults.set(showRecordingIndicator, forKey: Keys.showRecordingIndicator)
        defaults.set(autoSaveRecordings, forKey: Keys.autoSaveRecordings)
        
        if let directoryData = try? NSKeyedArchiver.archivedData(withRootObject: recordingDirectory, requiringSecureCoding: true) {
            defaults.set(directoryData, forKey: Keys.recordingDirectory)
        }
        
        // Zoom preferences
        defaults.set(defaultZoomMode.rawValue, forKey: Keys.defaultZoomMode)
        defaults.set(showZoomIndicatorInRecording, forKey: Keys.showZoomIndicatorInRecording)
        defaults.set(zoomIndicatorOpacity, forKey: Keys.zoomIndicatorOpacity)
        defaults.set(maxZoomLevel, forKey: Keys.maxZoomLevel)
        defaults.set(zoomStep, forKey: Keys.zoomStep)
        
        // Drawing preferences
        defaults.set(defaultStrokeWidth, forKey: Keys.defaultStrokeWidth)
        
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: defaultStrokeColor, requiringSecureCoding: true) {
            defaults.set(colorData, forKey: Keys.defaultStrokeColor)
        }
        
        defaults.set(showDrawingToolsInRecording, forKey: Keys.showDrawingToolsInRecording)
        defaults.set(enableDrawingSounds, forKey: Keys.enableDrawingSounds)
        defaults.set(autoSaveDrawings, forKey: Keys.autoSaveDrawings)
        
        // Hotkey preferences
        defaults.set(enableGlobalHotkeys, forKey: Keys.enableGlobalHotkeys)
        
        // Save hotkey configurations
        if let hotkeyData = try? JSONEncoder().encode(recordingStartHotkey) {
            defaults.set(hotkeyData, forKey: Keys.recordingStartHotkey)
        }
        
        if let hotkeyData = try? JSONEncoder().encode(zoomToggleHotkey) {
            defaults.set(hotkeyData, forKey: Keys.zoomToggleHotkey)
        }
        
        if let hotkeyData = try? JSONEncoder().encode(drawingToggleHotkey) {
            defaults.set(hotkeyData, forKey: Keys.drawingToggleHotkey)
        }
        
        // General preferences
        defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
        defaults.set(showMenuBarIcon, forKey: Keys.showMenuBarIcon)
        defaults.set(minimizeToMenuBar, forKey: Keys.minimizeToMenuBar)
        defaults.set(showNotifications, forKey: Keys.showNotifications)
        defaults.set(enableTelemetry, forKey: Keys.enableTelemetry)
        
        // Performance preferences
        defaults.set(enableGPUAcceleration, forKey: Keys.enableGPUAcceleration)
        defaults.set(maxFrameRate, forKey: Keys.maxFrameRate)
        defaults.set(compressionQuality, forKey: Keys.compressionQuality)
        defaults.set(enableBackgroundRecording, forKey: Keys.enableBackgroundRecording)
        
        defaults.synchronize()
        print("PreferencesManager: Saved all preferences to UserDefaults")
    }
    
    // MARK: - Preference Updates
    
    func updateRecordingDirectory(_ url: URL) {
        recordingDirectory = url
        createRecordingDirectoryIfNeeded()
        savePreferences()
        print("PreferencesManager: Recording directory updated to \(url.path)")
    }
    
    func updateHotkey(_ hotkey: HotkeyConfiguration, for action: HotkeyAction) {
        switch action {
        case .recordingToggle:
            recordingStartHotkey = hotkey
            recordingStopHotkey = hotkey
        case .zoomToggle:
            zoomToggleHotkey = hotkey
        case .drawingToggle:
            drawingToggleHotkey = hotkey
        }
        savePreferences()
        print("PreferencesManager: Hotkey updated for \(action)")
    }
    
    func resetToDefaults() {
        let defaultsToRemove = [
            Keys.defaultRecordingFormat, Keys.defaultRecordingQuality,
            Keys.includeSystemAudioByDefault, Keys.includeMicrophoneByDefault,
            Keys.includeAnnotationsByDefault, Keys.showRecordingIndicator,
            Keys.autoSaveRecordings, Keys.recordingDirectory,
            Keys.defaultZoomMode, Keys.showZoomIndicatorInRecording,
            Keys.zoomIndicatorOpacity, Keys.maxZoomLevel, Keys.zoomStep,
            Keys.defaultStrokeWidth, Keys.defaultStrokeColor,
            Keys.showDrawingToolsInRecording, Keys.enableDrawingSounds,
            Keys.autoSaveDrawings, Keys.enableGlobalHotkeys,
            Keys.recordingStartHotkey, Keys.recordingStopHotkey,
            Keys.zoomToggleHotkey, Keys.drawingToggleHotkey,
            Keys.launchAtLogin, Keys.showMenuBarIcon,
            Keys.minimizeToMenuBar, Keys.showNotifications,
            Keys.enableTelemetry, Keys.enableGPUAcceleration,
            Keys.maxFrameRate, Keys.compressionQuality,
            Keys.enableBackgroundRecording
        ]
        
        let defaults = UserDefaults.standard
        for key in defaultsToRemove {
            defaults.removeObject(forKey: key)
        }
        
        // Reset to default values
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        recordingDirectory = documentsPath.appendingPathComponent("Magnify Recordings", isDirectory: true)
        
        defaultRecordingFormat = .mp4
        defaultRecordingQuality = .high
        includeSystemAudioByDefault = false
        includeMicrophoneByDefault = false
        includeAnnotationsByDefault = true
        showRecordingIndicator = true
        autoSaveRecordings = true
        
        defaultZoomMode = .followMouse
        showZoomIndicatorInRecording = true
        zoomIndicatorOpacity = 0.8
        maxZoomLevel = 20.0
        zoomStep = 0.5
        
        defaultStrokeWidth = 3.0
        defaultStrokeColor = .systemRed
        showDrawingToolsInRecording = true
        enableDrawingSounds = false
        autoSaveDrawings = true
        
        enableGlobalHotkeys = true
        recordingStartHotkey = HotkeyConfiguration(keyCode: 15, modifiers: [.command, .shift])
        recordingStopHotkey = HotkeyConfiguration(keyCode: 15, modifiers: [.command, .shift])
        zoomToggleHotkey = HotkeyConfiguration(keyCode: 44, modifiers: [.command])
        drawingToggleHotkey = HotkeyConfiguration(keyCode: 2, modifiers: [.command])
        
        launchAtLogin = false
        showMenuBarIcon = true
        minimizeToMenuBar = true
        showNotifications = true
        enableTelemetry = false
        
        enableGPUAcceleration = true
        maxFrameRate = 30
        compressionQuality = 0.8
        enableBackgroundRecording = false
        
        savePreferences()
        print("PreferencesManager: Reset all preferences to defaults")
    }
    
    // MARK: - Helper Enums
    
    enum HotkeyAction: String, CaseIterable {
        case recordingToggle = "Recording Toggle"
        case zoomToggle = "Zoom Toggle"
        case drawingToggle = "Drawing Toggle"
        
        var displayName: String {
            return rawValue
        }
    }
}

// MARK: - NSEvent.ModifierFlags Codable Extension

extension NSEvent.ModifierFlags: Codable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(UInt.self)
        self.init(rawValue: rawValue)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
} 