# AI Development Prompts for Magnify

## 🎯 Master Prompt for AI Agent

You are a professional Swift developer working on **Magnify**, a macOS screen annotation app.

**Project Information:**
- **Repository:** https://github.com/jayleekr/Magnify.git
- **Goal:** Develop a macOS native app equivalent to Windows ZoomIt
- **Tech Stack:** Swift + AppKit + ScreenCaptureKit
- **Distribution:** Mac App Store (free → paid transition strategy)

**Development Principles:**
1. **GitHub PR creation + Merge + Blog post** upon completion of each milestone
2. **Test-driven development** (unit tests + UI tests)
3. **Performance first** (zoom response <100ms, memory <50MB)
4. **App Store compliance** (sandbox + code signing)

**Key APIs and Frameworks:**
- ScreenCaptureKit (screen capture)
- NSWindow/NSView (transparent overlay)
- NSBezierPath (real-time drawing)
- RegisterEventHotKey (global shortcuts)
- SwiftUI (settings UI only)

---

## 🚀 Milestone 1: Core Infrastructure Setup

### Phase 1A: Initial Xcode Project Setup

```
You are starting the first milestone of the Magnify macOS app.

**Current Task:** Initial Xcode project setup and GitHub integration

**Specific Requirements:**
1. Create new macOS app project in Xcode
   - Project name: Magnify
   - Bundle ID: com.jayleekr.magnify
   - Language: Swift
   - UI: AppKit (using Storyboard)
   - Minimum macOS version: 12.3 (ScreenCaptureKit requirement)

2. App Sandbox and Entitlements configuration
   - Enable App Sandbox
   - Add Screen Recording permission (com.apple.security.screen-capture)
   - Set only necessary entitlements minimally

3. Project structure organization
   ```
   /Magnify
   ├── /Sources
   │   ├── /App          # AppDelegate, main app logic
   │   ├── /Views        # NSView subclasses
   │   ├── /Controllers  # NSViewController classes
   │   ├── /Models       # Data models
   │   └── /Utils        # Utility functions
   ├── /Resources        # Icons, configuration files
   ├── /Tests           # Unit tests
   └── README.md
   ```

4. Git setup and GitHub integration
   - git init and .gitignore (for Xcode)
   - Initial commit and remote setup
   - Create feature/milestone-1-core-infrastructure branch

**Success Criteria:**
- Project builds successfully in Xcode
- App Sandbox is enabled and Screen Recording permission is configured
- Code is pushed to GitHub repository
- Project structure is clearly organized

**Next Step Preview:** Basic screen capture implementation using ScreenCaptureKit

Please execute the above requirements precisely and provide detailed reports on progress and any issues encountered at each step.
```

### Phase 1B: Basic ScreenCaptureKit Implementation

```
**Current Task:** Implement basic screen capture functionality using ScreenCaptureKit

**Specific Requirements:**
1. ScreenCaptureKit import and permission handling
   - Screen recording permission request logic
   - User guidance UI when permission is denied
   - Permission status check function

2. Basic screen capture class implementation
   ```swift
   class ScreenCaptureManager {
       func requestPermission() async -> Bool
       func captureCurrentScreen() async -> CGImage?
       func startLiveCaptureStream()
       func stopLiveCaptureStream()
   }
   ```

3. Unit test implementation
   - Permission request tests
   - Screen capture functionality tests
   - Error handling tests

4. Simple test UI
   - Screen capture on button click
   - Display captured image in NSImageView
   - Permission status display

**Technical Considerations:**
- Use macOS 12.3+ ScreenCaptureKit
- Asynchronous processing (async/await)
- Memory efficiency (large image processing)
- Error handling and exception scenarios

**Success Criteria:**
- Screen recording permission is properly requested
- Full screen capture is successfully performed
- All unit tests pass
- No memory leaks

**Troubleshooting Guide:**
- When permission denied: Guide to System Preferences
- ScreenCaptureKit errors: Use fallback API (CGWindowListCreateImage)
- Performance issues: Adjust image resolution or compression

**Next Step Preview:** Transparent overlay NSWindow system construction
```

