import SwiftUI
import AppKit

/// AdvancedAnnotationPanel provides a comprehensive interface for advanced annotation features
/// Includes templates, effects, automation suggestions, and workflow management
struct AdvancedAnnotationPanel: View {
    
    // MARK: - Properties
    
    @StateObject private var templateManager = AnnotationTemplateManager.shared
    @StateObject private var effectsEngine = AdvancedDrawingEffects.shared
    @StateObject private var automationEngine = AnnotationAutomationEngine.shared
    
    @State private var selectedTab: PanelTab = .templates
    @State private var selectedTemplate: AnnotationTemplateManager.AnnotationTemplate?
    @State private var selectedEffect: AdvancedDrawingEffects.EffectType?
    @State private var effectParameters = AdvancedDrawingEffects.EffectParameters()
    @State private var showingTemplateCreator = false
    @State private var showingEffectEditor = false
    @State private var showingAutomationSettings = false
    
    // MARK: - Panel Tabs
    
    enum PanelTab: String, CaseIterable {
        case templates = "Templates"
        case effects = "Effects"
        case automation = "Automation"
        case workflows = "Workflows"
        
        var systemImage: String {
            switch self {
            case .templates: return "doc.on.doc"
            case .effects: return "wand.and.rays"
            case .automation: return "gear.badge.checkmark"
            case .workflows: return "arrow.right.arrow.left"
            }
        }
    }
    
    // MARK: - Main View
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Header
            tabHeader
            
            Divider()
            
