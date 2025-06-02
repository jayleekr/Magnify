import AppKit
import SwiftUI
import Combine

/// TimerOverlayWindow provides a floating timer display for presentations
/// Shows countdown/count-up timer with minimal, non-intrusive design
class TimerOverlayWindow: NSWindow {
    
    // MARK: - Properties
    
    private let timerManager = PresentationTimerManager.shared
    private let preferencesManager = PreferencesManager.shared
    private var timerContentView: TimerOverlayContentView!
    private var cancellables = Set<AnyCancellable>()
    
    // Window configuration
    private var overlayPosition: OverlayPosition = .topRight
    private var overlayOpacity: Double = 0.8
    private var isOverlayVisible: Bool = false
    
    // MARK: - Overlay Position Options
    
    enum OverlayPosition: String, CaseIterable {
        case topLeft = "Top Left"
        case topRight = "Top Right"
        case bottomLeft = "Bottom Left"
        case bottomRight = "Bottom Right"
        case center = "Center"
        
        var systemImage: String {
            switch self {
            case .topLeft: return "arrow.up.left"
            case .topRight: return "arrow.up.right"
            case .bottomLeft: return "arrow.down.left"
            case .bottomRight: return "arrow.down.right"
            case .center: return "dot.circle"
            }
        }
    }
    