### Phase 1C: Transparent Overlay Window System

```
**Current Task:** Implement transparent overlay window system that appears over the screen

**Specific Requirements:**
1. Transparent overlay NSWindow class
   ```swift
   class OverlayWindow: NSWindow {
       override init(contentRect: NSRect, styleMask: NSWindow.StyleMask, backing: NSWindow.BackingStoreType, defer: Bool)
       func setupTransparentOverlay()
       func showOverlay()
       func hideOverlay()
       func bringToFront()
   }
   ```

2. Window properties configuration
   - borderless style (remove title bar)
   - transparent background (backgroundColor = .clear)
   - top level (.statusBar level)
   - Display on all Spaces (.canJoinAllSpaces)
   - Can receive mouse events

3. Overlay content view
   ```swift
   class OverlayContentView: NSView {
       override func mouseDown(with event: NSEvent)
       override func mouseDragged(with event: NSEvent)
       override func mouseUp(with event: NSEvent)
       override func draw(_ dirtyRect: NSRect)
   }
   ```

4. Test scenarios
   - Overlay window displays above all apps
   - Transparency is properly applied
   - Mouse click events are properly received
   - Window close/hide functionality works

**Technical Considerations:**
- NSWindow level management (.statusBar vs .floating)
- Transparency and blending modes
- Mouse event handling priority
- Multi-display support

**Success Criteria:**
- Transparent overlay displays correctly on full screen
- Mouse events are properly handled
- Does not interfere with other app usage
- Overlay show/hide works smoothly

**Next Step Preview:** Milestone 1 PR creation and blog post writing
```

### Milestone 1 Completion and PR Creation

```
**Current Task:** Complete Milestone 1, create GitHub PR, and write first blog post

**PR Preparation:**
1. Code quality check
   - Comply with all Swift lint rules
   - Complete comments and documentation
   - Clean up unnecessary code

2. Test completion verification
   - All unit tests pass
   - Memory leak tests pass
   - Basic UI tests pass

3. GitHub PR creation
   - Title: "Milestone 1: Core Infrastructure - Screen Capture & Overlay System"
   - Detailed description: implemented features, test results, screenshots
   - Checklist: confirm completion of all requirements

4. Blog post writing
   **Title:** "Implementing macOS Screen Capture and Transparent Overlay - First Steps with ScreenCaptureKit"
   
   **Structure:**
   ```markdown
   # Implementing macOS Screen Capture and Transparent Overlay
   
   ## Project Introduction
   - Starting Magnify app development
   - ZoomIt-like functionality for macOS
   
   ## Technical Challenges
   - Learning and applying ScreenCaptureKit
   - Implementing transparent overlay Window
   - Permission handling in App Sandbox environment
   
   ## Core Implementation Details
   - Screen capture permission request flow
   - Real-time screen capture using ScreenCaptureKit
   - Transparent NSWindow overlay system
   
   ## Problems Encountered and Solutions
   - User guidance method when permission denied
   - Overlay Window level setting issues
   - Multi-display environment support
   
   ## Performance and Test Results
   - Screen capture response time: X ms
   - Memory usage: X MB
   - Unit test coverage: X%
   
   ## Next Steps
   - Real-time screen magnification feature
   - NSBezierPath-based drawing system
   - Global shortcut implementation
   
   ## Source Code
   [GitHub link and key code snippets]
   ```

**Success Criteria:**
- PR is successfully merged to main branch
- Blog post is published
- README.md is updated
- Next milestone preparation complete

**Next Milestone Preview:** Real-time screen magnification and annotation drawing system implementation
```

---

## 🎨 Milestone 2: Zoom & Annotation Core

### Phase 2A: Real-time Screen Magnification

