import AppKit
import ScreenCaptureKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var mainWindow: NSWindow?
    private let screenCaptureManager = ScreenCaptureManager()
    private let screenRecordingManager = ScreenRecordingManager.shared
    private var imageView: NSImageView?
    private var overlayWindow: OverlayWindow?
    private var zoomWindow: ZoomWindow?
    private var annotationPanelWindow: NSWindow?
    private var recordingControlsWindow: NSWindow?
    private var recordingControlsPanel: RecordingControlsPanel?
    private let hotkeyManager = HotkeyManager.shared
    private let preferencesManager = PreferencesManager.shared
    private let zoomManager = ZoomManager.shared
    private let drawingToolManager = DrawingToolManager.shared
    private let annotationManager = AnnotationManager.shared
    private let layerManager = LayerManager.shared
    private let exportManager = ExportManager.shared
    
    // Status tracking
    private var drawingStatusLabel: NSTextField?
    private var layerStatusLabel: NSTextField?
    private var documentStatusLabel: NSTextField?
    private var recordingStatusLabel: NSTextField?
    private var statusUpdateTimer: Timer?
    
    // Recording Manager
    private var recordingManager: ScreenRecordingManager?
    
    // Timer System
    private var timerManager = PresentationTimerManager.shared
    private var timerOverlayWindow: TimerOverlayWindow?
    private var timerControlsWindow: NSWindow?
    private var timerControlsPanel: TimerControlsPanel?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        initializeComponents()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up timers
        statusUpdateTimer?.invalidate()
        
        // Stop any active recording
        if screenRecordingManager.isRecording {
            Task {
                let _ = await screenRecordingManager.stopRecording()
            }
        }
        
        // Save current document
        _ = annotationManager.saveCurrentDocument()
        
        // Clean up global hotkeys
        hotkeyManager.unregisterAllHotkeys()
        
        // Clean up zoom functionality
        zoomManager.stopZoom()
        
        // Clean up drawing tools
        drawingToolManager.clearAllDrawings()
        
        // Close all windows
        annotationPanelWindow?.close()
        recordingControlsWindow?.close()
        
        print("AppDelegate: Cleaned up all systems including screen recording on app termination")
    }
    
    // MARK: - Window Setup
    
    private func setupMainWindow() {
        let contentRect = NSRect(x: 0, y: 0, width: 900, height: 950) // Increased size for recording section
        
        mainWindow = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        mainWindow?.title = "Magnify - Advanced Screen Recording & Annotation System"
        mainWindow?.center()
        mainWindow?.makeKeyAndOrderFront(nil)
        
        setupEnhancedUI()
    }
    
    private func setupEnhancedUI() {
        guard let window = mainWindow else { return }
        
        let contentView = NSView(frame: window.contentView?.bounds ?? NSRect.zero)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        window.contentView = contentView
        
        // Title label
        let titleLabel = NSTextField(labelWithString: "Magnify - Advanced Screen Recording & Annotation System")
        titleLabel.alignment = .center
        titleLabel.font = NSFont.boldSystemFont(ofSize: 20)
        titleLabel.frame = NSRect(x: 50, y: 890, width: 800, height: 30)
        contentView.addSubview(titleLabel)
        
        // Permission status label
        let permissionLabel = NSTextField(labelWithString: "Permission Status: Checking...")
        permissionLabel.alignment = .center
        permissionLabel.font = NSFont.systemFont(ofSize: 14)
        permissionLabel.frame = NSRect(x: 50, y: 860, width: 800, height: 20)
        permissionLabel.textColor = .secondaryLabelColor
        contentView.addSubview(permissionLabel)
        permissionLabel.identifier = NSUserInterfaceItemIdentifier("permissionLabel")
        
        // Screen Recording Section (NEW)
        setupScreenRecordingSection(in: contentView)
        
        // Screen Capture Section
        setupScreenCaptureSection(in: contentView)
        
        // Zoom Section
        setupZoomSection(in: contentView)
        
        // Drawing Tools Section
        setupDrawingToolsSection(in: contentView)
        
        // Annotation Management Section
        setupAnnotationSection(in: contentView)
        
        // Layer Management Section
        setupLayerSection(in: contentView)
        
        // Export Section
        setupExportSection(in: contentView)
        
        // Status Section
        setupStatusSection(in: contentView)
        
        // Instructions
        setupInstructionsSection(in: contentView)
    }
    
    // MARK: - Screen Recording Section (NEW)
    
    private func setupScreenRecordingSection(in contentView: NSView) {
        let recordingLabel = createSectionLabel("📹 Screen Recording (Checkpoint 3.1)", frame: NSRect(x: 50, y: 820, width: 300, height: 25))
        recordingLabel.textColor = .systemBlue
        contentView.addSubview(recordingLabel)
        
        let startRecordingButton = createButton("Start Recording", frame: NSRect(x: 50, y: 785, width: 110, height: 30))
        startRecordingButton.target = self
        startRecordingButton.action = #selector(startRecordingPressed)
        contentView.addSubview(startRecordingButton)
        
        let stopRecordingButton = createButton("Stop Recording", frame: NSRect(x: 170, y: 785, width: 110, height: 30))
        stopRecordingButton.target = self
        stopRecordingButton.action = #selector(stopRecordingPressed)
        contentView.addSubview(stopRecordingButton)
        
        let recordingControlsButton = createButton("Recording Panel", frame: NSRect(x: 290, y: 785, width: 120, height: 30))
        recordingControlsButton.target = self
        recordingControlsButton.action = #selector(showRecordingControlsPressed)
        contentView.addSubview(recordingControlsButton)
        
        let openRecordingsButton = createButton("Open Folder", frame: NSRect(x: 420, y: 785, width: 100, height: 30))
        openRecordingsButton.target = self
        openRecordingsButton.action = #selector(openRecordingsFolderPressed)
        contentView.addSubview(openRecordingsButton)
        
        // Recording status indicator
        recordingStatusLabel = NSTextField(labelWithString: "Recording: Ready")
        recordingStatusLabel?.font = NSFont.systemFont(ofSize: 12)
        recordingStatusLabel?.frame = NSRect(x: 530, y: 790, width: 200, height: 20)
        recordingStatusLabel?.textColor = .secondaryLabelColor
        contentView.addSubview(recordingStatusLabel!)
    }
    
    private func setupScreenCaptureSection(in contentView: NSView) {
        let captureLabel = createSectionLabel("Screen Capture", frame: NSRect(x: 50, y: 750, width: 200, height: 25))
        contentView.addSubview(captureLabel)
        
        let captureButton = createButton("Capture Screen", frame: NSRect(x: 50, y: 715, width: 120, height: 30))
        captureButton.target = self
        captureButton.action = #selector(captureButtonPressed)
        contentView.addSubview(captureButton)
    }
    
    private func setupZoomSection(in contentView: NSView) {
        let zoomLabel = createSectionLabel("Zoom Functionality", frame: NSRect(x: 200, y: 750, width: 200, height: 25))
        contentView.addSubview(zoomLabel)
        
        let showZoomButton = createButton("Show Zoom", frame: NSRect(x: 200, y: 715, width: 90, height: 30))
        showZoomButton.target = self
        showZoomButton.action = #selector(showZoomPressed)
        contentView.addSubview(showZoomButton)
        
        let hideZoomButton = createButton("Hide Zoom", frame: NSRect(x: 300, y: 715, width: 90, height: 30))
        hideZoomButton.target = self
        hideZoomButton.action = #selector(hideZoomPressed)
        contentView.addSubview(hideZoomButton)
    }
    
    private func setupDrawingToolsSection(in contentView: NSView) {
        let drawingLabel = createSectionLabel("Drawing Tools", frame: NSRect(x: 420, y: 750, width: 200, height: 25))
        contentView.addSubview(drawingLabel)
        
        let toolPaletteButton = createButton("Toggle Palette", frame: NSRect(x: 420, y: 715, width: 110, height: 30))
        toolPaletteButton.target = self
        toolPaletteButton.action = #selector(toggleToolPalettePressed)
        contentView.addSubview(toolPaletteButton)
        
        let testDrawingButton = createButton("Test Drawing", frame: NSRect(x: 540, y: 715, width: 100, height: 30))
        testDrawingButton.target = self
        testDrawingButton.action = #selector(testDrawingPressed)
        contentView.addSubview(testDrawingButton)
        
        let clearDrawingButton = createButton("Clear All", frame: NSRect(x: 650, y: 715, width: 80, height: 30))
        clearDrawingButton.target = self
        clearDrawingButton.action = #selector(clearDrawingPressed)
        contentView.addSubview(clearDrawingButton)
    }
    
    private func setupAnnotationSection(in contentView: NSView) {
        let annotationLabel = createSectionLabel("Annotation Management", frame: NSRect(x: 50, y: 670, width: 250, height: 25))
        contentView.addSubview(annotationLabel)
        
        let newDocumentButton = createButton("New Document", frame: NSRect(x: 50, y: 635, width: 110, height: 30))
        newDocumentButton.target = self
        newDocumentButton.action = #selector(createNewDocumentPressed)
        contentView.addSubview(newDocumentButton)
        
        let saveDocumentButton = createButton("Save Document", frame: NSRect(x: 170, y: 635, width: 110, height: 30))
        saveDocumentButton.target = self
        saveDocumentButton.action = #selector(saveDocumentPressed)
        contentView.addSubview(saveDocumentButton)
        
        let showPanelButton = createButton("Show Panel", frame: NSRect(x: 290, y: 635, width: 100, height: 30))
        showPanelButton.target = self
        showPanelButton.action = #selector(showAnnotationPanelPressed)
        contentView.addSubview(showPanelButton)
    }
    
    private func setupLayerSection(in contentView: NSView) {
        let layerLabel = createSectionLabel("Layer Management", frame: NSRect(x: 420, y: 670, width: 200, height: 25))
        contentView.addSubview(layerLabel)
        
        let newLayerButton = createButton("New Layer", frame: NSRect(x: 420, y: 635, width: 90, height: 30))
        newLayerButton.target = self
        newLayerButton.action = #selector(createNewLayerPressed)
        contentView.addSubview(newLayerButton)
        
        let layerPanelButton = createButton("Layer Panel", frame: NSRect(x: 520, y: 635, width: 100, height: 30))
        layerPanelButton.target = self
        layerPanelButton.action = #selector(toggleLayerPanelPressed)
        contentView.addSubview(layerPanelButton)
    }
    
    private func setupExportSection(in contentView: NSView) {
        let exportLabel = createSectionLabel("Export & Import", frame: NSRect(x: 650, y: 670, width: 200, height: 25))
        contentView.addSubview(exportLabel)
        
        let exportPNGButton = createButton("Export PNG", frame: NSRect(x: 650, y: 635, width: 90, height: 30))
        exportPNGButton.target = self
        exportPNGButton.action = #selector(exportPNGPressed)
        contentView.addSubview(exportPNGButton)
        
        let exportPDFButton = createButton("Export PDF", frame: NSRect(x: 750, y: 635, width: 90, height: 30))
        exportPDFButton.target = self
        exportPDFButton.action = #selector(exportPDFPressed)
        contentView.addSubview(exportPDFButton)
    }
    
    private func setupStatusSection(in contentView: NSView) {
        let statusLabel = createSectionLabel("System Status", frame: NSRect(x: 50, y: 590, width: 200, height: 25))
        contentView.addSubview(statusLabel)
        
        // Recording status (NEW)
        recordingStatusLabel = NSTextField(labelWithString: "Recording: Ready")
        recordingStatusLabel?.font = NSFont.systemFont(ofSize: 12)
        recordingStatusLabel?.frame = NSRect(x: 50, y: 565, width: 200, height: 20)
        recordingStatusLabel?.textColor = .secondaryLabelColor
        contentView.addSubview(recordingStatusLabel!)
        
        // Drawing status
        drawingStatusLabel = NSTextField(labelWithString: "Drawing: No elements")
        drawingStatusLabel?.font = NSFont.systemFont(ofSize: 12)
        drawingStatusLabel?.frame = NSRect(x: 270, y: 565, width: 200, height: 20)
        drawingStatusLabel?.textColor = .secondaryLabelColor
        contentView.addSubview(drawingStatusLabel!)
        
        // Layer status
        layerStatusLabel = NSTextField(labelWithString: "Layers: No layers")
        layerStatusLabel?.font = NSFont.systemFont(ofSize: 12)
        layerStatusLabel?.frame = NSRect(x: 490, y: 565, width: 200, height: 20)
        layerStatusLabel?.textColor = .secondaryLabelColor
        contentView.addSubview(layerStatusLabel!)
        
        // Document status
        documentStatusLabel = NSTextField(labelWithString: "Document: No document")
        documentStatusLabel?.font = NSFont.systemFont(ofSize: 12)
        documentStatusLabel?.frame = NSRect(x: 710, y: 565, width: 150, height: 20)
        documentStatusLabel?.textColor = .secondaryLabelColor
        contentView.addSubview(documentStatusLabel!)
    }
    
    private func setupInstructionsSection(in contentView: NSView) {
        let instructionsLabel = createSectionLabel("Keyboard Shortcuts", frame: NSRect(x: 50, y: 520, width: 250, height: 25))
        contentView.addSubview(instructionsLabel)
        
        let instructions = """
        Global Shortcuts:
        • Cmd+Shift+R: Toggle screen recording
        • Cmd+Shift+C: Capture screen
        • Cmd+Shift+Z: Toggle zoom
        • Cmd+T: Toggle drawing palette
        • Cmd+Shift+A: Show annotation panel
        • Cmd+S: Save current document
        • Cmd+N: New document
        • Cmd+L: Toggle layer panel
        
        Recording Shortcuts:
        • Space: Pause/Resume recording
        • Escape: Stop recording
        
        Drawing Shortcuts:
        • 1-8: Select drawing tools
        • Cmd+Z: Undo
        • Cmd+Shift+Z: Redo
        • Escape: Exit current tool
        """
        
        let instructionsText = NSTextField(labelWithString: instructions)
        instructionsText.font = NSFont.systemFont(ofSize: 11)
        instructionsText.frame = NSRect(x: 50, y: 250, width: 800, height: 260)
        instructionsText.textColor = .secondaryLabelColor
        instructionsText.backgroundColor = .clear
        instructionsText.isBezeled = false
        instructionsText.isEditable = false
        instructionsText.maximumNumberOfLines = 0
        instructionsText.lineBreakMode = .byWordWrapping
        contentView.addSubview(instructionsText)
    }
    
    // MARK: - Screen Recording Setup (NEW)
    
    private func setupScreenRecording() {
        // Set up screen recording with default preferences
        screenRecordingManager.selectedFormat = preferencesManager.defaultRecordingFormat
        screenRecordingManager.recordingQuality = preferencesManager.defaultRecordingQuality
        screenRecordingManager.includeSystemAudio = preferencesManager.includeSystemAudioByDefault
        screenRecordingManager.includeMicrophone = preferencesManager.includeMicrophoneByDefault
        screenRecordingManager.includeAnnotations = preferencesManager.includeAnnotationsByDefault
        
        print("AppDelegate: Screen recording system initialized with user preferences")
    }
    
    // MARK: - Screen Recording Actions (NEW)
    
    @objc private func startRecordingPressed() {
        Task {
            let result = await screenRecordingManager.startRecording()
            
            await MainActor.run {
                switch result {
                case .success(let url):
                    print("Recording started successfully: \(url)")
                    showNotification(title: "Recording Started", message: "Screen recording has begun")
                    
                case .failure(let error):
                    showErrorAlert(title: "Recording Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func stopRecordingPressed() {
        Task {
            let result = await screenRecordingManager.stopRecording()
            
            await MainActor.run {
                switch result {
                case .success(let url):
                    print("Recording stopped successfully: \(url)")
                    showNotification(title: "Recording Completed", message: "Video saved to: \(url.lastPathComponent)")
                    
                case .failure(let error):
                    showErrorAlert(title: "Stop Recording Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func showRecordingControlsPressed() {
        if let existingWindow = recordingControlsWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        let contentRect = NSRect(x: 0, y: 0, width: 400, height: 500)
        
        recordingControlsWindow = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        recordingControlsWindow?.title = "Recording Controls"
        recordingControlsWindow?.center()
        
        // Create SwiftUI view
        let recordingControlsView = RecordingControlsPanel()
        let hostingView = NSHostingView(rootView: recordingControlsView)
        recordingControlsWindow?.contentView = hostingView
        
        recordingControlsWindow?.makeKeyAndOrderFront(nil)
        
        print("AppDelegate: Recording controls panel opened")
    }
    
    @objc private func openRecordingsFolderPressed() {
        NSWorkspace.shared.open(preferencesManager.recordingDirectory)
    }
    
    // MARK: - Helper Methods (NEW)
    
    private func showNotification(title: String, message: String) {
        guard preferencesManager.showNotifications else { return }
        
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    private func showErrorAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // MARK: - Status Updates (Updated)
    
    private func updateAllStatus() {
        updateRecordingStatus()  // NEW
        updateDrawingStatus()
        updateLayerStatus()
        updateDocumentStatus()
    }
    
    private func updateRecordingStatus() {
        let status = screenRecordingManager.recordingStatus
        let duration = screenRecordingManager.formattedDuration
        let fileSize = screenRecordingManager.estimatedFileSize
        
        var statusText = "Recording: \(status.rawValue)"
        if screenRecordingManager.isRecording {
            statusText += " (\(duration), \(fileSize))"
        }
        
        recordingStatusLabel?.stringValue = statusText
        recordingStatusLabel?.textColor = status.color
    }
    
    private func updateDrawingStatus() {
        let stats = drawingToolManager.getDrawingStatistics()
        let currentTool = drawingToolManager.currentTool.displayName
        drawingStatusLabel?.stringValue = "Drawing: \(stats.totalElements) elements | Tool: \(currentTool)"
    }
    
    private func updateLayerStatus() {
        let stats = layerManager.getLayerStatistics()
        let currentLayer = layerManager.currentLayer?.name ?? "None"
        layerStatusLabel?.stringValue = "Layers: \(stats.totalLayers) total (\(stats.visibleLayers) visible) | Current: \(currentLayer)"
    }
    
    private func updateDocumentStatus() {
        if let document = annotationManager.currentDocument {
            let dirtyIndicator = annotationManager.isDocumentDirty ? " (unsaved)" : ""
            documentStatusLabel?.stringValue = "Document: \(document.name)\(dirtyIndicator)"
        } else {
            documentStatusLabel?.stringValue = "Document: No document"
        }
    }
    
    // MARK: - Annotation Management Setup
    
    private func setupAnnotationManagement() {
        // Initialize with a default document
        let defaultDocument = annotationManager.createNewDocument(name: "Default Annotation")
        print("AppDelegate: Created default annotation document")
        
        // Set up notification observers
        setupAnnotationNotifications()
    }
    
    private func setupAnnotationNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(documentChanged),
            name: .documentChanged,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(layerChanged),
            name: .layerContentChanged,
            object: nil
        )
    }
    
    @objc private func documentChanged() {
        DispatchQueue.main.async {
            self.updateDocumentStatus()
        }
    }
    
    @objc private func layerChanged() {
        DispatchQueue.main.async {
            self.updateLayerStatus()
        }
    }
    
    // MARK: - Status Updates
    
    private func startStatusUpdates() {
        statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.updateAllStatus()
            }
        }
    }
    
    // MARK: - Annotation Panel
    
    private func showAnnotationPanel() {
        if annotationPanelWindow == nil {
            createAnnotationPanelWindow()
        }
        
        annotationPanelWindow?.makeKeyAndOrderFront(nil)
        print("AppDelegate: Showing annotation panel")
    }
    
    private func createAnnotationPanelWindow() {
        let panelRect = NSRect(x: 100, y: 100, width: 350, height: 650)
        
        annotationPanelWindow = NSWindow(
            contentRect: panelRect,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        annotationPanelWindow?.title = "Annotation Manager"
        annotationPanelWindow?.level = .floating
        
        // Create SwiftUI content
        let annotationPanel = AnnotationPanel()
        let hostingView = NSHostingView(rootView: annotationPanel)
        hostingView.frame = panelRect
        
        annotationPanelWindow?.contentView = hostingView
        print("AppDelegate: Created annotation panel window")
    }
    
    // MARK: - Action Methods
    
    @objc private func createNewDocumentPressed() {
        let document = annotationManager.createNewDocument()
        print("AppDelegate: Created new document: \(document.name)")
        updateDocumentStatus()
    }
    
    @objc private func saveDocumentPressed() {
        if annotationManager.saveCurrentDocument() {
            print("AppDelegate: Document saved successfully")
        } else {
            print("AppDelegate: Failed to save document")
        }
        updateDocumentStatus()
    }
    
    @objc private func showAnnotationPanelPressed() {
        showAnnotationPanel()
    }
    
    @objc private func createNewLayerPressed() {
        let layer = layerManager.createLayer()
        print("AppDelegate: Created new layer: \(layer.name)")
        updateLayerStatus()
    }
    
    @objc private func toggleLayerPanelPressed() {
        layerManager.toggleLayerPanel()
        print("AppDelegate: Toggled layer panel")
    }
    
    @objc private func exportPNGPressed() {
        exportCurrentDocument(format: .png)
    }
    
    @objc private func exportPDFPressed() {
        exportCurrentDocument(format: .pdf)
    }
    
    private func exportCurrentDocument(format: ExportManager.ExportFormat) {
        guard let document = annotationManager.currentDocument else {
            print("AppDelegate: No document to export")
            return
        }
        
        if let url = exportManager.showExportDialog(for: document, format: format) {
            Task {
                let result = await exportManager.exportDocument(document, format: format, to: url)
                switch result {
                case .success(let exportedURL):
                    print("AppDelegate: Successfully exported to: \(exportedURL)")
                case .failure(let error):
                    print("AppDelegate: Export failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createSectionLabel(_ text: String, frame: NSRect) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.alignment = .left
        label.font = NSFont.boldSystemFont(ofSize: 14)
        label.frame = frame
        return label
    }
    
    private func createButton(_ title: String, frame: NSRect) -> NSButton {
        let button = NSButton(frame: frame)
        button.title = title
        button.bezelStyle = .rounded
        return button
    }
    
    // MARK: - Screen Capture Permission
    
    private func checkScreenCapturePermission() {
        Task {
            let hasPermission = await screenCaptureManager.requestPermission()
            
            DispatchQueue.main.async {
                self.updatePermissionStatus(hasPermission: hasPermission)
            }
            
            if !hasPermission {
                DispatchQueue.main.async {
                    self.showPermissionAlert()
                }
            }
        }
    }
    
    private func updatePermissionStatus(hasPermission: Bool) {
        guard let contentView = mainWindow?.contentView,
              let permissionLabel = contentView.viewWithTag(0) as? NSTextField ??
              contentView.subviews.first(where: { $0.identifier?.rawValue == "permissionLabel" }) as? NSTextField else {
            return
        }
        
        if hasPermission {
            permissionLabel.stringValue = "Permission Status: ✅ Granted"
            permissionLabel.textColor = .systemGreen
        } else {
            permissionLabel.stringValue = "Permission Status: ❌ Not Granted"
            permissionLabel.textColor = .systemRed
        }
    }
    
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "Magnify needs screen recording permission to capture and annotate your screen. Please grant permission in System Preferences > Privacy & Security > Screen Recording."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Preferences
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
        }
    }
    
    // MARK: - Overlay Window Actions
    
    @objc private func showOverlayPressed() {
        if overlayWindow == nil {
            overlayWindow = OverlayWindow()
        }
        overlayWindow?.showOverlay()
        print("AppDelegate: Overlay window shown for testing")
    }
    
    @objc private func hideOverlayPressed() {
        overlayWindow?.hideOverlay()
        print("AppDelegate: Overlay window hidden")
    }
    
    @objc private func clearDrawingPressed() {
        if let contentView = overlayWindow?.contentView as? OverlayContentView {
            contentView.clearDrawing()
            print("AppDelegate: Overlay drawing cleared")
        }
    }
    
    // MARK: - Zoom Functionality Setup
    
    private func setupZoomFunctionality() {
        // Initialize zoom window
        zoomWindow = ZoomWindow()
        
        // Set up zoom menu items
        setupZoomMenuItems()
        
        print("AppDelegate: Zoom functionality initialized")
    }
    
    private func setupZoomMenuItems() {
        guard let mainMenu = NSApplication.shared.mainMenu else { return }
        
        // Find or create the View menu
        var viewMenu: NSMenu?
        for menuItem in mainMenu.items {
            if menuItem.title == "View" {
                viewMenu = menuItem.submenu
                break
            }
        }
        
        if viewMenu == nil {
            let viewMenuItem = NSMenuItem()
            viewMenuItem.title = "View"
            mainMenu.addItem(viewMenuItem)
            
            viewMenu = NSMenu()
            viewMenuItem.submenu = viewMenu
        }
        
        guard let menu = viewMenu else { return }
        
        // Add zoom menu items
        if !menu.items.contains(where: { $0.title == "Show Zoom Window" }) {
            // Add separator if needed
            if !menu.items.isEmpty {
                menu.addItem(NSMenuItem.separator())
            }
            
            // Zoom window toggle
            let showZoomMenuItem = NSMenuItem(
                title: "Show Zoom Window",
                action: #selector(toggleZoomFromMenu),
                keyEquivalent: "z"
            )
            showZoomMenuItem.keyEquivalentModifierMask = [.command, .shift]
            showZoomMenuItem.target = self
            menu.addItem(showZoomMenuItem)
            
            // Zoom level controls
            let zoomInMenuItem = NSMenuItem(
                title: "Zoom In",
                action: #selector(zoomInFromMenu),
                keyEquivalent: "+"
            )
            zoomInMenuItem.keyEquivalentModifierMask = .command
            zoomInMenuItem.target = self
            menu.addItem(zoomInMenuItem)
            
            let zoomOutMenuItem = NSMenuItem(
                title: "Zoom Out",
                action: #selector(zoomOutFromMenu),
                keyEquivalent: "-"
            )
            zoomOutMenuItem.keyEquivalentModifierMask = .command
            zoomOutMenuItem.target = self
            menu.addItem(zoomOutMenuItem)
            
            let resetZoomMenuItem = NSMenuItem(
                title: "Reset Zoom",
                action: #selector(resetZoomFromMenu),
                keyEquivalent: "0"
            )
            resetZoomMenuItem.keyEquivalentModifierMask = .command
            resetZoomMenuItem.target = self
            menu.addItem(resetZoomMenuItem)
        }
        
        print("AppDelegate: Zoom menu items added")
    }
    
    // MARK: - Zoom Actions
    
    @objc private func showZoomPressed() {
        zoomWindow?.showZoomWindow()
        print("AppDelegate: Zoom window shown for testing")
    }
    
    @objc private func hideZoomPressed() {
        zoomWindow?.hideZoomWindow()
        print("AppDelegate: Zoom window hidden")
    }
    
    @objc private func toggleZoomFromMenu() {
        zoomWindow?.toggleZoomWindow()
        
        // Update menu item title
        if let mainMenu = NSApplication.shared.mainMenu,
           let viewMenu = mainMenu.items.first(where: { $0.title == "View" })?.submenu,
           let zoomMenuItem = viewMenu.items.first(where: { $0.action == #selector(toggleZoomFromMenu) }) {
            
            if zoomWindow?.isVisible == true {
                zoomMenuItem.title = "Hide Zoom Window"
            } else {
                zoomMenuItem.title = "Show Zoom Window"
            }
        }
    }
    
    @objc private func zoomInFromMenu() {
        zoomManager.zoomIn()
        print("AppDelegate: Zoom in via menu")
    }
    
    @objc private func zoomOutFromMenu() {
        zoomManager.zoomOut()
        print("AppDelegate: Zoom out via menu")
    }
    
    @objc private func resetZoomFromMenu() {
        zoomManager.resetZoom()
        print("AppDelegate: Reset zoom via menu")
    }
    
    // MARK: - Preferences Setup
    
    private func setupPreferences() {
        // Set up preferences menu item
        PreferencesWindowController.setupPreferencesMenuItem()
        
        // Set up keyboard shortcuts
        PreferencesWindowController.setupKeyboardShortcuts()
        
        print("AppDelegate: Preferences system initialized")
    }
    
    // MARK: - Global Hotkeys
    
    private func setupGlobalHotkeys() {
        // Existing hotkeys
        hotkeyManager.registerHotkey(key: .m, modifiers: [.command, .shift]) { [weak self] in
            self?.toggleOverlay()
        }
        
        hotkeyManager.registerHotkey(key: .z, modifiers: [.command, .shift]) { [weak self] in
            self?.toggleZoom()
        }
        
        hotkeyManager.registerHotkey(key: .t, modifiers: [.command, .shift]) { [weak self] in
            self?.showTimerControls()
        }
        
        hotkeyManager.registerHotkey(key: .r, modifiers: [.command, .shift]) { [weak self] in
            self?.showRecordingControls()
        }
        
        // Timer-specific hotkeys
        hotkeyManager.registerHotkey(key: .p, modifiers: [.command, .shift, .option]) { [weak self] in
            self?.pauseResumeTimer()
        }
        
        hotkeyManager.registerHotkey(key: .s, modifiers: [.command, .shift, .option]) { [weak self] in
            self?.stopTimer()
        }
        
        hotkeyManager.registerHotkey(key: .o, modifiers: [.command, .shift]) { [weak self] in
            self?.toggleTimerOverlay()
        }
        
        print("AppDelegate: Global hotkeys registered including timer controls")
    }
    
    private func toggleOverlay() {
        if overlayWindow == nil {
            overlayWindow = OverlayWindow()
        }
        
        overlayWindow?.toggleOverlay()
        
        let status = overlayWindow?.isOverlayVisible == true ? "shown" : "hidden"
        print("AppDelegate: Overlay \(status) via global hotkey")
    }
    
    private func toggleZoom() {
        if zoomWindow == nil {
            zoomWindow = ZoomWindow()
        }
        
        zoomWindow?.toggleZoomWindow()
        
        let status = zoomWindow?.isVisible == true ? "shown" : "hidden"
        print("AppDelegate: Zoom window \(status) via global hotkey")
    }
    
    private func showHotkeyRegistrationAlert() {
        let alert = NSAlert()
        alert.messageText = "Global Hotkey Registration Failed"
        alert.informativeText = "Unable to register the global hotkey (⌘⇧M) for overlay toggle. You can still use the buttons in the app to control the overlay."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func testHotkeyPressed() {
        let overlayRegistered = hotkeyManager.isHotkeyRegistered(identifier: "overlay_toggle")
        let zoomRegistered = hotkeyManager.isHotkeyRegistered(identifier: "zoom_toggle")
        let registeredHotkeys = hotkeyManager.getRegisteredHotkeys()
        
        let alert = NSAlert()
        alert.messageText = "Global Hotkey Status"
        
        var statusMessage = ""
        
        if overlayRegistered && zoomRegistered {
            statusMessage = """
            ✅ All global hotkeys are registered successfully!
            
            Overlay Toggle: ⌘⇧M (Cmd+Shift+M)
            Zoom Toggle: ⌘⇧Z (Cmd+Shift+Z)
            
            Try pressing these hotkeys anywhere in the system.
            """
            alert.alertStyle = .informational
        } else {
            statusMessage = """
            ⚠️ Some global hotkeys failed to register:
            
            Overlay Toggle (⌘⇧M): \(overlayRegistered ? "✅ Registered" : "❌ Failed")
            Zoom Toggle (⌘⇧Z): \(zoomRegistered ? "✅ Registered" : "❌ Failed")
            
            This could be due to:
            • System security restrictions
            • Another app using the same hotkey
            • Insufficient permissions
            
            You can still use the buttons and menu items in this app.
            """
            alert.alertStyle = .warning
        }
        
        statusMessage += "\n\nRegistered hotkeys: \(registeredHotkeys.joined(separator: ", "))"
        alert.informativeText = statusMessage
        
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func showPreferencesPressed() {
        PreferencesWindowController.shared.showPreferences()
    }
    
    // MARK: - Drawing Tools Setup
    
    private func setupDrawingTools() {
        // Drawing tool manager is already initialized as a singleton
        // Load preferences and setup notifications
        print("AppDelegate: Drawing tools initialized")
    }
    
    @objc func setupMenuBar() {
        let mainMenu = NSMenu()
        
        // App Menu
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = createAppMenu()
        mainMenu.addItem(appMenuItem)
        
        // File Menu
        let fileMenuItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        fileMenuItem.submenu = createFileMenu()
        mainMenu.addItem(fileMenuItem)
        
        // Tools Menu
        let toolsMenuItem = NSMenuItem(title: "Tools", action: nil, keyEquivalent: "")
        toolsMenuItem.submenu = createToolsMenu()
        mainMenu.addItem(toolsMenuItem)
        
        // Timer Menu
        let timerMenuItem = NSMenuItem(title: "Timer", action: nil, keyEquivalent: "")
        timerMenuItem.submenu = createTimerMenu()
        mainMenu.addItem(timerMenuItem)
        
        // View Menu
        let viewMenuItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        viewMenuItem.submenu = createViewMenu()
        mainMenu.addItem(viewMenuItem)
        
        // Recording Menu
        let recordingMenuItem = NSMenuItem(title: "Recording", action: nil, keyEquivalent: "")
        recordingMenuItem.submenu = createRecordingMenu()
        mainMenu.addItem(recordingMenuItem)
        
        NSApp.mainMenu = mainMenu
        print("AppDelegate: Menu bar setup completed with Timer menu")
    }
    
    private func createTimerMenu() -> NSMenu {
        let menu = NSMenu(title: "Timer")
        
        // Timer Controls
        menu.addItem(NSMenuItem(title: "Show Timer Controls", action: #selector(showTimerControls), keyEquivalent: "t"))
        menu.addItem(NSMenuItem.separator())
        
        // Quick Start Timers
        let quickStartItem = NSMenuItem(title: "Quick Start", action: nil, keyEquivalent: "")
        let quickStartMenu = NSMenu(title: "Quick Start")
        
        // Add quick timer options
        let quickTimers: [(String, TimeInterval, String)] = [
            ("5 Minutes", 5 * 60, "5"),
            ("15 Minutes", 15 * 60, ""),
            ("25 Minutes (Pomodoro)", 25 * 60, ""),
            ("45 Minutes", 45 * 60, ""),
            ("1 Hour", 60 * 60, "")
        ]
        
        for (title, duration, keyEquivalent) in quickTimers {
            let item = NSMenuItem(title: title, action: #selector(startQuickTimer(_:)), keyEquivalent: keyEquivalent)
            item.representedObject = duration
            quickStartMenu.addItem(item)
        }
        
        quickStartItem.submenu = quickStartMenu
        menu.addItem(quickStartItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Timer Actions
        let pauseResumeItem = NSMenuItem(title: "Pause/Resume Timer", action: #selector(pauseResumeTimer), keyEquivalent: "p")
        pauseResumeItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(pauseResumeItem)
        
        let stopTimerItem = NSMenuItem(title: "Stop Timer", action: #selector(stopTimer), keyEquivalent: "")
        menu.addItem(stopTimerItem)
        
        let addTimeItem = NSMenuItem(title: "Add 5 Minutes", action: #selector(addTimerTime), keyEquivalent: "")
        menu.addItem(addTimeItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Timer Display
        let showOverlayItem = NSMenuItem(title: "Show Timer Overlay", action: #selector(toggleTimerOverlay), keyEquivalent: "")
        menu.addItem(showOverlayItem)
        
        let timerHistoryItem = NSMenuItem(title: "Timer History", action: #selector(showTimerHistory), keyEquivalent: "")
        menu.addItem(timerHistoryItem)
        
        return menu
    }
    
    @objc private func toggleToolPalettePressed() {
        if overlayWindow == nil {
            overlayWindow = OverlayWindow()
        }
        overlayWindow?.toggleToolPalette()
        print("AppDelegate: Tool palette toggled")
    }
    
    @objc private func testDrawingPressed() {
        // Show overlay window if not visible
        if overlayWindow == nil {
            overlayWindow = OverlayWindow()
        }
        
        if !(overlayWindow?.isOverlayVisible ?? false) {
            overlayWindow?.showOverlay()
        }
        
        // Show tool palette
        drawingToolManager.showToolPalette()
        
        print("AppDelegate: Drawing test started - overlay and tool palette shown")
    }
    
    @objc private func toolButtonPressed(_ sender: NSButton) {
        let tools = Array(DrawingToolManager.DrawingTool.allCases)
        if sender.tag < tools.count {
            drawingToolManager.selectTool(tools[sender.tag])
            print("AppDelegate: Tool selected: \(tools[sender.tag].displayName)")
        }
    }
    
    @objc private func selectToolFromMenu(_ sender: NSMenuItem) {
        let tools = Array(DrawingToolManager.DrawingTool.allCases)
        if sender.tag < tools.count {
            drawingToolManager.selectTool(tools[sender.tag])
            print("AppDelegate: Tool selected from menu: \(tools[sender.tag].displayName)")
        }
    }
    
    @objc private func clearAllDrawingsFromMenu() {
        drawingToolManager.clearAllDrawings()
        overlayWindow?.contentView?.needsDisplay = true
        print("AppDelegate: All drawings cleared from menu")
    }
    
    // MARK: - Timer Integration
    
    private func setupTimerIntegration() {
        // Observe timer state changes for menu updates
        timerManager.$isTimerActive
            .sink { [weak self] isActive in
                DispatchQueue.main.async {
                    self?.updateTimerMenuItems()
                    if !isActive {
                        self?.timerOverlayWindow?.hideOverlay()
                    }
                }
            }
            .store(in: &cancellables)
        
        print("AppDelegate: Timer integration setup completed")
    }
    
    private func updateTimerMenuItems() {
        // Update menu item states based on timer status
        guard let timerMenu = NSApp.mainMenu?.item(withTitle: "Timer")?.submenu else { return }
        
        // Update pause/resume item text
        if let pauseResumeItem = timerMenu.item(withTitle: "Pause/Resume Timer") {
            if timerManager.isTimerActive {
                pauseResumeItem.title = timerManager.isPaused ? "Resume Timer" : "Pause Timer"
                pauseResumeItem.isEnabled = true
            } else {
                pauseResumeItem.title = "Pause/Resume Timer"
                pauseResumeItem.isEnabled = false
            }
        }
        
        // Update stop timer item
        if let stopItem = timerMenu.item(withTitle: "Stop Timer") {
            stopItem.isEnabled = timerManager.isTimerActive
        }
        
        // Update add time item
        if let addTimeItem = timerMenu.item(withTitle: "Add 5 Minutes") {
            addTimeItem.isEnabled = timerManager.isTimerActive
        }
        
        // Update overlay item
        if let overlayItem = timerMenu.item(withTitle: "Show Timer Overlay") {
            if timerManager.isTimerActive {
                overlayItem.title = timerOverlayWindow?.isVisible == true ? "Hide Timer Overlay" : "Show Timer Overlay"
            } else {
                overlayItem.title = "Show Timer Overlay"
                overlayItem.isEnabled = false
            }
        }
    }
    
    // MARK: - Timer Action Methods
    
    @objc func showTimerControls() {
        if timerControlsWindow == nil {
            timerControlsPanel = TimerControlsPanel()
            
            let hostingView = NSHostingView(rootView: timerControlsPanel!)
            timerControlsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            timerControlsWindow?.contentView = hostingView
            timerControlsWindow?.title = "Timer Controls"
            timerControlsWindow?.center()
            timerControlsWindow?.setFrameAutosaveName("TimerControlsWindow")
        }
        
        timerControlsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        print("AppDelegate: Timer controls window shown")
    }
    
    @objc func startQuickTimer(_ sender: NSMenuItem) {
        guard let duration = sender.representedObject as? TimeInterval else { return }
        
        timerManager.startTimer(
            duration: duration,
            mode: .countdown,
            type: .presentation
        )
        
        print("AppDelegate: Quick timer started for \(duration) seconds")
    }
    
    @objc func pauseResumeTimer() {
        if timerManager.isPaused {
            timerManager.resumeTimer()
            print("AppDelegate: Timer resumed")
        } else if timerManager.isTimerActive {
            timerManager.pauseTimer()
            print("AppDelegate: Timer paused")
        }
    }
    
    @objc func stopTimer() {
        timerManager.stopTimer()
        print("AppDelegate: Timer stopped")
    }
    
    @objc func addTimerTime() {
        timerManager.addTime(5 * 60) // Add 5 minutes
        print("AppDelegate: Added 5 minutes to timer")
    }
    
    @objc func toggleTimerOverlay() {
        guard let overlayWindow = timerOverlayWindow else { return }
        
        if timerManager.isTimerActive {
            overlayWindow.toggleOverlay()
            print("AppDelegate: Timer overlay toggled")
        } else {
            // Show timer controls if no active timer
            showTimerControls()
        }
    }
    
    @objc func showTimerHistory() {
        // Show timer history as a sheet on timer controls window
        if timerControlsWindow == nil {
            showTimerControls()
        }
        
        // The history will be shown via the TimerControlsPanel interface
        print("AppDelegate: Timer history accessed")
    }
    
    @objc func initializeComponents() {
        print("AppDelegate: Initializing all components...")
        
        // Initialize managers
        initializeManagers()
        
        // Initialize UI components
        initializeWindows()
        
        // Setup hotkeys
        setupGlobalHotkeys()
        
        print("AppDelegate: All components initialized successfully")
    }
    
    private func initializeManagers() {
        // Screen capture manager
        screenCaptureManager = ScreenCaptureManager()
        
        // Recording manager
        recordingManager = ScreenRecordingManager()
        
        // Timer system is already initialized as shared instance
        setupTimerIntegration()
        
        print("AppDelegate: Managers initialized")
    }
    
    private func initializeWindows() {
        // Overlay window
        overlayWindow = OverlayWindow()
        
        // Zoom window
        zoomWindow = ZoomWindow()
        
        // Preferences window controller
        preferencesWindowController = PreferencesWindowController()
        
        // Timer overlay window
        timerOverlayWindow = TimerOverlayWindow()
        
        print("AppDelegate: Windows initialized")
    }
    
    @objc private func toggleToolPaletteFromMenu() {
        toggleToolPalettePressed()
    }
} 