import SwiftUI
import AppKit

/// PreferencesWindow is the main SwiftUI-based preferences interface
/// Provides tabbed organization for different preference categories
struct PreferencesWindow: View {
    
    @ObservedObject private var preferences = PreferencesManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        TabView {
            HotkeyPreferencesView()
                .tabItem {
                    Image(systemName: "keyboard")
                    Text("Hotkeys")
                }
                .tag(0)
            
            DrawingPreferencesView()
                .tabItem {
                    Image(systemName: "paintbrush")
                    Text("Drawing")
                }
                .tag(1)
            
            BehaviorPreferencesView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Behavior")
                }
                .tag(2)
            
            PerformancePreferencesView()
                .tabItem {
                    Image(systemName: "speedometer")
                    Text("Performance")
                }
                .tag(3)
        }
        .frame(width: 500, height: 400)
        .navigationTitle("Magnify Preferences")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
    }
}

// MARK: - Hotkey Preferences

struct HotkeyPreferencesView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var showingHotkeyConflictAlert = false
    @State private var conflictMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(label: Text("Global Hotkeys").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable global hotkeys", isOn: $preferences.globalHotkeyEnabled)
                        .onChange(of: preferences.globalHotkeyEnabled) { enabled in
                            if enabled {
                                updateGlobalHotkey()
                            } else {
                                HotkeyManager.shared.unregisterAllHotkeys()
                            }
                        }
                    
                    if preferences.globalHotkeyEnabled {
                        HStack {
                            Text("Overlay Toggle:")
                                .frame(width: 120, alignment: .leading)
                            
                            Picker("Hotkey", selection: $preferences.overlayToggleHotkey) {
                                ForEach(Array(PreferencesManager.availableHotkeys.keys), id: \.self) { key in
                                    Text(PreferencesManager.availableHotkeys[key] ?? key)
                                        .tag(key)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: preferences.overlayToggleHotkey) { _ in
                                updateGlobalHotkey()
                            }
                        }
                        
                        Text("Press the hotkey combination from anywhere in the system to toggle the overlay window.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Global hotkeys are disabled. Use the menu bar or main window controls instead.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            
            GroupBox(label: Text("Hotkey Information").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Hotkey Combinations:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(Array(PreferencesManager.availableHotkeys.keys), id: \.self) { key in
                        HStack {
                            Text(PreferencesManager.availableHotkeys[key] ?? key)
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 120, alignment: .leading)
                            Text("Toggle overlay window")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .padding()
        .alert("Hotkey Conflict", isPresented: $showingHotkeyConflictAlert) {
            Button("OK") { }
        } message: {
            Text(conflictMessage)
        }
    }
    
    private func updateGlobalHotkey() {
        // Unregister existing hotkeys
        HotkeyManager.shared.unregisterAllHotkeys()
        
        // Register new hotkey if enabled
        if preferences.globalHotkeyEnabled {
            if let components = preferences.parseHotkey(preferences.overlayToggleHotkey) {
                let success = HotkeyManager.shared.registerHotkey(
                    key: components.key,
                    modifiers: components.modifiers,
                    identifier: "overlay_toggle"
                )
                
                if !success {
                    conflictMessage = "Failed to register hotkey '\(preferences.getHotkeyDisplayString(preferences.overlayToggleHotkey))'. It may be in use by another application."
                    showingHotkeyConflictAlert = true
                }
            }
        }
    }
}

// MARK: - Drawing Preferences

struct DrawingPreferencesView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var selectedColorIndex = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(label: Text("Drawing Tools").font(.headline)) {
                VStack(alignment: .leading, spacing: 16) {
                    // Color Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default Stroke Color:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                            ForEach(0..<PreferencesManager.colorPresets.count, id: \.self) { index in
                                Button(action: {
                                    preferences.defaultStrokeColor = PreferencesManager.colorPresets[index]
                                    selectedColorIndex = index
                                }) {
                                    Circle()
                                        .fill(Color(PreferencesManager.colorPresets[index]))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary, lineWidth: preferences.defaultStrokeColor == PreferencesManager.colorPresets[index] ? 3 : 0)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        ColorPicker("Custom Color", selection: Binding(
                            get: { Color(preferences.defaultStrokeColor) },
                            set: { color in
                                preferences.defaultStrokeColor = NSColor(color)
                            }
                        ))
                        .labelsHidden()
                    }
                    
                    Divider()
                    
                    // Stroke Width
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Stroke Width:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(preferences.defaultStrokeWidth))px")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $preferences.defaultStrokeWidth, in: 1...20, step: 1)
                            .accentColor(Color(preferences.defaultStrokeColor))
                    }
                    
                    // Opacity
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Opacity:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(preferences.defaultOpacity * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $preferences.defaultOpacity, in: 0.1...1.0, step: 0.1)
                            .accentColor(Color(preferences.defaultStrokeColor))
                    }
                }
                .padding()
            }
            
            GroupBox(label: Text("Drawing Preview").font(.headline)) {
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 80)
                        .overlay(
                            ZStack {
                                Path { path in
                                    path.move(to: CGPoint(x: 50, y: 40))
                                    path.addLine(to: CGPoint(x: 150, y: 40))
                                    path.addLine(to: CGPoint(x: 100, y: 60))
                                }
                                .stroke(
                                    Color(preferences.defaultStrokeColor).opacity(preferences.defaultOpacity),
                                    lineWidth: preferences.defaultStrokeWidth
                                )
                                
                                Text("Preview of drawing stroke")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .offset(y: 25)
                            }
                        )
                }
                .padding()
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Behavior Preferences

