import Foundation
import AVFoundation
import AppKit
import ScreenCaptureKit
import CoreMedia

/// ScreenRecordingManager provides comprehensive screen recording functionality
/// Supports video capture with annotation overlay, real-time recording controls, and export capabilities
class ScreenRecordingManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = ScreenRecordingManager()
    
    // MARK: - Published Properties
    
    @Published var isRecording: Bool = false
    @Published var isPaused: Bool = false
    @Published var recordingDuration: TimeInterval = 0.0
    @Published var recordingStatus: RecordingStatus = .idle
    @Published var currentRecordingURL: URL?
    @Published var availableFormats: [VideoFormat] = VideoFormat.allCases
    @Published var selectedFormat: VideoFormat = .mp4
    @Published var recordingQuality: RecordingQuality = .high
    @Published var includeAnnotations: Bool = true
    @Published var includeSystemAudio: Bool = false
    @Published var includeMicrophone: Bool = false
    
    // MARK: - Recording Status
    
    enum RecordingStatus: String, CaseIterable {
        case idle = "Ready to record"
        case preparing = "Preparing recording..."
        case recording = "Recording"
        case paused = "Recording paused"
        case stopping = "Stopping recording..."
        case processing = "Processing video..."
        case completed = "Recording completed"
        case error = "Recording error"
        
        var color: NSColor {
            switch self {
            case .idle: return .systemGray
            case .preparing: return .systemOrange
            case .recording: return .systemRed
            case .paused: return .systemYellow
            case .stopping: return .systemOrange
            case .processing: return .systemBlue
            case .completed: return .systemGreen
            case .error: return .systemRed
            }
        }
        
        var icon: String {
            switch self {
            case .idle: return "record.circle"
            case .preparing: return "clock"
            case .recording: return "record.circle.fill"
            case .paused: return "pause.circle.fill"
            case .stopping: return "stop.circle"
            case .processing: return "gear"
            case .completed: return "checkmark.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            }
        }
    }
    
    // MARK: - Video Formats
    
    enum VideoFormat: String, CaseIterable {
        case mp4 = "mp4"
        case mov = "mov"
        case avi = "avi"
        
        var displayName: String {
            switch self {
            case .mp4: return "MP4 (H.264)"
            case .mov: return "MOV (QuickTime)"
            case .avi: return "AVI (Uncompressed)"
            }
        }
        
        var fileExtension: String {
            return rawValue
        }
        
        var codecType: AVVideoCodecType {
            switch self {
            case .mp4, .mov: return .h264
            case .avi: return .hevc
            }
        }
        
        var containerType: AVFileType {
            switch self {
            case .mp4: return .mp4
            case .mov: return .mov
            case .avi: return .avi
            }
        }
    }
    
    // MARK: - Recording Quality
    
    enum RecordingQuality: String, CaseIterable {
        case low = "Low (720p)"
        case medium = "Medium (1080p)"
        case high = "High (1440p)"
        case ultra = "Ultra (4K)"
        
        var resolution: CGSize {
            switch self {
            case .low: return CGSize(width: 1280, height: 720)
            case .medium: return CGSize(width: 1920, height: 1080)
            case .high: return CGSize(width: 2560, height: 1440)
            case .ultra: return CGSize(width: 3840, height: 2160)
            }
        }
        
        var bitrate: Int {
            switch self {
            case .low: return 2_000_000      // 2 Mbps
            case .medium: return 5_000_000   // 5 Mbps
            case .high: return 10_000_000    // 10 Mbps
            case .ultra: return 20_000_000   // 20 Mbps
            }
        }
        
        var frameRate: Int {
            switch self {
            case .low: return 24
            case .medium: return 30
            case .high: return 30
            case .ultra: return 60
            }
        }
    }
    
    // MARK: - Core Components
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var audioOutput: AVCaptureAudioDataOutput?
    private var assetWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var audioWriterInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    private var screenInput: SCScreenInput?
    private var streamConfiguration: SCStreamConfiguration?
    private var captureEngine: SCStream?
    
    // MARK: - Timing and State
    
    private var recordingStartTime: Date?
    private var recordingTimer: Timer?
    private var frameCount: Int = 0
    private var recordingQueue = DispatchQueue(label: "com.magnify.recording", qos: .userInitiated)
    private var processingQueue = DispatchQueue(label: "com.magnify.processing", qos: .utility)
    
    // MARK: - Integration References
    
    private let screenCaptureManager = ScreenCaptureManager()
    private let drawingToolManager = DrawingToolManager.shared
    private let zoomManager = ZoomManager.shared
    private let preferencesManager = PreferencesManager.shared
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupRecordingEnvironment()
        setupNotifications()
        print("ScreenRecordingManager: Initialized comprehensive screen recording system")
    }
    
    private func setupRecordingEnvironment() {
        // Configure audio session for potential microphone recording
        do {
            #if os(macOS)
            // macOS doesn't use AVAudioSession the same way as iOS
            // Audio configuration will be handled during capture setup
            #endif
        } catch {
            print("ScreenRecordingManager: Audio session setup error: \(error)")
        }
        
        // Set default recording directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let recordingsPath = documentsPath.appendingPathComponent("Magnify Recordings", isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: recordingsPath, withIntermediateDirectories: true)
        } catch {
            print("ScreenRecordingManager: Failed to create recordings directory: \(error)")
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }
    
    @objc private func applicationWillTerminate() {
        if isRecording {
            stopRecording()
        }
    }
    
    // MARK: - Recording Control
    
    /// Start screen recording with current settings
    func startRecording() async -> Result<URL, RecordingError> {
        guard !isRecording else {
            return .failure(.alreadyRecording)
        }
        
        // Check permissions
        let hasPermission = await screenCaptureManager.hasScreenRecordingPermission()
        guard hasPermission else {
            return .failure(.permissionDenied)
        }
        
        DispatchQueue.main.async {
            self.recordingStatus = .preparing
        }
        
        do {
            // Set up recording session
            let outputURL = generateOutputURL()
            
            try await setupCaptureSession()
            try await setupAssetWriter(outputURL: outputURL)
            
            // Start capture
            try await startCaptureSession()
            
            DispatchQueue.main.async {
                self.isRecording = true
                self.isPaused = false
                self.recordingStatus = .recording
                self.currentRecordingURL = outputURL
                self.recordingStartTime = Date()
                self.frameCount = 0
                self.startRecordingTimer()
            }
            
            print("ScreenRecordingManager: Recording started successfully")
            return .success(outputURL)
            
        } catch {
            DispatchQueue.main.async {
                self.recordingStatus = .error
            }
            print("ScreenRecordingManager: Failed to start recording: \(error)")
            return .failure(.setupFailed(error))
        }
    }
    
    /// Stop current recording
    func stopRecording() async -> Result<URL, RecordingError> {
        guard isRecording else {
            return .failure(.notRecording)
        }
        
        DispatchQueue.main.async {
            self.recordingStatus = .stopping
        }
        
        let outputURL = currentRecordingURL
        
        do {
            // Stop capture session
            try await stopCaptureSession()
            
            // Finalize asset writer
            try await finalizeAssetWriter()
            
            DispatchQueue.main.async {
                self.isRecording = false
                self.isPaused = false
                self.recordingStatus = .processing
                self.stopRecordingTimer()
            }
            
            // Process final video with annotations if enabled
            if includeAnnotations {
                return await processVideoWithAnnotations(sourceURL: outputURL!)
            } else {
                DispatchQueue.main.async {
                    self.recordingStatus = .completed
                }
                return .success(outputURL!)
            }
            
        } catch {
            DispatchQueue.main.async {
                self.recordingStatus = .error
            }
            print("ScreenRecordingManager: Failed to stop recording: \(error)")
            return .failure(.stopFailed(error))
        }
    }
    
    /// Pause current recording
    func pauseRecording() {
        guard isRecording && !isPaused else { return }
        
        captureEngine?.stopCapture()
        
        DispatchQueue.main.async {
            self.isPaused = true
            self.recordingStatus = .paused
        }
        
        print("ScreenRecordingManager: Recording paused")
    }
    
    /// Resume paused recording
    func resumeRecording() async {
        guard isRecording && isPaused else { return }
        
        do {
            try await captureEngine?.startCapture()
            
            DispatchQueue.main.async {
                self.isPaused = false
                self.recordingStatus = .recording
            }
            
            print("ScreenRecordingManager: Recording resumed")
        } catch {
            print("ScreenRecordingManager: Failed to resume recording: \(error)")
        }
    }
    
    // MARK: - Capture Session Setup
    
    private func setupCaptureSession() async throws {
        // Get available displays
        let availableDisplays = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        
        guard let display = availableDisplays.displays.first else {
            throw RecordingError.noDisplayAvailable
        }
        
        // Configure stream
        streamConfiguration = SCStreamConfiguration()
        streamConfiguration?.width = Int(recordingQuality.resolution.width)
        streamConfiguration?.height = Int(recordingQuality.resolution.height)
        streamConfiguration?.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(recordingQuality.frameRate))
        streamConfiguration?.queueDepth = 5
        streamConfiguration?.showsCursor = true
        streamConfiguration?.scalesToFit = true
        streamConfiguration?.colorFormat = .ARGB8888
        
        // Create content filter
        let filter = SCContentFilter(display: display, excludingWindows: [])
        
        // Create stream
        captureEngine = SCStream(filter: filter, configuration: streamConfiguration!, delegate: self)
        
        print("ScreenRecordingManager: Capture session configured")
    }
    
    private func startCaptureSession() async throws {
        guard let captureEngine = captureEngine else {
            throw RecordingError.setupFailed(NSError(domain: "ScreenRecording", code: -1, userInfo: [NSLocalizedDescriptionKey: "Capture engine not configured"]))
        }
        
        try await captureEngine.startCapture()
        print("ScreenRecordingManager: Capture session started")
    }
    
    private func stopCaptureSession() async throws {
        try await captureEngine?.stopCapture()
        captureEngine = nil
        print("ScreenRecordingManager: Capture session stopped")
    }
    
    // MARK: - Asset Writer Setup
    
    private func setupAssetWriter(outputURL: URL) async throws {
        // Remove existing file if present
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        
        // Create asset writer
        assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: selectedFormat.containerType)
        
        // Configure video input
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: selectedFormat.codecType,
            AVVideoWidthKey: recordingQuality.resolution.width,
            AVVideoHeightKey: recordingQuality.resolution.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: recordingQuality.bitrate,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel
            ]
        ]
        
        videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoWriterInput?.expectsMediaDataInRealTime = true
        
        // Set up pixel buffer adaptor
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: recordingQuality.resolution.width,
            kCVPixelBufferHeightKey as String: recordingQuality.resolution.height
        ]
        
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoWriterInput!,
            sourcePixelBufferAttributes: pixelBufferAttributes
        )
        
        guard assetWriter!.canAdd(videoWriterInput!) else {
            throw RecordingError.setupFailed(NSError(domain: "ScreenRecording", code: -2, userInfo: [NSLocalizedDescriptionKey: "Cannot add video input"]))
        }
        
        assetWriter!.add(videoWriterInput!)
        
        // Set up audio input if enabled
        if includeSystemAudio || includeMicrophone {
            try setupAudioInput()
        }
        
        // Start writing session
        guard assetWriter!.startWriting() else {
            throw RecordingError.setupFailed(assetWriter!.error!)
        }
        
        assetWriter!.startSession(atSourceTime: .zero)
        
        print("ScreenRecordingManager: Asset writer configured and started")
    }
    
    private func setupAudioInput() throws {
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 128000
        ]
        
        audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioWriterInput?.expectsMediaDataInRealTime = true
        
        guard assetWriter!.canAdd(audioWriterInput!) else {
            throw RecordingError.setupFailed(NSError(domain: "ScreenRecording", code: -3, userInfo: [NSLocalizedDescriptionKey: "Cannot add audio input"]))
        }
        
        assetWriter!.add(audioWriterInput!)
        print("ScreenRecordingManager: Audio input configured")
    }
    
    private func finalizeAssetWriter() async throws {
        guard let assetWriter = assetWriter else { return }
        
        videoWriterInput?.markAsFinished()
        audioWriterInput?.markAsFinished()
        
        await assetWriter.finishWriting()
        
        if assetWriter.status == .failed {
            throw RecordingError.exportFailed(assetWriter.error!)
        }
        
        self.assetWriter = nil
        self.videoWriterInput = nil
        self.audioWriterInput = nil
        self.pixelBufferAdaptor = nil
        
        print("ScreenRecordingManager: Asset writer finalized")
    }
    
    // MARK: - Annotation Overlay Processing
    
    private func processVideoWithAnnotations(sourceURL: URL) async -> Result<URL, RecordingError> {
        DispatchQueue.main.async {
            self.recordingStatus = .processing
        }
        
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                do {
                    let outputURL = self.generateAnnotatedOutputURL()
                    
                    // Create composition
                    let composition = AVMutableComposition()
                    let videoComposition = AVMutableVideoComposition()
                    
                    // Add source video track
                    let asset = AVAsset(url: sourceURL)
                    guard let videoTrack = asset.tracks(withMediaType: .video).first else {
                        continuation.resume(returning: .failure(.exportFailed(NSError(domain: "ScreenRecording", code: -4, userInfo: [NSLocalizedDescriptionKey: "No video track found"]))))
                        return
                    }
                    
                    let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
                    try compositionVideoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
                    
                    // Create overlay layer with annotations
                    let overlayLayer = self.createAnnotationOverlayLayer(size: videoTrack.naturalSize)
                    
                    // Set up video composition with overlay
                    videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
                    videoComposition.renderSize = videoTrack.naturalSize
                    
                    let instruction = AVMutableVideoCompositionInstruction()
                    instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
                    
                    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack!)
                    instruction.layerInstructions = [layerInstruction]
                    
                    videoComposition.instructions = [instruction]
                    videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: CALayer(), in: overlayLayer)
                    
                    // Export composition
                    guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
                        continuation.resume(returning: .failure(.exportFailed(NSError(domain: "ScreenRecording", code: -5, userInfo: [NSLocalizedDescriptionKey: "Cannot create export session"]))))
                        return
                    }
                    
                    exportSession.outputURL = outputURL
                    exportSession.outputFileType = self.selectedFormat.containerType
                    exportSession.videoComposition = videoComposition
                    
                    exportSession.exportAsynchronously {
                        DispatchQueue.main.async {
                            if exportSession.status == .completed {
                                self.recordingStatus = .completed
                                continuation.resume(returning: .success(outputURL))
                            } else {
                                self.recordingStatus = .error
                                continuation.resume(returning: .failure(.exportFailed(exportSession.error!)))
                            }
                        }
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        self.recordingStatus = .error
                    }
                    continuation.resume(returning: .failure(.exportFailed(error)))
                }
            }
        }
    }
    
    private func createAnnotationOverlayLayer(size: CGSize) -> CALayer {
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: size)
        overlayLayer.backgroundColor = NSColor.clear.cgColor
        
        // Add drawing elements from DrawingToolManager
        let drawingElements = drawingToolManager.allDrawingElements
        for element in drawingElements {
            let elementLayer = createLayerFromDrawingElement(element, canvasSize: size)
            overlayLayer.addSublayer(elementLayer)
        }
        
        // Add zoom indicator if zoom is active
        if zoomManager.isZooming {
            let zoomIndicator = createZoomIndicatorLayer(size: size)
            overlayLayer.addSublayer(zoomIndicator)
        }
        
        return overlayLayer
    }
    
    private func createLayerFromDrawingElement(_ element: DrawingToolManager.DrawingElement, canvasSize: CGSize) -> CALayer {
        let layer = CAShapeLayer()
        layer.frame = CGRect(origin: .zero, size: canvasSize)
        
        if element.tool == .text {
            // Handle text elements
            let textLayer = CATextLayer()
            textLayer.frame = CGRect(origin: element.textPosition ?? .zero, size: CGSize(width: 200, height: 50))
            textLayer.string = element.text ?? ""
            textLayer.fontSize = element.font?.pointSize ?? 16
            textLayer.foregroundColor = element.textColor?.cgColor ?? NSColor.black.cgColor
            return textLayer
        } else {
            // Handle path-based elements
            layer.path = element.path.cgPath
            layer.strokeColor = element.color.cgColor
            layer.lineWidth = element.strokeWidth
            layer.fillColor = element.fillColor?.cgColor ?? NSColor.clear.cgColor
            return layer
        }
    }
    
    private func createZoomIndicatorLayer(size: CGSize) -> CALayer {
        let indicator = CAShapeLayer()
        indicator.frame = CGRect(origin: .zero, size: size)
        
        // Create zoom indicator shape (e.g., magnifying glass icon)
        let path = NSBezierPath()
        let center = CGPoint(x: size.width - 50, y: size.height - 50)
        path.appendOval(in: CGRect(x: center.x - 15, y: center.y - 15, width: 30, height: 30))
        
        indicator.path = path.cgPath
        indicator.strokeColor = NSColor.white.cgColor
        indicator.lineWidth = 2
        indicator.fillColor = NSColor.clear.cgColor
        
        return indicator
    }
    
    // MARK: - Utility Functions
    
    private func generateOutputURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let recordingsPath = documentsPath.appendingPathComponent("Magnify Recordings", isDirectory: true)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        
        let filename = "Magnify_Recording_\(timestamp).\(selectedFormat.fileExtension)"
        return recordingsPath.appendingPathComponent(filename)
    }
    
    private func generateAnnotatedOutputURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let recordingsPath = documentsPath.appendingPathComponent("Magnify Recordings", isDirectory: true)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        
        let filename = "Magnify_Recording_Annotated_\(timestamp).\(selectedFormat.fileExtension)"
        return recordingsPath.appendingPathComponent(filename)
    }
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let startTime = self.recordingStartTime {
                DispatchQueue.main.async {
                    self.recordingDuration = Date().timeIntervalSince(startTime)
                }
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    // MARK: - Public Properties
    
    var isReadyToRecord: Bool {
        return !isRecording && recordingStatus != .error
    }
    
    var formattedDuration: String {
        let hours = Int(recordingDuration) / 3600
        let minutes = Int(recordingDuration) % 3600 / 60
        let seconds = Int(recordingDuration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var estimatedFileSize: String {
        let bytesPerSecond = Double(recordingQuality.bitrate) / 8.0
        let estimatedBytes = bytesPerSecond * recordingDuration
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        
        return formatter.string(fromByteCount: Int64(estimatedBytes))
    }
    
    // MARK: - Error Types
    
    enum RecordingError: LocalizedError {
        case permissionDenied
        case alreadyRecording
        case notRecording
        case noDisplayAvailable
        case setupFailed(Error)
        case stopFailed(Error)
        case exportFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Screen recording permission denied"
            case .alreadyRecording:
                return "Recording is already in progress"
            case .notRecording:
                return "No recording in progress"
            case .noDisplayAvailable:
                return "No display available for recording"
            case .setupFailed(let error):
                return "Failed to setup recording: \(error.localizedDescription)"
            case .stopFailed(let error):
                return "Failed to stop recording: \(error.localizedDescription)"
            case .exportFailed(let error):
                return "Failed to export recording: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - SCStreamDelegate

extension ScreenRecordingManager: SCStreamDelegate {
    
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("ScreenRecordingManager: Stream stopped with error: \(error)")
        DispatchQueue.main.async {
            self.recordingStatus = .error
            self.isRecording = false
        }
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        switch type {
        case .screen:
            processVideoSample(sampleBuffer)
        case .audio:
            processAudioSample(sampleBuffer)
        @unknown default:
            break
        }
    }
    
    private func processVideoSample(_ sampleBuffer: CMSampleBuffer) {
        guard let videoWriterInput = videoWriterInput,
              let pixelBufferAdaptor = pixelBufferAdaptor,
              videoWriterInput.isReadyForMoreMediaData else {
            return
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        recordingQueue.async {
            if self.includeAnnotations {
                // Overlay annotations on the pixel buffer
                let annotatedBuffer = self.overlayAnnotationsOnPixelBuffer(pixelBuffer)
                pixelBufferAdaptor.append(annotatedBuffer, withPresentationTime: timestamp)
            } else {
                pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: timestamp)
            }
            
            self.frameCount += 1
        }
    }
    
    private func processAudioSample(_ sampleBuffer: CMSampleBuffer) {
        guard let audioWriterInput = audioWriterInput,
              audioWriterInput.isReadyForMoreMediaData else {
            return
        }
        
        recordingQueue.async {
            audioWriterInput.append(sampleBuffer)
        }
    }
    
    private func overlayAnnotationsOnPixelBuffer(_ sourceBuffer: CVPixelBuffer) -> CVPixelBuffer {
        // For real-time overlay, we'll use the original buffer
        // More complex overlay processing would happen here
        return sourceBuffer
    }
} 