import Foundation
import AppKit
import CoreData
import UniformTypeIdentifiers

/// AnnotationManager provides comprehensive annotation persistence and file management
/// Handles saving, loading, organizing, and searching annotation documents
class AnnotationManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AnnotationManager()
    
    // MARK: - Published Properties
    
    @Published var currentDocument: AnnotationDocument?
    @Published var recentDocuments: [AnnotationDocument] = []
    @Published var documentDirectories: [URL] = []
    @Published var isDocumentDirty: Bool = false
    @Published var searchResults: [AnnotationDocument] = []
    @Published var currentSearchQuery: String = ""
    
    // MARK: - Constants
    
    private let maxRecentDocuments = 10
    private let defaultDocumentExtension = "magnify"
    private let supportedImportFormats = ["pdf", "png", "jpg", "jpeg", "svg"]
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AnnotationModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("AnnotationManager: Core Data error: \(error)")
            }
        }
        return container
    }()
    
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    private let preferencesManager = PreferencesManager.shared
    private var documentsDirectory: URL
    private var bookmarkData: [URL: Data] = [:]
    
    // MARK: - Initialization
    
    private override init() {
        // Set up documents directory
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Magnify Annotations", isDirectory: true)
        
        super.init()
        setupDocumentsDirectory()
        loadRecentDocuments()
        setupNotifications()
    }
    
    private func setupDocumentsDirectory() {
        do {
            try fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
            print("AnnotationManager: Documents directory ready at \(documentsDirectory.path)")
        } catch {
            print("AnnotationManager: Failed to create documents directory: \(error)")
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
        
        // Observe drawing tool changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(drawingToolsChanged),
            name: .drawingToolsChanged,
            object: nil
        )
    }
    
    @objc private func applicationWillTerminate() {
        saveCurrentDocument()
        saveRecentDocuments()
    }
    
    @objc private func drawingToolsChanged() {
        markDocumentDirty()
    }
    
    // MARK: - Document Creation and Management
    
    /// Create a new annotation document
    func createNewDocument(name: String? = nil) -> AnnotationDocument {
        let documentName = name ?? "Untitled Annotation \(Date().formatted(.dateTime.year().month().day().hour().minute()))"
        let document = AnnotationDocument(name: documentName)
        
        currentDocument = document
        markDocumentDirty()
        
        print("AnnotationManager: Created new document: \(documentName)")
        return document
    }
    
    /// Open an existing annotation document
    func openDocument(at url: URL) async -> Result<AnnotationDocument, AnnotationError> {
        do {
            let data = try Data(contentsOf: url)
            let document = try JSONDecoder().decode(AnnotationDocument.self, from: data)
            
            currentDocument = document
            addToRecentDocuments(document)
            isDocumentDirty = false
            
            print("AnnotationManager: Opened document: \(document.name)")
            return .success(document)
        } catch {
            print("AnnotationManager: Failed to open document: \(error)")
            return .failure(.fileReadError(error))
        }
    }
    
    /// Save the current document
    func saveCurrentDocument() -> Bool {
        guard let document = currentDocument else { return false }
        return saveDocument(document)
    }
    
    /// Save a specific document
    func saveDocument(_ document: AnnotationDocument) -> Bool {
        do {
            let data = try JSONEncoder().encode(document)
            let url = documentsDirectory.appendingPathComponent("\(document.name).\(defaultDocumentExtension)")
            
            try data.write(to: url)
            document.fileURL = url
            document.lastModified = Date()
            
            isDocumentDirty = false
            addToRecentDocuments(document)
            
            print("AnnotationManager: Saved document: \(document.name)")
            return true
        } catch {
            print("AnnotationManager: Failed to save document: \(error)")
            return false
        }
    }
    
    /// Save document with a new name (Save As...)
    func saveDocumentAs(_ document: AnnotationDocument, name: String) -> Bool {
        let originalName = document.name
        document.name = name
        
        if saveDocument(document) {
            print("AnnotationManager: Saved document as: \(name)")
            return true
        } else {
            document.name = originalName
            return false
        }
    }
    
    // MARK: - Document Organization
    
    /// List all documents in the documents directory
    func listDocuments() -> [AnnotationDocument] {
        do {
            let urls = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
            
            let documents = urls.compactMap { url -> AnnotationDocument? in
                guard url.pathExtension == defaultDocumentExtension else { return nil }
                
                do {
                    let data = try Data(contentsOf: url)
                    var document = try JSONDecoder().decode(AnnotationDocument.self, from: data)
                    document.fileURL = url
                    return document
                } catch {
                    print("AnnotationManager: Failed to load document at \(url): \(error)")
                    return nil
                }
            }
            
            return documents.sorted { $0.lastModified > $1.lastModified }
        } catch {
            print("AnnotationManager: Failed to list documents: \(error)")
            return []
        }
    }
    
    /// Delete a document
    func deleteDocument(_ document: AnnotationDocument) -> Bool {
        guard let url = document.fileURL else { return false }
        
        do {
            try fileManager.removeItem(at: url)
            removeFromRecentDocuments(document)
            
            if currentDocument?.id == document.id {
                currentDocument = nil
            }
            
            print("AnnotationManager: Deleted document: \(document.name)")
            return true
        } catch {
            print("AnnotationManager: Failed to delete document: \(error)")
            return false
        }
    }
    
    /// Duplicate a document
    func duplicateDocument(_ document: AnnotationDocument) -> AnnotationDocument? {
        let duplicateName = "\(document.name) Copy"
        let duplicate = AnnotationDocument(
            name: duplicateName,
            layers: document.layers.map { $0.copy() }
        )
        
        if saveDocument(duplicate) {
            print("AnnotationManager: Duplicated document: \(duplicateName)")
            return duplicate
        }
        
        return nil
    }
    
    // MARK: - Search and Filtering
    
    /// Search documents by name and content
    func searchDocuments(query: String) -> [AnnotationDocument] {
        guard !query.isEmpty else { return [] }
        
        currentSearchQuery = query
        let allDocuments = listDocuments()
        
        let results = allDocuments.filter { document in
            // Search in document name
            if document.name.localizedCaseInsensitiveContains(query) {
                return true
            }
            
            // Search in text annotations
            for layer in document.layers {
                for element in layer.elements {
                    if let text = element.text,
                       text.localizedCaseInsensitiveContains(query) {
                        return true
                    }
                }
            }
            
            // Search in tags
            for tag in document.tags {
                if tag.localizedCaseInsensitiveContains(query) {
                    return true
                }
            }
            
            return false
        }
        
        searchResults = results
        print("AnnotationManager: Found \(results.count) documents for query: \(query)")
        return results
    }
    
    /// Filter documents by date range
    func filterDocuments(from startDate: Date, to endDate: Date) -> [AnnotationDocument] {
        return listDocuments().filter { document in
            document.created >= startDate && document.created <= endDate
        }
    }
    
    /// Filter documents by tags
    func filterDocuments(byTags tags: [String]) -> [AnnotationDocument] {
        return listDocuments().filter { document in
            !Set(document.tags).isDisjoint(with: Set(tags))
        }
    }
    
    // MARK: - Recent Documents Management
    
    private func addToRecentDocuments(_ document: AnnotationDocument) {
        // Remove if already exists
        recentDocuments.removeAll { $0.id == document.id }
        
        // Add to beginning
        recentDocuments.insert(document, at: 0)
        
        // Maintain max count
        if recentDocuments.count > maxRecentDocuments {
            recentDocuments = Array(recentDocuments.prefix(maxRecentDocuments))
        }
        
        saveRecentDocuments()
    }
    
    private func removeFromRecentDocuments(_ document: AnnotationDocument) {
        recentDocuments.removeAll { $0.id == document.id }
        saveRecentDocuments()
    }
    
    private func loadRecentDocuments() {
        if let data = UserDefaults.standard.data(forKey: "recentAnnotationDocuments"),
           let documents = try? JSONDecoder().decode([AnnotationDocument].self, from: data) {
            recentDocuments = documents
        }
    }
    
    private func saveRecentDocuments() {
        if let data = try? JSONEncoder().encode(recentDocuments) {
            UserDefaults.standard.set(data, forKey: "recentAnnotationDocuments")
        }
    }
    
    // MARK: - Document State Management
    
    func markDocumentDirty() {
        isDocumentDirty = true
        currentDocument?.lastModified = Date()
    }
    
    func clearDocumentDirty() {
        isDocumentDirty = false
    }
    
    // MARK: - Integration with Drawing Tools
    
    /// Sync current drawing elements with the document
    func syncWithDrawingTools() {
        guard let document = currentDocument else { return }
        
        let drawingManager = DrawingToolManager.shared
        let elements = drawingManager.allDrawingElements
        
        // Update current layer with drawing elements
        if let currentLayer = document.layers.first {
            currentLayer.elements = elements.map { AnnotationElement(from: $0) }
            markDocumentDirty()
        }
    }
    
    /// Load document elements into drawing tools
    func loadIntoDrawingTools() {
        guard let document = currentDocument else { return }
        
        let drawingManager = DrawingToolManager.shared
        drawingManager.clearAllDrawings()
        
        // Load elements from current layer
        if let currentLayer = document.layers.first {
            for element in currentLayer.elements {
                // Convert AnnotationElement back to DrawingElement
                // This would require enhancing DrawingToolManager to accept external elements
            }
        }
    }
    
    // MARK: - File System Access
    
    /// Request access to a directory for saving documents
    func requestDirectoryAccess() -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.title = "Choose Directory for Annotations"
        
        if openPanel.runModal() == .OK {
            if let url = openPanel.url {
                // Store security-scoped bookmark
                do {
                    let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                    self.bookmarkData[url] = bookmarkData
                    documentDirectories.append(url)
                    return url
                } catch {
                    print("AnnotationManager: Failed to create bookmark: \(error)")
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Error Handling
    
    enum AnnotationError: LocalizedError {
        case fileReadError(Error)
        case fileWriteError(Error)
        case documentNotFound
        case invalidFormat
        case permissionDenied
        
        var errorDescription: String? {
            switch self {
            case .fileReadError(let error):
                return "Failed to read file: \(error.localizedDescription)"
            case .fileWriteError(let error):
                return "Failed to write file: \(error.localizedDescription)"
            case .documentNotFound:
                return "Document not found"
            case .invalidFormat:
                return "Invalid file format"
            case .permissionDenied:
                return "Permission denied"
            }
        }
    }
}

// MARK: - Extensions

extension Notification.Name {
    static let drawingToolsChanged = Notification.Name("drawingToolsChanged")
}

// MARK: - AnnotationDocument Model

/// Represents a complete annotation document with metadata and layers
class AnnotationDocument: ObservableObject, Codable, Identifiable {
    
    let id = UUID()
    var name: String
    var created: Date
    var lastModified: Date
    var fileURL: URL?
    var layers: [AnnotationLayer]
    var tags: [String]
    var metadata: [String: String]
    
    init(name: String, layers: [AnnotationLayer] = []) {
        self.name = name
        self.created = Date()
        self.lastModified = Date()
        self.layers = layers.isEmpty ? [AnnotationLayer(name: "Main Layer")] : layers
        self.tags = []
        self.metadata = [:]
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, created, lastModified, layers, tags, metadata
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        created = try container.decode(Date.self, forKey: .created)
        lastModified = try container.decode(Date.self, forKey: .lastModified)
        layers = try container.decode([AnnotationLayer].self, forKey: .layers)
        tags = try container.decode([String].self, forKey: .tags)
        metadata = try container.decode([String: String].self, forKey: .metadata)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(created, forKey: .created)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encode(layers, forKey: .layers)
        try container.encode(tags, forKey: .tags)
        try container.encode(metadata, forKey: .metadata)
    }
}

// MARK: - AnnotationLayer Model

/// Represents a layer within an annotation document
class AnnotationLayer: ObservableObject, Codable, Identifiable {
    
    let id = UUID()
    var name: String
    var isVisible: Bool
    var opacity: Double
    var elements: [AnnotationElement]
    var created: Date
    
    init(name: String) {
        self.name = name
        self.isVisible = true
        self.opacity = 1.0
        self.elements = []
        self.created = Date()
    }
    
    func copy() -> AnnotationLayer {
        let copy = AnnotationLayer(name: "\(name) Copy")
        copy.isVisible = isVisible
        copy.opacity = opacity
        copy.elements = elements.map { $0.copy() }
        return copy
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, isVisible, opacity, elements, created
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        isVisible = try container.decode(Bool.self, forKey: .isVisible)
        opacity = try container.decode(Double.self, forKey: .opacity)
        elements = try container.decode([AnnotationElement].self, forKey: .elements)
        created = try container.decode(Date.self, forKey: .created)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isVisible, forKey: .isVisible)
        try container.encode(opacity, forKey: .opacity)
        try container.encode(elements, forKey: .elements)
        try container.encode(created, forKey: .created)
    }
}

// MARK: - AnnotationElement Model

/// Represents a single annotation element (drawing, text, etc.)
struct AnnotationElement: Codable, Identifiable {
    
    let id = UUID()
    let tool: String
    let pathData: Data
    let color: String // Hex color string
    let strokeWidth: Double
    let fillColor: String?
    let text: String?
    let font: String?
    let fontSize: Double?
    let textColor: String?
    let textPosition: CGPoint?
    let created: Date
    
    init(from drawingElement: DrawingToolManager.DrawingElement) {
        self.tool = drawingElement.tool.rawValue
        self.pathData = NSKeyedArchiver.archivedData(withRootObject: drawingElement.path)
        self.color = drawingElement.color.hexString
        self.strokeWidth = Double(drawingElement.strokeWidth)
        self.fillColor = drawingElement.fillColor?.hexString
        self.text = drawingElement.text
        self.font = drawingElement.font?.fontName
        self.fontSize = drawingElement.font?.pointSize
        self.textColor = drawingElement.textColor?.hexString
        self.textPosition = drawingElement.textPosition
        self.created = drawingElement.timestamp
    }
    
    func copy() -> AnnotationElement {
        return AnnotationElement(
            tool: tool,
            pathData: pathData,
            color: color,
            strokeWidth: strokeWidth,
            fillColor: fillColor,
            text: text,
            font: font,
            fontSize: fontSize,
            textColor: textColor,
            textPosition: textPosition,
            created: created
        )
    }
    
    private init(tool: String, pathData: Data, color: String, strokeWidth: Double,
                fillColor: String?, text: String?, font: String?, fontSize: Double?,
                textColor: String?, textPosition: CGPoint?, created: Date) {
        self.tool = tool
        self.pathData = pathData
        self.color = color
        self.strokeWidth = strokeWidth
        self.fillColor = fillColor
        self.text = text
        self.font = font
        self.fontSize = fontSize
        self.textColor = textColor
        self.textPosition = textPosition
        self.created = created
    }
}

// MARK: - NSColor Extensions

extension NSColor {
    /// Convert NSColor to hex string
    var hexString: String {
        guard let rgbColor = usingColorSpace(.deviceRGB) else { return "#000000" }
        
        let red = Int(round(rgbColor.redComponent * 255))
        let green = Int(round(rgbColor.greenComponent * 255))
        let blue = Int(round(rgbColor.blueComponent * 255))
        
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
    
    /// Create NSColor from hex string
    convenience init?(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
    }
} 