struct BehaviorPreferencesView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(label: Text("App Behavior").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Launch at startup", isOn: $preferences.launchAtStartup)
                    
                    Toggle("Show menu bar icon", isOn: $preferences.showMenuBarIcon)
                    
                    Toggle("Hide overlay when pressing Escape", isOn: $preferences.hideOverlayOnEscape)
                    
                    Toggle("Remember window positions", isOn: $preferences.rememberWindowPosition)
                }
                .padding()
            }
            
            GroupBox(label: Text("Settings Management").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button("Export Settings...") {
                            exportSettings()
                        }
                        
                        Button("Import Settings...") {
                            importSettings()
                        }
                        
                        Spacer()
                        
                        Button("Reset to Defaults") {
                            showResetAlert()
                        }
                        .foregroundColor(.red)
                    }
                    
                    Text("Export your preferences to share with other devices or back them up. Import previously saved settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            GroupBox(label: Text("About").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Version:")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build:")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Bundle ID:")
                        Spacer()
                        Text(Bundle.main.bundleIdentifier ?? "com.jayleekr.magnify")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func exportSettings() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "Magnify-Settings.json"
        savePanel.title = "Export Magnify Settings"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    let settings = preferences.exportSettings()
                    let data = try JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)
                    try data.write(to: url)
                } catch {
                    showErrorAlert("Failed to export settings: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func importSettings() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.title = "Import Magnify Settings"
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.urls.first {
                do {
                    let data = try Data(contentsOf: url)
                    if let settings = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        preferences.importSettings(settings)
                    }
                } catch {
                    showErrorAlert("Failed to import settings: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showResetAlert() {
        let alert = NSAlert()
        alert.messageText = "Reset All Settings"
        alert.informativeText = "This will reset all preferences to their default values. This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            preferences.resetToDefaults()
        }
    }
    
    private func showErrorAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - Performance Preferences

struct PerformancePreferencesView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox(label: Text("Capture Performance").font(.headline)) {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Enable hardware acceleration", isOn: $preferences.enableHardwareAcceleration)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Maximum Capture Frame Rate:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(preferences.maxCaptureFrameRate)) FPS")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $preferences.maxCaptureFrameRate, in: 15...60, step: 5)
                        
                        Text("Higher frame rates provide smoother capture but use more system resources.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            
            GroupBox(label: Text("System Information").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("macOS Version:")
                        Spacer()
                        Text(ProcessInfo.processInfo.operatingSystemVersionString)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Architecture:")
                        Spacer()
                        Text(getSystemArchitecture())
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Screen Capture Available:")
                        Spacer()
                        Text(isScreenCaptureAvailable() ? "Yes" : "No")
                            .foregroundColor(isScreenCaptureAvailable() ? .green : .red)
                    }
                    
                    HStack {
                        Text("Recommended Settings:")
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Frame Rate: \(Int(preferences.getRecommendedCaptureSettings().frameRate)) FPS")
                            Text("Hardware Acceleration: \(preferences.getRecommendedCaptureSettings().useHardwareAcceleration ? "On" : "Off")")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            
            GroupBox(label: Text("Performance Tips").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Lower frame rates improve performance on older Macs")
                    Text("• Hardware acceleration requires macOS 12.3 or later")
                    Text("• Close unnecessary applications when using intensive features")
                    Text("• Restart the app if you experience performance issues")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func getSystemArchitecture() -> String {
        var size = 0
        sysctlbyname("hw.optional.arm64", nil, &size, nil, 0)
        var result: Int32 = 0
        sysctlbyname("hw.optional.arm64", &result, &size, nil, 0)
        return result == 1 ? "Apple Silicon" : "Intel"
    }
    
    private func isScreenCaptureAvailable() -> Bool {
        if #available(macOS 12.3, *) {
            return true
        } else {
            return false
        }
    }
}

// MARK: - Preview

struct PreferencesWindow_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesWindow()
    }
} 