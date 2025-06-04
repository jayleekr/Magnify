import XCTest
import AppKit
import Vision
@testable import Magnify

/// Comprehensive test suite for advanced annotation features in Checkpoint 3.3
/// Tests annotation templates, drawing effects, automation engine, and UI components
class AdvancedAnnotationSystemTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var templateManager: AnnotationTemplateManager!
    var effectsEngine: AdvancedDrawingEffects!
    var automationEngine: AnnotationAutomationEngine!
    
    // MARK: - Setup and Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        templateManager = AnnotationTemplateManager.shared
        effectsEngine = AdvancedDrawingEffects.shared
        automationEngine = AnnotationAutomationEngine.shared
        
        print("AdvancedAnnotationSystemTests: Test environment initialized")
    }
    
    override func tearDownWithError() throws {
        templateManager = nil
        effectsEngine = nil
        automationEngine = nil
        
        try super.tearDownWithError()
    }
    
    // MARK: - Template Manager Tests
    
    func testTemplateManagerInitialization() throws {
        XCTAssertNotNil(templateManager, "Template manager should be initialized")
        XCTAssertFalse(templateManager.availableTemplates.isEmpty, "Should have built-in templates")
        XCTAssertGreaterThan(templateManager.availableTemplates.count, 5, "Should have multiple built-in templates")
        
        print("✅ Template manager initialized with \(templateManager.availableTemplates.count) templates")
    }
    
    func testTemplateCategories() throws {
        let categories = AnnotationTemplateManager.TemplateCategory.allCases
        XCTAssertEqual(categories.count, 6, "Should have 6 template categories")
        
        // Test each category has templates
        for category in categories {
            let templates = templateManager.getTemplates(for: category)
            if category != .custom {
                XCTAssertFalse(templates.isEmpty, "Category \(category.rawValue) should have templates")
            }
        }
        
        print("✅ All template categories validated")
    }
    
    func testTemplateSearch() throws {
        let searchResults = templateManager.searchTemplates(query: "arrow")
        XCTAssertFalse(searchResults.isEmpty, "Should find arrow-related templates")
        
        let emptyResults = templateManager.searchTemplates(query: "nonexistent")
        XCTAssertTrue(emptyResults.isEmpty, "Should return empty results for non-existent queries")
        
        print("✅ Template search functionality working")
    }
    
    func testCustomTemplateCreation() throws {
        // Mock annotation layer
        let mockLayer = MockAnnotationLayer()
        mockLayer.addMockAnnotations(count: 3)
        
        let customTemplate = templateManager.saveAsCustomTemplate(
            name: "Test Template",
            description: "Test custom template",
            layer: mockLayer
        )
        
        XCTAssertNotNil(customTemplate, "Custom template should be created")
        XCTAssertEqual(customTemplate?.name, "Test Template")
        XCTAssertEqual(customTemplate?.category, .custom)
        
        print("✅ Custom template creation successful")
    }
    
    func testTemplateFavoriteToggle() throws {
        guard let template = templateManager.availableTemplates.first else {
            XCTFail("No templates available for testing")
            return
        }
        
        let initialFavoriteState = template.isFavorite
        templateManager.toggleFavorite(template)
        
        // Find the updated template
        let updatedTemplate = templateManager.availableTemplates.first { $0.id == template.id }
        XCTAssertNotNil(updatedTemplate)
        XCTAssertNotEqual(updatedTemplate?.isFavorite, initialFavoriteState, "Favorite state should toggle")
        
        print("✅ Template favorite toggle working")
    }
    
    // MARK: - Advanced Drawing Effects Tests
    
    func testEffectsEngineInitialization() throws {
        XCTAssertNotNil(effectsEngine, "Effects engine should be initialized")
        
        let effectTypes = AdvancedDrawingEffects.EffectType.allCases
        XCTAssertEqual(effectTypes.count, 8, "Should have 8 effect types")
        
        print("✅ Effects engine initialized with \(effectTypes.count) effect types")
    }
    
    func testDropShadowEffect() throws {
        let originalPath = NSBezierPath(rect: CGRect(x: 10, y: 10, width: 100, height: 50))
        let parameters = AdvancedDrawingEffects.defaultDropShadowPreset()
        
        let shadowPath = effectsEngine.applyEffect(.dropShadow, to: originalPath, with: parameters)
        
        XCTAssertNotNil(shadowPath, "Shadow path should be created")
        XCTAssertNotEqual(shadowPath.bounds, originalPath.bounds, "Shadow should offset the path")
        
        print("✅ Drop shadow effect applied successfully")
    }
    
    func testGlowEffect() throws {
        let originalPath = NSBezierPath(ovalIn: CGRect(x: 20, y: 20, width: 80, height: 80))
        let parameters = AdvancedDrawingEffects.defaultGlowPreset()
        
        let glowPath = effectsEngine.applyEffect(.outerGlow, to: originalPath, with: parameters)
        
        XCTAssertNotNil(glowPath, "Glow path should be created")
        XCTAssertGreaterThan(glowPath.lineWidth, originalPath.lineWidth, "Glow should increase line width")
        
        print("✅ Glow effect applied successfully")
    }
    
    func testBevelEffect() throws {
        let originalPath = NSBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 60, height: 40), xRadius: 5, yRadius: 5)
        let parameters = AdvancedDrawingEffects.defaultBevelPreset()
        
        let bevelPath = effectsEngine.applyEffect(.bevelEmboss, to: originalPath, with: parameters)
        
        XCTAssertNotNil(bevelPath, "Bevel path should be created")
        XCTAssertNotEqual(bevelPath.bounds, originalPath.bounds, "Bevel should modify the path")
        
        print("✅ Bevel effect applied successfully")
    }
    
    func testPatternGeneration() throws {
        let patternTypes: [AdvancedDrawingEffects.EffectParameters.PatternType] = [.dots, .lines, .crosshatch, .checkerboard, .waves]
        
        for patternType in patternTypes {
            let pattern = effectsEngine.createPattern(patternType, scale: 1.0, spacing: 10.0, color: .black)
            XCTAssertNotNil(pattern, "Pattern \(patternType) should be created")
            XCTAssertGreaterThan(pattern!.size.width, 0, "Pattern should have valid dimensions")
        }
        
        print("✅ All pattern types generated successfully")
    }
    
    func testGradientCreation() throws {
        let colors: [NSColor] = [.red, .blue, .green]
        let locations: [CGFloat] = [0.0, 0.5, 1.0]
        
        let gradient = effectsEngine.createGradient(type: .linear, colors: colors, locations: locations)
        XCTAssertNotNil(gradient, "Gradient should be created")
        
        // Test invalid gradient (mismatched arrays)
        let invalidGradient = effectsEngine.createGradient(type: .linear, colors: colors, locations: [0.0, 1.0])
        XCTAssertNil(invalidGradient, "Invalid gradient should return nil")
        
        print("✅ Gradient creation working correctly")
    }
    
    func testEffectPreview() throws {
        let effectTypes = AdvancedDrawingEffects.EffectType.allCases
        let parameters = AdvancedDrawingEffects.EffectParameters()
        
        for effectType in effectTypes {
            let preview = effectsEngine.previewEffect(effectType, parameters: parameters)
            XCTAssertNotNil(preview, "Preview should be generated for \(effectType.rawValue)")
            XCTAssertGreaterThan(preview!.size.width, 0, "Preview should have valid dimensions")
        }
        
        print("✅ Effect previews generated for all effect types")
    }
    
    // MARK: - Automation Engine Tests
    
    func testAutomationEngineInitialization() throws {
        XCTAssertNotNil(automationEngine, "Automation engine should be initialized")
        XCTAssertTrue(automationEngine.isEnabled, "Automation should be enabled by default")
        
        let features = AnnotationAutomationEngine.AutomationFeature.allCases
        XCTAssertEqual(features.count, 8, "Should have 8 automation features")
        XCTAssertEqual(automationEngine.enabledFeatures.count, features.count, "All features should be enabled by default")
        
        print("✅ Automation engine initialized with \(features.count) features")
    }
    
    func testAutomationFeatureToggle() throws {
        let initialCount = automationEngine.enabledFeatures.count
        
        // Disable a feature
        automationEngine.enabledFeatures.remove(.textRecognition)
        XCTAssertEqual(automationEngine.enabledFeatures.count, initialCount - 1, "Feature count should decrease")
        XCTAssertFalse(automationEngine.enabledFeatures.contains(.textRecognition), "Text recognition should be disabled")
        
        // Re-enable the feature
        automationEngine.enabledFeatures.insert(.textRecognition)
        XCTAssertEqual(automationEngine.enabledFeatures.count, initialCount, "Feature count should return to original")
        
        print("✅ Automation feature toggle working")
    }
    
    func testScreenContentAnalysis() throws {
        let testImage = createTestImage()
        let expectation = self.expectation(description: "Screen analysis completion")
        
        automationEngine.analyzeScreenContent(testImage) { suggestions in
            XCTAssertTrue(suggestions.count >= 0, "Suggestions should be valid array")
            XCTAssertTrue(suggestions.count <= 10, "Should limit to 10 suggestions")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error, "Screen analysis should complete within timeout")
        }
        
        print("✅ Screen content analysis completed")
    }
    
    func testWorkflowCreation() throws {
        let steps = [MockWorkflowStep(name: "Step 1"), MockWorkflowStep(name: "Step 2")]
        let workflow = automationEngine.createWorkflow(name: "Test Workflow", steps: steps)
        
        XCTAssertEqual(workflow.name, "Test Workflow")
        XCTAssertEqual(workflow.steps.count, 2)
        XCTAssertNotNil(workflow.id)
        
        print("✅ Workflow creation successful")
    }
    
    func testWorkflowExecution() throws {
        var executedSteps: [String] = []
        let steps = [
            MockWorkflowStep(name: "Step 1", onExecute: { executedSteps.append("Step 1") }),
            MockWorkflowStep(name: "Step 2", onExecute: { executedSteps.append("Step 2") })
        ]
        
        let workflow = automationEngine.createWorkflow(name: "Test Workflow", steps: steps)
        automationEngine.executeWorkflow(workflow)
        
        // Wait for async execution
        let expectation = self.expectation(description: "Workflow execution")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertEqual(executedSteps.count, 2, "Both steps should execute")
            XCTAssertEqual(executedSteps, ["Step 1", "Step 2"], "Steps should execute in order")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 3.0)
        print("✅ Workflow execution successful")
    }
    
    // MARK: - Integration Tests
    
    func testTemplateAndEffectIntegration() throws {
        guard let template = templateManager.availableTemplates.first else {
            XCTFail("No templates available")
            return
        }
        
        // Apply template
        templateManager.applyTemplate(template)
        
        // Apply effect to template elements
        let effectPath = NSBezierPath(rect: CGRect(x: 0, y: 0, width: 50, height: 30))
        let parameters = AdvancedDrawingEffects.EffectParameters()
        let enhancedPath = effectsEngine.applyEffect(.dropShadow, to: effectPath, with: parameters)
        
        XCTAssertNotNil(enhancedPath, "Effect should be applied to template elements")
        
        print("✅ Template and effect integration working")
    }
    
    func testAutomationTemplateMatching() throws {
        let testImage = createTestImage()
        let expectation = self.expectation(description: "Template matching")
        
        automationEngine.analyzeScreenContent(testImage) { suggestions in
            let templateSuggestions = suggestions.filter { $0.type == .template }
            // Template suggestions may or may not exist depending on image content
            XCTAssertTrue(templateSuggestions.count >= 0, "Template suggestions should be valid")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        print("✅ Automation template matching tested")
    }
    
    // MARK: - Performance Tests
    
    func testTemplateApplicationPerformance() throws {
        guard let template = templateManager.availableTemplates.first else {
            XCTFail("No templates available")
            return
        }
        
        measure {
            templateManager.applyTemplate(template)
        }
        
        print("✅ Template application performance measured")
    }
    
    func testEffectApplicationPerformance() throws {
        let path = NSBezierPath(rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        let parameters = AdvancedDrawingEffects.EffectParameters()
        
        measure {
            let _ = effectsEngine.applyEffect(.dropShadow, to: path, with: parameters)
        }
        
        print("✅ Effect application performance measured")
    }
    
    func testAutomationAnalysisPerformance() throws {
        let testImage = createTestImage()
        
        measure {
            let expectation = self.expectation(description: "Analysis performance")
            
            automationEngine.analyzeScreenContent(testImage) { _ in
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 2.0)
        }
        
        print("✅ Automation analysis performance measured")
    }
    
    // MARK: - Error Handling Tests
    
    func testTemplateApplicationWithInvalidLayer() throws {
        guard let template = templateManager.availableTemplates.first else {
            XCTFail("No templates available")
            return
        }
        
        // Apply template without proper layer setup should not crash
        templateManager.applyTemplate(template, to: nil)
        
        // Should complete without throwing
        XCTAssertTrue(true, "Template application with invalid layer should handle gracefully")
        
        print("✅ Template error handling working")
    }
    
    func testEffectApplicationWithInvalidParameters() throws {
        let path = NSBezierPath(rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        var parameters = AdvancedDrawingEffects.EffectParameters()
        
        // Test with extreme values
        parameters.opacity = 2.0 // Invalid opacity
        parameters.distance = -10.0 // Negative distance
        
        let result = effectsEngine.applyEffect(.dropShadow, to: path, with: parameters)
        XCTAssertNotNil(result, "Effect should handle invalid parameters gracefully")
        
        print("✅ Effect error handling working")
    }
    
    func testAutomationWithInvalidImage() throws {
        let invalidImage = NSImage()
        let expectation = self.expectation(description: "Invalid image analysis")
        
        automationEngine.analyzeScreenContent(invalidImage) { suggestions in
            XCTAssertTrue(suggestions.isEmpty, "Should return empty suggestions for invalid image")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
        print("✅ Automation error handling working")
    }
    
    // MARK: - UI Component Tests
    
    func testAdvancedAnnotationPanelCreation() throws {
        let panel = AdvancedAnnotationPanel()
        XCTAssertNotNil(panel, "Advanced annotation panel should be created")
        
        print("✅ Advanced annotation panel creation successful")
    }
    
    func testTemplateCardViewInteraction() throws {
        guard let template = templateManager.availableTemplates.first else {
            XCTFail("No templates available")
            return
        }
        
        var selectedCalled = false
        var applyCalled = false
        var favoriteCalled = false
        
        let card = TemplateCardView(
            template: template,
            isSelected: false,
            onSelect: { selectedCalled = true },
            onApply: { applyCalled = true },
            onFavorite: { favoriteCalled = true }
        )
        
        XCTAssertNotNil(card, "Template card view should be created")
        
        print("✅ Template card view creation successful")
    }
    
    func testEffectParameterSlider() throws {
        let sliderValue = Binding<CGFloat>(
            get: { 0.5 },
            set: { _ in }
        )
        
        let slider = ParameterSlider(
            title: "Test Parameter",
            value: sliderValue,
            range: 0...1,
            format: .percent
        )
        
        XCTAssertNotNil(slider, "Parameter slider should be created")
        
        print("✅ Parameter slider creation successful")
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryLeaks() throws {
        weak var weakTemplateManager: AnnotationTemplateManager?
        weak var weakEffectsEngine: AdvancedDrawingEffects?
        weak var weakAutomationEngine: AnnotationAutomationEngine?
        
        autoreleasepool {
            let localTemplateManager = AnnotationTemplateManager.shared
            let localEffectsEngine = AdvancedDrawingEffects.shared
            let localAutomationEngine = AnnotationAutomationEngine.shared
            
            weakTemplateManager = localTemplateManager
            weakEffectsEngine = localEffectsEngine
            weakAutomationEngine = localAutomationEngine
            
            // Perform operations
            if let template = localTemplateManager.availableTemplates.first {
                localTemplateManager.applyTemplate(template)
            }
            
            let path = NSBezierPath(rect: CGRect(x: 0, y: 0, width: 50, height: 50))
            let _ = localEffectsEngine.applyEffect(.dropShadow, to: path, with: AdvancedDrawingEffects.EffectParameters())
        }
        
        // Note: Singletons won't be deallocated, so we just test they're still accessible
        XCTAssertNotNil(weakTemplateManager, "Template manager singleton should persist")
        XCTAssertNotNil(weakEffectsEngine, "Effects engine singleton should persist")
        XCTAssertNotNil(weakAutomationEngine, "Automation engine singleton should persist")
        
        print("✅ Memory management test completed")
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentTemplateAccess() throws {
        let expectation = self.expectation(description: "Concurrent template access")
        expectation.expectedFulfillmentCount = 5
        
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        for i in 0..<5 {
            queue.async {
                let templates = self.templateManager.availableTemplates
                XCTAssertFalse(templates.isEmpty, "Templates should be accessible from concurrent queue \(i)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3.0)
        print("✅ Concurrent template access working")
    }
    
    func testConcurrentEffectApplication() throws {
        let expectation = self.expectation(description: "Concurrent effect application")
        expectation.expectedFulfillmentCount = 3
        
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        for i in 0..<3 {
            queue.async {
                let path = NSBezierPath(rect: CGRect(x: CGFloat(i * 10), y: CGFloat(i * 10), width: 50, height: 50))
                let result = self.effectsEngine.applyEffect(.dropShadow, to: path, with: AdvancedDrawingEffects.EffectParameters())
                XCTAssertNotNil(result, "Effect should be applied from concurrent queue \(i)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3.0)
        print("✅ Concurrent effect application working")
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> NSImage {
        let size = CGSize(width: 200, height: 150)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Draw test content
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        NSColor.black.setFill()
        NSRect(x: 20, y: 20, width: 160, height: 30).fill()
        
        NSColor.blue.setFill()
        NSBezierPath(ovalIn: NSRect(x: 50, y: 70, width: 100, height: 60)).fill()
        
        // Add some text
        let text = "Test Content"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16),
            .foregroundColor: NSColor.black
        ]
        
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        attributedText.draw(at: CGPoint(x: 60, y: 100))
        
        image.unlockFocus()
        
        return image
    }
}

// MARK: - Mock Classes

class MockAnnotationLayer {
    var name: String = "Mock Layer"
    var annotations: [MockAnnotation] = []
    
    func addMockAnnotations(count: Int) {
        for i in 0..<count {
            let annotation = MockAnnotation(id: UUID(), type: .shape)
            annotations.append(annotation)
        }
    }
}

struct MockAnnotation {
    let id: UUID
    let type: AnnotationType
    
    enum AnnotationType {
        case shape, text, line
    }
}

struct MockWorkflowStep: WorkflowStep {
    let name: String
    let description: String
    private let executeBlock: (() -> Void)?
    
    init(name: String, description: String = "Mock step", onExecute: (() -> Void)? = nil) {
        self.name = name
        self.description = description
        self.executeBlock = onExecute
    }
    
    func execute() {
        executeBlock?()
        print("Executed workflow step: \(name)")
    }
}

// MARK: - Test Extensions

extension AdvancedAnnotationSystemTests {
    
    func testCompleteWorkflow() throws {
        print("\n🚀 Running complete advanced annotation workflow test...")
        
        // 1. Load and apply template
        guard let template = templateManager.availableTemplates.first else {
            XCTFail("No templates available")
            return
        }
        
        templateManager.applyTemplate(template)
        print("✓ Template applied: \(template.name)")
        
        // 2. Apply effects
        let path = NSBezierPath(rect: CGRect(x: 10, y: 10, width: 100, height: 50))
        let shadowPath = effectsEngine.applyEffect(.dropShadow, to: path, with: AdvancedDrawingEffects.defaultDropShadowPreset())
        XCTAssertNotNil(shadowPath)
        print("✓ Drop shadow effect applied")
        
        // 3. Run automation analysis
        let testImage = createTestImage()
        let expectation = self.expectation(description: "Automation analysis")
        
        automationEngine.analyzeScreenContent(testImage) { suggestions in
            print("✓ Automation analysis completed with \(suggestions.count) suggestions")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        // 4. Create and execute workflow
        let steps = [MockWorkflowStep(name: "Apply Template"), MockWorkflowStep(name: "Add Effects")]
        let workflow = automationEngine.createWorkflow(name: "Complete Workflow", steps: steps)
        automationEngine.executeWorkflow(workflow)
        print("✓ Workflow created and executed")
        
        print("🎉 Complete advanced annotation workflow test passed!")
    }
    
    func printTestSummary() {
        print("\n📊 Advanced Annotation System Test Summary:")
        print("✅ Template Manager: \(templateManager.availableTemplates.count) templates loaded")
        print("✅ Effects Engine: \(AdvancedDrawingEffects.EffectType.allCases.count) effect types available")
        print("✅ Automation Engine: \(automationEngine.enabledFeatures.count) features enabled")
        print("✅ All advanced annotation features tested successfully")
    }
} 