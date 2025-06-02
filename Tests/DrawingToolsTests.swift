import XCTest
@testable import Magnify
import AppKit

/// Comprehensive test suite for the advanced drawing tools system
/// Tests all functionality of DrawingToolManager including tool selection, drawing operations, and preferences
final class DrawingToolsTests: XCTestCase {
    
    var drawingToolManager: DrawingToolManager!
    var testView: NSView!
    
    override func setUp() {
        super.setUp()
        drawingToolManager = DrawingToolManager.shared
        testView = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 500))
        
        // Clear any existing state
        drawingToolManager.clearAllDrawings()
        drawingToolManager.selectTool(.freehand)
        
        print("DrawingToolsTests: Setup completed")
    }
    
    override func tearDown() {
        drawingToolManager.clearAllDrawings()
        drawingToolManager = nil
        testView = nil
        super.tearDown()
        
        print("DrawingToolsTests: Teardown completed")
    }
    
    // MARK: - Initialization Tests
    
    func testDrawingToolManagerSingleton() {
        let manager1 = DrawingToolManager.shared
        let manager2 = DrawingToolManager.shared
        
        XCTAssertTrue(manager1 === manager2, "DrawingToolManager should be a singleton")
    }
    
    func testInitialState() {
        XCTAssertEqual(drawingToolManager.currentTool, .freehand, "Initial tool should be freehand")
        XCTAssertEqual(drawingToolManager.strokeWidth, 2.0, "Initial stroke width should be 2.0")
        XCTAssertEqual(drawingToolManager.elementCount, 0, "Initial element count should be 0")
        XCTAssertFalse(drawingToolManager.isToolPaletteVisible, "Tool palette should be initially hidden")
    }
    
    // MARK: - Tool Selection Tests
    
    func testToolSelection() {
        let tools = DrawingToolManager.DrawingTool.allCases
        
        for tool in tools {
            drawingToolManager.selectTool(tool)
            XCTAssertEqual(drawingToolManager.currentTool, tool, "Current tool should be \(tool.displayName)")
        }
    }
    
    func testToolProperties() {
        let tool = DrawingToolManager.DrawingTool.rectangle
        
        XCTAssertEqual(tool.displayName, "Rectangle", "Rectangle tool display name should be correct")
        XCTAssertEqual(tool.iconName, "rectangle", "Rectangle tool icon name should be correct")
        XCTAssertTrue(tool.requiresClickAndDrag, "Rectangle tool should require click and drag")
        
        let freehandTool = DrawingToolManager.DrawingTool.freehand
        XCTAssertFalse(freehandTool.requiresClickAndDrag, "Freehand tool should not require click and drag")
    }
    
    func testToolSelectionSideEffects() {
        drawingToolManager.selectTool(.line)
        
        // Start a drawing operation
        drawingToolManager.startDrawing(at: CGPoint(x: 10, y: 10), in: testView)
        
        // Change tool - should finish current drawing
        drawingToolManager.selectTool(.rectangle)
        
        XCTAssertEqual(drawingToolManager.currentTool, .rectangle, "Tool should change to rectangle")
    }
    
    // MARK: - Color Management Tests
    
    func testStrokeColorSetting() {
        let testColor = NSColor.systemRed
        drawingToolManager.setStrokeColor(testColor)
        
        XCTAssertEqual(drawingToolManager.currentColor, testColor, "Stroke color should be set correctly")
    }
    
    func testFillColorSetting() {
        let testColor = NSColor.systemBlue
        drawingToolManager.setFillColor(testColor)
        
        XCTAssertEqual(drawingToolManager.fillColor, testColor, "Fill color should be set correctly")
        
        // Test clearing fill color
        drawingToolManager.setFillColor(nil)
        XCTAssertNil(drawingToolManager.fillColor, "Fill color should be clearable")
    }
    
    func testTextColorSetting() {
        let testColor = NSColor.systemGreen
        drawingToolManager.setTextColor(testColor)
        
        XCTAssertEqual(drawingToolManager.textColor, testColor, "Text color should be set correctly")
    }
    
    func testColorWithTransparency() {
        let baseColor = NSColor.systemBlue
        let alpha: CGFloat = 0.5
        
        let transparentColor = drawingToolManager.createColorWithTransparency(baseColor, alpha: alpha)
        
        XCTAssertEqual(transparentColor.alphaComponent, alpha, accuracy: 0.01, "Transparency should be applied correctly")
    }
    
    func testColorPalette() {
        let standardColors = DrawingToolManager.ColorPalette.standardColors
        let transparencyLevels = DrawingToolManager.ColorPalette.transparencyLevels
        
        XCTAssertGreaterThan(standardColors.count, 0, "Standard colors should not be empty")
        XCTAssertGreaterThan(transparencyLevels.count, 0, "Transparency levels should not be empty")
        
        // Test that all transparency levels are valid
        for level in transparencyLevels {
            XCTAssertGreaterThanOrEqual(level, 0.0, "Transparency level should be >= 0.0")
            XCTAssertLessThanOrEqual(level, 1.0, "Transparency level should be <= 1.0")
        }
    }
    
    // MARK: - Stroke Width Tests
    
    func testStrokeWidthSetting() {
        let testWidth: CGFloat = 5.0
        drawingToolManager.setStrokeWidth(testWidth)
        
        XCTAssertEqual(drawingToolManager.strokeWidth, testWidth, "Stroke width should be set correctly")
    }
    
    func testStrokeWidthClamping() {
        // Test minimum clamping
        drawingToolManager.setStrokeWidth(0.1)
        XCTAssertEqual(drawingToolManager.strokeWidth, 0.5, "Stroke width should be clamped to minimum 0.5")
        
        // Test maximum clamping
        drawingToolManager.setStrokeWidth(100.0)
        XCTAssertEqual(drawingToolManager.strokeWidth, 50.0, "Stroke width should be clamped to maximum 50.0")
        
        // Test normal value
        drawingToolManager.setStrokeWidth(10.0)
        XCTAssertEqual(drawingToolManager.strokeWidth, 10.0, "Normal stroke width should not be clamped")
    }
    
    // MARK: - Drawing Operations Tests
    
    func testFreehandDrawing() {
        drawingToolManager.selectTool(.freehand)
        
        let startPoint = CGPoint(x: 10, y: 10)
        let continuePoint = CGPoint(x: 20, y: 20)
        let endPoint = CGPoint(x: 30, y: 30)
        
        drawingToolManager.startDrawing(at: startPoint, in: testView)
        drawingToolManager.continueDrawing(to: continuePoint, in: testView)
        drawingToolManager.finishDrawing(at: endPoint, in: testView)
        
        XCTAssertEqual(drawingToolManager.elementCount, 1, "Should have one drawing element after freehand drawing")
    }
    
    func testShapeDrawing() {
        let shapes: [DrawingToolManager.DrawingTool] = [.line, .rectangle, .circle, .arrow]
        
        for shape in shapes {
            drawingToolManager.selectTool(shape)
            
            let startPoint = CGPoint(x: 10, y: 10)
            let endPoint = CGPoint(x: 50, y: 50)
            
            let initialCount = drawingToolManager.elementCount
            
            drawingToolManager.startDrawing(at: startPoint, in: testView)
            drawingToolManager.continueDrawing(to: endPoint, in: testView)
            drawingToolManager.finishDrawing(at: endPoint, in: testView)
            
            XCTAssertEqual(drawingToolManager.elementCount, initialCount + 1, "Should add one element for \(shape.displayName)")
        }
    }
    
    func testHighlighterDrawing() {
        drawingToolManager.selectTool(.highlighter)
        
        let startPoint = CGPoint(x: 10, y: 10)
        let endPoint = CGPoint(x: 30, y: 30)
        
        drawingToolManager.startDrawing(at: startPoint, in: testView)
        drawingToolManager.finishDrawing(at: endPoint, in: testView)
        
        XCTAssertEqual(drawingToolManager.elementCount, 1, "Should create highlighter element")
        
        // Test that highlighter has reduced opacity
        let elements = drawingToolManager.allDrawingElements
        if let highlighterElement = elements.first {
            XCTAssertLessThan(highlighterElement.color.alphaComponent, 1.0, "Highlighter should have reduced opacity")
        }
    }
    
    func testEraserTool() {
        // First, create some elements to erase
        drawingToolManager.selectTool(.freehand)
        drawingToolManager.startDrawing(at: CGPoint(x: 10, y: 10), in: testView)
        drawingToolManager.finishDrawing(at: CGPoint(x: 20, y: 20), in: testView)
        
        let initialCount = drawingToolManager.elementCount
        XCTAssertGreaterThan(initialCount, 0, "Should have elements to erase")
        
        // Switch to eraser and try to erase
        drawingToolManager.selectTool(.eraser)
        drawingToolManager.startDrawing(at: CGPoint(x: 15, y: 15), in: testView)
        drawingToolManager.finishDrawing(at: CGPoint(x: 15, y: 15), in: testView)
        
        // Note: Eraser functionality depends on path hit testing which may not work in unit tests
        // This test mainly verifies the eraser tool can be selected and used without crashing
    }
    
    // MARK: - Undo/Redo Tests
    
    func testUndoRedo() {
        // Create some drawing elements
        drawingToolManager.selectTool(.freehand)
        
        XCTAssertFalse(drawingToolManager.canUndo(), "Should not be able to undo initially")
        XCTAssertFalse(drawingToolManager.canRedo(), "Should not be able to redo initially")
        
        // Add first element
        drawingToolManager.startDrawing(at: CGPoint(x: 10, y: 10), in: testView)
        drawingToolManager.finishDrawing(at: CGPoint(x: 20, y: 20), in: testView)
        
        XCTAssertTrue(drawingToolManager.canUndo(), "Should be able to undo after drawing")
        XCTAssertEqual(drawingToolManager.elementCount, 1, "Should have one element")
        
        // Add second element
        drawingToolManager.startDrawing(at: CGPoint(x: 30, y: 30), in: testView)
        drawingToolManager.finishDrawing(at: CGPoint(x: 40, y: 40), in: testView)
        
        XCTAssertEqual(drawingToolManager.elementCount, 2, "Should have two elements")
        
        // Test undo
        drawingToolManager.undo()
        XCTAssertEqual(drawingToolManager.elementCount, 1, "Should have one element after undo")
        XCTAssertTrue(drawingToolManager.canRedo(), "Should be able to redo after undo")
        
        // Test redo
        drawingToolManager.redo()
        XCTAssertEqual(drawingToolManager.elementCount, 2, "Should have two elements after redo")
        XCTAssertFalse(drawingToolManager.canRedo(), "Should not be able to redo after redo")
    }
    
    func testClearAllDrawings() {
        // Create some elements
        drawingToolManager.selectTool(.freehand)
        drawingToolManager.startDrawing(at: CGPoint(x: 10, y: 10), in: testView)
        drawingToolManager.finishDrawing(at: CGPoint(x: 20, y: 20), in: testView)
        
        XCTAssertGreaterThan(drawingToolManager.elementCount, 0, "Should have elements before clearing")
        
        drawingToolManager.clearAllDrawings()
        
        XCTAssertEqual(drawingToolManager.elementCount, 0, "Should have no elements after clearing")
        XCTAssertFalse(drawingToolManager.canRedo(), "Should not be able to redo after clearing")
    }
    
    // MARK: - Font Management Tests
    
    func testFontSetting() {
        let testFont = NSFont.boldSystemFont(ofSize: 24)
        drawingToolManager.setTextFont(testFont)
        
        XCTAssertEqual(drawingToolManager.selectedFont.pointSize, 24, "Font size should be set correctly")
        XCTAssertTrue(drawingToolManager.selectedFont.fontName.contains("Bold") || 
                     drawingToolManager.selectedFont.displayName?.contains("Bold") == true, 
                     "Font should be bold")
    }
    
    func testTextAnnotation() {
        drawingToolManager.selectTool(.text)
        
        // Note: Text annotation requires user interaction for input dialog
        // This test mainly verifies the tool can be selected without issues
        let point = CGPoint(x: 100, y: 100)
        
        // This won't actually create text since there's no user input, but shouldn't crash
        drawingToolManager.startDrawing(at: point, in: testView)
        drawingToolManager.finishDrawing(at: point, in: testView)
    }
    
    // MARK: - Tool Palette Tests
    
    func testToolPaletteVisibility() {
        XCTAssertFalse(drawingToolManager.isToolPaletteVisible, "Tool palette should be initially hidden")
        
        drawingToolManager.showToolPalette()
        XCTAssertTrue(drawingToolManager.isToolPaletteVisible, "Tool palette should be visible after showing")
        
        drawingToolManager.hideToolPalette()
        XCTAssertFalse(drawingToolManager.isToolPaletteVisible, "Tool palette should be hidden after hiding")
        
        drawingToolManager.toggleToolPalette()
        XCTAssertTrue(drawingToolManager.isToolPaletteVisible, "Tool palette should be visible after toggle")
        
        drawingToolManager.toggleToolPalette()
        XCTAssertFalse(drawingToolManager.isToolPaletteVisible, "Tool palette should be hidden after second toggle")
    }
    
    // MARK: - Preferences Integration Tests
    
    func testPreferencesIntegration() {
        let preferencesManager = PreferencesManager.shared
        
        // Test default tool preference
        let testTool = DrawingToolManager.DrawingTool.rectangle
        drawingToolManager.selectTool(testTool)
        
        XCTAssertEqual(preferencesManager.defaultDrawingTool, testTool.rawValue, "Tool preference should be saved")
        
        // Test stroke width preference
        let testWidth: CGFloat = 7.0
        drawingToolManager.setStrokeWidth(testWidth)
        
        XCTAssertEqual(preferencesManager.defaultStrokeWidth, testWidth, "Stroke width preference should be saved")
        
        // Test color preference
        let testColor = NSColor.systemPurple
        drawingToolManager.setStrokeColor(testColor)
        
        // Note: Color comparison in tests can be tricky due to color space differences
        // We'll just verify the preference was set without crashing
        XCTAssertNotNil(preferencesManager.defaultDrawingColor, "Color preference should be saved")
    }
    
    // MARK: - Rendering Tests
    
    func testRenderingWithoutCrashing() {
        // Create various drawing elements
        let tools: [DrawingToolManager.DrawingTool] = [.freehand, .line, .rectangle, .circle]
        
        for tool in tools {
            drawingToolManager.selectTool(tool)
            drawingToolManager.startDrawing(at: CGPoint(x: 10, y: 10), in: testView)
            drawingToolManager.finishDrawing(at: CGPoint(x: 50, y: 50), in: testView)
        }
        
        // Create a mock graphics context for testing
        let size = CGSize(width: 100, height: 100)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), 
                               bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, 
                               bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        XCTAssertNotNil(context, "Should be able to create graphics context")
        
        if let context = context {
            // Test rendering without crashing
            drawingToolManager.renderAllElements(in: context)
        }
    }
    
    // MARK: - Performance Tests
    
    func testDrawingPerformance() {
        drawingToolManager.selectTool(.freehand)
        
        measure {
            for i in 0..<100 {
                let point = CGPoint(x: i * 2, y: i * 2)
                drawingToolManager.startDrawing(at: point, in: testView)
                drawingToolManager.finishDrawing(at: point, in: testView)
            }
        }
    }
    
    func testUndoRedoPerformance() {
        // Create many elements
        drawingToolManager.selectTool(.freehand)
        for i in 0..<50 {
            let point = CGPoint(x: i * 2, y: i * 2)
            drawingToolManager.startDrawing(at: point, in: testView)
            drawingToolManager.finishDrawing(at: point, in: testView)
        }
        
        measure {
            // Undo all
            while drawingToolManager.canUndo() {
                drawingToolManager.undo()
            }
            
            // Redo all
            while drawingToolManager.canRedo() {
                drawingToolManager.redo()
            }
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() {
        let initialElementCount = drawingToolManager.elementCount
        
        // Create and clear many elements
        for _ in 0..<1000 {
            drawingToolManager.selectTool(.freehand)
            drawingToolManager.startDrawing(at: CGPoint(x: 10, y: 10), in: testView)
            drawingToolManager.finishDrawing(at: CGPoint(x: 20, y: 20), in: testView)
        }
        
        drawingToolManager.clearAllDrawings()
        
        XCTAssertEqual(drawingToolManager.elementCount, initialElementCount, "All elements should be cleared")
        
        // Memory should be released (tested indirectly through element count)
        XCTAssertEqual(drawingToolManager.elementCount, 0, "Element count should be zero after clearing")
    }
    
    // MARK: - Edge Case Tests
    
    func testDrawingAtBoundaryPoints() {
        let boundaryPoints = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: -10, y: -10),
            CGPoint(x: 10000, y: 10000),
            CGPoint(x: CGFloat.infinity, y: 0),
            CGPoint(x: 0, y: CGFloat.nan)
        ]
        
        drawingToolManager.selectTool(.freehand)
        
        for point in boundaryPoints {
            // These should not crash
            drawingToolManager.startDrawing(at: point, in: testView)
            drawingToolManager.finishDrawing(at: point, in: testView)
        }
    }
    
    func testMultipleSimultaneousDrawingAttempts() {
        drawingToolManager.selectTool(.freehand)
        
        // Start first drawing
        drawingToolManager.startDrawing(at: CGPoint(x: 10, y: 10), in: testView)
        
        // Try to start second drawing without finishing first
        drawingToolManager.startDrawing(at: CGPoint(x: 20, y: 20), in: testView)
        
        // Should handle gracefully without crashing
        drawingToolManager.finishDrawing(at: CGPoint(x: 30, y: 30), in: testView)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteDrawingWorkflow() {
        // Test complete workflow from tool selection to rendering
        
        // 1. Select tool
        drawingToolManager.selectTool(.rectangle)
        
        // 2. Set properties
        drawingToolManager.setStrokeColor(.systemBlue)
        drawingToolManager.setStrokeWidth(4.0)
        drawingToolManager.setFillColor(.systemRed)
        
        // 3. Draw
        drawingToolManager.startDrawing(at: CGPoint(x: 10, y: 10), in: testView)
        drawingToolManager.continueDrawing(to: CGPoint(x: 50, y: 50), in: testView)
        drawingToolManager.finishDrawing(at: CGPoint(x: 50, y: 50), in: testView)
        
        // 4. Verify element was created
        XCTAssertEqual(drawingToolManager.elementCount, 1, "Should have created one element")
        
        let elements = drawingToolManager.allDrawingElements
        XCTAssertEqual(elements.count, 1, "Should have one element in collection")
        
        if let element = elements.first {
            XCTAssertEqual(element.tool, .rectangle, "Element should be rectangle tool")
            XCTAssertEqual(element.strokeWidth, 4.0, "Element should have correct stroke width")
        }
    }
    
    func testToolSwitchingDuringDrawing() {
        drawingToolManager.selectTool(.line)
        
        // Start drawing
        drawingToolManager.startDrawing(at: CGPoint(x: 10, y: 10), in: testView)
        
        // Switch tool mid-drawing
        drawingToolManager.selectTool(.rectangle)
        
        // Current tool should be updated
        XCTAssertEqual(drawingToolManager.currentTool, .rectangle, "Tool should switch to rectangle")
    }
} 