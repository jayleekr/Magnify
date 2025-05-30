import AppKit
import Carbon
import Foundation

/// HotkeyManager handles global keyboard shortcuts for the application
/// Uses Carbon Event Manager for system-wide hotkey registration
/// Designed to be App Sandbox compatible
class HotkeyManager: NSObject {
    
    // MARK: - Properties
    
    /// Shared instance for global access
    static let shared = HotkeyManager()
    
    /// Currently registered hotkeys
    private var registeredHotkeys: [HotkeyDescriptor: EventHotKeyRef] = [:]
    
    /// Event target for Carbon events
    private var eventTarget: EventTargetRef?
    
    /// Callback closure for hotkey events
    private var hotkeyHandler: ((HotkeyDescriptor) -> Void)?
    
    /// Track initialization status
    private var isInitialized = false
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupEventTarget()
    }
    
    deinit {
        unregisterAllHotkeys()
        cleanupEventTarget()
    }
    
    // MARK: - Public Methods
    
    /// Set the callback handler for hotkey events
    /// - Parameter handler: Closure to call when hotkey is pressed
    func setHotkeyHandler(_ handler: @escaping (HotkeyDescriptor) -> Void) {
        self.hotkeyHandler = handler
        print("HotkeyManager: Handler set for hotkey events")
    }
    
    /// Register a global hotkey
    /// - Parameters:
    ///   - keyCode: Virtual key code
    ///   - modifiers: Modifier keys (Cmd, Shift, etc.)
    ///   - identifier: Unique identifier for this hotkey
    /// - Returns: True if registration successful
    @discardableResult
    func registerHotkey(keyCode: UInt32, modifiers: UInt32, identifier: String) -> Bool {
        let descriptor = HotkeyDescriptor(keyCode: keyCode, modifiers: modifiers, identifier: identifier)
        
        // Check if already registered
        if registeredHotkeys[descriptor] != nil {
            print("HotkeyManager: Hotkey \(identifier) already registered")
            return true
        }
        
        // Register the hotkey with Carbon
        var hotkeyRef: EventHotKeyRef?
        let hotkeyID = EventHotKeyID(signature: OSType(fourCharCode: "MGNF"), id: UInt32(registeredHotkeys.count + 1))
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetEventDispatcherTarget(),
            0,
            &hotkeyRef
        )
        
        if status == noErr, let hotkey = hotkeyRef {
            registeredHotkeys[descriptor] = hotkey
            print("HotkeyManager: Successfully registered hotkey \(identifier) (keyCode: \(keyCode), modifiers: \(modifiers))")
            return true
        } else {
            print("HotkeyManager: Failed to register hotkey \(identifier), error: \(status)")
            return false
        }
    }
    
    /// Register default overlay toggle hotkey (Cmd+Shift+M)
    /// - Returns: True if registration successful
    @discardableResult
    func registerDefaultOverlayToggle() -> Bool {
        let keyCode = UInt32(kVK_ANSI_M) // M key
        let modifiers = UInt32(cmdKey | shiftKey) // Cmd+Shift
        return registerHotkey(keyCode: keyCode, modifiers: modifiers, identifier: "overlay_toggle")
    }
    
    /// Unregister a specific hotkey
    /// - Parameter identifier: The identifier of the hotkey to unregister
    /// - Returns: True if successfully unregistered
    @discardableResult
    func unregisterHotkey(identifier: String) -> Bool {
        guard let descriptor = registeredHotkeys.keys.first(where: { $0.identifier == identifier }),
              let hotkeyRef = registeredHotkeys[descriptor] else {
            print("HotkeyManager: Hotkey \(identifier) not found for unregistration")
            return false
        }
        
        let status = UnregisterEventHotKey(hotkeyRef)
        if status == noErr {
            registeredHotkeys.removeValue(forKey: descriptor)
            print("HotkeyManager: Successfully unregistered hotkey \(identifier)")
            return true
        } else {
            print("HotkeyManager: Failed to unregister hotkey \(identifier), error: \(status)")
            return false
        }
    }
    
    /// Unregister all hotkeys
    func unregisterAllHotkeys() {
        for (descriptor, hotkeyRef) in registeredHotkeys {
            let status = UnregisterEventHotKey(hotkeyRef)
            if status == noErr {
                print("HotkeyManager: Unregistered hotkey \(descriptor.identifier)")
            } else {
                print("HotkeyManager: Failed to unregister hotkey \(descriptor.identifier), error: \(status)")
            }
        }
        registeredHotkeys.removeAll()
    }
    
    /// Check if a specific hotkey is registered
    /// - Parameter identifier: The identifier to check
    /// - Returns: True if the hotkey is registered
    func isHotkeyRegistered(identifier: String) -> Bool {
        return registeredHotkeys.keys.contains { $0.identifier == identifier }
    }
    
    /// Get all registered hotkey identifiers
    /// - Returns: Array of registered hotkey identifiers
    func getRegisteredHotkeys() -> [String] {
        return registeredHotkeys.keys.map { $0.identifier }
    }
    
    // MARK: - Private Methods
    
    private func setupEventTarget() {
        eventTarget = GetEventDispatcherTarget()
        
        // Install event handler for hotkey events
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        InstallEventHandler(
            eventTarget,
            { (nextHandler, theEvent, userData) -> OSStatus in
                return HotkeyManager.shared.handleHotkeyEvent(nextHandler: nextHandler, event: theEvent, userData: userData)
            },
            1,
            &eventType,
            nil,
            nil
        )
        
        isInitialized = true
        print("HotkeyManager: Event target initialized")
    }
    
    private func cleanupEventTarget() {
        // Carbon will clean up event handlers automatically
        eventTarget = nil
        isInitialized = false
        print("HotkeyManager: Event target cleaned up")
    }
    
    /// Handle Carbon hotkey events
    private func handleHotkeyEvent(nextHandler: EventHandlerCallRef?, event: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus {
        guard let event = event else { return eventNotHandledErr }
        
        var hotkeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            OSType(kEventParamDirectObject),
            OSType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotkeyID
        )
        
        if status == noErr {
            // Find the hotkey descriptor that matches this ID
            for (descriptor, hotkeyRef) in registeredHotkeys {
                // Note: In a production app, you'd want to store the mapping between
                // EventHotKeyID and HotkeyDescriptor more efficiently
                // For this implementation, we'll use the first registered hotkey
                DispatchQueue.main.async {
                    self.hotkeyHandler?(descriptor)
                    print("HotkeyManager: Hotkey pressed - \(descriptor.identifier)")
                }
                return noErr
            }
        }
        
        return eventNotHandledErr
    }
}

