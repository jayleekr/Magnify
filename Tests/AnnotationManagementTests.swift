import XCTest
import Foundation
import AppKit
@testable import Magnify

/// Comprehensive test suite for annotation management system
/// Tests document management, layer operations, export capabilities, and integration
class AnnotationManagementTests: XCTestCase {
    
    // MARK: - Test Setup
    
    var annotationManager: AnnotationManager!
    var layerManager: LayerManager!
    var exportManager: ExportManager!
    var drawingToolManager: DrawingToolManager!
    var testDocumentsDirectory: URL!
    
    override func setUp() {
        super.setUp()
        
        // Initialize managers
        annotationManager = AnnotationManager.shared
        layerManager = LayerManager.shared
        exportManager = ExportManager.shared
        drawingToolManager = DrawingToolManager.shared
        
        // Create test documents directory
        testDocumentsDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AnnotationManagementTests", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: testDocumentsDirectory, withIntermediateDirectories: true)
        
        print("AnnotationManagementTests: Setup completed")
    }
    
    override func tearDown() {
        // Clean up test files
        try? FileManager.default.removeItem(at: testDocumentsDirectory)
        
        // Reset managers
        annotationManager.currentDocument = nil
        layerManager.availableLayers.removeAll()
        drawingToolManager.clearAllDrawings()
        
        super.tearDown()
        print("AnnotationManagementTests: Teardown completed")
    }
    
    // MARK: - AnnotationManager Tests
    
    func testDocumentCreation() {
        let document = annotationManager.createNewDocument(name: "Test Document")
        
        XCTAssertNotNil(document)
        XCTAssertEqual(document.name, "Test Document")
        XCTAssertEqual(document.layers.count, 1) // Should have default layer
        XCTAssertEqual(annotationManager.currentDocument?.id, document.id)
        XCTAssertTrue(annotationManager.isDocumentDirty)
        
        print("✅ Document creation test passed")
    }
    
    func testDocumentSaving() {
        let document = annotationManager.createNewDocument(name: "Save Test Document")
        
        let success = annotationManager.saveDocument(document)
        
        XCTAssertTrue(success)
        XCTAssertNotNil(document.fileURL)
        XCTAssertFalse(annotationManager.isDocumentDirty)
        
        // Verify file exists
        if let fileURL = document.fileURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        }
        
