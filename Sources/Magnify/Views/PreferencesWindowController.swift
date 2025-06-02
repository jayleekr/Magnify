import AppKit
import SwiftUI

/// PreferencesWindowController manages the SwiftUI preferences window
/// Provides proper integration with AppKit and singleton behavior
class PreferencesWindowController: NSWindowController {
    
    // MARK: - Singleton
    
    static let shared = PreferencesWindowController()
    
    // MARK: - Initialization
    
    private init() {
        // Create the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        super.init(window: window)
        
        setupWindow()
        setupContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Window Setup
    
    private func setupWindow() {
        guard let window = window else { return }
        
        window.title = "Magnify Preferences"
        window.center()
        window.setFrameAutosaveName("PreferencesWindow")
        window.isReleasedWhenClosed = false
        window.level = .floating
        
        // Restore window position if preferences allow
        if let savedFrame = PreferencesManager.shared.loadWindowFrame(for: "preferences") {
            window.setFrame(savedFrame, display: false)
        }
        
        // Set minimum size
        window.minSize = NSSize(width: 450, height: 350)
        window.maxSize = NSSize(width: 600, height: 500)
    }
    
    private func setupContent() {
        guard let window = window else { return }
        
        // Create SwiftUI view
        let preferencesView = PreferencesWindow()
        let hostingView = NSHostingView(rootView: preferencesView)
        
        // Set up the content view
        window.contentView = hostingView
        window.contentView?.wantsLayer = true
        
        // Set up window delegate for cleanup
        window.delegate = self
    }
    
    // MARK: - Public Methods
    
    /// Show the preferences window
    func showPreferences() {
        guard let window = window else { return }
        
        // If window is already visible, just bring it to front
        if window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }
        
        // Show and center the window
        window.makeKeyAndOrderFront(nil)
        window.center()
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        print("PreferencesWindowController: Preferences window shown")
    }
    
    /// Hide the preferences window
    func hidePreferences() {
        window?.orderOut(nil)
        print("PreferencesWindowController: Preferences window hidden")
    }
    
    /// Toggle preferences window visibility
    func togglePreferences() {
        guard let window = window else { return }
        
        if window.isVisible {
            hidePreferences()
        } else {
            showPreferences()
        }
    }
    
    /// Check if preferences window is currently visible
    var isVisible: Bool {
        return window?.isVisible ?? false
    }
}

// MARK: - NSWindowDelegate

extension PreferencesWindowController: NSWindowDelegate {
    
    func windowWillClose(_ notification: Notification) {
        // Save window position if preferences allow
        if let window = window {
            PreferencesManager.shared.saveWindowFrame(window.frame, for: "preferences")
        }
        
        print("PreferencesWindowController: Window will close")
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        print("PreferencesWindowController: Window became key")
    }
    
    func windowDidResignKey(_ notification: Notification) {
        print("PreferencesWindowController: Window resigned key")
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Always allow closing
        return true
    }
}

// MARK: - Menu Integration

extension PreferencesWindowController {
    
    /// Set up preferences menu item
    static func setupPreferencesMenuItem() {
        guard let mainMenu = NSApplication.shared.mainMenu else { return }
        
        // Find or create the app menu
        var appMenu: NSMenu?
        if let appMenuItem = mainMenu.items.first {
            appMenu = appMenuItem.submenu
        } else {
            let appMenuItem = NSMenuItem()
            appMenuItem.title = "Magnify"
            mainMenu.addItem(appMenuItem)
            
            appMenu = NSMenu()
            appMenuItem.submenu = appMenu
        }
        
        guard let menu = appMenu else { return }
        
        // Check if preferences item already exists
        let preferencesTitle = "Preferences..."
        if menu.items.contains(where: { $0.title == preferencesTitle }) {
            return
        }
        
        // Add separator if needed
        if !menu.items.isEmpty && menu.items.last?.isSeparatorItem == false {
            menu.addItem(NSMenuItem.separator())
        }
        
        // Create preferences menu item
        let preferencesMenuItem = NSMenuItem(
            title: preferencesTitle,
            action: #selector(showPreferencesFromMenu),
            keyEquivalent: ","
        )
        preferencesMenuItem.target = PreferencesWindowController.shared
        menu.addItem(preferencesMenuItem)
        
        print("PreferencesWindowController: Preferences menu item added")
    }
    
    @objc private func showPreferencesFromMenu() {
        showPreferences()
    }
}

// MARK: - Keyboard Shortcuts

extension PreferencesWindowController {
    
    /// Set up global keyboard shortcuts for preferences
    static func setupKeyboardShortcuts() {
        // The preferences window will respond to Cmd+, when it's key window
        // This is handled automatically by the menu item
        
        // We could add additional shortcuts here if needed
        print("PreferencesWindowController: Keyboard shortcuts set up")
    }
} 