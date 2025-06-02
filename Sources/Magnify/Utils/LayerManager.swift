import Foundation
import AppKit
import SwiftUI

/// LayerManager provides comprehensive layer management for annotation documents
/// Handles layer creation, organization, visibility, and operations
class LayerManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = LayerManager()
    
    // MARK: - Published Properties
    
    @Published var currentLayer: AnnotationLayer?
    @Published var availableLayers: [AnnotationLayer] = []
    @Published var layerHistory: [LayerOperation] = []
    @Published var isLayerPanelVisible: Bool = false
    @Published var selectedLayers: Set<UUID> = []
    @Published var layerFilter: LayerFilter = .all
    
    // MARK: - Layer Operations
    
    enum LayerOperation {
        case created(AnnotationLayer)
        case deleted(AnnotationLayer)
        case renamed(AnnotationLayer, from: String, to: String)
        case visibilityChanged(AnnotationLayer, Bool)
        case opacityChanged(AnnotationLayer, Double)
        case reordered([AnnotationLayer])
        case duplicated(AnnotationLayer, copy: AnnotationLayer)
        case merged([AnnotationLayer], into: AnnotationLayer)
        
        var description: String {
            switch self {
            case .created(let layer):
                return "Created layer '\(layer.name)'"
            case .deleted(let layer):
                return "Deleted layer '\(layer.name)'"
            case .renamed(let layer, let from, let to):
                return "Renamed layer from '\(from)' to '\(to)'"
            case .visibilityChanged(let layer, let visible):
                return "\(visible ? "Showed" : "Hid") layer '\(layer.name)'"
            case .opacityChanged(let layer, let opacity):
                return "Changed opacity of '\(layer.name)' to \(Int(opacity * 100))%"
            case .reordered:
                return "Reordered layers"
            case .duplicated(let layer, _):
                return "Duplicated layer '\(layer.name)'"
            case .merged(let layers, let target):
                return "Merged \(layers.count) layers into '\(target.name)'"
            }
        }
        
        var timestamp: Date {
            return Date()
        }
    }
    
    // MARK: - Layer Filtering
    
    enum LayerFilter: String, CaseIterable {
        case all = "all"
        case visible = "visible"
        case hidden = "hidden"
        case selected = "selected"
        case recent = "recent"
        
        var displayName: String {
            switch self {
            case .all: return "All Layers"
            case .visible: return "Visible Layers"
            case .hidden: return "Hidden Layers"
            case .selected: return "Selected Layers"
            case .recent: return "Recent Layers"
            }
        }
    }
    
    // MARK: - Constants
    
    private let maxHistoryEntries = 100
    private let defaultLayerName = "New Layer"
    
    // MARK: - References
    
    private let annotationManager = AnnotationManager.shared
    private let drawingToolManager = DrawingToolManager.shared
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupNotifications()
        print("LayerManager: Initialized layer management system")
    }
    
    private func setupNotifications() {
        // Observe document changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(documentChanged),
            name: .documentChanged,
            object: nil
        )
        
        // Observe layer changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(layerContentChanged),
            name: .layerContentChanged,
            object: nil
        )
    }
    
    @objc private func documentChanged() {
        updateLayersFromCurrentDocument()
    }
    
    @objc private func layerContentChanged() {
        syncCurrentLayerWithDrawingTools()
    }
    
    // MARK: - Layer Creation and Management
    
    /// Create a new layer
    func createLayer(name: String? = nil, atIndex index: Int? = nil) -> AnnotationLayer {
        let layerName = name ?? generateUniqueLayerName()
        let newLayer = AnnotationLayer(name: layerName)
        
        if let index = index, index >= 0, index <= availableLayers.count {
            availableLayers.insert(newLayer, at: index)
        } else {
            availableLayers.append(newLayer)
        }
        
        // Set as current layer
        currentLayer = newLayer
        
        // Add to document if available
        if let document = annotationManager.currentDocument {
            if let index = index {
                document.layers.insert(newLayer, at: index)
            } else {
                document.layers.append(newLayer)
            }
            annotationManager.markDocumentDirty()
        }
        
        // Record operation
        recordOperation(.created(newLayer))
        
        print("LayerManager: Created layer '\(layerName)'")
        return newLayer
    }
    
    /// Delete a layer
    func deleteLayer(_ layer: AnnotationLayer) -> Bool {
        guard let index = availableLayers.firstIndex(where: { $0.id == layer.id }) else {
            return false
        }
        
        // Don't delete if it's the only layer
        if availableLayers.count <= 1 {
            print("LayerManager: Cannot delete the only remaining layer")
            return false
        }
        
        // Remove from available layers
        availableLayers.remove(at: index)
        
        // Update current layer if needed
        if currentLayer?.id == layer.id {
            currentLayer = availableLayers.first
        }
        
        // Remove from document
        if let document = annotationManager.currentDocument {
            document.layers.removeAll { $0.id == layer.id }
            annotationManager.markDocumentDirty()
        }
        
        // Remove from selection
        selectedLayers.remove(layer.id)
        
        // Record operation
        recordOperation(.deleted(layer))
        
        print("LayerManager: Deleted layer '\(layer.name)'")
        return true
    }
    
    /// Duplicate a layer
    func duplicateLayer(_ layer: AnnotationLayer) -> AnnotationLayer {
        let duplicatedLayer = layer.copy()
        duplicatedLayer.name = generateUniqueLayerName(baseName: "\(layer.name) Copy")
        
        // Insert after the original layer
        if let index = availableLayers.firstIndex(where: { $0.id == layer.id }) {
            availableLayers.insert(duplicatedLayer, at: index + 1)
        } else {
            availableLayers.append(duplicatedLayer)
        }
        
        // Add to document
        if let document = annotationManager.currentDocument {
            if let index = document.layers.firstIndex(where: { $0.id == layer.id }) {
                document.layers.insert(duplicatedLayer, at: index + 1)
            } else {
                document.layers.append(duplicatedLayer)
            }
            annotationManager.markDocumentDirty()
        }
        
        // Record operation
        recordOperation(.duplicated(layer, copy: duplicatedLayer))
        
        print("LayerManager: Duplicated layer '\(layer.name)'")
        return duplicatedLayer
    }
    
    /// Rename a layer
    func renameLayer(_ layer: AnnotationLayer, to newName: String) {
        let oldName = layer.name
        layer.name = newName
        
        // Update document
        annotationManager.markDocumentDirty()
        
        // Record operation
        recordOperation(.renamed(layer, from: oldName, to: newName))
        
        print("LayerManager: Renamed layer from '\(oldName)' to '\(newName)'")
    }
    
    // MARK: - Layer Properties
    
    /// Toggle layer visibility
    func toggleLayerVisibility(_ layer: AnnotationLayer) {
        setLayerVisibility(layer, !layer.isVisible)
    }
    
    /// Set layer visibility
    func setLayerVisibility(_ layer: AnnotationLayer, _ visible: Bool) {
        layer.isVisible = visible
        
        // Update document
        annotationManager.markDocumentDirty()
        
        // Record operation
        recordOperation(.visibilityChanged(layer, visible))
        
        print("LayerManager: \(visible ? "Showed" : "Hid") layer '\(layer.name)'")
    }
    
    /// Set layer opacity
    func setLayerOpacity(_ layer: AnnotationLayer, _ opacity: Double) {
        let clampedOpacity = max(0.0, min(1.0, opacity))
        layer.opacity = clampedOpacity
        
        // Update document
        annotationManager.markDocumentDirty()
        
        // Record operation
        recordOperation(.opacityChanged(layer, clampedOpacity))
        
        print("LayerManager: Set opacity of '\(layer.name)' to \(Int(clampedOpacity * 100))%")
    }
    
    // MARK: - Layer Organization
    
    /// Move layer to a new position
    func moveLayer(_ layer: AnnotationLayer, to newIndex: Int) {
        guard let currentIndex = availableLayers.firstIndex(where: { $0.id == layer.id }),
              newIndex >= 0,
              newIndex < availableLayers.count,
              currentIndex != newIndex else {
            return
        }
        
        // Update available layers
        availableLayers.remove(at: currentIndex)
        availableLayers.insert(layer, at: newIndex)
        
        // Update document layers
        if let document = annotationManager.currentDocument {
            if let docIndex = document.layers.firstIndex(where: { $0.id == layer.id }) {
                document.layers.remove(at: docIndex)
                document.layers.insert(layer, at: newIndex)
                annotationManager.markDocumentDirty()
            }
        }
        
        // Record operation
        recordOperation(.reordered(availableLayers))
        
        print("LayerManager: Moved layer '\(layer.name)' to position \(newIndex)")
    }
    
    /// Merge selected layers into target layer
    func mergeLayers(_ sourceLayers: [AnnotationLayer], into targetLayer: AnnotationLayer) -> Bool {
        guard !sourceLayers.isEmpty,
              sourceLayers.allSatisfy({ availableLayers.contains(where: { $0.id == $0.id }) }),
              availableLayers.contains(where: { $0.id == targetLayer.id }) else {
            return false
        }
        
        // Merge elements from source layers into target
        for sourceLayer in sourceLayers {
            if sourceLayer.id != targetLayer.id {
                targetLayer.elements.append(contentsOf: sourceLayer.elements)
            }
        }
        
        // Remove source layers (except target)
        for sourceLayer in sourceLayers {
            if sourceLayer.id != targetLayer.id {
                _ = deleteLayer(sourceLayer)
            }
        }
        
        // Update document
        annotationManager.markDocumentDirty()
        
        // Record operation
        recordOperation(.merged(sourceLayers, into: targetLayer))
        
        print("LayerManager: Merged \(sourceLayers.count) layers into '\(targetLayer.name)'")
        return true
    }
    
    // MARK: - Layer Selection
    
    /// Select a layer
    func selectLayer(_ layer: AnnotationLayer, exclusive: Bool = true) {
        if exclusive {
            selectedLayers.removeAll()
        }
        
        selectedLayers.insert(layer.id)
        currentLayer = layer
        
        print("LayerManager: Selected layer '\(layer.name)'")
    }
    
    /// Deselect a layer
    func deselectLayer(_ layer: AnnotationLayer) {
        selectedLayers.remove(layer.id)
        
        if currentLayer?.id == layer.id {
            currentLayer = selectedLayers.isEmpty ? availableLayers.first : 
                           availableLayers.first { selectedLayers.contains($0.id) }
        }
        
        print("LayerManager: Deselected layer '\(layer.name)'")
    }
    
    /// Select multiple layers
    func selectLayers(_ layers: [AnnotationLayer]) {
        selectedLayers.removeAll()
        selectedLayers.formUnion(layers.map { $0.id })
        
        if let firstLayer = layers.first {
            currentLayer = firstLayer
        }
        
        print("LayerManager: Selected \(layers.count) layers")
    }
    
    /// Clear layer selection
    func clearSelection() {
        selectedLayers.removeAll()
        print("LayerManager: Cleared layer selection")
    }
    
    // MARK: - Layer Filtering and Search
    
    /// Get filtered layers based on current filter
    func getFilteredLayers() -> [AnnotationLayer] {
        switch layerFilter {
        case .all:
            return availableLayers
        case .visible:
            return availableLayers.filter { $0.isVisible }
        case .hidden:
            return availableLayers.filter { !$0.isVisible }
        case .selected:
            return availableLayers.filter { selectedLayers.contains($0.id) }
        case .recent:
            return getRecentLayers()
        }
    }
    
    /// Search layers by name
    func searchLayers(query: String) -> [AnnotationLayer] {
        guard !query.isEmpty else { return availableLayers }
        
        return availableLayers.filter { layer in
            layer.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    /// Get recently modified layers
    private func getRecentLayers() -> [AnnotationLayer] {
        let recentCutoff = Date().addingTimeInterval(-24 * 60 * 60) // Last 24 hours
        
        return availableLayers
            .filter { $0.created >= recentCutoff }
            .sorted { $0.created > $1.created }
    }
    
    // MARK: - Layer Templates and Presets
    
    /// Create layer from template
    func createLayerFromTemplate(_ template: LayerTemplate) -> AnnotationLayer {
        let layer = createLayer(name: template.name)
        layer.opacity = template.opacity
        layer.isVisible = template.isVisible
        
        // Apply template-specific properties
        switch template {
        case .background:
            moveLayer(layer, to: availableLayers.count - 1) // Move to bottom
        case .foreground:
            moveLayer(layer, to: 0) // Move to top
        case .annotation:
            break // Keep in current position
        case .sketch:
            setLayerOpacity(layer, 0.7)
        case .highlight:
            setLayerOpacity(layer, 0.3)
        }
        
        print("LayerManager: Created layer from template: \(template.name)")
        return layer
    }
    
    // MARK: - Layer Export/Import
    
    /// Export layer as separate document
    func exportLayer(_ layer: AnnotationLayer, to url: URL) -> Bool {
        let exportDocument = AnnotationDocument(name: layer.name, layers: [layer])
        
        do {
            let data = try JSONEncoder().encode(exportDocument)
            try data.write(to: url)
            
            print("LayerManager: Exported layer '\(layer.name)' to \(url.lastPathComponent)")
            return true
        } catch {
            print("LayerManager: Failed to export layer: \(error)")
            return false
        }
    }
    
    /// Import layer from document
    func importLayer(from url: URL) -> AnnotationLayer? {
        do {
            let data = try Data(contentsOf: url)
            let document = try JSONDecoder().decode(AnnotationDocument.self, from: data)
            
            if let firstLayer = document.layers.first {
                let importedLayer = firstLayer.copy()
                importedLayer.name = generateUniqueLayerName(baseName: importedLayer.name)
                
                availableLayers.append(importedLayer)
                
                // Add to current document
                if let currentDocument = annotationManager.currentDocument {
                    currentDocument.layers.append(importedLayer)
                    annotationManager.markDocumentDirty()
                }
                
                recordOperation(.created(importedLayer))
                
                print("LayerManager: Imported layer '\(importedLayer.name)'")
                return importedLayer
            }
        } catch {
            print("LayerManager: Failed to import layer: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Document Integration
    
    /// Update layers from current document
    private func updateLayersFromCurrentDocument() {
        if let document = annotationManager.currentDocument {
            availableLayers = document.layers
            currentLayer = availableLayers.first
            selectedLayers.removeAll()
        } else {
            availableLayers.removeAll()
            currentLayer = nil
            selectedLayers.removeAll()
        }
        
        print("LayerManager: Updated layers from document (\(availableLayers.count) layers)")
    }
    
    /// Sync current layer with drawing tools
    private func syncCurrentLayerWithDrawingTools() {
        guard let layer = currentLayer else { return }
        
        let drawingManager = DrawingToolManager.shared
        let elements = drawingManager.allDrawingElements
        
        // Convert drawing elements to annotation elements
        layer.elements = elements.map { AnnotationElement(from: $0) }
        
        annotationManager.markDocumentDirty()
    }
    
    // MARK: - Layer Panel Management
    
    /// Show layer panel
    func showLayerPanel() {
        isLayerPanelVisible = true
        print("LayerManager: Layer panel shown")
    }
    
    /// Hide layer panel
    func hideLayerPanel() {
        isLayerPanelVisible = false
        print("LayerManager: Layer panel hidden")
    }
    
    /// Toggle layer panel visibility
    func toggleLayerPanel() {
        isLayerPanelVisible.toggle()
        print("LayerManager: Layer panel toggled to \(isLayerPanelVisible ? "visible" : "hidden")")
    }
    
    // MARK: - Helper Methods
    
    /// Generate unique layer name
    private func generateUniqueLayerName(baseName: String = "") -> String {
        let base = baseName.isEmpty ? defaultLayerName : baseName
        
        let existingNames = availableLayers.map { $0.name }
        
        if !existingNames.contains(base) {
            return base
        }
        
        var counter = 1
        var uniqueName = "\(base) \(counter)"
        
        while existingNames.contains(uniqueName) {
            counter += 1
            uniqueName = "\(base) \(counter)"
        }
        
        return uniqueName
    }
    
    /// Record layer operation in history
    private func recordOperation(_ operation: LayerOperation) {
        layerHistory.append(operation)
        
        // Maintain history size limit
        if layerHistory.count > maxHistoryEntries {
            layerHistory.removeFirst()
        }
    }
    
    /// Get layer by ID
    func getLayer(by id: UUID) -> AnnotationLayer? {
        return availableLayers.first { $0.id == id }
    }
    
    /// Get layer statistics
    func getLayerStatistics() -> LayerStatistics {
        let visibleCount = availableLayers.filter { $0.isVisible }.count
        let hiddenCount = availableLayers.count - visibleCount
        let totalElements = availableLayers.reduce(0) { $0 + $1.elements.count }
        
        return LayerStatistics(
            totalLayers: availableLayers.count,
            visibleLayers: visibleCount,
            hiddenLayers: hiddenCount,
            selectedLayers: selectedLayers.count,
            totalElements: totalElements
        )
    }
}

// MARK: - Supporting Types

/// Layer template for creating predefined layer types
enum LayerTemplate {
    case background
    case foreground
    case annotation
    case sketch
    case highlight
    
    var name: String {
        switch self {
        case .background: return "Background Layer"
        case .foreground: return "Foreground Layer"
        case .annotation: return "Annotation Layer"
        case .sketch: return "Sketch Layer"
        case .highlight: return "Highlight Layer"
        }
    }
    
    var opacity: Double {
        switch self {
        case .background: return 0.5
        case .foreground: return 1.0
        case .annotation: return 1.0
        case .sketch: return 0.7
        case .highlight: return 0.3
        }
    }
    
    var isVisible: Bool {
        return true
    }
}

/// Layer statistics for reporting
struct LayerStatistics {
    let totalLayers: Int
    let visibleLayers: Int
    let hiddenLayers: Int
    let selectedLayers: Int
    let totalElements: Int
}

// MARK: - Notifications

extension Notification.Name {
    static let documentChanged = Notification.Name("documentChanged")
    static let layerContentChanged = Notification.Name("layerContentChanged")
    static let layerSelectionChanged = Notification.Name("layerSelectionChanged")
} 