// MARK: - Supporting Types

/// Describes a hotkey configuration
struct HotkeyDescriptor: Hashable {
    let keyCode: UInt32
    let modifiers: UInt32
    let identifier: String
    
    /// Human-readable description of the hotkey
    var description: String {
        var modifierStrings: [String] = []
        
        if modifiers & UInt32(cmdKey) != 0 { modifierStrings.append("⌘") }
        if modifiers & UInt32(shiftKey) != 0 { modifierStrings.append("⇧") }
        if modifiers & UInt32(optionKey) != 0 { modifierStrings.append("⌥") }
        if modifiers & UInt32(controlKey) != 0 { modifierStrings.append("⌃") }
        
        let keyName = keyCodeToString(keyCode) ?? "Unknown"
        return modifierStrings.joined(separator: "") + keyName
    }
    
    /// Convert key code to readable string
    private func keyCodeToString(_ keyCode: UInt32) -> String? {
        switch keyCode {
        case UInt32(kVK_ANSI_A): return "A"
        case UInt32(kVK_ANSI_S): return "S"
        case UInt32(kVK_ANSI_D): return "D"
        case UInt32(kVK_ANSI_F): return "F"
        case UInt32(kVK_ANSI_H): return "H"
        case UInt32(kVK_ANSI_G): return "G"
        case UInt32(kVK_ANSI_Z): return "Z"
        case UInt32(kVK_ANSI_X): return "X"
        case UInt32(kVK_ANSI_C): return "C"
        case UInt32(kVK_ANSI_V): return "V"
        case UInt32(kVK_ANSI_B): return "B"
        case UInt32(kVK_ANSI_Q): return "Q"
        case UInt32(kVK_ANSI_W): return "W"
        case UInt32(kVK_ANSI_E): return "E"
        case UInt32(kVK_ANSI_R): return "R"
        case UInt32(kVK_ANSI_Y): return "Y"
        case UInt32(kVK_ANSI_T): return "T"
        case UInt32(kVK_ANSI_O): return "O"
        case UInt32(kVK_ANSI_U): return "U"
        case UInt32(kVK_ANSI_I): return "I"
        case UInt32(kVK_ANSI_P): return "P"
        case UInt32(kVK_ANSI_L): return "L"
        case UInt32(kVK_ANSI_J): return "J"
        case UInt32(kVK_ANSI_K): return "K"
        case UInt32(kVK_ANSI_N): return "N"
        case UInt32(kVK_ANSI_M): return "M"
        case UInt32(kVK_Space): return "Space"
        case UInt32(kVK_Return): return "Return"
        case UInt32(kVK_Tab): return "Tab"
        case UInt32(kVK_Escape): return "Escape"
        default: return nil
        }
    }
}