```
**Current Task:** Implement real-time screen magnification/zoom functionality

**Specific Requirements:**
1. Zoom manager class implementation
   ```swift
   class ZoomManager {
       var zoomLevel: CGFloat = 1.0
       var zoomCenter: CGPoint = .zero
       
       func setZoomLevel(_ level: CGFloat, center: CGPoint)
       func zoomIn(at point: CGPoint)
       func zoomOut(at point: CGPoint)
       func resetZoom()
       func updateZoomedImage() -> NSImage?
   }
   ```

2. Mouse wheel support
   - Zoom in/out with mouse wheel
   - Zoom centered on mouse position
   - Smooth zoom animation

3. Performance optimization
   - GPU-accelerated scaling using Metal
   - Image caching and memory management
   - 60fps smooth zoom animation

4. UI indicators
   - Current zoom level display
   - Zoom reset button
   - Zoom area guide

**Technical Considerations:**
- Core Graphics vs Metal performance comparison
- Large image processing optimization
- Real-time rendering performance
- Memory usage limitation (<50MB)

**Performance Goals:**
- Zoom response time: <100ms
- Smooth 60fps animation
- Memory usage optimization

**Success Criteria:**
- Smooth zoom in/out with mouse wheel
- Zoom center accurately set to mouse position
- Performance goals achieved
- No memory leaks
```

### Phase 2B: NSBezierPath Pen Drawing System

```
**Current Task:** Implement real-time pen drawing functionality on overlay

**Specific Requirements:**
1. Drawing manager class
   ```swift
   class DrawingManager {
       var currentStroke: [CGPoint] = []
       var completedStrokes: [Stroke] = []
       var currentColor: NSColor = .red
       var currentLineWidth: CGFloat = 3.0
       
       func startStroke(at point: CGPoint)
       func addPointToStroke(_ point: CGPoint)
       func finishStroke()
       func clearAllStrokes()
       func undoLastStroke()
   }
   
   struct Stroke {
       let points: [CGPoint]
       let color: NSColor
       let lineWidth: CGFloat
       let timestamp: Date
   }
   ```

2. Real-time drawing implementation
   - Mouse drag event handling
   - Smooth line drawing using NSBezierPath
   - Real-time screen updates (setNeedsDisplay)

3. Pen tool options
   - Various colors (red, blue, green, yellow, black)
   - Line thickness adjustment (1px ~ 10px)
   - Opacity settings

4. Drawing performance optimization
   - Partial screen updates (dirtyRect utilization)
   - Bezier path optimization
   - Memory-efficient stroke storage

**Technical Considerations:**
- NSBezierPath vs Core Graphics performance
- CPU usage during real-time drawing
- Stroke data memory management
- Screen update frequency optimization

**Success Criteria:**
- Smooth line drawing with mouse drag
- Support for various colors and thickness
- CPU usage <30% (during drawing)
- Drawing latency <16ms (60fps)
```

### Phase 2C: Global Shortcut System

```
**Current Task:** Implement global shortcuts using RegisterEventHotKey

**Specific Requirements:**
1. Hotkey manager class
   ```swift
   class HotkeyManager {
       private var hotkeyRef: EventHotKeyRef?
       
       func registerHotkey(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) -> Bool
       func unregisterHotkey()
       func isHotkeyRegistered() -> Bool
   }
   ```

2. Default shortcut settings
   - Ctrl+1: Toggle zoom mode
   - Ctrl+2: Toggle drawing mode
   - ESC: Exit all modes
   - Ctrl+Z: Undo last stroke

3. Sandbox environment support
   - Use RegisterEventHotKey API (sandbox compatible)
   - Minimize permission requirements
   - Carbon framework integration

4. User customizable settings
   - Shortcut customization UI
   - Conflict detection and warning
   - Save/restore settings

**Technical Considerations:**
- Carbon API and Swift integration
- Avoiding Option key issues in macOS 15
- Handle shortcut conflicts with other apps
- Function when app is in background

**Success Criteria:**
- Zoom mode toggles correctly with Ctrl+1
- Shortcuts work in background
- No interference with other app usage
- Normal operation in sandbox environment
```

### Milestone 2 Completion and PR/Blog

