import Foundation
import AppKit
import SwiftUI

/// DrawingToolManager handles all advanced drawing tool functionality
/// Provides centralized management for geometric shapes, text annotation, and tool selection
class DrawingToolManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = DrawingToolManager()
    
    // MARK: - Published Properties
    
    @Published var currentTool: DrawingTool = .freehand
    @Published var currentColor: NSColor = .systemBlue
    @Published var strokeWidth: CGFloat = 2.0
    @Published var fillColor: NSColor? = nil
    @Published var isToolPaletteVisible: Bool = false
    @Published var selectedFont: NSFont = NSFont.systemFont(ofSize: 16)
    @Published var textColor: NSColor = .black
    
    // MARK: - Drawing Tools
    
    enum DrawingTool: String, CaseIterable {
        case freehand = "freehand"
        case line = "line"
        case rectangle = "rectangle"
        case circle = "circle"
        case arrow = "arrow"
        case text = "text"
        case highlighter = "highlighter"
        case eraser = "eraser"
        
        var displayName: String {
            switch self {
            case .freehand: return "Freehand"
            case .line: return "Line"
            case .rectangle: return "Rectangle"
            case .circle: return "Circle"
            case .arrow: return "Arrow"
            case .text: return "Text"
            case .highlighter: return "Highlighter"
            case .eraser: return "Eraser"
            }
        }
        
        var iconName: String {
            switch self {
            case .freehand: return "pencil"
            case .line: return "line.diagonal"
            case .rectangle: return "rectangle"
            case .circle: return "circle"
            case .arrow: return "arrow.right"
            case .text: return "textformat"
            case .highlighter: return "highlighter"
            case .eraser: return "trash"
            }
        }
        
        var requiresClickAndDrag: Bool {
            switch self {
            case .freehand, .highlighter, .eraser:
                return false
            case .line, .rectangle, .circle, .arrow:
                return true
            case .text:
                return false
            }
        }
    }
    
    // MARK: - Color Management
    
    struct ColorPalette {
        static let standardColors: [NSColor] = [
            .black, .darkGray, .gray, .lightGray, .white,
            .systemRed, .systemOrange, .systemYellow, .systemGreen,
            .systemBlue, .systemPurple, .systemPink, .systemBrown
        ]
        
        static let transparencyLevels: [CGFloat] = [1.0, 0.8, 0.6, 0.4, 0.2]
    }
    
    // MARK: - Drawing State
    
    private var currentDrawingPath: NSBezierPath?
    private var startPoint: CGPoint = .zero
    private var isDrawing: Bool = false
    private var tempShapeLayer: CAShapeLayer?
    
    // MARK: - Preferences Integration
    
    private let preferencesManager = PreferencesManager.shared
    
    // MARK: - Drawing Elements Storage
    
    struct DrawingElement {
        let id: UUID = UUID()
        let tool: DrawingTool
        let path: NSBezierPath
        let color: NSColor
        let strokeWidth: CGFloat
        let fillColor: NSColor?
        let timestamp: Date = Date()
        
        // Text-specific properties
        let text: String?
        let font: NSFont?
        let textColor: NSColor?
        let textPosition: CGPoint?
    }
    
    private var drawingElements: [DrawingElement] = []
    private var undoStack: [DrawingElement] = []
    private var redoStack: [DrawingElement] = []
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        loadPreferences()
        setupNotifications()
    }
    
    private func loadPreferences() {
        currentTool = DrawingTool(rawValue: preferencesManager.defaultDrawingTool) ?? .freehand
        currentColor = preferencesManager.defaultDrawingColor
        strokeWidth = preferencesManager.defaultStrokeWidth
        selectedFont = preferencesManager.defaultTextFont
        textColor = preferencesManager.defaultTextColor
        
        print("DrawingToolManager: Loaded preferences - Tool: \(currentTool.displayName), Color: \(currentColor)")
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(savePreferences),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }
    
    @objc private func savePreferences() {
        preferencesManager.defaultDrawingTool = currentTool.rawValue
        preferencesManager.defaultDrawingColor = currentColor
        preferencesManager.defaultStrokeWidth = strokeWidth
        preferencesManager.defaultTextFont = selectedFont
        preferencesManager.defaultTextColor = textColor
        
        print("DrawingToolManager: Saved preferences")
    }
    
    // MARK: - Tool Selection
    
    func selectTool(_ tool: DrawingTool) {
        guard tool != currentTool else { return }
        
        // Finish any current drawing operation
        finishCurrentDrawing()
        
        currentTool = tool
        print("DrawingToolManager: Selected tool: \(tool.displayName)")
        
        // Update cursor for the new tool
        updateCursor()
        
        // Save preference
        preferencesManager.defaultDrawingTool = tool.rawValue
    }
    
    func updateCursor() {
        let cursor: NSCursor
        
        switch currentTool {
        case .freehand, .highlighter:
            cursor = NSCursor.pencil()
        case .line, .rectangle, .circle, .arrow:
            cursor = NSCursor.crosshair
        case .text:
            cursor = NSCursor.iBeam
        case .eraser:
            cursor = NSCursor.operationNotAllowed
        }
        
        cursor.set()
    }
    
    // MARK: - Color Management
    
    func setStrokeColor(_ color: NSColor) {
        currentColor = color
        preferencesManager.defaultDrawingColor = color
        print("DrawingToolManager: Set stroke color to \(color)")
    }
    
    func setFillColor(_ color: NSColor?) {
        fillColor = color
        print("DrawingToolManager: Set fill color to \(color?.description ?? "none")")
    }
    
    func setStrokeWidth(_ width: CGFloat) {
        let clampedWidth = max(0.5, min(50.0, width))
        strokeWidth = clampedWidth
        preferencesManager.defaultStrokeWidth = clampedWidth
        print("DrawingToolManager: Set stroke width to \(clampedWidth)")
    }
    
    func createColorWithTransparency(_ baseColor: NSColor, alpha: CGFloat) -> NSColor {
        return baseColor.withAlphaComponent(alpha)
    }
    
    // MARK: - Drawing Operations
    
    func startDrawing(at point: CGPoint, in view: NSView) {
        guard !isDrawing else { return }
        
        isDrawing = true
        startPoint = point
        
        switch currentTool {
        case .freehand, .highlighter:
            startFreehandDrawing(at: point)
        case .line, .rectangle, .circle, .arrow:
            startShapeDrawing(at: point, in: view)
        case .text:
            startTextAnnotation(at: point, in: view)
        case .eraser:
            startErasing(at: point, in: view)
        }
        
        print("DrawingToolManager: Started drawing with \(currentTool.displayName) at \(point)")
    }
    
    func continueDrawing(to point: CGPoint, in view: NSView) {
        guard isDrawing else { return }
        
        switch currentTool {
        case .freehand, .highlighter:
            continueFreehandDrawing(to: point)
        case .line, .rectangle, .circle, .arrow:
            updateShapeDrawing(to: point, in: view)
        case .eraser:
            continueErasing(at: point, in: view)
        case .text:
            // Text doesn't have continuous drawing
            break
        }
    }
    
    func finishDrawing(at point: CGPoint, in view: NSView) {
        guard isDrawing else { return }
        
        switch currentTool {
        case .freehand, .highlighter:
            finishFreehandDrawing()
        case .line, .rectangle, .circle, .arrow:
            finishShapeDrawing(at: point, in: view)
        case .text:
            finishTextAnnotation(at: point, in: view)
        case .eraser:
            finishErasing()
        }
        
        isDrawing = false
        print("DrawingToolManager: Finished drawing with \(currentTool.displayName)")
    }
    
    private func finishCurrentDrawing() {
        if isDrawing {
            isDrawing = false
            currentDrawingPath = nil
            removeTempShapeLayer()
        }
    }
    
    // MARK: - Freehand Drawing
    
    private func startFreehandDrawing(at point: CGPoint) {
        currentDrawingPath = NSBezierPath()
        currentDrawingPath?.move(to: point)
        currentDrawingPath?.lineWidth = strokeWidth
    }
    
    private func continueFreehandDrawing(to point: CGPoint) {
        currentDrawingPath?.line(to: point)
    }
    
    private func finishFreehandDrawing() {
        guard let path = currentDrawingPath else { return }
        
        let element = DrawingElement(
            tool: currentTool,
            path: path.copy() as! NSBezierPath,
            color: currentTool == .highlighter ? currentColor.withAlphaComponent(0.3) : currentColor,
            strokeWidth: strokeWidth,
            fillColor: nil,
            text: nil,
            font: nil,
            textColor: nil,
            textPosition: nil
        )
        
        addDrawingElement(element)
        currentDrawingPath = nil
    }
    
    // MARK: - Shape Drawing
    
    private func startShapeDrawing(at point: CGPoint, in view: NSView) {
        // Create temporary shape layer for preview
        tempShapeLayer = CAShapeLayer()
        tempShapeLayer?.strokeColor = currentColor.cgColor
        tempShapeLayer?.fillColor = fillColor?.cgColor ?? NSColor.clear.cgColor
        tempShapeLayer?.lineWidth = strokeWidth
        view.layer?.addSublayer(tempShapeLayer!)
    }
    
    private func updateShapeDrawing(to point: CGPoint, in view: NSView) {
        guard let shapeLayer = tempShapeLayer else { return }
        
        let path = createShapePath(from: startPoint, to: point, tool: currentTool)
        shapeLayer.path = path.cgPath
    }
    
    private func finishShapeDrawing(at point: CGPoint, in view: NSView) {
        let path = createShapePath(from: startPoint, to: point, tool: currentTool)
        
        let element = DrawingElement(
            tool: currentTool,
            path: path,
            color: currentColor,
            strokeWidth: strokeWidth,
            fillColor: fillColor,
            text: nil,
            font: nil,
            textColor: nil,
            textPosition: nil
        )
        
        addDrawingElement(element)
        removeTempShapeLayer()
    }
    
    private func createShapePath(from startPoint: CGPoint, to endPoint: CGPoint, tool: DrawingTool) -> NSBezierPath {
        let path = NSBezierPath()
        
        switch tool {
        case .line:
            path.move(to: startPoint)
            path.line(to: endPoint)
            
        case .rectangle:
            let rect = NSRect(
                x: min(startPoint.x, endPoint.x),
                y: min(startPoint.y, endPoint.y),
                width: abs(endPoint.x - startPoint.x),
                height: abs(endPoint.y - startPoint.y)
            )
            path.appendRect(rect)
            
        case .circle:
            let rect = NSRect(
                x: min(startPoint.x, endPoint.x),
                y: min(startPoint.y, endPoint.y),
                width: abs(endPoint.x - startPoint.x),
                height: abs(endPoint.y - startPoint.y)
            )
            path.appendOval(in: rect)
            
        case .arrow:
            // Create arrow shape
            createArrowPath(path, from: startPoint, to: endPoint)
            
        default:
            break
        }
        
        path.lineWidth = strokeWidth
        return path
    }
    
    private func createArrowPath(_ path: NSBezierPath, from start: CGPoint, to end: CGPoint) {
        // Main line
        path.move(to: start)
        path.line(to: end)
        
        // Calculate arrow head
        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowLength: CGFloat = 15.0
        let arrowAngle: CGFloat = .pi / 6 // 30 degrees
        
        let arrowPoint1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        
        let arrowPoint2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )
        
        // Arrow head lines
        path.move(to: end)
        path.line(to: arrowPoint1)
        path.move(to: end)
        path.line(to: arrowPoint2)
    }
    
    private func removeTempShapeLayer() {
        tempShapeLayer?.removeFromSuperlayer()
        tempShapeLayer = nil
    }
    
    // MARK: - Text Annotation
    
    private func startTextAnnotation(at point: CGPoint, in view: NSView) {
        // Show text input dialog
        let alert = NSAlert()
        alert.messageText = "Add Text Annotation"
        alert.informativeText = "Enter the text you want to add:"
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.placeholderString = "Enter text here..."
        alert.accessoryView = textField
        
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")
        
        alert.beginSheetModal(for: view.window!) { response in
            if response == .alertFirstButtonReturn {
                let text = textField.stringValue
                if !text.isEmpty {
                    self.createTextAnnotation(text: text, at: point)
                }
            }
        }
    }
    
    private func createTextAnnotation(text: String, at point: CGPoint) {
        // Create a path for text positioning
        let path = NSBezierPath()
        path.move(to: point)
        
        let element = DrawingElement(
            tool: .text,
            path: path,
            color: currentColor,
            strokeWidth: strokeWidth,
            fillColor: nil,
            text: text,
            font: selectedFont,
            textColor: textColor,
            textPosition: point
        )
        
        addDrawingElement(element)
    }
    
    private func finishTextAnnotation(at point: CGPoint, in view: NSView) {
        // Text annotation is handled in startTextAnnotation
    }
    
    // MARK: - Eraser
    
    private func startErasing(at point: CGPoint, in view: NSView) {
        eraseElementsAt(point: point)
    }
    
    private func continueErasing(at point: CGPoint, in view: NSView) {
        eraseElementsAt(point: point)
    }
    
    private func finishErasing() {
        // Erasing is complete
    }
    
    private func eraseElementsAt(point: CGPoint) {
        let eraserRadius: CGFloat = strokeWidth * 2
        
        drawingElements.removeAll { element in
            return element.path.contains(point) || 
                   isPointNearPath(point, path: element.path, tolerance: eraserRadius)
        }
    }
    
    private func isPointNearPath(_ point: CGPoint, path: NSBezierPath, tolerance: CGFloat) -> Bool {
        // Create a slightly expanded version of the path for hit testing
        let expandedPath = path.copy() as! NSBezierPath
        expandedPath.lineWidth = path.lineWidth + tolerance
        return expandedPath.contains(point)
    }
    
    // MARK: - Drawing Element Management
    
    private func addDrawingElement(_ element: DrawingElement) {
        // Clear redo stack when adding new element
        redoStack.removeAll()
        
        // Add to undo stack for potential undo
        if let lastElement = drawingElements.last {
            undoStack.append(lastElement)
        }
        
        drawingElements.append(element)
        
        // Limit undo stack size
        if undoStack.count > 50 {
            undoStack.removeFirst()
        }
        
        print("DrawingToolManager: Added drawing element with \(element.tool.displayName)")
    }
    
    // MARK: - Undo/Redo Operations
    
    func canUndo() -> Bool {
        return !drawingElements.isEmpty
    }
    
    func canRedo() -> Bool {
        return !redoStack.isEmpty
    }
    
    func undo() {
        guard !drawingElements.isEmpty else { return }
        
        let lastElement = drawingElements.removeLast()
        redoStack.append(lastElement)
        
        print("DrawingToolManager: Undo operation completed")
    }
    
    func redo() {
        guard !redoStack.isEmpty else { return }
        
        let element = redoStack.removeLast()
        drawingElements.append(element)
        
        print("DrawingToolManager: Redo operation completed")
    }
    
    func clearAllDrawings() {
        undoStack.append(contentsOf: drawingElements)
        drawingElements.removeAll()
        redoStack.removeAll()
        
        print("DrawingToolManager: Cleared all drawings")
    }
    
    // MARK: - Rendering
    
    func renderAllElements(in context: CGContext) {
        for element in drawingElements {
            renderElement(element, in: context)
        }
    }
    
    private func renderElement(_ element: DrawingElement, in context: CGContext) {
        context.saveGState()
        
        // Set color and stroke properties
        context.setStrokeColor(element.color.cgColor)
        context.setLineWidth(element.strokeWidth)
        
        if let fillColor = element.fillColor {
            context.setFillColor(fillColor.cgColor)
        }
        
        // Render based on tool type
        switch element.tool {
        case .text:
            renderTextElement(element, in: context)
        default:
            // Render path-based elements
            context.addPath(element.path.cgPath)
            
            if element.fillColor != nil {
                context.drawPath(using: .fillStroke)
            } else {
                context.strokePath()
            }
        }
        
        context.restoreGState()
    }
    
    private func renderTextElement(_ element: DrawingElement, in context: CGContext) {
        guard let text = element.text,
              let font = element.font,
              let textColor = element.textColor,
              let position = element.textPosition else { return }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        
        let textRect = NSRect(
            x: position.x,
            y: position.y - textSize.height,
            width: textSize.width,
            height: textSize.height
        )
        
        // Convert to Core Graphics coordinate system
        context.saveGState()
        context.textMatrix = CGAffineTransform.identity
        context.translateBy(x: 0, y: context.boundingBoxOfClipPath.height)
        context.scaleBy(x: 1, y: -1)
        
        attributedString.draw(in: textRect)
        context.restoreGState()
    }
    
    // MARK: - Tool Palette Management
    
    func showToolPalette() {
        isToolPaletteVisible = true
        print("DrawingToolManager: Tool palette shown")
    }
    
    func hideToolPalette() {
        isToolPaletteVisible = false
        print("DrawingToolManager: Tool palette hidden")
    }
    
    func toggleToolPalette() {
        isToolPaletteVisible.toggle()
        print("DrawingToolManager: Tool palette toggled to \(isToolPaletteVisible ? "visible" : "hidden")")
    }
    
    // MARK: - Font Management
    
    func setTextFont(_ font: NSFont) {
        selectedFont = font
        preferencesManager.defaultTextFont = font
        print("DrawingToolManager: Set text font to \(font.displayName ?? font.fontName)")
    }
    
    func setTextColor(_ color: NSColor) {
        textColor = color
        preferencesManager.defaultTextColor = color
        print("DrawingToolManager: Set text color to \(color)")
    }
    
    // MARK: - Public Properties
    
    var allDrawingElements: [DrawingElement] {
        return drawingElements
    }
    
    var elementCount: Int {
        return drawingElements.count
    }
    
    // MARK: - Annotation Management Integration
    
    /// Sync current drawing elements with annotation document
    func syncWithAnnotationManager() {
        NotificationCenter.default.post(name: .drawingToolsChanged, object: nil)
        print("DrawingToolManager: Synced with annotation manager")
    }
    
    /// Load drawing elements from annotation elements
    func loadFromAnnotationElements(_ elements: [AnnotationElement]) {
        clearAllDrawings()
        
        for element in elements {
            if let drawingElement = convertFromAnnotationElement(element) {
                drawingElements.append(drawingElement)
            }
        }
        
        print("DrawingToolManager: Loaded \(drawingElements.count) elements from annotation")
    }
    
    /// Convert annotation element to drawing element
    private func convertFromAnnotationElement(_ element: AnnotationElement) -> DrawingElement? {
        guard let tool = DrawingTool(rawValue: element.tool),
              let path = NSKeyedUnarchiver.unarchiveObject(with: element.pathData) as? NSBezierPath,
              let color = NSColor(hexString: element.color) else {
            return nil
        }
        
        var fillColor: NSColor?
        if let fillColorHex = element.fillColor {
            fillColor = NSColor(hexString: fillColorHex)
        }
        
        var font: NSFont?
        if let fontName = element.font, let fontSize = element.fontSize {
            font = NSFont(name: fontName, size: CGFloat(fontSize))
        }
        
        var textColor: NSColor?
        if let textColorHex = element.textColor {
            textColor = NSColor(hexString: textColorHex)
        }
        
        return DrawingElement(
            tool: tool,
            path: path,
            color: color,
            strokeWidth: CGFloat(element.strokeWidth),
            fillColor: fillColor,
            text: element.text,
            font: font,
            textColor: textColor,
            textPosition: element.textPosition
        )
    }
    
    /// Get current tool state for saving
    func getCurrentToolState() -> ToolState {
        return ToolState(
            tool: currentTool,
            strokeColor: currentColor,
            fillColor: fillColor,
            strokeWidth: strokeWidth,
            textFont: selectedFont,
            textColor: textColor
        )
    }
    
    /// Restore tool state from saved state
    func restoreToolState(_ state: ToolState) {
        currentTool = state.tool
        currentColor = state.strokeColor
        fillColor = state.fillColor
        strokeWidth = state.strokeWidth
        selectedFont = state.textFont
        textColor = state.textColor
        
        updateCursor()
        print("DrawingToolManager: Restored tool state")
    }
    
    /// Tool state for saving/restoring
    struct ToolState: Codable {
        let tool: DrawingTool
        let strokeColor: NSColor
        let fillColor: NSColor?
        let strokeWidth: CGFloat
        let textFont: NSFont
        let textColor: NSColor
        
        private enum CodingKeys: String, CodingKey {
            case tool, strokeColor, fillColor, strokeWidth, textFont, textColor
        }
        
        init(tool: DrawingTool, strokeColor: NSColor, fillColor: NSColor?, 
             strokeWidth: CGFloat, textFont: NSFont, textColor: NSColor) {
            self.tool = tool
            self.strokeColor = strokeColor
            self.fillColor = fillColor
            self.strokeWidth = strokeWidth
            self.textFont = textFont
            self.textColor = textColor
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            tool = try container.decode(DrawingTool.self, forKey: .tool)
            
            let strokeColorHex = try container.decode(String.self, forKey: .strokeColor)
            strokeColor = NSColor(hexString: strokeColorHex) ?? .black
            
            if let fillColorHex = try container.decodeIfPresent(String.self, forKey: .fillColor) {
                fillColor = NSColor(hexString: fillColorHex)
            } else {
                fillColor = nil
            }
            
            strokeWidth = try container.decode(CGFloat.self, forKey: .strokeWidth)
            
            let fontName = try container.decode(String.self, forKey: .textFont)
            let fontSize = try container.decode(CGFloat.self, forKey: .textFont)
            textFont = NSFont(name: fontName, size: fontSize) ?? NSFont.systemFont(ofSize: 16)
            
            let textColorHex = try container.decode(String.self, forKey: .textColor)
            textColor = NSColor(hexString: textColorHex) ?? .black
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(tool, forKey: .tool)
            try container.encode(strokeColor.hexString, forKey: .strokeColor)
            try container.encodeIfPresent(fillColor?.hexString, forKey: .fillColor)
            try container.encode(strokeWidth, forKey: .strokeWidth)
            try container.encode(textFont.fontName, forKey: .textFont)
            try container.encode(textColor.hexString, forKey: .textColor)
        }
    }
    
    /// Enhanced undo functionality for annotation management
    func performEnhancedUndo() -> Bool {
        guard !undoStack.isEmpty else { return false }
        
        if let lastElement = drawingElements.last {
            redoStack.append(lastElement)
            drawingElements.removeLast()
            
            // Sync with annotation manager
            syncWithAnnotationManager()
            
            print("DrawingToolManager: Enhanced undo completed")
            return true
        }
        
        return false
    }
    
    /// Enhanced redo functionality for annotation management
    func performEnhancedRedo() -> Bool {
        guard !redoStack.isEmpty else { return false }
        
        let element = redoStack.removeLast()
        drawingElements.append(element)
        
        // Sync with annotation manager
        syncWithAnnotationManager()
        
        print("DrawingToolManager: Enhanced redo completed")
        return true
    }
    
    /// Get drawing statistics for annotation panel
    func getDrawingStatistics() -> DrawingStatistics {
        let toolCounts = Dictionary(grouping: drawingElements, by: { $0.tool })
            .mapValues { $0.count }
        
        return DrawingStatistics(
            totalElements: drawingElements.count,
            undoStackSize: undoStack.count,
            redoStackSize: redoStack.count,
            toolCounts: toolCounts,
            lastDrawingTime: drawingElements.last?.timestamp
        )
    }
    
    /// Drawing statistics structure
    struct DrawingStatistics {
        let totalElements: Int
        let undoStackSize: Int
        let redoStackSize: Int
        let toolCounts: [DrawingTool: Int]
        let lastDrawingTime: Date?
    }
    
    /// Export drawing elements to specific format data
    func exportDrawingData(format: ExportFormat) -> Data? {
        switch format {
        case .json:
            return exportToJSON()
        case .svg:
            return exportToSVG()
        case .drawing:
            return exportToDrawingFormat()
        }
    }
    
    enum ExportFormat {
        case json
        case svg
        case drawing
    }
    
    private func exportToJSON() -> Data? {
        let exportData = DrawingExportData(
            elements: drawingElements,
            toolState: getCurrentToolState(),
            metadata: DrawingMetadata()
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    private func exportToSVG() -> Data? {
        var svgContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="800" height="600">
        
        """
        
        for element in drawingElements {
            svgContent += convertElementToSVG(element)
        }
        
        svgContent += "\n</svg>"
        return svgContent.data(using: .utf8)
    }
    
    private func exportToDrawingFormat() -> Data? {
        return try? NSKeyedArchiver.archivedData(withRootObject: drawingElements, requiringSecureCoding: true)
    }
    
    private func convertElementToSVG(_ element: DrawingElement) -> String {
        // Simplified SVG conversion - would need full implementation
        let color = element.color.hexString
        let strokeWidth = element.strokeWidth
        
        switch element.tool {
        case .text:
            if let text = element.text, let position = element.textPosition {
                return """
                <text x="\(position.x)" y="\(position.y)" fill="\(color)" stroke-width="\(strokeWidth)">\(text)</text>
                
                """
            }
        default:
            return """
            <path stroke="\(color)" stroke-width="\(strokeWidth)" fill="none" d="M 0 0"/>
            
            """
        }
        
        return ""
    }
    
    /// Drawing export data structure
    private struct DrawingExportData: Codable {
        let elements: [DrawingElement]
        let toolState: ToolState
        let metadata: DrawingMetadata
    }
    
    /// Drawing metadata structure
    private struct DrawingMetadata: Codable {
        let version: String = "1.0"
        let createdDate: Date = Date()
        let application: String = "Magnify"
        let elementCount: Int
        
        init() {
            self.elementCount = 0
        }
        
        init(elementCount: Int) {
            self.elementCount = elementCount
        }
    }
    
    // MARK: - Layer Management Integration
    
    /// Update drawing for specific layer
    func updateForLayer(_ layerId: UUID) {
        // This would integrate with LayerManager to show only elements for specific layer
        print("DrawingToolManager: Updated for layer \(layerId)")
    }
    
    /// Filter elements by layer ID (future enhancement)
    func getElementsForLayer(_ layerId: UUID) -> [DrawingElement] {
        // Future implementation would filter by layer ID
        return drawingElements
    }
    
    // MARK: - Cleanup
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        savePreferences()
        print("DrawingToolManager: Cleanup completed")
    }
}

// MARK: - PreferencesManager Extension for Drawing Tools

extension PreferencesManager {
    
    /// Default drawing tool setting
    var defaultDrawingTool: String {
        get {
            return UserDefaults.standard.string(forKey: "defaultDrawingTool") ?? "freehand"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "defaultDrawingTool")
        }
    }
    
    /// Default drawing color setting
    var defaultDrawingColor: NSColor {
        get {
            if let colorData = UserDefaults.standard.data(forKey: "defaultDrawingColor"),
               let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) {
                return color
            }
            return .systemBlue // Default color
        }
        set {
            if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true) {
                UserDefaults.standard.set(colorData, forKey: "defaultDrawingColor")
            }
        }
    }
    
    /// Default stroke width setting
    var defaultStrokeWidth: CGFloat {
        get {
            let width = UserDefaults.standard.double(forKey: "defaultStrokeWidth")
            return width > 0 ? CGFloat(width) : 2.0 // Default width
        }
        set {
            UserDefaults.standard.set(Double(newValue), forKey: "defaultStrokeWidth")
        }
    }
    
    /// Default text font setting
    var defaultTextFont: NSFont {
        get {
            if let fontData = UserDefaults.standard.data(forKey: "defaultTextFont"),
               let font = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSFont.self, from: fontData) {
                return font
            }
            return NSFont.systemFont(ofSize: 16) // Default font
        }
        set {
            if let fontData = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true) {
                UserDefaults.standard.set(fontData, forKey: "defaultTextFont")
            }
        }
    }
    
    /// Default text color setting
    var defaultTextColor: NSColor {
        get {
            if let colorData = UserDefaults.standard.data(forKey: "defaultTextColor"),
               let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) {
                return color
            }
            return .black // Default text color
        }
        set {
            if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true) {
                UserDefaults.standard.set(colorData, forKey: "defaultTextColor")
            }
        }
    }
    
    /// Tool palette visibility setting
    var toolPaletteVisible: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "toolPaletteVisible")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "toolPaletteVisible")
        }
    }
} 