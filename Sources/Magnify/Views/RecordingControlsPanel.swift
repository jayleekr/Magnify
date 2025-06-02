import SwiftUI
import AppKit

/// RecordingControlsPanel provides a comprehensive SwiftUI interface for screen recording
/// Features recording controls, settings, status indicators, and format selection
struct RecordingControlsPanel: View {
    
    @StateObject private var recordingManager = ScreenRecordingManager.shared
    @StateObject private var zoomManager = ZoomManager.shared
    @StateObject private var preferencesManager = PreferencesManager.shared
    
    @State private var showingSettings = false
    @State private var showingFilePicker = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            headerSection
            
            // Recording Status
            statusSection
            
            if isExpanded {
                // Recording Controls
                controlsSection
                
                // Quick Settings
                settingsSection
                
                // File Management
                fileManagementSection
            }
        }
        .padding(20)
        .frame(width: isExpanded ? 400 : 300)
        .background(Material.hudWindow, in: RoundedRectangle(cornerRadius: 12))
        .alert("Recording Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            handleDirectorySelection(result)
        }
        .sheet(isPresented: $showingSettings) {
            RecordingSettingsView()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "video.circle.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Screen Recording")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Magnify - Advanced Recording")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { withAnimation(.spring()) { isExpanded.toggle() } }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(spacing: 12) {
            // Recording Status Indicator
            HStack {
                Circle()
                    .fill(recordingManager.recordingStatus.color)
                    .frame(width: 12, height: 12)
                    .scaleEffect(recordingManager.isRecording ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recordingManager.isRecording)
                
                Text(recordingManager.recordingStatus.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if recordingManager.isRecording {
                    Text(recordingManager.formattedDuration)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Bar (when recording)
            if recordingManager.isRecording {
                VStack(spacing: 4) {
                    HStack {
                        Text("Recording...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(recordingManager.estimatedFileSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: min(recordingManager.recordingDuration / 3600, 1.0)) // Max 1 hour visualization
                        .progressViewStyle(LinearProgressViewStyle(tint: recordingManager.recordingStatus.color))
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        VStack(spacing: 12) {
            // Primary Recording Controls
            HStack(spacing: 16) {
                // Start/Stop Button
                Button(action: handleRecordingToggle) {
                    HStack {
                        Image(systemName: recordingManager.isRecording ? "stop.fill" : "record.circle")
                            .font(.title3)
                        
                        Text(recordingManager.isRecording ? "Stop Recording" : "Start Recording")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(recordingManager.isRecording ? Color.red : Color.accentColor, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundColor(.white)
                }
                .disabled(recordingManager.recordingStatus == .preparing || recordingManager.recordingStatus == .stopping)
                
                // Pause/Resume Button (only when recording)
                if recordingManager.isRecording {
                    Button(action: handlePauseToggle) {
                        Image(systemName: recordingManager.isPaused ? "play.fill" : "pause.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            
            // Secondary Controls
            HStack(spacing: 12) {
                Button("Settings") {
                    showingSettings = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Open Folder") {
                    openRecordingsFolder()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                // Quick format selector
                Picker("Format", selection: $recordingManager.selectedFormat) {
                    ForEach(recordingManager.availableFormats, id: \.self) { format in
                        Text(format.displayName)
                            .tag(format)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.small)
            }
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Settings")
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(spacing: 8) {
                // Quality Selector
                HStack {
                    Text("Quality:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Picker("Quality", selection: $recordingManager.recordingQuality) {
                        ForEach(ScreenRecordingManager.RecordingQuality.allCases, id: \.self) { quality in
                            Text(quality.rawValue)
                                .tag(quality)
                        }
                    }
                    .pickerStyle(.menu)
                    .controlSize(.mini)
                }
                
                // Options Toggles
                SettingsToggle(
                    title: "Include Annotations",
                    subtitle: "Overlay drawings and zoom indicators",
                    isOn: $recordingManager.includeAnnotations
                )
                
                SettingsToggle(
                    title: "System Audio",
                    subtitle: "Record computer audio output",
                    isOn: $recordingManager.includeSystemAudio
                )
                
                SettingsToggle(
                    title: "Microphone",
                    subtitle: "Record microphone input",
                    isOn: $recordingManager.includeMicrophone
                )
                
                SettingsToggle(
                    title: "Show Zoom Indicator",
                    subtitle: "Display zoom level in recording",
                    isOn: $zoomManager.showZoomIndicator
                )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - File Management Section
    
    private var fileManagementSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("File Management")
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(spacing: 6) {
                HStack {
                    Text("Save Location:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Change") {
                        showingFilePicker = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
                
                Text(preferencesManager.recordingDirectory.lastPathComponent)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let currentURL = recordingManager.currentRecordingURL {
                    HStack {
                        Text("Current File:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Reveal") {
                            NSWorkspace.shared.selectFile(currentURL.path, inFileViewerRootedAtPath: currentURL.deletingLastPathComponent().path)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }
                    
                    Text(currentURL.lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Action Handlers
    
    private func handleRecordingToggle() {
        Task {
            if recordingManager.isRecording {
                let result = await recordingManager.stopRecording()
                await MainActor.run {
                    handleRecordingResult(result)
                }
            } else {
                let result = await recordingManager.startRecording()
                await MainActor.run {
                    handleRecordingResult(result)
                }
            }
        }
    }
    
    private func handlePauseToggle() {
        Task {
            if recordingManager.isPaused {
                await recordingManager.resumeRecording()
            } else {
                recordingManager.pauseRecording()
            }
        }
    }
    
    private func handleRecordingResult(_ result: Result<URL, ScreenRecordingManager.RecordingError>) {
        switch result {
        case .success(let url):
            print("Recording operation successful: \(url)")
            
            // Show notification
            if preferencesManager.showNotifications {
                let notification = NSUserNotification()
                notification.title = "Magnify Recording"
                notification.informativeText = recordingManager.isRecording ? "Recording started" : "Recording completed"
                notification.soundName = NSUserNotificationDefaultSoundName
                NSUserNotificationCenter.default.deliver(notification)
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
    
    private func openRecordingsFolder() {
        NSWorkspace.shared.open(preferencesManager.recordingDirectory)
    }
    
    private func handleDirectorySelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let selectedURL = urls.first {
                preferencesManager.updateRecordingDirectory(selectedURL)
            }
        case .failure(let error):
            errorMessage = "Failed to select directory: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
}

// MARK: - Settings Toggle Component

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .controlSize(.mini)
        }
    }
}

// MARK: - Recording Settings View

struct RecordingSettingsView: View {
    @StateObject private var preferencesManager = PreferencesManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Recording Defaults") {
                    Picker("Default Format", selection: $preferencesManager.defaultRecordingFormat) {
                        ForEach(ScreenRecordingManager.VideoFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    
                    Picker("Default Quality", selection: $preferencesManager.defaultRecordingQuality) {
                        ForEach(ScreenRecordingManager.RecordingQuality.allCases, id: \.self) { quality in
                            Text(quality.rawValue).tag(quality)
                        }
                    }
                    
                    Toggle("Include System Audio by Default", isOn: $preferencesManager.includeSystemAudioByDefault)
                    Toggle("Include Microphone by Default", isOn: $preferencesManager.includeMicrophoneByDefault)
                    Toggle("Include Annotations by Default", isOn: $preferencesManager.includeAnnotationsByDefault)
                }
                
                Section("Display Options") {
                    Toggle("Show Recording Indicator", isOn: $preferencesManager.showRecordingIndicator)
                    Toggle("Show Zoom Indicator in Recording", isOn: $preferencesManager.showZoomIndicatorInRecording)
                    
                    VStack(alignment: .leading) {
                        Text("Zoom Indicator Opacity")
                        Slider(value: $preferencesManager.zoomIndicatorOpacity, in: 0.1...1.0)
                        Text("\(Int(preferencesManager.zoomIndicatorOpacity * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Performance") {
                    Toggle("Enable GPU Acceleration", isOn: $preferencesManager.enableGPUAcceleration)
                    
                    VStack(alignment: .leading) {
                        Text("Max Frame Rate")
                        Picker("Frame Rate", selection: $preferencesManager.maxFrameRate) {
                            Text("24 fps").tag(24)
                            Text("30 fps").tag(30)
                            Text("60 fps").tag(60)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Compression Quality")
                        Slider(value: $preferencesManager.compressionQuality, in: 0.1...1.0)
                        Text("\(Int(preferencesManager.compressionQuality * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("File Management") {
                    Toggle("Auto-save Recordings", isOn: $preferencesManager.autoSaveRecordings)
                    
                    HStack {
                        Text("Save Location")
                        Spacer()
                        Text(preferencesManager.recordingDirectory.lastPathComponent)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("Reset to Defaults") {
                        preferencesManager.resetToDefaults()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Recording Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        preferencesManager.savePreferences()
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 600)
    }
}

// MARK: - Preview

struct RecordingControlsPanel_Previews: PreviewProvider {
    static var previews: some View {
        RecordingControlsPanel()
            .preferredColorScheme(.dark)
    }
} 