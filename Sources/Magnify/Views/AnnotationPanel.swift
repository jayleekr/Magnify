import SwiftUI
import UniformTypeIdentifiers

/// AnnotationPanel provides a comprehensive SwiftUI interface for annotation management
/// Includes document management, layer controls, export options, and settings
struct AnnotationPanel: View {
    
    // MARK: - State Management
    
    @StateObject private var annotationManager = AnnotationManager.shared
    @StateObject private var layerManager = LayerManager.shared
    @StateObject private var exportManager = ExportManager.shared
    @StateObject private var preferencesManager = PreferencesManager.shared
    
    @State private var selectedTab: PanelTab = .documents
    @State private var searchText: String = ""
    @State private var showingNewDocumentDialog = false
    @State private var showingExportPanel = false
    @State private var showingDeleteConfirmation = false
    @State private var showingRenameDialog = false
    @State private var showingImportDialog = false
    @State private var newDocumentName = ""
    @State private var layerToRename: AnnotationLayer?
    @State private var newLayerName = ""
    @State private var documentToDelete: AnnotationDocument?
    @State private var selectedExportFormat: ExportFormat = .png
    @State private var exportQuality: Double = 0.8
    @State private var exportResolution: ExportResolution = .resolution2x
    @State private var exportTransparent = true
    
    // MARK: - Panel Tabs
    
