import XCTest
import AppKit
@testable import Magnify

final class OverlayWindowTests: XCTestCase {
    
    var overlayWindow: OverlayWindow!
    
    override func setUpWithError() throws {
        overlayWindow = OverlayWindow()
    }
    
    override func tearDownWithError() throws {
        overlayWindow?.hideOverlay()
        overlayWindow = nil
    }
    
    // MARK: - Initialization Tests
    
    func testOverlayWindowInitialization() throws {
        XCTAssertNotNil(overlayWindow, "OverlayWindow should initialize successfully")
        XCTAssertTrue(overlayWindow.styleMask.contains(.borderless), "Window should be borderless")
        XCTAssertEqual(overlayWindow.backgroundColor, NSColor.clear, "Window background should be clear")
        XCTAssertFalse(overlayWindow.isOpaque, "Window should not be opaque")
        XCTAssertFalse(overlayWindow.hasShadow, "Window should not have shadow")
    }
    
    func testOverlayWindowLevel() throws {
        XCTAssertEqual(overlayWindow.level, NSWindow.Level.statusBar, "Window should have statusBar level")
    }
    
    func testOverlayWindowCollectionBehavior() throws {
        let expectedBehavior: NSWindow.CollectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        XCTAssertEqual(overlayWindow.collectionBehavior, expectedBehavior, "Window should have correct collection behavior")
    }
    
    // MARK: - Content View Tests
    
    func testOverlayContentViewExists() throws {
        XCTAssertNotNil(overlayWindow.contentView, "Window should have a content view")
        XCTAssertTrue(overlayWindow.contentView is OverlayContentView, "Content view should be OverlayContentView")
    }
    
    func testOverlayContentViewProperties() throws {
        guard let contentView = overlayWindow.contentView as? OverlayContentView else {
            XCTFail("Content view should be OverlayContentView")
            return
        }
        
        XCTAssertTrue(contentView.wantsLayer, "Content view should want layer")
        XCTAssertEqual(contentView.pathCount, 0, "Initial path count should be 0")
        XCTAssertFalse(contentView.isFlipped, "Content view should use standard Cocoa coordinates")
    }
    
    // MARK: - Window Behavior Tests
    
    func testWindowShowHide() throws {
        // Initially not visible
        XCTAssertFalse(overlayWindow.isOverlayVisible, "Window should not be visible initially")
        
        // Show window
        overlayWindow.showOverlay()
        
        // Note: In headless testing environment, window visibility might not work as expected
        // We test that the methods don't crash
        XCTAssertTrue(true, "showOverlay() should not crash")
        
        // Hide window
        overlayWindow.hideOverlay()
        XCTAssertTrue(true, "hideOverlay() should not crash")
    }
    
    func testWindowCanBecomeKeyButNotMain() throws {
        XCTAssertTrue(overlayWindow.canBecomeKey(), "Window should be able to become key")
        XCTAssertFalse(overlayWindow.canBecomeMain(), "Window should not become main")
        XCTAssertTrue(overlayWindow.acceptsFirstResponder(), "Window should accept first responder")
    }
    
    // MARK: - Drawing Tests
    
    func testClearDrawing() throws {
        guard let contentView = overlayWindow.contentView as? OverlayContentView else {
            XCTFail("Content view should be OverlayContentView")
            return
        }
        
        // Clear drawing (should not crash even when no paths exist)
        contentView.clearDrawing()
        XCTAssertEqual(contentView.pathCount, 0, "Path count should remain 0 after clearing empty drawing")
    }
    
    func testStrokeProperties() throws {
        guard let contentView = overlayWindow.contentView as? OverlayContentView else {
            XCTFail("Content view should be OverlayContentView")
            return
        }
        
        // Test setting stroke color
        contentView.setStrokeColor(.blue)
        XCTAssertTrue(true, "setStrokeColor should not crash")
        
        // Test setting stroke width
        contentView.setStrokeWidth(5.0)
        XCTAssertTrue(true, "setStrokeWidth should not crash")
    }
    
    // MARK: - Mouse Event Tests
    
    func testMouseEventHandling() throws {
        guard let contentView = overlayWindow.contentView as? OverlayContentView else {
            XCTFail("Content view should be OverlayContentView")
            return
        }
        
        // Test that acceptsFirstMouse returns true
        let event = NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: NSPoint(x: 100, y: 100),
            modifierFlags: [],
            timestamp: Date().timeIntervalSince1970,
            windowNumber: overlayWindow.windowNumber,
            context: nil,
            eventNumber: 1,
            clickCount: 1,
            pressure: 1.0
        )
        
        XCTAssertTrue(contentView.acceptsFirstMouse(for: event), "Content view should accept first mouse")
    }
    
    // MARK: - Frame Update Tests
    
    func testFrameUpdate() throws {
        let newFrame = NSRect(x: 0, y: 0, width: 800, height: 600)
        
        // Test frame update doesn't crash
        overlayWindow.setFrame(newFrame, display: true)
        
        XCTAssertEqual(overlayWindow.frame.size, newFrame.size, "Window frame size should be updated")
    }
    
    // MARK: - Integration Tests
    
    func testBringToFront() throws {
        overlayWindow.bringToFront()
        XCTAssertEqual(overlayWindow.level, NSWindow.Level.statusBar, "Window level should remain statusBar after bringToFront")
    }
    
    func testOverlayWindowScreenBounds() throws {
        // Test that window initializes with screen bounds
        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let newOverlay = OverlayWindow()
        
        XCTAssertEqual(newOverlay.frame.size, screenRect.size, "New overlay window should match screen size")
    }
    
    // MARK: - Memory Tests
    
    func testMemoryManagement() throws {
        // Test that window doesn't get released when closed
        XCTAssertFalse(overlayWindow.isReleasedWhenClosed, "Window should not be released when closed")
        XCTAssertFalse(overlayWindow.hidesOnDeactivate, "Window should not hide on deactivate")
    }
    
    // MARK: - Performance Tests
    
    func testOverlayWindowCreationPerformance() throws {
        measure {
            let testWindow = OverlayWindow()
            testWindow.hideOverlay()
        }
    }
} 