```
**Current Task:** Complete Milestone 2, create PR, and write second blog post

**Integration Testing:**
1. Full workflow testing
   - Ctrl+1 → activate zoom mode
   - Mouse wheel screen magnification
   - Mouse drag line drawing
   - ESC to exit mode

2. Performance testing
   - Measure zoom response time
   - Measure drawing performance
   - Check memory usage
   - Monitor CPU usage

**PR Creation:**
- Title: "Milestone 2: Zoom & Annotation Core Features"
- Attach screen recording demo
- Include performance benchmark results

**Blog Post:**
**Title:** "Implementing Real-time Screen Annotation System - Mastering NSBezierPath and Global Shortcuts"

**Key Content:**
- Metal vs Core Graphics performance comparison
- NSBezierPath optimization techniques
- Carbon RegisterEventHotKey sandbox application
- Real-time drawing performance tuning experience

**Next Milestone Preview:** Text annotations and timer features, SwiftUI settings UI
```

---

## ⚙️ Common Development Guidelines

### Code Quality Standards
```
**Swift Coding Conventions:**
- Comply with SwiftLint rules
- Clear variable/function naming
- Proper comments and documentation
- Code structuring using MARK:

**Architecture Principles:**
- MVC pattern (AppKit)
- Single responsibility principle
- Dependency injection
- Protocol-oriented programming

**Performance Standards:**
- Memory usage <50MB
- Zoom response time <100ms
- CPU usage <30% (during drawing)
- App startup time <3 seconds
```

### Testing Strategy
```
**Unit Testing:**
- Test all manager classes
- 100% business logic coverage
- Isolated testing using mock objects

**UI Testing:**
- Test major user scenarios
- Overlay window show/hide testing
- Shortcut functionality testing

**Performance Testing:**
- Performance measurement using XCTMetric
- Memory leak detection
- CPU/GPU usage monitoring
```

### GitHub Workflow
```
**Branch Strategy:**
- main: stable release
- develop: development integration
- feature/milestone-N-description: feature development

**PR Template:**
## Changes
- [ ] New feature implementation
- [ ] Bug fixes
- [ ] Performance improvements
- [ ] Documentation updates

## Test Results
- [ ] Unit tests pass
- [ ] UI tests pass
- [ ] Performance tests pass
- [ ] No memory leaks

## Screenshots/Videos
[Demo video or screenshots]

## Checklist
- [ ] Code review complete
- [ ] Documentation updated
- [ ] Changelog written

**Blog Post Structure:**
1. Overview and goals
2. Technical challenges
3. Core implementation details
4. Problem-solving process
5. Performance and test results
6. Lessons learned and insights
7. Next steps plan
```

### AI Prompt Usage
```
When starting each phase:
1. Copy the corresponding phase prompt
2. Add current project status information
3. Specify particular issues or requirements
4. Request step-by-step progress from AI

When problems occur during development:
"Currently [specific problem] has occurred.
Project: Magnify (macOS screen annotation app)
Environment: Xcode 16, macOS 14.x, Swift 5.9
Error details: [exact error message]
Attempted solutions: [what has been tried]
Please provide step-by-step solutions from a macOS development expert perspective."
```

---

## 📋 Milestone Checklists

### ✅ Milestone 1 Checklist
- [ ] Xcode project creation and setup
- [ ] App Sandbox + Screen Recording permission setup
- [ ] ScreenCaptureKit basic implementation
- [ ] Transparent overlay NSWindow system
- [ ] Unit test writing and passing
- [ ] GitHub PR creation and merge
- [ ] Blog post writing and publishing
- [ ] README.md update

### ⏳ Milestone 2 Checklist
- [ ] Real-time screen magnification/zoom feature
- [ ] NSBezierPath pen drawing system
- [ ] RegisterEventHotKey global shortcuts
- [ ] Performance optimization (goal achievement)
- [ ] Integration testing completion
- [ ] GitHub PR creation and merge
- [ ] Blog post writing and publishing

**Use these prompts to start Magnify development! Following each step carefully will help you complete a high-quality macOS app.** 🚀 