        print("✅ Document saving test passed")
    }
    
    func testDocumentLoading() async {
        // Create and save a document
        let originalDocument = annotationManager.createNewDocument(name: "Load Test Document")
        originalDocument.tags = ["test", "annotation"]
        _ = annotationManager.saveDocument(originalDocument)
        
        guard let fileURL = originalDocument.fileURL else {
            XCTFail("Document file URL is nil")
            return
        }
        
        // Load the document
        let result = await annotationManager.openDocument(at: fileURL)
        
        switch result {
        case .success(let loadedDocument):
            XCTAssertEqual(loadedDocument.name, "Load Test Document")
            XCTAssertEqual(loadedDocument.tags, ["test", "annotation"])
            XCTAssertEqual(annotationManager.currentDocument?.id, loadedDocument.id)
            print("✅ Document loading test passed")
            
        case .failure(let error):
            XCTFail("Failed to load document: \(error)")
        }
    }
    
    func testDocumentSearch() {
        // Create test documents
        let doc1 = annotationManager.createNewDocument(name: "Swift Programming Guide")
        let doc2 = annotationManager.createNewDocument(name: "iOS Development Tutorial")
        let doc3 = annotationManager.createNewDocument(name: "macOS Application Design")
        
        // Save documents
        _ = annotationManager.saveDocument(doc1)
        _ = annotationManager.saveDocument(doc2)
        _ = annotationManager.saveDocument(doc3)
        
        // Test search
        let swiftResults = annotationManager.searchDocuments(query: "Swift")
        let iOSResults = annotationManager.searchDocuments(query: "iOS")
        let macOSResults = annotationManager.searchDocuments(query: "macOS")
        
        XCTAssertEqual(swiftResults.count, 1)
        XCTAssertEqual(swiftResults.first?.name, "Swift Programming Guide")
        
        XCTAssertEqual(iOSResults.count, 1)
        XCTAssertEqual(iOSResults.first?.name, "iOS Development Tutorial")
        
        XCTAssertEqual(macOSResults.count, 1)
        XCTAssertEqual(macOSResults.first?.name, "macOS Application Design")
        
        print("✅ Document search test passed")
    }
    
    func testDocumentDeletion() {
        let document = annotationManager.createNewDocument(name: "Delete Test Document")
        _ = annotationManager.saveDocument(document)
        
        guard let fileURL = document.fileURL else {
            XCTFail("Document file URL is nil")
            return
        }
        
        // Verify file exists before deletion
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        
        let success = annotationManager.deleteDocument(document)
        
        XCTAssertTrue(success)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertNil(annotationManager.currentDocument)
        
        print("✅ Document deletion test passed")
    }
    
    func testRecentDocuments() {
        let documents = (1...5).map { index in
            annotationManager.createNewDocument(name: "Recent Document \(index)")
        }
        
        // Save documents to add them to recent
        documents.forEach { _ = annotationManager.saveDocument($0) }
        
        let recentDocuments = annotationManager.recentDocuments
        
        XCTAssertEqual(recentDocuments.count, 5)
        // Most recent should be first
        XCTAssertEqual(recentDocuments.first?.name, "Recent Document 5")
        
        print("✅ Recent documents test passed")
    }
    
    // MARK: - LayerManager Tests
    
    func testLayerCreation() {
        let layer = layerManager.createLayer(name: "Test Layer")
        
        XCTAssertNotNil(layer)
        XCTAssertEqual(layer.name, "Test Layer")
        XCTAssertTrue(layer.isVisible)
        XCTAssertEqual(layer.opacity, 1.0)
        XCTAssertEqual(layerManager.currentLayer?.id, layer.id)
        XCTAssertTrue(layerManager.availableLayers.contains(where: { $0.id == layer.id }))
        
        print("✅ Layer creation test passed")
    }
    
    func testLayerDeletion() {
        // Create multiple layers
        let layer1 = layerManager.createLayer(name: "Layer 1")
        let layer2 = layerManager.createLayer(name: "Layer 2")
        
        XCTAssertEqual(layerManager.availableLayers.count, 2)
        
        // Delete one layer
        let success = layerManager.deleteLayer(layer1)
        
        XCTAssertTrue(success)
        XCTAssertEqual(layerManager.availableLayers.count, 1)
        XCTAssertFalse(layerManager.availableLayers.contains(where: { $0.id == layer1.id }))
        XCTAssertEqual(layerManager.currentLayer?.id, layer2.id)
        
        print("✅ Layer deletion test passed")
    }
    
    func testLayerDuplication() {
        let originalLayer = layerManager.createLayer(name: "Original Layer")
        originalLayer.opacity = 0.5
        originalLayer.isVisible = false
        
        let duplicatedLayer = layerManager.duplicateLayer(originalLayer)
        
        XCTAssertNotNil(duplicatedLayer)
        XCTAssertEqual(duplicatedLayer.name, "Original Layer Copy")
        XCTAssertEqual(duplicatedLayer.opacity, 0.5)
        XCTAssertEqual(duplicatedLayer.isVisible, false)
        XCTAssertNotEqual(duplicatedLayer.id, originalLayer.id)
        
        print("✅ Layer duplication test passed")
    }
    
    func testLayerVisibilityToggle() {
        let layer = layerManager.createLayer(name: "Visibility Test Layer")
        XCTAssertTrue(layer.isVisible)
        
        layerManager.toggleLayerVisibility(layer)
        XCTAssertFalse(layer.isVisible)
        
        layerManager.toggleLayerVisibility(layer)
        XCTAssertTrue(layer.isVisible)
        
        print("✅ Layer visibility toggle test passed")
    }
    
    func testLayerOpacityControl() {
        let layer = layerManager.createLayer(name: "Opacity Test Layer")
        
        layerManager.setLayerOpacity(layer, 0.75)
        XCTAssertEqual(layer.opacity, 0.75, accuracy: 0.01)
        
        // Test clamping
        layerManager.setLayerOpacity(layer, 1.5)
        XCTAssertEqual(layer.opacity, 1.0, accuracy: 0.01)
        
        layerManager.setLayerOpacity(layer, -0.5)
        XCTAssertEqual(layer.opacity, 0.0, accuracy: 0.01)
        
        print("✅ Layer opacity control test passed")
    }
    
    func testLayerFiltering() {
        // Create layers with different properties
        let visibleLayer = layerManager.createLayer(name: "Visible Layer")
        let hiddenLayer = layerManager.createLayer(name: "Hidden Layer")
        hiddenLayer.isVisible = false
        
        // Test all layers filter
        layerManager.layerFilter = .all
        let allLayers = layerManager.getFilteredLayers()
        XCTAssertEqual(allLayers.count, 2)
        
        // Test visible layers filter
        layerManager.layerFilter = .visible
        let visibleLayers = layerManager.getFilteredLayers()
        XCTAssertEqual(visibleLayers.count, 1)
        XCTAssertEqual(visibleLayers.first?.id, visibleLayer.id)
        
        // Test hidden layers filter
        layerManager.layerFilter = .hidden
        let hiddenLayers = layerManager.getFilteredLayers()
        XCTAssertEqual(hiddenLayers.count, 1)
        XCTAssertEqual(hiddenLayers.first?.id, hiddenLayer.id)
        
        print("✅ Layer filtering test passed")
    }
    
    func testLayerReordering() {
        let layer1 = layerManager.createLayer(name: "Layer 1")
        let layer2 = layerManager.createLayer(name: "Layer 2")
        let layer3 = layerManager.createLayer(name: "Layer 3")
        
        // Initial order: [layer1, layer2, layer3]
        XCTAssertEqual(layerManager.availableLayers[0].id, layer1.id)
        XCTAssertEqual(layerManager.availableLayers[1].id, layer2.id)
        XCTAssertEqual(layerManager.availableLayers[2].id, layer3.id)
        
        // Move layer1 to position 2
        layerManager.moveLayer(layer1, to: 2)
        
        // New order should be: [layer2, layer3, layer1]
        XCTAssertEqual(layerManager.availableLayers[0].id, layer2.id)
        XCTAssertEqual(layerManager.availableLayers[1].id, layer3.id)
        XCTAssertEqual(layerManager.availableLayers[2].id, layer1.id)
        
        print("✅ Layer reordering test passed")
    }
    
    func testLayerTemplates() {
        let backgroundLayer = layerManager.createLayerFromTemplate(.background)
        let foregroundLayer = layerManager.createLayerFromTemplate(.foreground)
        let highlightLayer = layerManager.createLayerFromTemplate(.highlight)
        
        XCTAssertEqual(backgroundLayer.name, "Background Layer")
        XCTAssertEqual(backgroundLayer.opacity, 0.5, accuracy: 0.01)
        
        XCTAssertEqual(foregroundLayer.name, "Foreground Layer")
        XCTAssertEqual(foregroundLayer.opacity, 1.0, accuracy: 0.01)
        
        XCTAssertEqual(highlightLayer.name, "Highlight Layer")
        XCTAssertEqual(highlightLayer.opacity, 0.3, accuracy: 0.01)
        
        print("✅ Layer templates test passed")
    }
    
    // MARK: - ExportManager Tests
    
    func testExportFormatSupport() {
        let formats = ExportManager.ExportFormat.allCases
        
        XCTAssertTrue(formats.contains(.png))
        XCTAssertTrue(formats.contains(.pdf))
        XCTAssertTrue(formats.contains(.svg))
        XCTAssertTrue(formats.contains(.jpeg))
        
        // Test display names
        XCTAssertEqual(ExportManager.ExportFormat.png.displayName, "PNG Image")
        XCTAssertEqual(ExportManager.ExportFormat.pdf.displayName, "PDF Document")
        XCTAssertEqual(ExportManager.ExportFormat.svg.displayName, "SVG Vector")
        XCTAssertEqual(ExportManager.ExportFormat.jpeg.displayName, "JPEG Image")
        
        print("✅ Export format support test passed")
    }
    
    func testExportSettings() {
        let pngSettings = ExportManager.ExportSettings.defaultPNG
        let pdfSettings = ExportManager.ExportSettings.defaultPDF
        let svgSettings = ExportManager.ExportSettings.defaultSVG
        
        XCTAssertEqual(pngSettings.format, .png)
        XCTAssertTrue(pngSettings.includeTransparency)
        XCTAssertEqual(pngSettings.backgroundColor, .clear)
        
        XCTAssertEqual(pdfSettings.format, .pdf)
        XCTAssertFalse(pdfSettings.includeTransparency)
        XCTAssertEqual(pdfSettings.backgroundColor, .white)
        
        XCTAssertEqual(svgSettings.format, .svg)
        XCTAssertTrue(svgSettings.includeTransparency)
        
        print("✅ Export settings test passed")
    }
    
    func testDocumentExportPNG() async {
        let document = annotationManager.createNewDocument(name: "Export Test Document")
        let exportURL = testDocumentsDirectory.appendingPathComponent("test_export.png")
        
        let result = await exportManager.exportDocument(document, format: .png, to: exportURL)
        
        switch result {
        case .success(let url):
            XCTAssertEqual(url, exportURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL.path))
            print("✅ PNG export test passed")
            
        case .failure(let error):
            XCTFail("PNG export failed: \(error)")
        }
    }
    
    func testDocumentExportPDF() async {
        let document = annotationManager.createNewDocument(name: "PDF Export Test Document")
        let exportURL = testDocumentsDirectory.appendingPathComponent("test_export.pdf")
        
        let result = await exportManager.exportDocument(document, format: .pdf, to: exportURL)
        
        switch result {
        case .success(let url):
            XCTAssertEqual(url, exportURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL.path))
            print("✅ PDF export test passed")
            
        case .failure(let error):
            XCTFail("PDF export failed: \(error)")
        }
    }
    
    func testBatchExport() async {
        let documents = [
            annotationManager.createNewDocument(name: "Batch Document 1"),
            annotationManager.createNewDocument(name: "Batch Document 2"),
            annotationManager.createNewDocument(name: "Batch Document 3")
        ]
        
        let result = await exportManager.exportBatch(documents, format: .png, to: testDocumentsDirectory)
        
        switch result {
        case .success(let urls):
            XCTAssertEqual(urls.count, 3)
            
            for url in urls {
                XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            }
            
            print("✅ Batch export test passed")
            
        case .failure(let error):
            XCTFail("Batch export failed: \(error)")
        }
    }
    
    // MARK: - DrawingToolManager Integration Tests
    
    func testDrawingToolIntegration() {
        // Create drawing elements
        drawingToolManager.selectTool(.freehand)
        drawingToolManager.setStrokeColor(.red)
        drawingToolManager.setStrokeWidth(5.0)
        
        // Simulate drawing
        let path = NSBezierPath()
        path.move(to: CGPoint(x: 10, y: 10))
        path.line(to: CGPoint(x: 50, y: 50))
        
        let element = DrawingToolManager.DrawingElement(
            tool: .freehand,
            path: path,
            color: .red,
            strokeWidth: 5.0,
            fillColor: nil,
            text: nil,
            font: nil,
            textColor: nil,
            textPosition: nil
        )
        
        // Test statistics
        let stats = drawingToolManager.getDrawingStatistics()
        XCTAssertEqual(stats.totalElements, 0) // No elements added yet
        XCTAssertEqual(stats.undoStackSize, 0)
        XCTAssertEqual(stats.redoStackSize, 0)
        
        print("✅ Drawing tool integration test passed")
    }
    
    func testAnnotationElementConversion() {
        // Create a drawing element
        let path = NSBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.line(to: CGPoint(x: 100, y: 100))
        
        let drawingElement = DrawingToolManager.DrawingElement(
            tool: .line,
            path: path,
            color: .blue,
            strokeWidth: 3.0,
            fillColor: .yellow,
            text: nil,
            font: nil,
            textColor: nil,
            textPosition: nil
        )
        
        // Convert to annotation element
        let annotationElement = AnnotationElement(from: drawingElement)
        
        XCTAssertEqual(annotationElement.tool, "line")
        XCTAssertEqual(annotationElement.color, NSColor.blue.hexString)
        XCTAssertEqual(annotationElement.strokeWidth, 3.0)
        XCTAssertEqual(annotationElement.fillColor, NSColor.yellow.hexString)
        
        print("✅ Annotation element conversion test passed")
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflow() {
        // 1. Create document
        let document = annotationManager.createNewDocument(name: "Complete Workflow Test")
        
        // 2. Create layers
        let backgroundLayer = layerManager.createLayer(name: "Background")
        let foregroundLayer = layerManager.createLayer(name: "Foreground")
        
        // 3. Add elements to layers
        backgroundLayer.elements.append(AnnotationElement(
            tool: "rectangle",
            pathData: Data(),
            color: "#FF0000",
            strokeWidth: 2.0,
            fillColor: "#FFFF00",
            text: nil,
            font: nil,
            fontSize: nil,
            textColor: nil,
            textPosition: nil,
            created: Date()
        ))
        
        foregroundLayer.elements.append(AnnotationElement(
            tool: "text",
            pathData: Data(),
            color: "#000000",
            strokeWidth: 1.0,
            fillColor: nil,
            text: "Test Text",
            font: "Helvetica",
            fontSize: 16.0,
            textColor: "#000000",
            textPosition: CGPoint(x: 50, y: 50),
            created: Date()
        ))
        
        // 4. Save document
        let saveSuccess = annotationManager.saveDocument(document)
        XCTAssertTrue(saveSuccess)
        
        // 5. Verify layer statistics
        let layerStats = layerManager.getLayerStatistics()
        XCTAssertEqual(layerStats.totalLayers, 2)
        XCTAssertEqual(layerStats.visibleLayers, 2)
        XCTAssertEqual(layerStats.totalElements, 2)
        
        print("✅ Complete workflow test passed")
    }
    
    func testPerformanceWithLargeDataset() {
        measure {
            // Create document with many layers and elements
            let document = annotationManager.createNewDocument(name: "Performance Test")
            
            for i in 1...50 {
                let layer = layerManager.createLayer(name: "Layer \(i)")
                
                for j in 1...20 {
                    layer.elements.append(AnnotationElement(
                        tool: "freehand",
                        pathData: Data(),
                        color: "#\(String(format: "%06X", Int.random(in: 0...0xFFFFFF)))",
                        strokeWidth: Double.random(in: 1.0...10.0),
                        fillColor: nil,
                        text: "Element \(j)",
                        font: "Arial",
                        fontSize: 12.0,
                        textColor: "#000000",
                        textPosition: CGPoint(
                            x: Double.random(in: 0...800),
                            y: Double.random(in: 0...600)
                        ),
                        created: Date()
                    ))
                }
            }
            
            // Save document
            _ = annotationManager.saveDocument(document)
        }
        
        print("✅ Performance test completed")
    }
    
    func testMemoryManagement() {
        weak var weakDocument: AnnotationDocument?
        weak var weakLayer: AnnotationLayer?
        
        autoreleasepool {
            let document = annotationManager.createNewDocument(name: "Memory Test")
            let layer = layerManager.createLayer(name: "Memory Test Layer")
            
            weakDocument = document
            weakLayer = layer
            
            // Use the objects
            _ = annotationManager.saveDocument(document)
            _ = layerManager.duplicateLayer(layer)
        }
        
        // Clear references
        annotationManager.currentDocument = nil
        layerManager.availableLayers.removeAll()
        
        // Force garbage collection
        for _ in 0..<3 {
            autoreleasepool { }
        }
        
        // Check if objects were deallocated
        XCTAssertNil(weakDocument, "Document should be deallocated")
        XCTAssertNil(weakLayer, "Layer should be deallocated")
        
        print("✅ Memory management test passed")
    }
    
    func testConcurrentOperations() async {
        let expectation = XCTestExpectation(description: "Concurrent operations completed")
        expectation.expectedFulfillmentCount = 3
        
        // Perform multiple operations concurrently
        Task {
            let document1 = annotationManager.createNewDocument(name: "Concurrent Test 1")
            _ = annotationManager.saveDocument(document1)
            expectation.fulfill()
        }
        
        Task {
            let layer1 = layerManager.createLayer(name: "Concurrent Layer 1")
            _ = layerManager.duplicateLayer(layer1)
            expectation.fulfill()
        }
        
        Task {
            let document2 = annotationManager.createNewDocument(name: "Concurrent Test 2")
            let exportURL = testDocumentsDirectory.appendingPathComponent("concurrent_export.png")
            _ = await exportManager.exportDocument(document2, format: .png, to: exportURL)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
        print("✅ Concurrent operations test passed")
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidFileHandling() async {
        let invalidURL = URL(fileURLWithPath: "/invalid/path/document.magnify")
        
        let result = await annotationManager.openDocument(at: invalidURL)
        
        switch result {
        case .success:
            XCTFail("Should have failed to open invalid file")
        case .failure(let error):
            XCTAssertTrue(error is AnnotationManager.AnnotationError)
            print("✅ Invalid file handling test passed")
        }
    }
    
    func testExportToInvalidPath() async {
        let document = annotationManager.createNewDocument(name: "Invalid Export Test")
        let invalidURL = URL(fileURLWithPath: "/invalid/path/export.png")
        
        let result = await exportManager.exportDocument(document, format: .png, to: invalidURL)
        
        switch result {
        case .success:
            XCTFail("Should have failed to export to invalid path")
        case .failure(let error):
            XCTAssertTrue(error is ExportManager.ExportError)
            print("✅ Invalid export path test passed")
        }
    }
    
    func testLayerDeletionValidation() {
        let layer = layerManager.createLayer(name: "Only Layer")
        
        // Should not be able to delete the only layer
        let success = layerManager.deleteLayer(layer)
        
        XCTAssertFalse(success)
        XCTAssertEqual(layerManager.availableLayers.count, 1)
        
        print("✅ Layer deletion validation test passed")
    }
    
    // MARK: - Edge Cases
    
    func testEmptyDocumentOperations() {
        let document = annotationManager.createNewDocument(name: "Empty Document")
        
        // Remove all layers
        document.layers.removeAll()
        
        let saveSuccess = annotationManager.saveDocument(document)
        XCTAssertTrue(saveSuccess)
        
        let layerStats = layerManager.getLayerStatistics()
        XCTAssertEqual(layerStats.totalElements, 0)
        
        print("✅ Empty document operations test passed")
    }
    
    func testSpecialCharactersInNames() {
        let specialNames = [
            "Document with émojis 🎨📝",
            "Special chars: @#$%^&*()",
            "Unicode: 中文测试",
            "Very long name: " + String(repeating: "A", count: 200)
        ]
        
        for name in specialNames {
            let document = annotationManager.createNewDocument(name: name)
            let saveSuccess = annotationManager.saveDocument(document)
            XCTAssertTrue(saveSuccess, "Failed to save document with name: \(name)")
        }
        
        print("✅ Special characters in names test passed")
    }
    
    func testLargeDocumentSizeHandling() {
        let document = annotationManager.createNewDocument(name: "Large Document")
        let layer = layerManager.createLayer(name: "Large Layer")
        
        // Add many elements
        for i in 0..<1000 {
            layer.elements.append(AnnotationElement(
                tool: "freehand",
                pathData: Data(count: 1000), // Large path data
                color: "#FF0000",
                strokeWidth: 1.0,
                fillColor: nil,
                text: "Large text element \(i) with lots of content",
                font: "Arial",
                fontSize: 12.0,
                textColor: "#000000",
                textPosition: CGPoint(x: Double(i % 100), y: Double(i / 100)),
                created: Date()
            ))
        }
        
        let saveSuccess = annotationManager.saveDocument(document)
        XCTAssertTrue(saveSuccess)
        
        let stats = layerManager.getLayerStatistics()
        XCTAssertEqual(stats.totalElements, 1000)
        
        print("✅ Large document size handling test passed")
    }
}

// MARK: - Test Utilities

extension AnnotationManagementTests {
    
    /// Helper function to create test annotation element
    private func createTestAnnotationElement(tool: String = "freehand") -> AnnotationElement {
        return AnnotationElement(
            tool: tool,
            pathData: Data(),
            color: "#FF0000",
            strokeWidth: 2.0,
            fillColor: nil,
            text: nil,
            font: nil,
            fontSize: nil,
            textColor: nil,
            textPosition: nil,
            created: Date()
        )
    }
    
    /// Helper function to create test document with layers
    private func createTestDocumentWithLayers(name: String, layerCount: Int = 3) -> AnnotationDocument {
        let document = annotationManager.createNewDocument(name: name)
        
        for i in 1...layerCount {
            let layer = layerManager.createLayer(name: "Layer \(i)")
            layer.elements.append(createTestAnnotationElement())
        }
        
        return document
    }
    
    /// Helper function to verify file export
    private func verifyFileExport(at url: URL, format: ExportManager.ExportFormat) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return false
        }
        
        // Basic file size check
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int ?? 0
            return fileSize > 0
        } catch {
            return false
        }
    }
} 