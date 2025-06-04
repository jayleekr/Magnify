import Foundation
import AppKit
import Combine

/// AnnotationTemplateManager manages pre-built annotation templates for common presentation scenarios
/// Provides templates for educational, business, design, and general presentation needs
class AnnotationTemplateManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AnnotationTemplateManager()
    
    // MARK: - Properties
    
    @Published var availableTemplates: [AnnotationTemplate] = []
    @Published var recentlyUsedTemplates: [AnnotationTemplate] = []
    @Published var favoriteTemplates: [AnnotationTemplate] = []
    
    private let preferencesManager = PreferencesManager.shared
    private let annotationManager = AnnotationManager.shared
    private let layerManager = LayerManager.shared
    
    // MARK: - Template Categories
    
    enum TemplateCategory: String, CaseIterable {
        case educational = "Educational"
        case business = "Business"
        case design = "Design"
        case software = "Software"
        case general = "General"
        case custom = "Custom"
        
        var systemImage: String {
            switch self {
            case .educational: return "graduationcap"
            case .business: return "briefcase"
            case .design: return "paintbrush"
            case .software: return "hammer"
            case .general: return "star"
            case .custom: return "folder"
            }
        }
        
        var description: String {
            switch self {
            case .educational: return "Templates for lectures and education"
            case .business: return "Templates for presentations and meetings"
            case .design: return "Templates for design reviews and critiques"
            case .software: return "Templates for code reviews and demos"
            case .general: return "General-purpose annotation templates"
            case .custom: return "User-created custom templates"
            }
        }
    }
    
    // MARK: - Template Definition
    
    struct AnnotationTemplate: Identifiable, Codable {
        let id = UUID()
        let name: String
        let description: String
        let category: TemplateCategory
        let preview: String // Base64 encoded preview image
        let elements: [TemplateElement]
        let metadata: TemplateMetadata
        var isFavorite: Bool = false
        var useCount: Int = 0
        var lastUsed: Date?
        
        struct TemplateElement: Codable {
            let type: ElementType
            let position: CGPoint
            let size: CGSize
            let properties: [String: Any]
            
            enum ElementType: String, Codable {
                case arrow = "arrow"
                case highlight = "highlight"
                case text = "text"
                case shape = "shape"
                case callout = "callout"
                case stamp = "stamp"
            }
            
            private enum CodingKeys: CodingKey {
                case type, position, size, properties
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                type = try container.decode(ElementType.self, forKey: .type)
                position = try container.decode(CGPoint.self, forKey: .position)
                size = try container.decode(CGSize.self, forKey: .size)
                
                let propertiesData = try container.decode(Data.self, forKey: .properties)
                properties = try JSONSerialization.jsonObject(with: propertiesData) as? [String: Any] ?? [:]
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(type, forKey: .type)
                try container.encode(position, forKey: .position)
                try container.encode(size, forKey: .size)
                
                let propertiesData = try JSONSerialization.data(withJSONObject: properties)
                try container.encode(propertiesData, forKey: .properties)
            }
        }
        
        struct TemplateMetadata: Codable {
            let version: String
            let author: String
            let createdDate: Date
            let tags: [String]
            let targetAudience: String
            let usageInstructions: String
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        loadBuiltInTemplates()
        loadCustomTemplates()
        loadUserPreferences()
        
        print("AnnotationTemplateManager: Initialized with \(availableTemplates.count) templates")
    }
    
    // MARK: - Template Management
    
    func getTemplates(for category: TemplateCategory) -> [AnnotationTemplate] {
        return availableTemplates.filter { $0.category == category }
    }
    
    func searchTemplates(query: String) -> [AnnotationTemplate] {
        let lowercaseQuery = query.lowercased()
        return availableTemplates.filter { template in
            template.name.lowercased().contains(lowercaseQuery) ||
            template.description.lowercased().contains(lowercaseQuery) ||
            template.metadata.tags.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }
    
    func applyTemplate(_ template: AnnotationTemplate, to layer: AnnotationLayer? = nil) {
        let targetLayer = layer ?? layerManager.currentLayer ?? layerManager.createLayer(name: "Template: \(template.name)")
        
        // Create annotation elements from template
        for element in template.elements {
            let annotation = createAnnotationFromElement(element)
            targetLayer.addAnnotation(annotation)
        }
        
        // Update usage statistics
        updateTemplateUsage(template)
        
        print("AnnotationTemplateManager: Applied template '\(template.name)' with \(template.elements.count) elements")
    }
    
    func saveAsCustomTemplate(name: String, description: String, layer: AnnotationLayer) -> AnnotationTemplate? {
        guard !layer.annotations.isEmpty else {
            print("AnnotationTemplateManager: Cannot create template from empty layer")
            return nil
        }
        
        let elements = layer.annotations.compactMap { annotation in
            createTemplateElementFromAnnotation(annotation)
        }
        
        let metadata = AnnotationTemplate.TemplateMetadata(
            version: "1.0",
            author: NSFullUserName(),
            createdDate: Date(),
            tags: ["custom", "user-created"],
            targetAudience: "General",
            usageInstructions: "User-created template from layer '\(layer.name)'"
        )
        
        let template = AnnotationTemplate(
            name: name,
            description: description,
            category: .custom,
            preview: generatePreviewImage(for: layer),
            elements: elements,
            metadata: metadata
        )
        
        availableTemplates.append(template)
        saveCustomTemplates()
        
        print("AnnotationTemplateManager: Created custom template '\(name)' with \(elements.count) elements")
        return template
    }
    
    func deleteTemplate(_ template: AnnotationTemplate) {
        guard template.category == .custom else {
            print("AnnotationTemplateManager: Cannot delete built-in template")
            return
        }
        
        availableTemplates.removeAll { $0.id == template.id }
        recentlyUsedTemplates.removeAll { $0.id == template.id }
        favoriteTemplates.removeAll { $0.id == template.id }
        
        saveCustomTemplates()
        saveUserPreferences()
        
        print("AnnotationTemplateManager: Deleted custom template '\(template.name)'")
    }
    
    func toggleFavorite(_ template: AnnotationTemplate) {
        if let index = availableTemplates.firstIndex(where: { $0.id == template.id }) {
            availableTemplates[index].isFavorite.toggle()
            
            if availableTemplates[index].isFavorite {
                if !favoriteTemplates.contains(where: { $0.id == template.id }) {
                    favoriteTemplates.append(availableTemplates[index])
                }
            } else {
                favoriteTemplates.removeAll { $0.id == template.id }
            }
            
            saveUserPreferences()
        }
    }
    
    // MARK: - Built-in Templates
    
    private func loadBuiltInTemplates() {
        // Educational Templates
        availableTemplates.append(createArrowPointerTemplate())
        availableTemplates.append(createStepByStepTemplate())
        availableTemplates.append(createHighlightBoxTemplate())
        availableTemplates.append(createComparisonTemplate())
        
        // Business Templates
        availableTemplates.append(createActionItemTemplate())
        availableTemplates.append(createDecisionPointTemplate())
        availableTemplates.append(createProcessFlowTemplate())
        
        // Design Templates
        availableTemplates.append(createMarkupTemplate())
        availableTemplates.append(createMeasurementTemplate())
        availableTemplates.append(createColorCalloutTemplate())
        
        // Software Templates
        availableTemplates.append(createBugReportTemplate())
        availableTemplates.append(createCodeReviewTemplate())
        availableTemplates.append(createFeatureHighlightTemplate())
        
        print("AnnotationTemplateManager: Loaded \(availableTemplates.count) built-in templates")
    }
    
    // Educational Template Creators
    private func createArrowPointerTemplate() -> AnnotationTemplate {
        let elements = [
            AnnotationTemplate.TemplateElement(
                type: .arrow,
                position: CGPoint(x: 100, y: 100),
                size: CGSize(width: 80, height: 20),
                properties: [
                    "color": NSColor.systemRed.toHex(),
                    "strokeWidth": 3.0,
                    "arrowStyle": "curved"
                ]
            ),
            AnnotationTemplate.TemplateElement(
                type: .text,
                position: CGPoint(x: 180, y: 90),
                size: CGSize(width: 150, height: 40),
                properties: [
                    "text": "Important Point",
                    "font": "Helvetica-Bold",
                    "fontSize": 16.0,
                    "color": NSColor.systemRed.toHex()
                ]
            )
        ]
        
        let metadata = AnnotationTemplate.TemplateMetadata(
            version: "1.0",
            author: "Magnify",
            createdDate: Date(),
            tags: ["arrow", "pointer", "education", "highlight"],
            targetAudience: "Educators, Presenters",
            usageInstructions: "Use to point out specific elements and add explanatory text"
        )
        
        return AnnotationTemplate(
            name: "Arrow Pointer",
            description: "Curved arrow with explanatory text for highlighting important points",
            category: .educational,
            preview: "",
            elements: elements,
            metadata: metadata
        )
    }
    
    private func createStepByStepTemplate() -> AnnotationTemplate {
        let elements = [
            AnnotationTemplate.TemplateElement(
                type: .shape,
                position: CGPoint(x: 50, y: 50),
                size: CGSize(width: 30, height: 30),
                properties: [
                    "shape": "circle",
                    "fillColor": NSColor.systemBlue.toHex(),
                    "strokeColor": NSColor.white.toHex(),
                    "strokeWidth": 2.0
                ]
            ),
            AnnotationTemplate.TemplateElement(
                type: .text,
                position: CGPoint(x: 60, y: 60),
                size: CGSize(width: 20, height: 20),
                properties: [
                    "text": "1",
                    "font": "Helvetica-Bold",
                    "fontSize": 14.0,
                    "color": NSColor.white.toHex(),
                    "alignment": "center"
                ]
            ),
            AnnotationTemplate.TemplateElement(
                type: .text,
                position: CGPoint(x: 90, y: 55),
                size: CGSize(width: 200, height: 30),
                properties: [
                    "text": "Step description",
                    "font": "Helvetica",
                    "fontSize": 14.0,
                    "color": NSColor.labelColor.toHex()
                ]
            )
        ]
        
        let metadata = AnnotationTemplate.TemplateMetadata(
            version: "1.0",
            author: "Magnify",
            createdDate: Date(),
            tags: ["steps", "tutorial", "education", "sequence"],
            targetAudience: "Tutorial creators, Educators",
            usageInstructions: "Use for step-by-step instructions and tutorials"
        )
        
        return AnnotationTemplate(
            name: "Step-by-Step",
            description: "Numbered circles with descriptions for sequential instructions",
            category: .educational,
            preview: "",
            elements: elements,
            metadata: metadata
        )
    }
    
    private func createHighlightBoxTemplate() -> AnnotationTemplate {
        let elements = [
            AnnotationTemplate.TemplateElement(
                type: .highlight,
                position: CGPoint(x: 50, y: 50),
                size: CGSize(width: 200, height: 100),
                properties: [
                    "color": NSColor.systemYellow.toHex(),
                    "opacity": 0.3,
                    "borderColor": NSColor.systemOrange.toHex(),
                    "borderWidth": 2.0
                ]
            ),
            AnnotationTemplate.TemplateElement(
                type: .text,
                position: CGPoint(x: 60, y: 160),
                size: CGSize(width: 180, height: 30),
                properties: [
                    "text": "Key Information",
                    "font": "Helvetica-Bold",
                    "fontSize": 14.0,
                    "color": NSColor.systemOrange.toHex()
                ]
            )
        ]
        
        let metadata = AnnotationTemplate.TemplateMetadata(
            version: "1.0",
            author: "Magnify",
            createdDate: Date(),
            tags: ["highlight", "box", "emphasis", "attention"],
            targetAudience: "General users",
            usageInstructions: "Use to highlight important sections with explanatory text"
        )
        
        return AnnotationTemplate(
            name: "Highlight Box",
            description: "Semi-transparent highlight box with descriptive label",
            category: .educational,
            preview: "",
            elements: elements,
            metadata: metadata
        )
    }
    
    // Business Template Creators
    private func createActionItemTemplate() -> AnnotationTemplate {
        let elements = [
            AnnotationTemplate.TemplateElement(
                type: .stamp,
                position: CGPoint(x: 50, y: 50),
                size: CGSize(width: 25, height: 25),
                properties: [
                    "symbol": "exclamationmark.triangle.fill",
                    "color": NSColor.systemRed.toHex()
                ]
            ),
            AnnotationTemplate.TemplateElement(
                type: .text,
                position: CGPoint(x: 85, y: 45),
                size: CGSize(width: 150, height: 30),
                properties: [
                    "text": "ACTION REQUIRED",
                    "font": "Helvetica-Bold",
                    "fontSize": 12.0,
                    "color": NSColor.systemRed.toHex()
                ]
            )
        ]
        
        let metadata = AnnotationTemplate.TemplateMetadata(
            version: "1.0",
            author: "Magnify",
            createdDate: Date(),
            tags: ["action", "business", "urgent", "task"],
            targetAudience: "Business users, Project managers",
            usageInstructions: "Mark items that require immediate attention or action"
        )
        
        return AnnotationTemplate(
            name: "Action Item",
            description: "Warning symbol with action required text for urgent items",
            category: .business,
            preview: "",
            elements: elements,
            metadata: metadata
        )
    }
    
    // MARK: - Helper Methods
    
    private func createAnnotationFromElement(_ element: AnnotationTemplate.TemplateElement) -> Annotation {
        // Convert template element to actual annotation
        // This would integrate with the existing AnnotationManager
        let annotation = Annotation(
            id: UUID(),
            type: .shape, // Map from template element type
            content: element.properties,
            bounds: CGRect(origin: element.position, size: element.size),
            layer: layerManager.currentLayer?.id ?? UUID(),
            timestamp: Date()
        )
        return annotation
    }
    
    private func createTemplateElementFromAnnotation(_ annotation: Annotation) -> AnnotationTemplate.TemplateElement? {
        // Convert annotation back to template element
        return AnnotationTemplate.TemplateElement(
            type: .shape, // Map from annotation type
            position: annotation.bounds.origin,
            size: annotation.bounds.size,
            properties: annotation.content
        )
    }
    
    private func generatePreviewImage(for layer: AnnotationLayer) -> String {
        // Generate base64 encoded preview image
        // For now, return empty string - would implement actual preview generation
        return ""
    }
    
    private func updateTemplateUsage(_ template: AnnotationTemplate) {
        if let index = availableTemplates.firstIndex(where: { $0.id == template.id }) {
            availableTemplates[index].useCount += 1
            availableTemplates[index].lastUsed = Date()
            
            // Update recently used list
            recentlyUsedTemplates.removeAll { $0.id == template.id }
            recentlyUsedTemplates.insert(availableTemplates[index], at: 0)
            
            // Keep only recent 10 templates
            if recentlyUsedTemplates.count > 10 {
                recentlyUsedTemplates.removeLast()
            }
            
            saveUserPreferences()
        }
    }
    
    // MARK: - Persistence
    
    private func loadCustomTemplates() {
        // Load custom templates from file system
        // Implementation would read from user documents
    }
    
    private func saveCustomTemplates() {
        // Save custom templates to file system
        // Implementation would write to user documents
    }
    
    private func loadUserPreferences() {
        // Load user preferences for favorites and recent templates
        // Implementation would read from UserDefaults
    }
    
    private func saveUserPreferences() {
        // Save user preferences for favorites and recent templates
        // Implementation would write to UserDefaults
    }
}

// MARK: - Extensions

extension NSColor {
    func toHex() -> String {
        guard let rgbColor = self.usingColorSpace(.deviceRGB) else { return "#000000" }
        let red = Int(rgbColor.redComponent * 255)
        let green = Int(rgbColor.greenComponent * 255)
        let blue = Int(rgbColor.blueComponent * 255)
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
} 