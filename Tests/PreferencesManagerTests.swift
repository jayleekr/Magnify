import XCTest
import AppKit
@testable import Magnify

final class PreferencesManagerTests: XCTestCase {
    
    var preferencesManager: PreferencesManager!
    private let testSuiteName = "PreferencesManagerTests"
    
    override func setUpWithError() throws {
        // Use a separate UserDefaults suite for testing
        UserDefaults.standard.removePersistentDomain(forName: testSuiteName)
        UserDefaults.standard.synchronize()
        
        preferencesManager = PreferencesManager.shared
    }
    
    override func tearDownWithError() throws {
        // Clean up test preferences
        UserDefaults.standard.removePersistentDomain(forName: testSuiteName)
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Initialization Tests
    
    func testSingletonInstance() throws {
        let instance1 = PreferencesManager.shared
        let instance2 = PreferencesManager.shared
        
        XCTAssertTrue(instance1 === instance2, "PreferencesManager should be a singleton")
    }
    
    func testDefaultValues() throws {
        XCTAssertTrue(preferencesManager.globalHotkeyEnabled, "Global hotkeys should be enabled by default")
        XCTAssertEqual(preferencesManager.overlayToggleHotkey, "cmd+shift+m", "Default hotkey should be cmd+shift+m")
        XCTAssertEqual(preferencesManager.defaultStrokeWidth, 3.0, "Default stroke width should be 3.0")
        XCTAssertEqual(preferencesManager.defaultOpacity, 1.0, "Default opacity should be 1.0")
        XCTAssertFalse(preferencesManager.launchAtStartup, "Launch at startup should be false by default")
        XCTAssertTrue(preferencesManager.showMenuBarIcon, "Show menu bar icon should be true by default")
        XCTAssertTrue(preferencesManager.hideOverlayOnEscape, "Hide overlay on escape should be true by default")
        XCTAssertTrue(preferencesManager.rememberWindowPosition, "Remember window position should be true by default")
        XCTAssertTrue(preferencesManager.enableHardwareAcceleration, "Hardware acceleration should be enabled by default")
        XCTAssertEqual(preferencesManager.maxCaptureFrameRate, 60.0, "Max capture frame rate should be 60.0 by default")
    }
    
    func testDefaultStrokeColor() throws {
        // Default color should be system red
        XCTAssertEqual(preferencesManager.defaultStrokeColor, NSColor.systemRed, "Default stroke color should be system red")
    }
    
    // MARK: - Property Persistence Tests
    
    func testGlobalHotkeyEnabledPersistence() throws {
        preferencesManager.globalHotkeyEnabled = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "globalHotkeyEnabled"), "Global hotkey enabled should be persisted")
        
