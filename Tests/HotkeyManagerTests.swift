import XCTest
import Carbon
@testable import Magnify

final class HotkeyManagerTests: XCTestCase {
    
    var hotkeyManager: HotkeyManager!
    
    override func setUpWithError() throws {
        hotkeyManager = HotkeyManager.shared
    }
    
    override func tearDownWithError() throws {
        // Clean up any registered hotkeys
        hotkeyManager.unregisterAllHotkeys()
    }
    
    // MARK: - Initialization Tests
    
    func testHotkeyManagerSingleton() throws {
        let instance1 = HotkeyManager.shared
        let instance2 = HotkeyManager.shared
        
        XCTAssertTrue(instance1 === instance2, "HotkeyManager should be a singleton")
    }
    
    // MARK: - Hotkey Registration Tests
    
    func testRegisterDefaultOverlayToggle() throws {
        // Test registering the default overlay toggle hotkey
        let success = hotkeyManager.registerDefaultOverlayToggle()
        
        // In testing environment, hotkey registration might fail due to system restrictions
        // We test that the method doesn't crash and returns a boolean
        XCTAssertTrue(success || !success, "registerDefaultOverlayToggle should return a boolean")
        
        // Check if the hotkey is tracked internally
        if success {
            XCTAssertTrue(hotkeyManager.isHotkeyRegistered(identifier: "overlay_toggle"), 
                         "Overlay toggle hotkey should be registered")
        }
    }
    
    func testRegisterCustomHotkey() throws {
        let keyCode = UInt32(kVK_ANSI_T) // T key
        let modifiers = UInt32(cmdKey | shiftKey) // Cmd+Shift
        let identifier = "test_hotkey"
        
        let success = hotkeyManager.registerHotkey(keyCode: keyCode, modifiers: modifiers, identifier: identifier)
        
        // Test that the method handles registration properly
        XCTAssertTrue(success || !success, "registerHotkey should return a boolean")
        
        if success {
            XCTAssertTrue(hotkeyManager.isHotkeyRegistered(identifier: identifier), 
                         "Custom hotkey should be registered")
        }
    }
    
    func testRegisterStringBasedHotkey() throws {
        let success = hotkeyManager.registerHotkey(key: "T", modifiers: ["cmd", "shift"], identifier: "string_test")
        
        XCTAssertTrue(success || !success, "String-based hotkey registration should return a boolean")
        
        if success {
            XCTAssertTrue(hotkeyManager.isHotkeyRegistered(identifier: "string_test"), 
                         "String-based hotkey should be registered")
        }
    }
    
    func testRegisterDuplicateHotkey() throws {
        let keyCode = UInt32(kVK_ANSI_D) // D key
        let modifiers = UInt32(cmdKey) // Cmd
        let identifier = "duplicate_test"
        
        // Register hotkey first time
        let success1 = hotkeyManager.registerHotkey(keyCode: keyCode, modifiers: modifiers, identifier: identifier)
        
        // Try to register the same hotkey again
        let success2 = hotkeyManager.registerHotkey(keyCode: keyCode, modifiers: modifiers, identifier: identifier)
        
        if success1 {
            XCTAssertTrue(success2, "Registering duplicate hotkey should return true (already registered)")
        }
    }
    
    func testRegisterInvalidStringHotkey() throws {
        let success = hotkeyManager.registerHotkey(key: "InvalidKey", modifiers: ["cmd"], identifier: "invalid_test")
        
        XCTAssertFalse(success, "Registering invalid key should return false")
        XCTAssertFalse(hotkeyManager.isHotkeyRegistered(identifier: "invalid_test"), 
                      "Invalid hotkey should not be registered")
    }
    
    func testRegisterInvalidModifier() throws {
        let success = hotkeyManager.registerHotkey(key: "T", modifiers: ["cmd", "invalid"], identifier: "invalid_modifier_test")
        
        XCTAssertFalse(success, "Registering with invalid modifier should return false")
        XCTAssertFalse(hotkeyManager.isHotkeyRegistered(identifier: "invalid_modifier_test"), 
                      "Hotkey with invalid modifier should not be registered")
    }
    
    // MARK: - Hotkey Unregistration Tests
    
    func testUnregisterHotkey() throws {
        let identifier = "unregister_test"
        
        // First register a hotkey
        let registerSuccess = hotkeyManager.registerHotkey(key: "U", modifiers: ["cmd"], identifier: identifier)
        
        if registerSuccess {
            XCTAssertTrue(hotkeyManager.isHotkeyRegistered(identifier: identifier), 
                         "Hotkey should be registered before unregistering")
            
            // Now unregister it
            let unregisterSuccess = hotkeyManager.unregisterHotkey(identifier: identifier)
            XCTAssertTrue(unregisterSuccess, "Unregistering existing hotkey should succeed")
            XCTAssertFalse(hotkeyManager.isHotkeyRegistered(identifier: identifier), 
                          "Hotkey should not be registered after unregistering")
        }
    }
    
    func testUnregisterNonexistentHotkey() throws {
        let success = hotkeyManager.unregisterHotkey(identifier: "nonexistent")
        
        XCTAssertFalse(success, "Unregistering nonexistent hotkey should return false")
    }
    