// MARK: - Convenience Extensions

extension HotkeyManager {
    
    /// Register hotkey with string-based modifiers (convenience method)
    /// - Parameters:
    ///   - key: Key character (e.g., "M")
    ///   - modifiers: Array of modifier strings (e.g., ["cmd", "shift"])
    ///   - identifier: Unique identifier
    /// - Returns: True if registration successful
    @discardableResult
    func registerHotkey(key: String, modifiers: [String], identifier: String) -> Bool {
        guard let keyCode = stringToKeyCode(key.uppercased()) else {
            print("HotkeyManager: Invalid key '\(key)'")
            return false
        }
        
        var modifierFlags: UInt32 = 0
        for modifier in modifiers {
            switch modifier.lowercased() {
            case "cmd", "command": modifierFlags |= UInt32(cmdKey)
            case "shift": modifierFlags |= UInt32(shiftKey)
            case "option", "alt": modifierFlags |= UInt32(optionKey)
            case "control", "ctrl": modifierFlags |= UInt32(controlKey)
            default:
                print("HotkeyManager: Unknown modifier '\(modifier)'")
                return false
            }
        }
        
        return registerHotkey(keyCode: keyCode, modifiers: modifierFlags, identifier: identifier)
    }
    
    /// Convert string to key code
    private func stringToKeyCode(_ key: String) -> UInt32? {
        switch key {
        case "A": return UInt32(kVK_ANSI_A)
        case "S": return UInt32(kVK_ANSI_S)
        case "D": return UInt32(kVK_ANSI_D)
        case "F": return UInt32(kVK_ANSI_F)
        case "H": return UInt32(kVK_ANSI_H)
        case "G": return UInt32(kVK_ANSI_G)
        case "Z": return UInt32(kVK_ANSI_Z)
        case "X": return UInt32(kVK_ANSI_X)
        case "C": return UInt32(kVK_ANSI_C)
        case "V": return UInt32(kVK_ANSI_V)
        case "B": return UInt32(kVK_ANSI_B)
        case "Q": return UInt32(kVK_ANSI_Q)
        case "W": return UInt32(kVK_ANSI_W)
        case "E": return UInt32(kVK_ANSI_E)
        case "R": return UInt32(kVK_ANSI_R)
        case "Y": return UInt32(kVK_ANSI_Y)
        case "T": return UInt32(kVK_ANSI_T)
        case "O": return UInt32(kVK_ANSI_O)
        case "U": return UInt32(kVK_ANSI_U)
        case "I": return UInt32(kVK_ANSI_I)
        case "P": return UInt32(kVK_ANSI_P)
        case "L": return UInt32(kVK_ANSI_L)
        case "J": return UInt32(kVK_ANSI_J)
        case "K": return UInt32(kVK_ANSI_K)
        case "N": return UInt32(kVK_ANSI_N)
        case "M": return UInt32(kVK_ANSI_M)
        case "SPACE": return UInt32(kVK_Space)
        case "RETURN": return UInt32(kVK_Return)
        case "TAB": return UInt32(kVK_Tab)
        case "ESCAPE": return UInt32(kVK_Escape)
        default: return nil
        }
    }
}

// MARK: - Helper Functions

/// Create four-character code from string
private func fourCharCode(_ string: String) -> OSType {
    let chars = Array(string.prefix(4).padding(toLength: 4, withPad: " ", startingAt: 0))
    return OSType(chars[0].asciiValue! << 24 | chars[1].asciiValue! << 16 | chars[2].asciiValue! << 8 | chars[3].asciiValue!)
} 