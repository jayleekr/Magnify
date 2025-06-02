import Foundation
import AppKit
import CoreGraphics
import QuartzCore
import PDFKit
import UniformTypeIdentifiers

/// ExportManager handles multi-format export capabilities for annotation documents
/// Supports PNG, PDF, SVG formats with high-quality rendering and progress tracking
class ExportManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = ExportManager()
    
    // MARK: - Published Properties
    
    @Published var isExporting: Bool = false
    @Published var exportProgress: Double = 0.0
    @Published var exportStatus: String = ""
    @Published var lastExportURL: URL?
    
    // MARK: - Export Formats
    
    enum ExportFormat: String, CaseIterable {
        case png = "png"
        case pdf = "pdf"
        case svg = "svg"
        case jpeg = "jpeg"
        
        var displayName: String {
            switch self {
            case .png: return "PNG Image"
            case .pdf: return "PDF Document"
            case .svg: return "SVG Vector"
            case .jpeg: return "JPEG Image"
            }
        }
        
        var fileExtension: String {
            return rawValue
        }
        
        var utType: UTType {
            switch self {
            case .png: return .png
            case .pdf: return .pdf
            case .svg: return .svg
            case .jpeg: return .jpeg
            }
        }
    }
    
    // MARK: - Export Quality Settings
    
    struct ExportSettings {
        var format: ExportFormat
        var resolution: CGSize
        var quality: Double = 1.0 // 0.0 to 1.0
        var backgroundColor: NSColor = .white
        var includeTransparency: Bool = true
        var compressionLevel: Double = 0.8
        var includeLayers: [UUID] = [] // Empty means all layers
        var exportVisibleOnly: Bool = true
        
        static let defaultPNG = ExportSettings(
            format: .png,
            resolution: CGSize(width: 1920, height: 1080),
            backgroundColor: .clear,
            includeTransparency: true
        )
        
        static let defaultPDF = ExportSettings(
            format: .pdf,
            resolution: CGSize(width: 8.5 * 72, height: 11 * 72), // Letter size in points
            backgroundColor: .white,
            includeTransparency: false
        )
        
        static let defaultSVG = ExportSettings(
            format: .svg,
            resolution: CGSize(width: 1920, height: 1080),
            backgroundColor: .clear,
            includeTransparency: true
        )
    }
    
    // MARK: - Progress Tracking
    
    private var exportProgressHandler: ((Double, String) -> Void)?
    private var exportCompletionHandler: ((Result<URL, ExportError>) -> Void)?
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        print("ExportManager: Initialized multi-format export system")
    }
    
    // MARK: - Main Export Functions
    
    /// Export an annotation document to the specified format
    func exportDocument(_ document: AnnotationDocument, 
                       format: ExportFormat, 
                       to url: URL,
                       settings: ExportSettings? = nil) async -> Result<URL, ExportError> {
        
        let exportSettings = settings ?? defaultSettings(for: format)
        
        DispatchQueue.main.async {
            self.isExporting = true
            self.exportProgress = 0.0
            self.exportStatus = "Preparing export..."
        }
        
        do {
            let exportURL: URL
            
            switch format {
            case .png:
                exportURL = try await exportToPNG(document: document, url: url, settings: exportSettings)
            case .pdf:
                exportURL = try await exportToPDF(document: document, url: url, settings: exportSettings)
            case .svg:
                exportURL = try await exportToSVG(document: document, url: url, settings: exportSettings)
            case .jpeg:
                exportURL = try await exportToJPEG(document: document, url: url, settings: exportSettings)
            }
            
            DispatchQueue.main.async {
                self.isExporting = false
                self.exportProgress = 1.0
                self.exportStatus = "Export completed successfully"
                self.lastExportURL = exportURL
            }
            
            print("ExportManager: Successfully exported \(document.name) as \(format.displayName)")
            return .success(exportURL)
            
        } catch {
            DispatchQueue.main.async {
                self.isExporting = false
                self.exportStatus = "Export failed: \(error.localizedDescription)"
            }
            
            print("ExportManager: Export failed: \(error)")
            return .failure(error as? ExportError ?? .exportFailed(error))
        }
    }
    
    /// Export multiple documents in batch
    func exportBatch(_ documents: [AnnotationDocument], 
                    format: ExportFormat, 
                    to directory: URL,
                    settings: ExportSettings? = nil) async -> Result<[URL], ExportError> {
        
        var exportedURLs: [URL] = []
        let totalDocuments = documents.count
        
        DispatchQueue.main.async {
            self.isExporting = true
            self.exportStatus = "Batch exporting \(totalDocuments) documents..."
        }
        
        for (index, document) in documents.enumerated() {
            let fileName = "\(document.name).\(format.fileExtension)"
            let fileURL = directory.appendingPathComponent(fileName)
            
            let progress = Double(index) / Double(totalDocuments)
            DispatchQueue.main.async {
                self.exportProgress = progress
                self.exportStatus = "Exporting \(document.name)... (\(index + 1)/\(totalDocuments))"
            }
            
            let result = await exportDocument(document, format: format, to: fileURL, settings: settings)
            
            switch result {
            case .success(let url):
                exportedURLs.append(url)
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isExporting = false
                    self.exportStatus = "Batch export failed on \(document.name)"
                }
                return .failure(error)
            }
        }
        
        DispatchQueue.main.async {
            self.isExporting = false
            self.exportProgress = 1.0
            self.exportStatus = "Batch export completed: \(exportedURLs.count) files"
        }
        
        return .success(exportedURLs)
    }
    
    // MARK: - PNG Export
    
    private func exportToPNG(document: AnnotationDocument, url: URL, settings: ExportSettings) async throws -> URL {
        updateProgress(0.2, "Rendering PNG image...")
        
        let size = settings.resolution
        let scale: CGFloat = 2.0 // Retina resolution
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(scaledSize.width),
            pixelsHigh: Int(scaledSize.height),
            bitsPerSample: 8,
            samplesPerPixel: settings.includeTransparency ? 4 : 3,
            hasAlpha: settings.includeTransparency,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw ExportError.renderingFailed
        }
        
        updateProgress(0.4, "Drawing annotation layers...")
        
        let context = NSGraphicsContext(bitmapImageRep: bitmap)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        
        // Set up drawing context
        let cgContext = context?.cgContext
        cgContext?.scaleBy(x: scale, y: scale)
        
        // Draw background if not transparent
        if !settings.includeTransparency {
            settings.backgroundColor.setFill()
            NSRect(origin: .zero, size: size).fill()
        }
        
        // Render document layers
        try renderDocument(document, in: cgContext!, size: size, settings: settings)
        
        NSGraphicsContext.restoreGraphicsState()
        
        updateProgress(0.8, "Saving PNG file...")
        
        // Save to file
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw ExportError.saveError
        }
        
        try pngData.write(to: url)
        
        updateProgress(1.0, "PNG export completed")
        return url
    }
    
    // MARK: - PDF Export
    
    private func exportToPDF(document: AnnotationDocument, url: URL, settings: ExportSettings) async throws -> URL {
        updateProgress(0.2, "Creating PDF document...")
        
        let pdfDocument = PDFDocument()
        let pageSize = NSRect(origin: .zero, size: settings.resolution)
        
        // Create PDF page
        let pdfPage = PDFPage()
        pdfDocument.insert(pdfPage, at: 0)
        
        updateProgress(0.4, "Rendering PDF content...")
        
        // Create PDF context
        let pdfData = NSMutableData()
        let consumer = CGDataConsumer(data: pdfData)!
        let context = CGContext(consumer: consumer, mediaBox: &pageSize, nil)!
        
        context.beginPDFPage(nil)
        
        // Draw background
        if !settings.includeTransparency {
            context.setFillColor(settings.backgroundColor.cgColor)
            context.fill(pageSize)
        }
        
        // Render document
        try renderDocument(document, in: context, size: settings.resolution, settings: settings)
        
        context.endPDFPage()
        context.closePDF()
        
        updateProgress(0.8, "Saving PDF file...")
        
        // Save to file
        try pdfData.write(to: url)
        
        updateProgress(1.0, "PDF export completed")
        return url
    }
    
    // MARK: - SVG Export
    
    private func exportToSVG(document: AnnotationDocument, url: URL, settings: ExportSettings) async throws -> URL {
        updateProgress(0.2, "Generating SVG markup...")
        
        let size = settings.resolution
        var svgContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg width="\(size.width)" height="\(size.height)" viewBox="0 0 \(size.width) \(size.height)" 
             xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
        
        """
        
        // Add background if not transparent
        if !settings.includeTransparency {
            let bgColor = settings.backgroundColor.hexString
            svgContent += """
            <rect width="100%" height="100%" fill="\(bgColor)"/>
            
            """
        }
        
        updateProgress(0.4, "Converting annotation layers...")
        
        // Convert each layer to SVG
        for layer in document.layers {
            if settings.exportVisibleOnly && !layer.isVisible {
                continue
            }
            
            if !settings.includeLayers.isEmpty && !settings.includeLayers.contains(layer.id) {
                continue
            }
            
            svgContent += generateSVGLayer(layer, opacity: layer.opacity)
        }
        
        svgContent += "\n</svg>"
        
        updateProgress(0.8, "Saving SVG file...")
        
        // Save to file
        try svgContent.write(to: url, atomically: true, encoding: .utf8)
        
        updateProgress(1.0, "SVG export completed")
        return url
    }
    
    // MARK: - JPEG Export
    
    private func exportToJPEG(document: AnnotationDocument, url: URL, settings: ExportSettings) async throws -> URL {
        updateProgress(0.2, "Rendering JPEG image...")
        
        let size = settings.resolution
        let scale: CGFloat = 2.0
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(scaledSize.width),
            pixelsHigh: Int(scaledSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 3, // No alpha for JPEG
            hasAlpha: false,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw ExportError.renderingFailed
        }
        
        updateProgress(0.4, "Drawing annotation layers...")
        
        let context = NSGraphicsContext(bitmapImageRep: bitmap)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        
        let cgContext = context?.cgContext
        cgContext?.scaleBy(x: scale, y: scale)
        
        // Always draw background for JPEG
        settings.backgroundColor.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        // Render document
        try renderDocument(document, in: cgContext!, size: size, settings: settings)
        
        NSGraphicsContext.restoreGraphicsState()
        
        updateProgress(0.8, "Saving JPEG file...")
        
        // Save to file with compression
        let jpegProperties: [NSBitmapImageRep.PropertyKey: Any] = [
            .compressionFactor: settings.compressionLevel
        ]
        
        guard let jpegData = bitmap.representation(using: .jpeg, properties: jpegProperties) else {
            throw ExportError.saveError
        }
        
        try jpegData.write(to: url)
        
        updateProgress(1.0, "JPEG export completed")
        return url
    }
    
    // MARK: - Rendering Core
    
    private func renderDocument(_ document: AnnotationDocument, 
                               in context: CGContext, 
                               size: CGSize, 
                               settings: ExportSettings) throws {
        
        // Render each layer
        for (index, layer) in document.layers.enumerated() {
            if settings.exportVisibleOnly && !layer.isVisible {
                continue
            }
            
            if !settings.includeLayers.isEmpty && !settings.includeLayers.contains(layer.id) {
                continue
            }
            
            let layerProgress = Double(index) / Double(document.layers.count) * 0.4 + 0.4
            updateProgress(layerProgress, "Rendering layer: \(layer.name)")
            
            // Set layer opacity
            context.setAlpha(CGFloat(layer.opacity))
            
            // Render each element in the layer
            for element in layer.elements {
                try renderElement(element, in: context)
            }
            
            // Reset alpha
            context.setAlpha(1.0)
        }
    }
    
    private func renderElement(_ element: AnnotationElement, in context: CGContext) throws {
        context.saveGState()
        
        // Set element properties
        if let color = NSColor(hexString: element.color) {
            context.setStrokeColor(color.cgColor)
        }
        
        context.setLineWidth(CGFloat(element.strokeWidth))
        
        if let fillColorHex = element.fillColor,
           let fillColor = NSColor(hexString: fillColorHex) {
            context.setFillColor(fillColor.cgColor)
        }
        
        // Render based on element type
        if element.tool == "text" {
            try renderTextElement(element, in: context)
        } else {
            try renderPathElement(element, in: context)
        }
        
        context.restoreGState()
    }
    
    private func renderPathElement(_ element: AnnotationElement, in context: CGContext) throws {
        guard let path = NSKeyedUnarchiver.unarchiveObject(with: element.pathData) as? NSBezierPath else {
            throw ExportError.renderingFailed
        }
        
        // Convert NSBezierPath to CGPath
        let cgPath = path.cgPath
        context.addPath(cgPath)
        
        if element.fillColor != nil {
            context.drawPath(using: .fillStroke)
        } else {
            context.strokePath()
        }
    }
    
    private func renderTextElement(_ element: AnnotationElement, in context: CGContext) throws {
        guard let text = element.text,
              let position = element.textPosition else {
            return
        }
        
        var font = NSFont.systemFont(ofSize: 16)
        if let fontName = element.font,
           let fontSize = element.fontSize {
            font = NSFont(name: fontName, size: CGFloat(fontSize)) ?? font
        }
        
        var textColor = NSColor.black
        if let colorHex = element.textColor {
            textColor = NSColor(hexString: colorHex) ?? textColor
        }
        
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
        
        // Flip coordinate system for text rendering
        context.saveGState()
        context.textMatrix = CGAffineTransform.identity
        context.translateBy(x: 0, y: context.boundingBoxOfClipPath.height)
        context.scaleBy(x: 1, y: -1)
        
        attributedString.draw(in: textRect)
        context.restoreGState()
    }
    
    // MARK: - SVG Generation Helpers
    
    private func generateSVGLayer(_ layer: AnnotationLayer, opacity: Double) -> String {
        var layerSVG = """
        <g id="layer-\(layer.id)" opacity="\(opacity)">
        
        """
        
        for element in layer.elements {
            layerSVG += generateSVGElement(element)
        }
        
        layerSVG += """
        </g>
        
        """
        
        return layerSVG
    }
    
    private func generateSVGElement(_ element: AnnotationElement) -> String {
        if element.tool == "text" {
            return generateSVGText(element)
        } else {
            return generateSVGPath(element)
        }
    }
    
    private func generateSVGPath(_ element: AnnotationElement) -> String {
        // Convert path data to SVG path
        // This is a simplified implementation - would need full NSBezierPath to SVG conversion
        let strokeColor = element.color
        let strokeWidth = element.strokeWidth
        let fillColor = element.fillColor ?? "none"
        
        return """
        <path stroke="\(strokeColor)" stroke-width="\(strokeWidth)" fill="\(fillColor)" d="M 0 0"/>
        
        """
    }
    
    private func generateSVGText(_ element: AnnotationElement) -> String {
        guard let text = element.text,
              let position = element.textPosition else {
            return ""
        }
        
        let fontSize = element.fontSize ?? 16
        let textColor = element.textColor ?? "#000000"
        
        return """
        <text x="\(position.x)" y="\(position.y)" font-size="\(fontSize)" fill="\(textColor)">\(text)</text>
        
        """
    }
    
    // MARK: - Helper Functions
    
    private func defaultSettings(for format: ExportFormat) -> ExportSettings {
        switch format {
        case .png: return .defaultPNG
        case .pdf: return .defaultPDF
        case .svg: return .defaultSVG
        case .jpeg: return ExportSettings(format: .jpeg, resolution: CGSize(width: 1920, height: 1080))
        }
    }
    
    private func updateProgress(_ progress: Double, _ status: String) {
        DispatchQueue.main.async {
            self.exportProgress = progress
            self.exportStatus = status
        }
    }
    
    // MARK: - File Dialog Helpers
    
    /// Show save dialog for export
    func showExportDialog(for document: AnnotationDocument, format: ExportFormat) -> URL? {
        let savePanel = NSSavePanel()
        savePanel.title = "Export \(document.name)"
        savePanel.allowedContentTypes = [format.utType]
        savePanel.nameFieldStringValue = "\(document.name).\(format.fileExtension)"
        
        if savePanel.runModal() == .OK {
            return savePanel.url
        }
        
        return nil
    }
    
    /// Show directory dialog for batch export
    func showBatchExportDialog() -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose Export Directory"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK {
            return openPanel.url
        }
        
        return nil
    }
    
    // MARK: - Error Handling
    
    enum ExportError: LocalizedError {
        case renderingFailed
        case saveError
        case invalidFormat
        case exportFailed(Error)
        case insufficientSpace
        case permissionDenied
        
        var errorDescription: String? {
            switch self {
            case .renderingFailed:
                return "Failed to render annotation content"
            case .saveError:
                return "Failed to save exported file"
            case .invalidFormat:
                return "Invalid export format"
            case .exportFailed(let error):
                return "Export failed: \(error.localizedDescription)"
            case .insufficientSpace:
                return "Insufficient disk space for export"
            case .permissionDenied:
                return "Permission denied to write file"
            }
        }
    }
}

// MARK: - Extensions

extension NSBezierPath {
    /// Convert NSBezierPath to CGPath for rendering
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        
        for i in 0..<elementCount {
            let type = element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }
        
        return path
    }
} 