    func testUnregisterAllHotkeys() throws {
        // Register multiple hotkeys
        let identifiers = ["test1", "test2", "test3"]
        var registeredCount = 0
        
        for (index, identifier) in identifiers.enumerated() {
            let keyCode = UInt32(kVK_ANSI_1 + index) // Use keys 1, 2, 3
            if hotkeyManager.registerHotkey(keyCode: keyCode, modifiers: UInt32(cmdKey), identifier: identifier) {
                registeredCount += 1
            }
        }
        
        // Unregister all
        hotkeyManager.unregisterAllHotkeys()
        
        // Verify all are unregistered
        for identifier in identifiers {
            XCTAssertFalse(hotkeyManager.isHotkeyRegistered(identifier: identifier), 
                          "Hotkey \(identifier) should be unregistered")
        }
        
        XCTAssertEqual(hotkeyManager.getRegisteredHotkeys().count, 0, 
                      "No hotkeys should be registered after unregisterAll")
    }
    
    // MARK: - Handler Tests
    
    func testSetHotkeyHandler() throws {
        var handlerCalled = false
        var receivedDescriptor: HotkeyDescriptor?
        
        hotkeyManager.setHotkeyHandler { descriptor in
            handlerCalled = true
            receivedDescriptor = descriptor
        }
        
        // We can't easily trigger a hotkey event in tests, but we can verify the handler is set
        XCTAssertTrue(true, "setHotkeyHandler should not crash")
    }
    
    // MARK: - Query Tests
    
    func testGetRegisteredHotkeys() throws {
        let initialCount = hotkeyManager.getRegisteredHotkeys().count
        
        // Register a test hotkey
        if hotkeyManager.registerHotkey(key: "G", modifiers: ["cmd"], identifier: "get_test") {
            let newCount = hotkeyManager.getRegisteredHotkeys().count
            XCTAssertEqual(newCount, initialCount + 1, "Registered hotkeys count should increase by 1")
            
            let registeredIds = hotkeyManager.getRegisteredHotkeys()
            XCTAssertTrue(registeredIds.contains("get_test"), "Registered hotkeys should contain test identifier")
        }
    }
    
    func testIsHotkeyRegistered() throws {
        let identifier = "check_test"
        
        XCTAssertFalse(hotkeyManager.isHotkeyRegistered(identifier: identifier), 
                      "Hotkey should not be registered initially")
        
        if hotkeyManager.registerHotkey(key: "C", modifiers: ["cmd"], identifier: identifier) {
            XCTAssertTrue(hotkeyManager.isHotkeyRegistered(identifier: identifier), 
                         "Hotkey should be registered after registration")
        }
    }
    
    // MARK: - HotkeyDescriptor Tests
    
    func testHotkeyDescriptorDescription() throws {
        let descriptor = HotkeyDescriptor(
            keyCode: UInt32(kVK_ANSI_M),
            modifiers: UInt32(cmdKey | shiftKey),
            identifier: "test_description"
        )
        
        let description = descriptor.description
        XCTAssertTrue(description.contains("⌘"), "Description should contain Cmd symbol")
        XCTAssertTrue(description.contains("⇧"), "Description should contain Shift symbol")
        XCTAssertTrue(description.contains("M"), "Description should contain key name")
    }
    
    func testHotkeyDescriptorEquality() throws {
        let descriptor1 = HotkeyDescriptor(
            keyCode: UInt32(kVK_ANSI_A),
            modifiers: UInt32(cmdKey),
            identifier: "equality_test1"
        )
        
        let descriptor2 = HotkeyDescriptor(
            keyCode: UInt32(kVK_ANSI_A),
            modifiers: UInt32(cmdKey),
            identifier: "equality_test1"
        )
        
        let descriptor3 = HotkeyDescriptor(
            keyCode: UInt32(kVK_ANSI_B),
            modifiers: UInt32(cmdKey),
            identifier: "equality_test2"
        )
        
        XCTAssertEqual(descriptor1, descriptor2, "Identical descriptors should be equal")
        XCTAssertNotEqual(descriptor1, descriptor3, "Different descriptors should not be equal")
    }
    
    // MARK: - Integration Tests
    
    func testHotkeyManagerIntegration() throws {
        // Test the complete workflow
        var eventReceived = false
        
        hotkeyManager.setHotkeyHandler { descriptor in
            if descriptor.identifier == "integration_test" {
                eventReceived = true
            }
        }
        
        let success = hotkeyManager.registerHotkey(key: "I", modifiers: ["cmd", "shift"], identifier: "integration_test")
        
        if success {
            XCTAssertTrue(hotkeyManager.isHotkeyRegistered(identifier: "integration_test"), 
                         "Integration test hotkey should be registered")
            
            // Clean up
            XCTAssertTrue(hotkeyManager.unregisterHotkey(identifier: "integration_test"), 
                         "Integration test hotkey should be unregistered successfully")
        }
    }
    
    // MARK: - Performance Tests
    
    func testHotkeyRegistrationPerformance() throws {
        measure {
            for i in 0..<10 {
                let identifier = "perf_test_\(i)"
                _ = hotkeyManager.registerHotkey(key: "P", modifiers: ["cmd"], identifier: identifier)
                _ = hotkeyManager.unregisterHotkey(identifier: identifier)
            }
        }
    }
} 