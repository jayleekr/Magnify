import Foundation
import AppKit
import QuartzCore
import Accelerate

/// AdvancedDrawingEffects provides sophisticated visual effects and filters for annotations
/// Includes shadows, glows, patterns, gradients, and advanced compositing effects
class AdvancedDrawingEffects {
    
    // MARK: - Effect Types
    
    enum EffectType: String, CaseIterable {
        case dropShadow = "Drop Shadow"
        case outerGlow = "Outer Glow"
        case innerGlow = "Inner Glow"
        case bevelEmboss = "Bevel & Emboss"
        case gradientOverlay = "Gradient Overlay"
        case patternOverlay = "Pattern Overlay"
        case stroke = "Stroke"
        case colorOverlay = "Color Overlay"
        
        var systemImage: String {
            switch self {
            case .dropShadow: return "shadow"
            case .outerGlow: return "circle.dashed"
            case .innerGlow: return "circle.dashed.inset.filled"
            case .bevelEmboss: return "cube"
            case .gradientOverlay: return "circle.lefthalf.filled"
            case .patternOverlay: return "checkboard.shield"
            case .stroke: return "pencil.circle"
            case .colorOverlay: return "paintbrush.fill"
            }
        }
    }
    
    // MARK: - Effect Parameters
    
    struct EffectParameters {
        // Common parameters
        var isEnabled: Bool = true
        var blendMode: CGBlendMode = .normal
        var opacity: CGFloat = 1.0
        
        // Shadow/Glow parameters
        var color: NSColor = .black
        var distance: CGFloat = 5.0
        var spread: CGFloat = 0.0
        var size: CGFloat = 5.0
        var angle: CGFloat = 135.0
        
        // Bevel/Emboss parameters
        var depth: CGFloat = 1.0
        var direction: BevelDirection = .up
        var highlightMode: CGBlendMode = .normal
        var shadowMode: CGBlendMode = .multiply
        var highlightColor: NSColor = .white
        var shadowColor: NSColor = .black
        
        // Gradient parameters
        var gradientType: GradientType = .linear
        var gradientColors: [NSColor] = [.black, .white]
        var gradientLocations: [CGFloat] = [0.0, 1.0]
        var gradientAngle: CGFloat = 0.0
        var gradientScale: CGFloat = 1.0
        
        // Pattern parameters
        var patternType: PatternType = .dots
        var patternScale: CGFloat = 1.0
        var patternSpacing: CGFloat = 10.0
        
        // Stroke parameters
        var strokeWidth: CGFloat = 1.0
        var strokePosition: StrokePosition = .outside
        
        enum BevelDirection {
            case up, down
        }
        
        enum GradientType {
            case linear, radial, angle, reflected, diamond
        }
        
        enum PatternType {
            case dots, lines, crosshatch, checkerboard, waves
        }
        
        enum StrokePosition {
            case inside, center, outside
        }
    }
    
    // MARK: - Singleton
    
    static let shared = AdvancedDrawingEffects()
    
    // MARK: - Properties
    
    private var effectsCache: [String: CIFilter] = [:]
    private let ciContext: CIContext
    
    // MARK: - Initialization
    
