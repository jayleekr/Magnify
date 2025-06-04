import Foundation
import AppKit
import Vision
import NaturalLanguage

/// AnnotationAutomationEngine provides intelligent automation features for annotations
/// Includes smart suggestions, workflow automation, and AI-powered assistance
class AnnotationAutomationEngine: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AnnotationAutomationEngine()
    
    // MARK: - Automation Features
    
    enum AutomationFeature: String, CaseIterable {
        case smartShapeDetection = "Smart Shape Detection"
        case textRecognition = "Text Recognition"
        case colorAnalysis = "Color Analysis"
        case layoutSuggestions = "Layout Suggestions"
        case contentAwarePlacement = "Content-Aware Placement"
        case sequenceGeneration = "Sequence Generation"
        case templateMatching = "Template Matching"
        case workflowAutomation = "Workflow Automation"
        
        var systemImage: String {
            switch self {
            case .smartShapeDetection: return "square.on.circle"
            case .textRecognition: return "textformat.abc"
            case .colorAnalysis: return "eyedropper"
            case .layoutSuggestions: return "rectangle.3.group"
            case .contentAwarePlacement: return "target"
            case .sequenceGeneration: return "arrow.right.arrow.left"
            case .templateMatching: return "doc.on.doc"
            case .workflowAutomation: return "gear.badge.checkmark"
            }
        }
        
        var description: String {
            switch self {
            case .smartShapeDetection: return "Automatically detect and enhance geometric shapes"
            case .textRecognition: return "Recognize and extract text from screen content"
            case .colorAnalysis: return "Analyze colors and suggest complementary schemes"
            case .layoutSuggestions: return "Suggest optimal annotation placement"
            case .contentAwarePlacement: return "Intelligently place annotations based on content"
            case .sequenceGeneration: return "Generate step-by-step annotation sequences"
            case .templateMatching: return "Match content to appropriate templates"
            case .workflowAutomation: return "Automate repetitive annotation workflows"
            }
        }
    }
    
    // MARK: - Suggestion Types
    
    struct AutomationSuggestion {
        let id = UUID()
        let type: SuggestionType
        let title: String
        let description: String
        let confidence: Float
        let action: () -> Void
        let preview: NSImage?
        
        enum SuggestionType {
            case template, placement, enhancement, workflow
        }
    }
    
    // MARK: - Properties
    
    @Published var isEnabled: Bool = true
    @Published var currentSuggestions: [AutomationSuggestion] = []
    @Published var enabledFeatures: Set<AutomationFeature> = Set(AutomationFeature.allCases)
    
    private let templateManager = AnnotationTemplateManager.shared
    private let drawingToolManager = DrawingToolManager.shared
    private let preferencesManager = PreferencesManager.shared
    
    // Vision framework components
    private lazy var textRecognitionRequest: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        return request
    }()
    
    private lazy var shapeDetectionRequest: VNDetectContoursRequest = {
        let request = VNDetectContoursRequest()
        request.contrastAdjustment = 1.0
        request.detectsDarkOnLight = true
        return request
    }()
    
    // MARK: - Initialization
    
    private init() {
        loadAutomationPreferences()
        setupVisionRequests()
        print("AnnotationAutomationEngine: Initialized with AI-powered features")
    }
    
    // MARK: - Smart Analysis
    
    func analyzeScreenContent(_ image: NSImage, completion: @escaping ([AutomationSuggestion]) -> Void) {
        guard isEnabled else {
            completion([])
            return
        }
        
        var suggestions: [AutomationSuggestion] = []
        
        // Convert NSImage to CIImage for Vision framework
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion([])
            return
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        
        // Perform parallel analysis
        let analysisGroup = DispatchGroup()
        
        // Text recognition analysis
        if enabledFeatures.contains(.textRecognition) {
            analysisGroup.enter()
            performTextAnalysis(ciImage) { textSuggestions in
                suggestions.append(contentsOf: textSuggestions)
                analysisGroup.leave()
            }
        }
        
        // Shape detection analysis
        if enabledFeatures.contains(.smartShapeDetection) {
            analysisGroup.enter()
            performShapeAnalysis(ciImage) { shapeSuggestions in
                suggestions.append(contentsOf: shapeSuggestions)
                analysisGroup.leave()
            }
        }
        
        // Color analysis
        if enabledFeatures.contains(.colorAnalysis) {
            analysisGroup.enter()
            performColorAnalysis(ciImage) { colorSuggestions in
                suggestions.append(contentsOf: colorSuggestions)
                analysisGroup.leave()
            }
        }
        
        // Layout analysis
        if enabledFeatures.contains(.layoutSuggestions) {
            analysisGroup.enter()
            performLayoutAnalysis(ciImage) { layoutSuggestions in
                suggestions.append(contentsOf: layoutSuggestions)
                analysisGroup.leave()
            }
        }
        
        analysisGroup.notify(queue: .main) {
            // Sort suggestions by confidence
            let sortedSuggestions = suggestions.sorted { $0.confidence > $1.confidence }
            completion(Array(sortedSuggestions.prefix(10))) // Return top 10 suggestions
        }
    }
    
    // MARK: - Text Recognition Analysis
    
    private func performTextAnalysis(_ image: CIImage, completion: @escaping ([AutomationSuggestion]) -> Void) {
        let handler = VNImageRequestHandler(ciImage: image)
        
        textRecognitionRequest.completionHandler = { [weak self] request, error in
            guard let self = self,
                  let results = request.results as? [VNRecognizedTextObservation],
                  error == nil else {
                completion([])
                return
            }
            
            var suggestions: [AutomationSuggestion] = []
            
            for observation in results {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                
                // Analyze text content for annotation opportunities
                let text = topCandidate.string
                let confidence = topCandidate.confidence
                
                // Suggest highlighting important terms
                if self.isImportantText(text) {
                    let suggestion = AutomationSuggestion(
                        type: .enhancement,
                        title: "Highlight Key Term",
                        description: "Consider highlighting '\(text)' as it appears to be important",
                        confidence: confidence,
                        action: {
                            self.createHighlightForText(text, observation: observation)
                        },
                        preview: self.generateTextHighlightPreview(text)
                    )
                    suggestions.append(suggestion)
                }
                
                // Suggest callouts for technical terms
                if self.isTechnicalTerm(text) {
                    let suggestion = AutomationSuggestion(
                        type: .enhancement,
                        title: "Add Technical Callout",
                        description: "Add explanation callout for technical term '\(text)'",
                        confidence: confidence * 0.8,
                        action: {
                            self.createCalloutForText(text, observation: observation)
                        },
                        preview: self.generateCalloutPreview(text)
                    )
                    suggestions.append(suggestion)
                }
            }
            
            completion(suggestions)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([self.textRecognitionRequest])
        }
    }
    
    // MARK: - Shape Detection Analysis
    
    private func performShapeAnalysis(_ image: CIImage, completion: @escaping ([AutomationSuggestion]) -> Void) {
        let handler = VNImageRequestHandler(ciImage: image)
        
        shapeDetectionRequest.completionHandler = { [weak self] request, error in
            guard let self = self,
                  let results = request.results as? [VNContoursObservation],
                  error == nil else {
                completion([])
                return
            }
            
            var suggestions: [AutomationSuggestion] = []
            
            for observation in results {
                let contourCount = observation.contourCount
                
                // Analyze contours for shape enhancement opportunities
                if contourCount > 0 {
                    // Suggest shape enhancement
                    let suggestion = AutomationSuggestion(
                        type: .enhancement,
                        title: "Enhance Detected Shape",
                        description: "Perfect and highlight detected geometric shapes",
                        confidence: 0.8,
                        action: {
                            self.enhanceDetectedShapes(observation)
                        },
                        preview: self.generateShapeEnhancementPreview()
                    )
                    suggestions.append(suggestion)
                }
            }
            
            completion(suggestions)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([self.shapeDetectionRequest])
        }
    }
    
    // MARK: - Color Analysis
    
    private func performColorAnalysis(_ image: CIImage, completion: @escaping ([AutomationSuggestion]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Analyze dominant colors in the image
            let dominantColors = self.extractDominantColors(from: image)
            
            var suggestions: [AutomationSuggestion] = []
            
            // Suggest complementary color schemes
            for color in dominantColors.prefix(3) {
                let complementaryColors = self.generateComplementaryColors(for: color)
                
                let suggestion = AutomationSuggestion(
                    type: .enhancement,
                    title: "Use Complementary Colors",
                    description: "Apply complementary color scheme based on image content",
                    confidence: 0.7,
                    action: {
                        self.applyColorScheme(complementaryColors)
                    },
                    preview: self.generateColorSchemePreview(complementaryColors)
                )
                suggestions.append(suggestion)
            }
            
            DispatchQueue.main.async {
                completion(suggestions)
            }
        }
    }
    
    // MARK: - Layout Analysis
    
    private func performLayoutAnalysis(_ image: CIImage, completion: @escaping ([AutomationSuggestion]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Analyze image composition and layout
            let layoutInfo = self.analyzeImageLayout(image)
            
            var suggestions: [AutomationSuggestion] = []
            
            // Suggest optimal annotation placement
            if let optimalRegions = layoutInfo.emptyRegions {
                for region in optimalRegions.prefix(3) {
                    let suggestion = AutomationSuggestion(
                        type: .placement,
                        title: "Optimal Annotation Placement",
                        description: "Place annotations in areas with minimal visual interference",
                        confidence: 0.8,
                        action: {
                            self.suggestAnnotationPlacement(in: region)
                        },
                        preview: self.generatePlacementPreview(region)
                    )
                    suggestions.append(suggestion)
                }
            }
            
            // Suggest template matching
            if let matchedTemplate = self.findMatchingTemplate(for: layoutInfo) {
                let suggestion = AutomationSuggestion(
                    type: .template,
                    title: "Apply Matching Template",
                    description: "Use '\(matchedTemplate.name)' template for this content type",
                    confidence: 0.9,
                    action: {
                        self.templateManager.applyTemplate(matchedTemplate)
                    },
                    preview: self.generateTemplatePreview(matchedTemplate)
                )
                suggestions.append(suggestion)
            }
            
            DispatchQueue.main.async {
                completion(suggestions)
            }
        }
    }
    
    // MARK: - Smart Assistance Methods
    
    private func isImportantText(_ text: String) -> Bool {
        let importantPatterns = [
            "error", "warning", "important", "note", "critical",
            "step", "process", "result", "conclusion", "summary"
        ]
        
        let lowercaseText = text.lowercased()
        return importantPatterns.contains { lowercaseText.contains($0) }
    }
    
    private func isTechnicalTerm(_ text: String) -> Bool {
        // Simple heuristic for technical terms
        let technicalPatterns = [
            "API", "SDK", "URL", "HTTP", "SSL", "JSON", "XML",
            "CPU", "GPU", "RAM", "SSD", "UI", "UX"
        ]
        
        return technicalPatterns.contains(text) || 
               (text.count > 8 && text.contains(".")) // Likely a technical identifier
    }
    
    private func extractDominantColors(from image: CIImage) -> [NSColor] {
        // Simplified color extraction - in a real implementation, 
        // this would use more sophisticated color clustering
        return [
            NSColor.systemBlue,
            NSColor.systemRed,
            NSColor.systemGreen
        ]
    }
    
    private func generateComplementaryColors(for color: NSColor) -> [NSColor] {
        // Generate complementary color scheme
        guard let rgbColor = color.usingColorSpace(.deviceRGB) else { return [color] }
        
        let hue = rgbColor.hueComponent
        let saturation = rgbColor.saturationComponent
        let brightness = rgbColor.brightnessComponent
        
        // Generate complementary colors
        let complementaryHue = fmod(hue + 0.5, 1.0)
        let analogousHue1 = fmod(hue + 0.083, 1.0) // 30 degrees
        let analogousHue2 = fmod(hue - 0.083, 1.0) // -30 degrees
        
        return [
            NSColor(hue: complementaryHue, saturation: saturation, brightness: brightness, alpha: 1.0),
            NSColor(hue: analogousHue1, saturation: saturation, brightness: brightness, alpha: 1.0),
            NSColor(hue: analogousHue2, saturation: saturation, brightness: brightness, alpha: 1.0)
        ]
    }
    
    private func analyzeImageLayout(_ image: CIImage) -> ImageLayoutInfo {
        // Analyze image for empty regions, content density, etc.
        // This is a simplified implementation
        let emptyRegions = [
            CGRect(x: 50, y: 50, width: 100, height: 50),
            CGRect(x: 200, y: 150, width: 120, height: 60)
        ]
        
        return ImageLayoutInfo(
            contentDensity: 0.6,
            emptyRegions: emptyRegions,
            primaryContentArea: CGRect(x: 100, y: 100, width: 300, height: 200),
            contentType: .presentation
        )
    }
    
    private func findMatchingTemplate(for layoutInfo: ImageLayoutInfo) -> AnnotationTemplateManager.AnnotationTemplate? {
        // Match layout to appropriate template
        let allTemplates = templateManager.availableTemplates
        
        switch layoutInfo.contentType {
        case .presentation:
            return allTemplates.first { $0.category == .business }
        case .educational:
            return allTemplates.first { $0.category == .educational }
        case .technical:
            return allTemplates.first { $0.category == .software }
        default:
            return allTemplates.first { $0.category == .general }
        }
    }
    
    // MARK: - Action Methods
    
    private func createHighlightForText(_ text: String, observation: VNRecognizedTextObservation) {
        // Create highlight annotation for detected text
        print("AnnotationAutomationEngine: Creating highlight for text: \(text)")
    }
    
    private func createCalloutForText(_ text: String, observation: VNRecognizedTextObservation) {
        // Create callout annotation for technical term
        print("AnnotationAutomationEngine: Creating callout for text: \(text)")
    }
    
    private func enhanceDetectedShapes(_ observation: VNContoursObservation) {
        // Enhance detected geometric shapes
        print("AnnotationAutomationEngine: Enhancing detected shapes")
    }
    
    private func applyColorScheme(_ colors: [NSColor]) {
        // Apply complementary color scheme to drawing tools
        if let primaryColor = colors.first {
            drawingToolManager.setStrokeColor(primaryColor)
        }
        print("AnnotationAutomationEngine: Applied color scheme with \(colors.count) colors")
    }
    
    private func suggestAnnotationPlacement(in region: CGRect) {
        // Suggest optimal placement for annotations
        print("AnnotationAutomationEngine: Suggesting placement in region: \(region)")
    }
    
    // MARK: - Preview Generation
    
    private func generateTextHighlightPreview(_ text: String) -> NSImage? {
        let previewSize = CGSize(width: 100, height: 30)
        let image = NSImage(size: previewSize)
        
        image.lockFocus()
        
        // Draw highlight preview
        NSColor.systemYellow.withAlphaComponent(0.3).setFill()
        NSRect(origin: .zero, size: previewSize).fill()
        
        // Draw text
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.labelColor
        ]
        
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        attributedText.draw(in: NSRect(x: 5, y: 8, width: 90, height: 20))
        
        image.unlockFocus()
        return image
    }
    
    private func generateCalloutPreview(_ text: String) -> NSImage? {
        let previewSize = CGSize(width: 120, height: 40)
        let image = NSImage(size: previewSize)
        
        image.lockFocus()
        
        // Draw callout bubble
        let bubbleRect = NSRect(x: 10, y: 5, width: 100, height: 30)
        let bubblePath = NSBezierPath(roundedRect: bubbleRect, xRadius: 8, yRadius: 8)
        
        NSColor.systemBlue.withAlphaComponent(0.2).setFill()
        bubblePath.fill()
        
        NSColor.systemBlue.setStroke()
        bubblePath.stroke()
        
        // Draw pointer
        let pointerPath = NSBezierPath()
        pointerPath.move(to: CGPoint(x: 20, y: 5))
        pointerPath.line(to: CGPoint(x: 15, y: 0))
        pointerPath.line(to: CGPoint(x: 25, y: 0))
        pointerPath.close()
        
        NSColor.systemBlue.withAlphaComponent(0.2).setFill()
        pointerPath.fill()
        
        NSColor.systemBlue.setStroke()
        pointerPath.stroke()
        
        image.unlockFocus()
        return image
    }
    
    private func generateShapeEnhancementPreview() -> NSImage? {
        let previewSize = CGSize(width: 80, height: 60)
        let image = NSImage(size: previewSize)
        
        image.lockFocus()
        
        // Draw enhanced shape preview
        let shapeRect = NSRect(x: 10, y: 10, width: 60, height: 40)
        let shapePath = NSBezierPath(rect: shapeRect)
        
        NSColor.systemGreen.withAlphaComponent(0.3).setFill()
        shapePath.fill()
        
        NSColor.systemGreen.setStroke()
        shapePath.lineWidth = 2.0
        shapePath.stroke()
        
        image.unlockFocus()
        return image
    }
    
    private func generateColorSchemePreview(_ colors: [NSColor]) -> NSImage? {
        let previewSize = CGSize(width: 100, height: 20)
        let image = NSImage(size: previewSize)
        
        image.lockFocus()
        
        let colorWidth = previewSize.width / CGFloat(colors.count)
        
        for (index, color) in colors.enumerated() {
            let colorRect = NSRect(
                x: CGFloat(index) * colorWidth,
                y: 0,
                width: colorWidth,
                height: previewSize.height
            )
            
            color.setFill()
            colorRect.fill()
        }
        
        image.unlockFocus()
        return image
    }
    
    private func generatePlacementPreview(_ region: CGRect) -> NSImage? {
        let previewSize = CGSize(width: 100, height: 80)
        let image = NSImage(size: previewSize)
        
        image.lockFocus()
        
        // Draw placement region preview
        let regionRect = NSRect(x: 20, y: 20, width: 60, height: 40)
        let regionPath = NSBezierPath(rect: regionRect)
        
        NSColor.systemPurple.withAlphaComponent(0.2).setFill()
        regionPath.fill()
        
        NSColor.systemPurple.setStroke()
        regionPath.lineWidth = 2.0
        regionPath.setLineDash([4, 2], count: 2, phase: 0)
        regionPath.stroke()
        
        image.unlockFocus()
        return image
    }
    
    private func generateTemplatePreview(_ template: AnnotationTemplateManager.AnnotationTemplate) -> NSImage? {
        // Generate template preview - simplified implementation
        let previewSize = CGSize(width: 100, height: 60)
        let image = NSImage(size: previewSize)
        
        image.lockFocus()
        
        // Draw template elements preview
        NSColor.systemIndigo.withAlphaComponent(0.3).setFill()
        NSRect(origin: .zero, size: previewSize).fill()
        
        // Draw template name
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.labelColor
        ]
        
        let attributedText = NSAttributedString(string: template.name, attributes: attributes)
        attributedText.draw(in: NSRect(x: 5, y: 25, width: 90, height: 20))
        
        image.unlockFocus()
        return image
    }
    
    // MARK: - Workflow Automation
    
    func createWorkflow(name: String, steps: [WorkflowStep]) -> AnnotationWorkflow {
        let workflow = AnnotationWorkflow(
            id: UUID(),
            name: name,
            steps: steps,
            createdDate: Date()
        )
        
        print("AnnotationAutomationEngine: Created workflow '\(name)' with \(steps.count) steps")
        return workflow
    }
    
    func executeWorkflow(_ workflow: AnnotationWorkflow) {
        print("AnnotationAutomationEngine: Executing workflow '\(workflow.name)'")
        
        for (index, step) in workflow.steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) {
                step.execute()
            }
        }
    }
    
    // MARK: - Setup and Configuration
    
    private func setupVisionRequests() {
        // Configure Vision requests for optimal performance
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = true
        
        shapeDetectionRequest.contrastAdjustment = 1.0
        shapeDetectionRequest.detectsDarkOnLight = true
    }
    
    private func loadAutomationPreferences() {
        // Load automation preferences from UserDefaults
        let savedFeatures = preferencesManager.enabledAutomationFeatures
        enabledFeatures = Set(savedFeatures)
        
        isEnabled = preferencesManager.isAutomationEnabled
    }
    
    func saveAutomationPreferences() {
        // Save automation preferences to UserDefaults
        preferencesManager.enabledAutomationFeatures = Array(enabledFeatures)
        preferencesManager.isAutomationEnabled = isEnabled
    }
}

// MARK: - Supporting Types

struct ImageLayoutInfo {
    let contentDensity: Float
    let emptyRegions: [CGRect]?
    let primaryContentArea: CGRect
    let contentType: ContentType
    
    enum ContentType {
        case presentation, educational, technical, design, general
    }
}

struct AnnotationWorkflow {
    let id: UUID
    let name: String
    let steps: [WorkflowStep]
    let createdDate: Date
}

protocol WorkflowStep {
    var name: String { get }
    var description: String { get }
    func execute()
}

// MARK: - PreferencesManager Extensions

extension PreferencesManager {
    var enabledAutomationFeatures: [AnnotationAutomationEngine.AutomationFeature] {
        get {
            let savedRawValues = UserDefaults.standard.stringArray(forKey: "enabledAutomationFeatures") ?? []
            return savedRawValues.compactMap { AnnotationAutomationEngine.AutomationFeature(rawValue: $0) }
        }
        set {
            let rawValues = newValue.map { $0.rawValue }
            UserDefaults.standard.set(rawValues, forKey: "enabledAutomationFeatures")
        }
    }
    
    var isAutomationEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "isAutomationEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "isAutomationEnabled") }
    }
} 