            // Tab Content
            TabView(selection: $selectedTab) {
                templatesView
                    .tabItem {
                        Image(systemName: PanelTab.templates.systemImage)
                        Text(PanelTab.templates.rawValue)
                    }
                    .tag(PanelTab.templates)
                
                effectsView
                    .tabItem {
                        Image(systemName: PanelTab.effects.systemImage)
                        Text(PanelTab.effects.rawValue)
                    }
                    .tag(PanelTab.effects)
                
                automationView
                    .tabItem {
                        Image(systemName: PanelTab.automation.systemImage)
                        Text(PanelTab.automation.rawValue)
                    }
                    .tag(PanelTab.automation)
                
                workflowsView
                    .tabItem {
                        Image(systemName: PanelTab.workflows.systemImage)
                        Text(PanelTab.workflows.rawValue)
                    }
                    .tag(PanelTab.workflows)
            }
        }
        .frame(width: 320, height: 480)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingTemplateCreator) {
            TemplateCreatorView()
        }
        .sheet(isPresented: $showingEffectEditor) {
            EffectEditorView(effectType: selectedEffect ?? .dropShadow, parameters: $effectParameters)
        }
        .sheet(isPresented: $showingAutomationSettings) {
            AutomationSettingsView()
        }
    }
    
    // MARK: - Tab Header
    
    private var tabHeader: some View {
        HStack {
            Text("Advanced Annotations")
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: {
                switch selectedTab {
                case .templates:
                    showingTemplateCreator = true
                case .effects:
                    showingEffectEditor = true
                case .automation:
                    showingAutomationSettings = true
                case .workflows:
                    createNewWorkflow()
                }
            }) {
                Image(systemName: "plus.circle")
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Add new \(selectedTab.rawValue.lowercased())")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Templates View
    
    private var templatesView: some View {
        VStack(spacing: 0) {
            // Template Categories
            templateCategoriesView
            
            Divider()
            
            // Template Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(filteredTemplates, id: \.id) { template in
                        TemplateCardView(
                            template: template,
                            isSelected: selectedTemplate?.id == template.id,
                            onSelect: { selectedTemplate = template },
                            onApply: { applyTemplate(template) },
                            onFavorite: { toggleTemplateFavorite(template) }
                        )
                    }
                }
                .padding(16)
            }
            
            // Template Actions
            templateActionsView
        }
    }
    
    private var templateCategoriesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AnnotationTemplateManager.TemplateCategory.allCases, id: \.self) { category in
                    CategoryChipView(
                        category: category,
                        isSelected: selectedCategory == category,
                        onSelect: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
    
    @State private var selectedCategory: AnnotationTemplateManager.TemplateCategory = .general
    
    private var filteredTemplates: [AnnotationTemplateManager.AnnotationTemplate] {
        templateManager.getTemplates(for: selectedCategory)
    }
    
    private var templateActionsView: some View {
        HStack {
            Button("Recent") {
                // Show recent templates
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            
            Button("Favorites") {
                // Show favorite templates
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Spacer()
            
            if let template = selectedTemplate {
                Button("Apply") {
                    applyTemplate(template)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(16)
    }
    
    // MARK: - Effects View
    
    private var effectsView: some View {
        VStack(spacing: 0) {
            // Effect Types
            effectTypesView
            
            Divider()
            
            // Effect Parameters
            if let effectType = selectedEffect {
                effectParametersView(for: effectType)
            } else {
                effectSelectionPrompt
            }
            
            Spacer()
            
            // Effect Actions
            effectActionsView
        }
    }
    
    private var effectTypesView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(AdvancedDrawingEffects.EffectType.allCases, id: \.self) { effectType in
                    EffectTypeButton(
                        effectType: effectType,
                        isSelected: selectedEffect == effectType,
                        onSelect: { selectedEffect = effectType }
                    )
                }
            }
            .padding(16)
        }
    }
    
    private func effectParametersView(for effectType: AdvancedDrawingEffects.EffectType) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(effectType.rawValue)
                    .font(.headline)
                    .padding(.horizontal, 16)
                
                Group {
                    // Common parameters
                    ParameterSlider(
                        title: "Opacity",
                        value: $effectParameters.opacity,
                        range: 0...1,
                        format: .percent
                    )
                    
                    // Effect-specific parameters
                    switch effectType {
                    case .dropShadow, .outerGlow, .innerGlow:
                        shadowGlowParameters
                    case .bevelEmboss:
                        bevelParameters
                    case .gradientOverlay:
                        gradientParameters
                    case .patternOverlay:
                        patternParameters
                    case .stroke:
                        strokeParameters
                    case .colorOverlay:
                        colorOverlayParameters
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var shadowGlowParameters: some View {
        Group {
            ColorPicker("Color", selection: Binding(
                get: { Color(effectParameters.color) },
                set: { effectParameters.color = NSColor($0) }
            ))
            
            ParameterSlider(
                title: "Distance",
                value: $effectParameters.distance,
                range: 0...20,
                format: .number
            )
            
            ParameterSlider(
                title: "Size",
                value: $effectParameters.size,
                range: 0...20,
                format: .number
            )
            
            ParameterSlider(
                title: "Angle",
                value: $effectParameters.angle,
                range: 0...360,
                format: .degrees
            )
        }
    }
    
    private var bevelParameters: some View {
        Group {
            ParameterSlider(
                title: "Depth",
                value: $effectParameters.depth,
                range: 0...10,
                format: .number
            )
            
            Picker("Direction", selection: $effectParameters.direction) {
                Text("Up").tag(AdvancedDrawingEffects.EffectParameters.BevelDirection.up)
                Text("Down").tag(AdvancedDrawingEffects.EffectParameters.BevelDirection.down)
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var gradientParameters: some View {
        Group {
            Picker("Type", selection: $effectParameters.gradientType) {
                Text("Linear").tag(AdvancedDrawingEffects.EffectParameters.GradientType.linear)
                Text("Radial").tag(AdvancedDrawingEffects.EffectParameters.GradientType.radial)
                Text("Angle").tag(AdvancedDrawingEffects.EffectParameters.GradientType.angle)
            }
            .pickerStyle(.menu)
            
            ParameterSlider(
                title: "Angle",
                value: $effectParameters.gradientAngle,
                range: 0...360,
                format: .degrees
            )
        }
    }
    
    private var patternParameters: some View {
        Group {
            Picker("Pattern", selection: $effectParameters.patternType) {
                Text("Dots").tag(AdvancedDrawingEffects.EffectParameters.PatternType.dots)
                Text("Lines").tag(AdvancedDrawingEffects.EffectParameters.PatternType.lines)
                Text("Crosshatch").tag(AdvancedDrawingEffects.EffectParameters.PatternType.crosshatch)
                Text("Checkerboard").tag(AdvancedDrawingEffects.EffectParameters.PatternType.checkerboard)
                Text("Waves").tag(AdvancedDrawingEffects.EffectParameters.PatternType.waves)
            }
            .pickerStyle(.menu)
            
            ParameterSlider(
                title: "Scale",
                value: $effectParameters.patternScale,
                range: 0.1...3.0,
                format: .number
            )
            
            ParameterSlider(
                title: "Spacing",
                value: $effectParameters.patternSpacing,
                range: 5...50,
                format: .number
            )
        }
    }
    
    private var strokeParameters: some View {
        Group {
            ParameterSlider(
                title: "Width",
                value: $effectParameters.strokeWidth,
                range: 1...20,
                format: .number
            )
            
            Picker("Position", selection: $effectParameters.strokePosition) {
                Text("Inside").tag(AdvancedDrawingEffects.EffectParameters.StrokePosition.inside)
                Text("Center").tag(AdvancedDrawingEffects.EffectParameters.StrokePosition.center)
                Text("Outside").tag(AdvancedDrawingEffects.EffectParameters.StrokePosition.outside)
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var colorOverlayParameters: some View {
        Group {
            ColorPicker("Overlay Color", selection: Binding(
                get: { Color(effectParameters.color) },
                set: { effectParameters.color = NSColor($0) }
            ))
            
            Picker("Blend Mode", selection: $effectParameters.blendMode) {
                Text("Normal").tag(CGBlendMode.normal)
                Text("Multiply").tag(CGBlendMode.multiply)
                Text("Screen").tag(CGBlendMode.screen)
                Text("Overlay").tag(CGBlendMode.overlay)
            }
            .pickerStyle(.menu)
        }
    }
    
    private var effectSelectionPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "wand.and.rays")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Select an Effect")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Choose an effect type above to configure its parameters")
                .font(.caption)
                .foregroundColor(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var effectActionsView: some View {
        HStack {
            Button("Preview") {
                previewEffect()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(selectedEffect == nil)
            
            Spacer()
            
            Button("Apply Effect") {
                applyEffect()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(selectedEffect == nil)
        }
        .padding(16)
    }
    
    // MARK: - Automation View
    
    private var automationView: some View {
        VStack(spacing: 0) {
            // Automation Status
            automationStatusView
            
            Divider()
            
            // Suggestions
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(automationEngine.currentSuggestions, id: \.id) { suggestion in
                        SuggestionCardView(
                            suggestion: suggestion,
                            onAccept: { acceptSuggestion(suggestion) },
                            onDismiss: { dismissSuggestion(suggestion) }
                        )
                    }
                }
                .padding(16)
            }
            
            // Automation Controls
            automationControlsView
        }
    }
    
    private var automationStatusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: automationEngine.isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(automationEngine.isEnabled ? .green : .red)
                
                Text("Automation \(automationEngine.isEnabled ? "Enabled" : "Disabled")")
                    .font(.headline)
                
                Spacer()
                
                Toggle("", isOn: $automationEngine.isEnabled)
                    .toggleStyle(SwitchToggleStyle())
            }
            
            Text("\(automationEngine.currentSuggestions.count) suggestions available")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
    }
    
    private var automationControlsView: some View {
        VStack(spacing: 12) {
            Button("Analyze Current Screen") {
                analyzeCurrentScreen()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            
            HStack {
                Button("Settings") {
                    showingAutomationSettings = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Clear Suggestions") {
                    clearSuggestions()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(16)
    }
    
    // MARK: - Workflows View
    
    private var workflowsView: some View {
        VStack(spacing: 0) {
            // Workflow List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(savedWorkflows, id: \.id) { workflow in
                        WorkflowCardView(
                            workflow: workflow,
                            onExecute: { executeWorkflow(workflow) },
                            onEdit: { editWorkflow(workflow) },
                            onDelete: { deleteWorkflow(workflow) }
                        )
                    }
                }
                .padding(16)
            }
            
            // Workflow Actions
            workflowActionsView
        }
    }
    
    @State private var savedWorkflows: [AnnotationWorkflow] = []
    
    private var workflowActionsView: some View {
        HStack {
            Button("Import") {
                importWorkflow()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Button("Export") {
                exportWorkflows()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Spacer()
            
            Button("New Workflow") {
                createNewWorkflow()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(16)
    }
    
    // MARK: - Action Methods
    
    private func applyTemplate(_ template: AnnotationTemplateManager.AnnotationTemplate) {
        templateManager.applyTemplate(template)
        print("Applied template: \(template.name)")
    }
    
    private func toggleTemplateFavorite(_ template: AnnotationTemplateManager.AnnotationTemplate) {
        templateManager.toggleFavorite(template)
    }
    
    private func previewEffect() {
        guard let effectType = selectedEffect else { return }
        
        // Show effect preview
        if let previewImage = effectsEngine.previewEffect(effectType, parameters: effectParameters) {
            // Display preview in a popover or window
            print("Showing preview for effect: \(effectType.rawValue)")
        }
    }
    
    private func applyEffect() {
        guard let effectType = selectedEffect else { return }
        
        // Apply effect to current annotation
        print("Applied effect: \(effectType.rawValue)")
    }
    
    private func analyzeCurrentScreen() {
        // Capture current screen and analyze
        print("Analyzing current screen for automation suggestions")
    }
    
    private func acceptSuggestion(_ suggestion: AnnotationAutomationEngine.AutomationSuggestion) {
        suggestion.action()
        // Remove from suggestions
        automationEngine.currentSuggestions.removeAll { $0.id == suggestion.id }
    }
    
    private func dismissSuggestion(_ suggestion: AnnotationAutomationEngine.AutomationSuggestion) {
        automationEngine.currentSuggestions.removeAll { $0.id == suggestion.id }
    }
    
    private func clearSuggestions() {
        automationEngine.currentSuggestions.removeAll()
    }
    
    private func createNewWorkflow() {
        print("Creating new workflow")
    }
    
    private func executeWorkflow(_ workflow: AnnotationWorkflow) {
        automationEngine.executeWorkflow(workflow)
    }
    
    private func editWorkflow(_ workflow: AnnotationWorkflow) {
        print("Editing workflow: \(workflow.name)")
    }
    
    private func deleteWorkflow(_ workflow: AnnotationWorkflow) {
        savedWorkflows.removeAll { $0.id == workflow.id }
    }
    
    private func importWorkflow() {
        print("Importing workflow")
    }
    
    private func exportWorkflows() {
        print("Exporting workflows")
    }
}

// MARK: - Supporting Views

struct TemplateCardView: View {
    let template: AnnotationTemplateManager.AnnotationTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    let onApply: () -> Void
    let onFavorite: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Template preview
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 60)
                .overlay(
                    Image(systemName: template.category.systemImage)
                        .font(.title2)
                        .foregroundColor(.secondary)
                )
            
            // Template info
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(template.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Actions
            HStack {
                Button(action: onFavorite) {
                    Image(systemName: template.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(template.isFavorite ? .red : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button("Apply", action: onApply)
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
            }
        }
        .padding(8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onTapGesture { onSelect() }
    }
}

struct CategoryChipView: View {
    let category: AnnotationTemplateManager.TemplateCategory
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.systemImage)
                .font(.caption)
            
            Text(category.rawValue)
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(16)
        .onTapGesture { onSelect() }
    }
}

struct EffectTypeButton: View {
    let effectType: AdvancedDrawingEffects.EffectType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: effectType.systemImage)
                .font(.title2)
                .foregroundColor(isSelected ? .white : .primary)
            
            Text(effectType.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
        .cornerRadius(8)
        .onTapGesture { onSelect() }
    }
}

struct ParameterSlider: View {
    let title: String
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let format: SliderFormat
    
    enum SliderFormat {
        case number, percent, degrees
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(formatValue(value))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            
            Slider(value: $value, in: range)
                .accentColor(.blue)
        }
    }
    
    private func formatValue(_ value: CGFloat) -> String {
        switch format {
        case .number:
            return String(format: "%.1f", value)
        case .percent:
            return String(format: "%.0f%%", value * 100)
        case .degrees:
            return String(format: "%.0f°", value)
        }
    }
}

struct SuggestionCardView: View {
    let suggestion: AnnotationAutomationEngine.AutomationSuggestion
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text(suggestion.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Confidence indicator
                Text("\(Int(suggestion.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            
            HStack {
                Button("Accept", action: onAccept)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                
                Button("Dismiss", action: onDismiss)
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                
                Spacer()
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct WorkflowCardView: View {
    let workflow: AnnotationWorkflow
    let onExecute: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workflow.name)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("\(workflow.steps.count) steps")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Menu {
                    Button("Edit", action: onEdit)
                    Button("Delete", action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Button("Execute", action: onExecute)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .frame(maxWidth: .infinity)
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Sheet Views (Placeholder)

struct TemplateCreatorView: View {
    var body: some View {
        Text("Template Creator")
            .frame(width: 400, height: 300)
    }
}

struct EffectEditorView: View {
    let effectType: AdvancedDrawingEffects.EffectType
    @Binding var parameters: AdvancedDrawingEffects.EffectParameters
    
    var body: some View {
        Text("Effect Editor for \(effectType.rawValue)")
            .frame(width: 400, height: 300)
    }
}

struct AutomationSettingsView: View {
    var body: some View {
        Text("Automation Settings")
            .frame(width: 400, height: 300)
    }
} 