        preferencesManager.globalHotkeyEnabled = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "globalHotkeyEnabled"), "Global hotkey enabled should be persisted")
    }
    
    func testOverlayToggleHotkeyPersistence() throws {
        let testHotkey = "cmd+shift+z"
        preferencesManager.overlayToggleHotkey = testHotkey
        
        XCTAssertEqual(UserDefaults.standard.string(forKey: "overlayToggleHotkey"), testHotkey, "Overlay toggle hotkey should be persisted")
    }
    
    func testStrokeWidthPersistence() throws {
        let testWidth: CGFloat = 5.0
        preferencesManager.defaultStrokeWidth = testWidth
        
        XCTAssertEqual(UserDefaults.standard.double(forKey: "defaultStrokeWidth"), testWidth, "Stroke width should be persisted")
    }
    
    func testOpacityPersistence() throws {
        let testOpacity = 0.5
        preferencesManager.defaultOpacity = testOpacity
        
        XCTAssertEqual(UserDefaults.standard.double(forKey: "defaultOpacity"), testOpacity, "Opacity should be persisted")
    }
    
    func testStrokeColorPersistence() throws {
        let testColor = NSColor.systemBlue
        preferencesManager.defaultStrokeColor = testColor
        
        // Verify color data is stored
        let colorData = UserDefaults.standard.data(forKey: "defaultStrokeColor")
        XCTAssertNotNil(colorData, "Color data should be persisted")
        
        // Verify color can be unarchived
        if let data = colorData,
           let restoredColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? NSColor {
            XCTAssertEqual(restoredColor, testColor, "Persisted color should match the set color")
        } else {
            XCTFail("Failed to restore color from persisted data")
        }
    }
    
    // MARK: - Hotkey Management Tests
    
    func testAvailableHotkeys() throws {
        let availableHotkeys = PreferencesManager.availableHotkeys
        
        XCTAssertFalse(availableHotkeys.isEmpty, "Available hotkeys should not be empty")
        XCTAssertTrue(availableHotkeys.keys.contains("cmd+shift+m"), "Should contain default hotkey")
        XCTAssertEqual(availableHotkeys["cmd+shift+m"], "⌘⇧M", "Should contain proper display string")
    }
    
    func testParseHotkey() throws {
        let result = preferencesManager.parseHotkey("cmd+shift+m")
        
        XCTAssertNotNil(result, "Should successfully parse valid hotkey")
        XCTAssertEqual(result?.key, "m", "Should extract correct key")
        XCTAssertEqual(result?.modifiers, ["cmd", "shift"], "Should extract correct modifiers")
    }
    
    func testParseHotkeyInvalidInput() throws {
        let result = preferencesManager.parseHotkey("")
        XCTAssertNil(result, "Should return nil for empty string")
    }
    
    func testIsValidHotkey() throws {
        XCTAssertTrue(preferencesManager.isValidHotkey("cmd+shift+m"), "Should validate known hotkey")
        XCTAssertFalse(preferencesManager.isValidHotkey("invalid+hotkey"), "Should reject unknown hotkey")
    }
    
    func testGetHotkeyDisplayString() throws {
        let displayString = preferencesManager.getHotkeyDisplayString("cmd+shift+m")
        XCTAssertEqual(displayString, "⌘⇧M", "Should return correct display string")
        
        let unknownDisplayString = preferencesManager.getHotkeyDisplayString("unknown")
        XCTAssertEqual(unknownDisplayString, "unknown", "Should return input string for unknown hotkey")
    }
    
    // MARK: - Color Preset Tests
    
    func testColorPresets() throws {
        let presets = PreferencesManager.colorPresets
        
        XCTAssertFalse(presets.isEmpty, "Color presets should not be empty")
        XCTAssertTrue(presets.contains(.systemRed), "Should contain system red")
        XCTAssertTrue(presets.contains(.systemBlue), "Should contain system blue")
        XCTAssertTrue(presets.contains(.black), "Should contain black")
        XCTAssertTrue(presets.contains(.white), "Should contain white")
    }
    
    func testGetColorPreset() throws {
        let firstColor = preferencesManager.getColorPreset(at: 0)
        XCTAssertNotNil(firstColor, "Should return color for valid index")
        XCTAssertEqual(firstColor, PreferencesManager.colorPresets[0], "Should return correct color")
        
        let invalidColor = preferencesManager.getColorPreset(at: 999)
        XCTAssertNil(invalidColor, "Should return nil for invalid index")
        
        let negativeColor = preferencesManager.getColorPreset(at: -1)
        XCTAssertNil(negativeColor, "Should return nil for negative index")
    }
    
    // MARK: - Window Position Tests
    
    func testSaveAndLoadWindowFrame() throws {
        let testFrame = NSRect(x: 100, y: 200, width: 500, height: 400)
        let testIdentifier = "test_window"
        
        // Save frame
        preferencesManager.saveWindowFrame(testFrame, for: testIdentifier)
        
        // Load frame
        let loadedFrame = preferencesManager.loadWindowFrame(for: testIdentifier)
        
        XCTAssertNotNil(loadedFrame, "Should load saved frame")
        XCTAssertEqual(loadedFrame, testFrame, "Loaded frame should match saved frame")
    }
    
    func testLoadWindowFrameWithRememberDisabled() throws {
        preferencesManager.rememberWindowPosition = false
        
        let testFrame = NSRect(x: 100, y: 200, width: 500, height: 400)
        preferencesManager.saveWindowFrame(testFrame, for: "test")
        
        let loadedFrame = preferencesManager.loadWindowFrame(for: "test")
        XCTAssertNil(loadedFrame, "Should not load frame when remember position is disabled")
    }
    
    func testLoadNonexistentWindowFrame() throws {
        let loadedFrame = preferencesManager.loadWindowFrame(for: "nonexistent")
        XCTAssertNil(loadedFrame, "Should return nil for nonexistent window frame")
    }
    
    // MARK: - Performance Settings Tests
    
    func testGetRecommendedCaptureSettings() throws {
        let settings = preferencesManager.getRecommendedCaptureSettings()
        
        XCTAssertLessThanOrEqual(settings.frameRate, 60.0, "Frame rate should not exceed 60.0")
        XCTAssertEqual(settings.frameRate, preferencesManager.maxCaptureFrameRate, "Frame rate should match preference")
        XCTAssertEqual(settings.useHardwareAcceleration, preferencesManager.enableHardwareAcceleration, "Hardware acceleration should match preference")
    }
    
    func testFrameRateCapping() throws {
        preferencesManager.maxCaptureFrameRate = 120.0
        
        let settings = preferencesManager.getRecommendedCaptureSettings()
        XCTAssertEqual(settings.frameRate, 60.0, "Frame rate should be capped at 60.0")
    }
    
    // MARK: - Settings Import/Export Tests
    
    func testExportSettings() throws {
        // Set some test values
        preferencesManager.globalHotkeyEnabled = false
        preferencesManager.overlayToggleHotkey = "cmd+shift+z"
        preferencesManager.defaultStrokeWidth = 5.0
        preferencesManager.defaultOpacity = 0.8
        
        let exported = preferencesManager.exportSettings()
        
        XCTAssertEqual(exported["globalHotkeyEnabled"] as? Bool, false, "Should export global hotkey enabled")
        XCTAssertEqual(exported["overlayToggleHotkey"] as? String, "cmd+shift+z", "Should export overlay toggle hotkey")
        XCTAssertEqual(exported["defaultStrokeWidth"] as? Double, 5.0, "Should export stroke width")
        XCTAssertEqual(exported["defaultOpacity"] as? Double, 0.8, "Should export opacity")
    }
    
    func testImportSettings() throws {
        let testSettings: [String: Any] = [
            "globalHotkeyEnabled": false,
            "overlayToggleHotkey": "cmd+shift+d",
            "defaultStrokeWidth": 7.0,
            "defaultOpacity": 0.6,
            "launchAtStartup": true,
            "maxCaptureFrameRate": 30.0,
            "defaultStrokeColorHex": "#00FF00"
        ]
        
        preferencesManager.importSettings(testSettings)
        
        XCTAssertFalse(preferencesManager.globalHotkeyEnabled, "Should import global hotkey enabled")
        XCTAssertEqual(preferencesManager.overlayToggleHotkey, "cmd+shift+d", "Should import overlay toggle hotkey")
        XCTAssertEqual(preferencesManager.defaultStrokeWidth, 7.0, "Should import stroke width")
        XCTAssertEqual(preferencesManager.defaultOpacity, 0.6, "Should import opacity")
        XCTAssertTrue(preferencesManager.launchAtStartup, "Should import launch at startup")
        XCTAssertEqual(preferencesManager.maxCaptureFrameRate, 30.0, "Should import max capture frame rate")
        
        // Test color import (green color)
        XCTAssertEqual(preferencesManager.defaultStrokeColor, NSColor(hexString: "#00FF00"), "Should import color from hex string")
    }
    
    func testResetToDefaults() throws {
        // Change some values from defaults
        preferencesManager.globalHotkeyEnabled = false
        preferencesManager.overlayToggleHotkey = "cmd+shift+z"
        preferencesManager.defaultStrokeWidth = 10.0
        
        // Reset to defaults
        preferencesManager.resetToDefaults()
        
        // Verify defaults are restored
        XCTAssertTrue(preferencesManager.globalHotkeyEnabled, "Should reset global hotkey enabled to default")
        XCTAssertEqual(preferencesManager.overlayToggleHotkey, "cmd+shift+m", "Should reset hotkey to default")
        XCTAssertEqual(preferencesManager.defaultStrokeWidth, 3.0, "Should reset stroke width to default")
    }
    
    // MARK: - NSColor Extension Tests
    
    func testNSColorHexString() throws {
        let redColor = NSColor.red
        let hexString = redColor.hexString
        
        XCTAssertNotNil(hexString, "Should convert red color to hex string")
        XCTAssertEqual(hexString, "#FF0000", "Red color should convert to #FF0000")
        
        let blueColor = NSColor.blue
        let blueHex = blueColor.hexString
        XCTAssertEqual(blueHex, "#0000FF", "Blue color should convert to #0000FF")
    }
    
    func testNSColorFromHexString() throws {
        let redFromHex = NSColor(hexString: "#FF0000")
        XCTAssertNotNil(redFromHex, "Should create color from valid hex string")
        
        let redFromHexNoHash = NSColor(hexString: "FF0000")
        XCTAssertNotNil(redFromHexNoHash, "Should create color from hex string without #")
        
        let invalidColor = NSColor(hexString: "invalid")
        XCTAssertNil(invalidColor, "Should return nil for invalid hex string")
        
        let shortHex = NSColor(hexString: "#FFF")
        XCTAssertNil(shortHex, "Should return nil for short hex string")
    }
    
    // MARK: - Integration Tests
    
    func testPreferencesObservableObject() throws {
        // Test that PreferencesManager conforms to ObservableObject
        XCTAssertTrue(preferencesManager is ObservableObject, "PreferencesManager should conform to ObservableObject")
    }
    
    func testPreferencesManagerIntegration() throws {
        // Test complete workflow
        let originalEnabled = preferencesManager.globalHotkeyEnabled
        let originalHotkey = preferencesManager.overlayToggleHotkey
        
        // Change settings
        preferencesManager.globalHotkeyEnabled = !originalEnabled
        preferencesManager.overlayToggleHotkey = "cmd+shift+d"
        
        // Export and import
        let exported = preferencesManager.exportSettings()
        preferencesManager.resetToDefaults()
        preferencesManager.importSettings(exported)
        
        // Verify settings were restored
        XCTAssertEqual(preferencesManager.globalHotkeyEnabled, !originalEnabled, "Settings should be restored after export/import")
        XCTAssertEqual(preferencesManager.overlayToggleHotkey, "cmd+shift+d", "Settings should be restored after export/import")
    }
    
    // MARK: - Performance Tests
    
    func testPreferencesPerformance() throws {
        measure {
            for i in 0..<100 {
                preferencesManager.defaultStrokeWidth = CGFloat(i % 20 + 1)
                preferencesManager.defaultOpacity = Double(i % 10) / 10.0
                _ = preferencesManager.exportSettings()
            }
        }
    }
} 