    private init() {
        self.ciContext = CIContext(options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])
        setupFilters()
        print("AdvancedDrawingEffects: Initialized with Core Image support")
    }
    
    // MARK: - Effect Application
    
    func applyEffect(_ effectType: EffectType, to path: NSBezierPath, with parameters: EffectParameters) -> NSBezierPath {
        switch effectType {
        case .dropShadow:
            return applyDropShadow(to: path, parameters: parameters)
        case .outerGlow:
            return applyOuterGlow(to: path, parameters: parameters)
        case .innerGlow:
            return applyInnerGlow(to: path, parameters: parameters)
        case .bevelEmboss:
            return applyBevelEmboss(to: path, parameters: parameters)
        case .gradientOverlay:
            return applyGradientOverlay(to: path, parameters: parameters)
        case .patternOverlay:
            return applyPatternOverlay(to: path, parameters: parameters)
        case .stroke:
            return applyStroke(to: path, parameters: parameters)
        case .colorOverlay:
            return applyColorOverlay(to: path, parameters: parameters)
        }
    }
    
    func applyEffectToImage(_ effectType: EffectType, to image: NSImage, with parameters: EffectParameters) -> NSImage? {
        guard let ciImage = CIImage(data: image.tiffRepresentation!) else { return nil }
        
        let filteredImage: CIImage?
        
        switch effectType {
        case .dropShadow:
            filteredImage = applyDropShadowFilter(to: ciImage, parameters: parameters)
        case .outerGlow:
            filteredImage = applyGlowFilter(to: ciImage, parameters: parameters)
        case .bevelEmboss:
            filteredImage = applyBevelEmbossFilter(to: ciImage, parameters: parameters)
        case .gradientOverlay:
            filteredImage = applyGradientOverlayFilter(to: ciImage, parameters: parameters)
        default:
            filteredImage = ciImage
        }
        
        guard let outputImage = filteredImage,
              let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: image.size)
    }
    
    // MARK: - Path-based Effects
    
    private func applyDropShadow(to path: NSBezierPath, parameters: EffectParameters) -> NSBezierPath {
        let shadowPath = path.copy() as! NSBezierPath
        
        // Calculate shadow offset
        let angleRad = parameters.angle * .pi / 180.0
        let offsetX = cos(angleRad) * parameters.distance
        let offsetY = sin(angleRad) * parameters.distance
        
        // Apply shadow transform
        let shadowTransform = AffineTransform(translationByX: offsetX, byY: offsetY)
        shadowPath.transform(using: shadowTransform)
        
        return shadowPath
    }
    
    private func applyOuterGlow(to path: NSBezierPath, parameters: EffectParameters) -> NSBezierPath {
        let glowPath = path.copy() as! NSBezierPath
        glowPath.lineWidth = path.lineWidth + (parameters.size * 2)
        return glowPath
    }
    
    private func applyInnerGlow(to path: NSBezierPath, parameters: EffectParameters) -> NSBezierPath {
        let glowPath = path.copy() as! NSBezierPath
        let insetAmount = max(1.0, parameters.size * 0.5)
        
        // Create inset path for inner glow effect
        if let insetPath = createInsetPath(from: path, insetBy: insetAmount) {
            return insetPath
        }
        
        return glowPath
    }
    
    private func applyBevelEmboss(to path: NSBezierPath, parameters: EffectParameters) -> NSBezierPath {
        let bevelPath = path.copy() as! NSBezierPath
        
        // Create highlight and shadow paths for bevel effect
        let highlightOffset = parameters.depth * (parameters.direction == .up ? 1 : -1)
        let shadowOffset = parameters.depth * (parameters.direction == .up ? -1 : 1)
        
        // Apply subtle offset for 3D effect
        let highlightTransform = AffineTransform(translationByX: highlightOffset, byY: highlightOffset)
        bevelPath.transform(using: highlightTransform)
        
        return bevelPath
    }
    
    private func applyGradientOverlay(to path: NSBezierPath, parameters: EffectParameters) -> NSBezierPath {
        // Gradient overlay doesn't modify the path geometry
        return path
    }
    
    private func applyPatternOverlay(to path: NSBezierPath, parameters: EffectParameters) -> NSBezierPath {
        // Pattern overlay doesn't modify the path geometry
        return path
    }
    
    private func applyStroke(to path: NSBezierPath, parameters: EffectParameters) -> NSBezierPath {
        let strokePath = path.copy() as! NSBezierPath
        
        switch parameters.strokePosition {
        case .inside:
            strokePath.lineWidth = path.lineWidth
        case .center:
            strokePath.lineWidth = path.lineWidth + parameters.strokeWidth
        case .outside:
            strokePath.lineWidth = path.lineWidth + (parameters.strokeWidth * 2)
        }
        
        return strokePath
    }
    
    private func applyColorOverlay(to path: NSBezierPath, parameters: EffectParameters) -> NSBezierPath {
        // Color overlay doesn't modify the path geometry
        return path
    }
    
    // MARK: - Core Image Filters
    
    private func setupFilters() {
        // Setup reusable Core Image filters
        effectsCache["dropShadow"] = CIFilter(name: "CIDropShadow")
        effectsCache["glow"] = CIFilter(name: "CIBloom")
        effectsCache["bevel"] = CIFilter(name: "CIBumpDistortion")
        effectsCache["gradient"] = CIFilter(name: "CILinearGradient")
        
        print("AdvancedDrawingEffects: Core Image filters initialized")
    }
    
    private func applyDropShadowFilter(to image: CIImage, parameters: EffectParameters) -> CIImage? {
        guard let filter = effectsCache["dropShadow"] else { return image }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(parameters.distance, forKey: kCIInputRadiusKey)
        filter.setValue(CIColor(color: parameters.color), forKey: "inputColor")
        
        return filter.outputImage
    }
    
    private func applyGlowFilter(to image: CIImage, parameters: EffectParameters) -> CIImage? {
        guard let filter = effectsCache["glow"] else { return image }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(parameters.size, forKey: kCIInputRadiusKey)
        filter.setValue(NSNumber(value: Float(parameters.opacity)), forKey: kCIInputIntensityKey)
        
        return filter.outputImage
    }
    
    private func applyBevelEmbossFilter(to image: CIImage, parameters: EffectParameters) -> CIImage? {
        guard let filter = effectsCache["bevel"] else { return image }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(parameters.depth * 10, forKey: kCIInputRadiusKey)
        filter.setValue(NSNumber(value: Float(parameters.depth)), forKey: kCIInputScaleKey)
        
        return filter.outputImage
    }
    
    private func applyGradientOverlayFilter(to image: CIImage, parameters: EffectParameters) -> CIImage? {
        guard let filter = effectsCache["gradient"] else { return image }
        
        let startColor = CIColor(color: parameters.gradientColors.first ?? .black)
        let endColor = CIColor(color: parameters.gradientColors.last ?? .white)
        
        filter.setValue(startColor, forKey: "inputColor0")
        filter.setValue(endColor, forKey: "inputColor1")
        
        return filter.outputImage
    }
    
    // MARK: - Pattern Generation
    
    func createPattern(_ patternType: EffectParameters.PatternType, scale: CGFloat, spacing: CGFloat, color: NSColor) -> NSImage? {
        let patternSize = CGSize(width: spacing * scale, height: spacing * scale)
        let image = NSImage(size: patternSize)
        
        image.lockFocus()
        
        let context = NSGraphicsContext.current?.cgContext
        context?.setFillColor(color.cgColor)
        
        switch patternType {
        case .dots:
            drawDotsPattern(in: CGRect(origin: .zero, size: patternSize), spacing: spacing)
        case .lines:
            drawLinesPattern(in: CGRect(origin: .zero, size: patternSize), spacing: spacing)
        case .crosshatch:
            drawCrosshatchPattern(in: CGRect(origin: .zero, size: patternSize), spacing: spacing)
        case .checkerboard:
            drawCheckerboardPattern(in: CGRect(origin: .zero, size: patternSize), spacing: spacing)
        case .waves:
            drawWavesPattern(in: CGRect(origin: .zero, size: patternSize), spacing: spacing)
        }
        
        image.unlockFocus()
        return image
    }
    
    private func drawDotsPattern(in rect: CGRect, spacing: CGFloat) {
        let context = NSGraphicsContext.current?.cgContext
        let dotSize = spacing * 0.3
        let centerX = rect.midX
        let centerY = rect.midY
        
        context?.fillEllipse(in: CGRect(
            x: centerX - dotSize/2,
            y: centerY - dotSize/2,
            width: dotSize,
            height: dotSize
        ))
    }
    
    private func drawLinesPattern(in rect: CGRect, spacing: CGFloat) {
        let context = NSGraphicsContext.current?.cgContext
        let lineWidth = spacing * 0.1
        
        context?.setLineWidth(lineWidth)
        context?.move(to: CGPoint(x: 0, y: rect.midY))
        context?.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        context?.strokePath()
    }
    
    private func drawCrosshatchPattern(in rect: CGRect, spacing: CGFloat) {
        drawLinesPattern(in: rect, spacing: spacing)
        
        let context = NSGraphicsContext.current?.cgContext
        let lineWidth = spacing * 0.1
        
        context?.setLineWidth(lineWidth)
        context?.move(to: CGPoint(x: rect.midX, y: 0))
        context?.addLine(to: CGPoint(x: rect.midX, y: rect.height))
        context?.strokePath()
    }
    
    private func drawCheckerboardPattern(in rect: CGRect, spacing: CGFloat) {
        let context = NSGraphicsContext.current?.cgContext
        let squareSize = spacing * 0.5
        
        context?.fill(CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
        context?.fill(CGRect(x: squareSize, y: squareSize, width: squareSize, height: squareSize))
    }
    
    private func drawWavesPattern(in rect: CGRect, spacing: CGFloat) {
        let context = NSGraphicsContext.current?.cgContext
        let amplitude = spacing * 0.2
        let frequency = 2.0 * .pi / spacing
        
        context?.setLineWidth(spacing * 0.1)
        context?.move(to: CGPoint(x: 0, y: rect.midY))
        
        for x in stride(from: 0, to: rect.width, by: 1) {
            let y = rect.midY + amplitude * sin(frequency * x)
            context?.addLine(to: CGPoint(x: x, y: y))
        }
        
        context?.strokePath()
    }
    
    // MARK: - Gradient Generation
    
    func createGradient(type: EffectParameters.GradientType, colors: [NSColor], locations: [CGFloat], angle: CGFloat = 0) -> NSGradient? {
        guard colors.count == locations.count else { return nil }
        
        return NSGradient(colors: colors, atLocations: locations, colorSpace: .deviceRGB)
    }
    
    func drawGradient(_ gradient: NSGradient, in rect: CGRect, type: EffectParameters.GradientType, angle: CGFloat = 0) {
        switch type {
        case .linear:
            let angleRad = angle * .pi / 180.0
            let startPoint = CGPoint(x: rect.minX, y: rect.midY)
            let endPoint = CGPoint(
                x: rect.minX + cos(angleRad) * rect.width,
                y: rect.midY + sin(angleRad) * rect.height
            )
            gradient.draw(from: startPoint, to: endPoint, options: [])
            
        case .radial:
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(rect.width, rect.height) / 2
            gradient.draw(in: rect, relativeCenterPosition: NSPoint.zero)
            
        case .angle:
            // Custom angle gradient implementation
            drawAngleGradient(gradient, in: rect, angle: angle)
            
        case .reflected:
            drawReflectedGradient(gradient, in: rect, angle: angle)
            
        case .diamond:
            drawDiamondGradient(gradient, in: rect)
        }
    }
    
    private func drawAngleGradient(_ gradient: NSGradient, in rect: CGRect, angle: CGFloat) {
        // Implementation for angle/conical gradient
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = max(rect.width, rect.height) / 2
        
        // This would require custom Core Graphics implementation
        // For now, fall back to radial gradient
        gradient.draw(in: rect, relativeCenterPosition: NSPoint.zero)
    }
    
    private func drawReflectedGradient(_ gradient: NSGradient, in rect: CGRect, angle: CGFloat) {
        // Implementation for reflected gradient
        let angleRad = angle * .pi / 180.0
        let startPoint = CGPoint(x: rect.midX, y: rect.midY)
        let endPoint = CGPoint(
            x: rect.midX + cos(angleRad) * rect.width / 2,
            y: rect.midY + sin(angleRad) * rect.height / 2
        )
        
        gradient.draw(from: startPoint, to: endPoint, options: [])
        gradient.draw(from: startPoint, to: CGPoint(
            x: rect.midX - cos(angleRad) * rect.width / 2,
            y: rect.midY - sin(angleRad) * rect.height / 2
        ), options: [])
    }
    
    private func drawDiamondGradient(_ gradient: NSGradient, in rect: CGRect) {
        // Implementation for diamond gradient
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let size = min(rect.width, rect.height) / 2
        
        // Create diamond path
        let diamondPath = NSBezierPath()
        diamondPath.move(to: CGPoint(x: center.x, y: center.y - size))
        diamondPath.line(to: CGPoint(x: center.x + size, y: center.y))
        diamondPath.line(to: CGPoint(x: center.x, y: center.y + size))
        diamondPath.line(to: CGPoint(x: center.x - size, y: center.y))
        diamondPath.close()
        
        // Clip to diamond and draw radial gradient
        diamondPath.addClip()
        gradient.draw(in: rect, relativeCenterPosition: NSPoint.zero)
    }
    
    // MARK: - Utility Methods
    
    private func createInsetPath(from path: NSBezierPath, insetBy amount: CGFloat) -> NSBezierPath? {
        // Create an inset path for inner glow effects
        // This is a simplified implementation - a full implementation would use path offsetting
        let insetPath = path.copy() as! NSBezierPath
        let transform = AffineTransform(scaleByX: 0.9, byY: 0.9)
        insetPath.transform(using: transform)
        return insetPath
    }
    
    func previewEffect(_ effectType: EffectType, parameters: EffectParameters) -> NSImage? {
        // Generate a preview image showing the effect
        let previewSize = CGSize(width: 100, height: 60)
        let image = NSImage(size: previewSize)
        
        image.lockFocus()
        
        // Draw a sample shape with the effect
        let sampleRect = CGRect(x: 20, y: 20, width: 60, height: 20)
        let samplePath = NSBezierPath(roundedRect: sampleRect, xRadius: 5, yRadius: 5)
        
        NSColor.systemBlue.setFill()
        samplePath.fill()
        
        // Apply effect (simplified for preview)
        let effectPath = applyEffect(effectType, to: samplePath, with: parameters)
        parameters.color.setStroke()
        effectPath.stroke()
        
        image.unlockFocus()
        
        return image
    }
}

// MARK: - Effect Presets

extension AdvancedDrawingEffects {
    
    static func defaultDropShadowPreset() -> EffectParameters {
        var params = EffectParameters()
        params.color = NSColor.black.withAlphaComponent(0.5)
        params.distance = 5.0
        params.size = 5.0
        params.angle = 135.0
        return params
    }
    
    static func defaultGlowPreset() -> EffectParameters {
        var params = EffectParameters()
        params.color = NSColor.systemBlue.withAlphaComponent(0.8)
        params.size = 10.0
        params.spread = 2.0
        return params
    }
    
    static func defaultBevelPreset() -> EffectParameters {
        var params = EffectParameters()
        params.depth = 3.0
        params.direction = .up
        params.highlightColor = NSColor.white.withAlphaComponent(0.8)
        params.shadowColor = NSColor.black.withAlphaComponent(0.4)
        return params
    }
} 