    enum PanelTab: String, CaseIterable {
        case documents = "Documents"
        case layers = "Layers"
        case export = "Export"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .documents: return "doc.text"
            case .layers: return "square.stack.3d.up"
            case .export: return "square.and.arrow.up"
            case .settings: return "gear"
            }
        }
    }
    
    // MARK: - Main View
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            tabBar
            
            // Content Area
            contentArea
                .frame(minWidth: 320, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Tab Bar
    
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(PanelTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    HStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14, weight: .medium))
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .white : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedTab == tab ? Color.accentColor : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                if tab != PanelTab.allCases.last {
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlColor))
    }
    
    // MARK: - Content Area
    
    private var contentArea: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                switch selectedTab {
                case .documents:
                    documentsContent
                case .layers:
                    layersContent
                case .export:
                    exportContent
                case .settings:
                    settingsContent
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Documents Tab
    
    private var documentsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with actions
            HStack {
                Text("Documents")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("Import") {
                        showingImportDialog = true
                    }
                    .foregroundColor(.secondary)
                    
                    Button("New") {
                        showingNewDocumentDialog = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            // Current Document Section
            if let currentDocument = annotationManager.currentDocument {
                GroupBox("Current Document") {
                    VStack(alignment: .leading, spacing: 12) {
                        documentCard(currentDocument, isCurrent: true)
                        
                        HStack {
                            Button("Save") {
                                _ = annotationManager.saveCurrentDocument()
                            }
                            .disabled(!annotationManager.isDocumentDirty)
                            
                            Button("Save As...") {
                                // TODO: Implement save as dialog
                            }
                            
                            Spacer()
                            
                            if annotationManager.isDocumentDirty {
                                Text("Unsaved changes")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search documents...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: searchText) { query in
                        if query.isEmpty {
                            annotationManager.searchResults = []
                        } else {
                            annotationManager.searchDocuments(query: query)
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Recent Documents Section
            let documentsToShow = searchText.isEmpty ? annotationManager.recentDocuments : annotationManager.searchResults
            
            if !documentsToShow.isEmpty {
                GroupBox(searchText.isEmpty ? "Recent Documents" : "Search Results") {
                    LazyVStack(spacing: 8) {
                        ForEach(documentsToShow, id: \.id) { document in
                            documentCard(document, isCurrent: false)
                        }
                    }
                }
            } else if !searchText.isEmpty {
                Text("No documents found")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
            
            // Statistics
            documentStatistics
        }
        .sheet(isPresented: $showingNewDocumentDialog) {
            newDocumentDialog
        }
        .sheet(isPresented: $showingImportDialog) {
            importDocumentDialog
        }
        .alert("Delete Document", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let document = documentToDelete {
                    _ = annotationManager.deleteDocument(document)
                }
                documentToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete '\(documentToDelete?.name ?? "")'? This action cannot be undone.")
        }
    }
    
    private func documentCard(_ document: AnnotationDocument, isCurrent: Bool) -> some View {
        HStack(spacing: 12) {
            // Document Icon
            RoundedRectangle(cornerRadius: 6)
                .fill(isCurrent ? Color.accentColor : Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: isCurrent ? "doc.text.fill" : "doc.text")
                        .foregroundColor(isCurrent ? .white : .primary)
                        .font(.system(size: 16, weight: .medium))
                )
            
            // Document Info
            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(document.lastModified.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if document.layers.count > 0 {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(document.layers.count) layers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !document.tags.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(document.tags.prefix(2).joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Actions
            if !isCurrent {
                Menu {
                    Button("Open") {
                        Task {
                            if let url = document.fileURL {
                                _ = await annotationManager.openDocument(at: url)
                            }
                        }
                    }
                    
                    Button("Duplicate") {
                        _ = annotationManager.duplicateDocument(document)
                    }
                    
                    Divider()
                    
                    Button("Delete", role: .destructive) {
                        documentToDelete = document
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrent ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
    
    private var documentStatistics: some View {
        GroupBox("Statistics") {
            VStack(alignment: .leading, spacing: 8) {
                statisticRow("Total Documents", value: "\(annotationManager.recentDocuments.count)")
                statisticRow("Current Layers", value: "\(layerManager.availableLayers.count)")
                statisticRow("Drawing Elements", value: "\(DrawingToolManager.shared.allElements.count)")
            }
        }
    }
    
    // MARK: - Layers Tab
    
    private var layersContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with layer controls
            HStack {
                Text("Layers")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Layer Filter
                    Picker("Filter", selection: $layerManager.layerFilter) {
                        ForEach(LayerManager.LayerFilter.allCases, id: \.self) { filter in
                            Text(filter.displayName).tag(filter)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 120)
                    
                    Button("New Layer") {
                        _ = layerManager.createLayer()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            // Layer Management Tools
            HStack {
                Button("Show Panel") {
                    layerManager.isLayerPanelVisible.toggle()
                }
                .foregroundColor(.accentColor)
                
                Spacer()
                
                // Layer statistics
                Text("\(layerManager.availableLayers.count) layers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Current Layer Info
            if let currentLayer = layerManager.currentLayer {
                GroupBox("Current Layer") {
                    VStack(spacing: 12) {
                        layerRow(currentLayer, isCurrent: true)
                        
                        // Layer Controls
                        VStack(spacing: 8) {
                            HStack {
                                Text("Opacity")
                                    .font(.caption)
                                Spacer()
                                Text("\(Int(currentLayer.opacity * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: Binding(
                                get: { currentLayer.opacity },
                                set: { newValue in
                                    layerManager.setLayerOpacity(currentLayer, opacity: newValue)
                                }
                            ), in: 0...1)
                            .tint(.accentColor)
                        }
                    }
                }
            }
            
            // All Layers List
            if !layerManager.filteredLayers.isEmpty {
                GroupBox("All Layers") {
                    LazyVStack(spacing: 6) {
                        ForEach(layerManager.filteredLayers, id: \.id) { layer in
                            layerRow(layer, isCurrent: layer.id == layerManager.currentLayer?.id)
                        }
                    }
                }
            }
            
            // Layer Statistics
            layerStatistics
        }
        .alert("Rename Layer", isPresented: $showingRenameDialog) {
            TextField("Layer name", text: $newLayerName)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                if let layer = layerToRename {
                    layerManager.renameLayer(layer, to: newLayerName)
                }
                layerToRename = nil
                newLayerName = ""
            }
        } message: {
            Text("Enter a new name for the layer")
        }
    }
    
    private func layerRow(_ layer: AnnotationLayer, isCurrent: Bool) -> some View {
        HStack(spacing: 12) {
            // Visibility Toggle
            Button(action: {
                layerManager.toggleLayerVisibility(layer)
            }) {
                Image(systemName: layer.isVisible ? "eye" : "eye.slash")
                    .foregroundColor(layer.isVisible ? .accentColor : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Layer Icon
            RoundedRectangle(cornerRadius: 4)
                .fill(isCurrent ? Color.accentColor : Color.gray.opacity(0.3))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "square.stack")
                        .foregroundColor(isCurrent ? .white : .primary)
                        .font(.system(size: 12, weight: .medium))
                )
            
            // Layer Info
            VStack(alignment: .leading, spacing: 2) {
                Text(layer.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text("\(layer.elements.count) elements")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if layer.opacity < 1.0 {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(Int(layer.opacity * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Actions
            Menu {
                Button("Select") {
                    layerManager.currentLayer = layer
                }
                
                Button("Rename") {
                    layerToRename = layer
                    newLayerName = layer.name
                    showingRenameDialog = true
                }
                
                Button("Duplicate") {
                    _ = layerManager.duplicateLayer(layer)
                }
                
                Divider()
                
                Button("Delete", role: .destructive) {
                    _ = layerManager.deleteLayer(layer)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isCurrent ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isCurrent ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private var layerStatistics: some View {
        GroupBox("Layer Statistics") {
            VStack(alignment: .leading, spacing: 8) {
                statisticRow("Total Layers", value: "\(layerManager.availableLayers.count)")
                statisticRow("Visible Layers", value: "\(layerManager.visibleLayers.count)")
                statisticRow("Hidden Layers", value: "\(layerManager.availableLayers.count - layerManager.visibleLayers.count)")
                statisticRow("Selected Layers", value: "\(layerManager.selectedLayers.count)")
            }
        }
    }
    
    // MARK: - Export Tab
    
    private var exportContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Export")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Export Now") {
                    performExport()
                }
                .buttonStyle(.borderedProminent)
                .disabled(annotationManager.currentDocument == nil)
            }
            
            // Export Format Selection
            GroupBox("Format") {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Export Format", selection: $selectedExportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            HStack {
                                Text(format.displayName)
                                Spacer()
                                Text(format.fileExtension.uppercased())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(format)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    if selectedExportFormat.description != nil {
                        Text(selectedExportFormat.description!)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Export Settings
            GroupBox("Settings") {
                VStack(alignment: .leading, spacing: 16) {
                    // Resolution
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Resolution")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("Resolution", selection: $exportResolution) {
                            ForEach(ExportResolution.allCases, id: \.self) { resolution in
                                Text(resolution.displayName).tag(resolution)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Quality (for lossy formats)
                    if selectedExportFormat.supportsQuality {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Quality")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(Int(exportQuality * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: $exportQuality, in: 0.1...1.0)
                                .tint(.accentColor)
                        }
                    }
                    
                    // Transparency
                    if selectedExportFormat.supportsTransparency {
                        Toggle("Transparent Background", isOn: $exportTransparent)
                    }
                }
            }
            
            // Export Progress
            if exportManager.isExporting {
                GroupBox("Export Progress") {
                    VStack(spacing: 8) {
                        ProgressView(value: exportManager.exportProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Text(exportManager.exportStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Recent Exports
            if !exportManager.recentExports.isEmpty {
                GroupBox("Recent Exports") {
                    LazyVStack(spacing: 6) {
                        ForEach(exportManager.recentExports.prefix(5), id: \.timestamp) { export in
                            HStack {
                                Image(systemName: export.format.systemIcon)
                                    .foregroundColor(.accentColor)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(export.filename)
                                        .font(.system(size: 12, weight: .medium))
                                        .lineLimit(1)
                                    
                                    Text(export.timestamp.formatted(.dateTime.hour().minute()))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Show") {
                                    NSWorkspace.shared.selectFile(export.url.path, inFileViewerRootedAtPath: export.url.deletingLastPathComponent().path)
                                }
                                .buttonStyle(.borderless)
                                .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Settings Tab
    
    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Annotation Settings
            GroupBox("Annotation") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Auto-save documents", isOn: $preferencesManager.autoSaveEnabled)
                    Toggle("Show layer panel by default", isOn: $layerManager.isLayerPanelVisible)
                    Toggle("Remember window positions", isOn: $preferencesManager.rememberWindowPositions)
                }
            }
            
            // Export Settings
            GroupBox("Export Defaults") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Default format:")
                        Spacer()
                        Picker("", selection: $selectedExportFormat) {
                            ForEach(ExportFormat.allCases, id: \.self) { format in
                                Text(format.displayName).tag(format)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Default resolution:")
                        Spacer()
                        Picker("", selection: $exportResolution) {
                            ForEach(ExportResolution.allCases, id: \.self) { resolution in
                                Text(resolution.displayName).tag(resolution)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 100)
                    }
                }
            }
            
            // Performance Settings
            GroupBox("Performance") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Hardware acceleration", isOn: $preferencesManager.hardwareAcceleration)
                    Toggle("Optimize for large documents", isOn: $preferencesManager.optimizeForLargeDocuments)
                    
                    HStack {
                        Text("Max undo history:")
                        Spacer()
                        Stepper("\(preferencesManager.maxUndoHistory)", value: $preferencesManager.maxUndoHistory, in: 10...200, step: 10)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helper Views
    
    private func statisticRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Dialog Views
    
    private var newDocumentDialog: some View {
        VStack(spacing: 20) {
            Text("New Document")
                .font(.headline)
            
            TextField("Document name", text: $newDocumentName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack {
                Button("Cancel") {
                    showingNewDocumentDialog = false
                    newDocumentName = ""
                }
                
                Spacer()
                
                Button("Create") {
                    let name = newDocumentName.isEmpty ? nil : newDocumentName
                    _ = annotationManager.createNewDocument(name: name)
                    showingNewDocumentDialog = false
                    newDocumentName = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(newDocumentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
    
    private var importDocumentDialog: some View {
        VStack(spacing: 20) {
            Text("Import Document")
                .font(.headline)
            
            Text("Select a file to import:")
                .foregroundColor(.secondary)
            
            HStack {
                Button("Cancel") {
                    showingImportDialog = false
                }
                
                Spacer()
                
                Button("Browse...") {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [.png, .pdf, .jpeg]
                    panel.allowsMultipleSelection = false
                    
                    if panel.runModal() == .OK, let url = panel.url {
                        Task {
                            _ = await annotationManager.importDocument(from: url)
                        }
                    }
                    showingImportDialog = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300)
    }
    
    // MARK: - Actions
    
    private func performExport() {
        guard let document = annotationManager.currentDocument else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [selectedExportFormat.utType]
        panel.nameFieldStringValue = "\(document.name).\(selectedExportFormat.fileExtension)"
        
        if panel.runModal() == .OK, let url = panel.url {
            let settings = ExportSettings(
                format: selectedExportFormat,
                resolution: exportResolution,
                quality: exportQuality,
                includeTransparency: exportTransparent,
                layerOptions: .allLayers
            )
            
            Task {
                await exportManager.exportDocument(document, to: url, settings: settings)
            }
        }
    }
}

// MARK: - Extensions

extension ExportFormat {
    var displayName: String {
        switch self {
        case .png: return "PNG Image"
        case .pdf: return "PDF Document"
        case .svg: return "SVG Vector"
        case .jpeg: return "JPEG Image"
        }
    }
    
    var description: String? {
        switch self {
        case .png: return "Best for detailed images with transparency"
        case .pdf: return "Best for documents and vector graphics"
        case .svg: return "Scalable vector format for web and print"
        case .jpeg: return "Compressed format for photos and web"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .png: return "photo"
        case .pdf: return "doc.richtext"
        case .svg: return "globe"
        case .jpeg: return "camera"
        }
    }
    
    var supportsQuality: Bool {
        switch self {
        case .jpeg: return true
        case .png, .pdf, .svg: return false
        }
    }
    
    var supportsTransparency: Bool {
        switch self {
        case .png, .svg: return true
        case .pdf, .jpeg: return false
        }
    }
    
    var utType: UTType {
        switch self {
        case .png: return .png
        case .pdf: return .pdf
        case .svg: return UTType(filenameExtension: "svg") ?? .data
        case .jpeg: return .jpeg
        }
    }
    
    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .pdf: return "pdf"
        case .svg: return "svg"
        case .jpeg: return "jpg"
        }
    }
}

extension ExportResolution {
    var displayName: String {
        switch self {
        case .resolution1x: return "1x"
        case .resolution2x: return "2x (Retina)"
        case .resolution3x: return "3x"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Preview

struct AnnotationPanel_Previews: PreviewProvider {
    static var previews: some View {
        AnnotationPanel()
            .frame(width: 400, height: 600)
    }
} 