    // MARK: - Initialization
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        setupWindow()
        setupContent()
        setupObservers()
    }
    
    convenience init() {
        let initialRect = NSRect(x: 0, y: 0, width: 200, height: 100)
        self.init(
            contentRect: initialRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
    }
    
    private func setupWindow() {
        // Configure window for overlay display
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.hasShadow = true
        self.level = .statusBar
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        // Load preferences
        loadOverlayPreferences()
        
        print("TimerOverlayWindow: Initialized floating timer overlay")
    }
    
    private func setupContent() {
        timerContentView = TimerOverlayContentView()
        timerContentView.timerManager = timerManager
        timerContentView.overlayWindow = self
        
        let hostingView = NSHostingView(rootView: timerContentView)
        hostingView.frame = self.frame
        
        self.contentView = hostingView
        
        // Set initial visibility
        self.alphaValue = CGFloat(overlayOpacity)
        self.isVisible = false
    }
    
    private func setupObservers() {
        // Observe timer state changes
        timerManager.$isTimerActive
            .sink { [weak self] isActive in
                DispatchQueue.main.async {
                    if isActive {
                        self?.showOverlay()
                    } else {
                        self?.hideOverlay()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observe preferences changes
        preferencesManager.$timerOverlayPosition
            .sink { [weak self] position in
                DispatchQueue.main.async {
                    self?.overlayPosition = position
                    self?.updateOverlayPosition()
                }
            }
            .store(in: &cancellables)
        
        preferencesManager.$timerOverlayOpacity
            .sink { [weak self] opacity in
                DispatchQueue.main.async {
                    self?.overlayOpacity = opacity
                    self?.alphaValue = CGFloat(opacity)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Overlay Management
    
    func showOverlay() {
        guard !isOverlayVisible else { return }
        
        updateOverlayPosition()
        self.alphaValue = CGFloat(overlayOpacity)
        self.orderFrontRegardless()
        isOverlayVisible = true
        
        print("TimerOverlayWindow: Timer overlay shown")
    }
    
    func hideOverlay() {
        guard isOverlayVisible else { return }
        
        self.orderOut(nil)
        isOverlayVisible = false
        
        print("TimerOverlayWindow: Timer overlay hidden")
    }
    
    func toggleOverlay() {
        if isOverlayVisible {
            hideOverlay()
        } else {
            showOverlay()
        }
    }
    
    // MARK: - Position Management
    
    private func updateOverlayPosition() {
        guard let screen = NSScreen.main else { return }
        
        let screenRect = screen.visibleFrame
        let windowSize = self.frame.size
        let margin: CGFloat = 20
        
        var newOrigin: CGPoint
        
        switch overlayPosition {
        case .topLeft:
            newOrigin = CGPoint(
                x: screenRect.minX + margin,
                y: screenRect.maxY - windowSize.height - margin
            )
        case .topRight:
            newOrigin = CGPoint(
                x: screenRect.maxX - windowSize.width - margin,
                y: screenRect.maxY - windowSize.height - margin
            )
        case .bottomLeft:
            newOrigin = CGPoint(
                x: screenRect.minX + margin,
                y: screenRect.minY + margin
            )
        case .bottomRight:
            newOrigin = CGPoint(
                x: screenRect.maxX - windowSize.width - margin,
                y: screenRect.minY + margin
            )
        case .center:
            newOrigin = CGPoint(
                x: screenRect.midX - windowSize.width / 2,
                y: screenRect.midY - windowSize.height / 2
            )
        }
        
        self.setFrameOrigin(newOrigin)
    }
    
    private func loadOverlayPreferences() {
        overlayPosition = preferencesManager.timerOverlayPosition
        overlayOpacity = preferencesManager.timerOverlayOpacity
    }
    
    // MARK: - Public Interface
    
    var currentPosition: OverlayPosition {
        return overlayPosition
    }
    
    var currentOpacity: Double {
        return overlayOpacity
    }
    
    func setPosition(_ position: OverlayPosition) {
        overlayPosition = position
        preferencesManager.timerOverlayPosition = position
        updateOverlayPosition()
    }
    
    func setOpacity(_ opacity: Double) {
        overlayOpacity = max(0.2, min(1.0, opacity))
        preferencesManager.timerOverlayOpacity = overlayOpacity
        self.alphaValue = CGFloat(overlayOpacity)
    }
}

// MARK: - SwiftUI Timer Content View

struct TimerOverlayContentView: View {
    
    @ObservedObject var timerManager = PresentationTimerManager.shared
    weak var overlayWindow: TimerOverlayWindow?
    
    @State private var isHovered = false
    @State private var showControls = false
    
    var body: some View {
        VStack(spacing: 0) {
            if timerManager.isTimerActive {
                timerDisplayView
                    .background(timerBackgroundColor)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isHovered = hovering
                        }
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showControls.toggle()
                        }
                    }
                
                if showControls && isHovered {
                    timerControlsView
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .frame(minWidth: 150, maxWidth: 250)
    }
    
    // MARK: - Timer Display
    
    private var timerDisplayView: some View {
        HStack(spacing: 12) {
            // Timer icon
            Image(systemName: timerManager.timerMode.systemImage)
                .font(.title2)
                .foregroundColor(timerIconColor)
                .scaleEffect(timerManager.isTimerActive ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: timerManager.isTimerActive)
            
            VStack(alignment: .leading, spacing: 2) {
                // Time display
                Text(timerManager.formatCurrentTime())
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(timerTextColor)
                
                // Timer type and status
                HStack(spacing: 4) {
                    Text(timerManager.timerType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if timerManager.isPaused {
                        Text("• PAUSED")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Timer Controls
    
    private var timerControlsView: some View {
        HStack(spacing: 8) {
            // Pause/Resume button
            Button(action: {
                if timerManager.isPaused {
                    timerManager.resumeTimer()
                } else {
                    timerManager.pauseTimer()
                }
            }) {
                Image(systemName: timerManager.isPaused ? "play.fill" : "pause.fill")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .buttonStyle(OverlayButtonStyle(color: .blue))
            
            // Add time button
            Button(action: {
                timerManager.addTime(60) // Add 1 minute
            }) {
                Image(systemName: "plus")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .buttonStyle(OverlayButtonStyle(color: .green))
            
            // Stop button
            Button(action: {
                timerManager.stopTimer()
            }) {
                Image(systemName: "stop.fill")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .buttonStyle(OverlayButtonStyle(color: .red))
            
            // Position button
            Button(action: {
                cyclePosition()
            }) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .buttonStyle(OverlayButtonStyle(color: .purple))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
    }
    
    // MARK: - Styling
    
    private var timerBackgroundColor: Color {
        switch timerManager.currentStatus {
        case .running:
            return Color.black.opacity(0.85)
        case .warning:
            return Color.orange.opacity(0.9)
        case .finished, .expired:
            return Color.red.opacity(0.9)
        case .paused:
            return Color.blue.opacity(0.85)
        default:
            return Color.gray.opacity(0.85)
        }
    }
    
    private var timerIconColor: Color {
        switch timerManager.currentStatus {
        case .running:
            return .green
        case .warning:
            return .yellow
        case .finished, .expired:
            return .red
        case .paused:
            return .orange
        default:
            return .blue
        }
    }
    
    private var timerTextColor: Color {
        switch timerManager.currentStatus {
        case .warning, .finished, .expired:
            return .white
        default:
            return .white
        }
    }
    
    // MARK: - Actions
    
    private func cyclePosition() {
        guard let window = overlayWindow else { return }
        
        let positions = TimerOverlayWindow.OverlayPosition.allCases
        let currentIndex = positions.firstIndex(of: window.currentPosition) ?? 0
        let nextIndex = (currentIndex + 1) % positions.count
        let nextPosition = positions[nextIndex]
        
        window.setPosition(nextPosition)
    }
}

// MARK: - Custom Button Style

struct OverlayButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preferences Extensions

extension PreferencesManager {
    var timerOverlayPosition: TimerOverlayWindow.OverlayPosition {
        get {
            let stored = UserDefaults.standard.string(forKey: "timerOverlayPosition") ?? "topRight"
            return TimerOverlayWindow.OverlayPosition(rawValue: stored) ?? .topRight
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "timerOverlayPosition")
        }
    }
    
    var timerOverlayOpacity: Double {
        get {
            let stored = UserDefaults.standard.double(forKey: "timerOverlayOpacity")
            return stored > 0 ? stored : 0.8
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "timerOverlayOpacity")
        }
    }
} 