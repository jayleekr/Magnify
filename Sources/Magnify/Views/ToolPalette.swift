import SwiftUI
import AppKit

/// ToolPalette provides a comprehensive SwiftUI interface for drawing tool selection
/// Includes tool buttons, color picker, stroke controls, and font selection
struct ToolPalette: View {
    
    @ObservedObject var drawingToolManager = DrawingToolManager.shared
    @State private var showingColorPicker = false
    @State private var showingFontPicker = false
    @State private var selectedColorTab: ColorTab = .stroke
    @State private var customColor: Color = .blue
    
    enum ColorTab: String, CaseIterable {
        case stroke = "Stroke"
        case fill = "Fill"
        case text = "Text"
        
        var iconName: String {
            switch self {
            case .stroke: return "pencil"
            case .fill: return "paintbrush.fill"
            case .text: return "textformat"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            toolPaletteHeader
            
            Divider()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Tool Selection Section
                    toolSelectionSection
                    
                    Divider()
                    
                    // Color Management Section
                    colorManagementSection
                    
                    Divider()
                    
                    // Stroke Width Section
                    strokeWidthSection
                    
                    Divider()
                    
                    // Font Section (when text tool is selected)
                    if drawingToolManager.currentTool == .text {
                        fontSelectionSection
                        Divider()
                    }
                    
                    // Action Buttons Section
                    actionButtonsSection
                }
                .padding(12)
            }
        }
        .frame(width: 280)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Header
    
    private var toolPaletteHeader: some View {
        HStack {
            Image(systemName: "paintpalette.fill")
                .foregroundColor(.accentColor)
            
            Text("Drawing Tools")
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: {
                drawingToolManager.hideToolPalette()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Tool Selection
    
    private var toolSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tools")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(DrawingToolManager.DrawingTool.allCases, id: \.self) { tool in
                    toolButton(for: tool)
                }
            }
        }
    }
    
    private func toolButton(for tool: DrawingToolManager.DrawingTool) -> some View {
        Button(action: {
            drawingToolManager.selectTool(tool)
        }) {
            VStack(spacing: 4) {
                Image(systemName: tool.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(drawingToolManager.currentTool == tool ? .white : .primary)
                
                Text(tool.displayName)
                    .font(.caption2)
                    .foregroundColor(drawingToolManager.currentTool == tool ? .white : .secondary)
            }
            .frame(width: 60, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(drawingToolManager.currentTool == tool ? Color.accentColor : Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(drawingToolManager.currentTool == tool ? Color.clear : Color(NSColor.separatorColor), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Color Management
    
    private var colorManagementSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Colors")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Color tab selection
            Picker("Color Type", selection: $selectedColorTab) {
                ForEach(ColorTab.allCases, id: \.self) { tab in
                    HStack {
                        Image(systemName: tab.iconName)
                        Text(tab.rawValue)
                    }
                    .tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Current color display
            currentColorDisplay
            
            // Standard color palette
            standardColorPalette
            
            // Custom color picker button
            Button(action: {
                showingColorPicker = true
            }) {
                HStack {
                    Image(systemName: "eyedropper")
                    Text("Custom Color...")
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Transparency controls
            if selectedColorTab == .stroke || selectedColorTab == .fill {
                transparencyControls
            }
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerView(selectedTab: selectedColorTab, drawingToolManager: drawingToolManager)
        }
    }
    
    private var currentColorDisplay: some View {
        HStack {
            Text(getCurrentColorLabel())
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(getCurrentColor()))
                .frame(width: 40, height: 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
        }
    }
    
    private var standardColorPalette: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 6) {
            ForEach(DrawingToolManager.ColorPalette.standardColors, id: \.self) { color in
                colorSwatch(color: color)
            }
        }
    }
    
    private func colorSwatch(color: NSColor) -> some View {
        Button(action: {
            setCurrentColor(color)
        }) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(color))
                .frame(width: 24, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var transparencyControls: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Transparency")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                ForEach(DrawingToolManager.ColorPalette.transparencyLevels, id: \.self) { alpha in
                    transparencyButton(alpha: alpha)
                }
            }
        }
    }
    
    private func transparencyButton(alpha: CGFloat) -> some View {
        Button(action: {
            applyTransparency(alpha)
        }) {
            VStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(getCurrentColor().withAlphaComponent(alpha)))
                    .frame(width: 20, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                    )
                
                Text("\(Int(alpha * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Stroke Width
    
    private var strokeWidthSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Stroke Width")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(drawingToolManager.strokeWidth))pt")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $drawingToolManager.strokeWidth, in: 0.5...50.0, step: 0.5) {
                Text("Stroke Width")
            }
            .onChange(of: drawingToolManager.strokeWidth) { newValue in
                drawingToolManager.setStrokeWidth(newValue)
            }
            
            // Preset stroke widths
            HStack(spacing: 8) {
                ForEach([1.0, 2.0, 4.0, 8.0, 16.0], id: \.self) { width in
                    strokeWidthPreset(width: width)
                }
            }
        }
    }
    
    private func strokeWidthPreset(width: CGFloat) -> some View {
        Button(action: {
            drawingToolManager.setStrokeWidth(width)
        }) {
            VStack(spacing: 2) {
                Circle()
                    .fill(Color.primary)
                    .frame(width: width * 2, height: width * 2)
                
                Text("\(Int(width))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Font Selection
    
    private var fontSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Font")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Current font display
            HStack {
                Text(drawingToolManager.selectedFont.displayName ?? drawingToolManager.selectedFont.fontName)
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(drawingToolManager.selectedFont.pointSize))pt")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            
            // Font size slider
            HStack {
                Text("Size")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(value: Binding(
                    get: { Double(drawingToolManager.selectedFont.pointSize) },
                    set: { newSize in
                        let newFont = NSFont(name: drawingToolManager.selectedFont.fontName, size: CGFloat(newSize)) ?? 
                                     NSFont.systemFont(ofSize: CGFloat(newSize))
                        drawingToolManager.setTextFont(newFont)
                    }
                ), in: 8...72, step: 1)
                
                Text("\(Int(drawingToolManager.selectedFont.pointSize))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 24)
            }
            
            // Font picker button
            Button(action: {
                showingFontPicker = true
            }) {
                HStack {
                    Image(systemName: "textformat.size")
                    Text("Choose Font...")
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingFontPicker) {
            FontPickerView(drawingToolManager: drawingToolManager)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // Undo button
                Button(action: {
                    drawingToolManager.undo()
                }) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Undo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(drawingToolManager.canUndo() ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                    .foregroundColor(drawingToolManager.canUndo() ? .white : .secondary)
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!drawingToolManager.canUndo())
                
                // Redo button
                Button(action: {
                    drawingToolManager.redo()
                }) {
                    HStack {
                        Image(systemName: "arrow.uturn.forward")
                        Text("Redo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(drawingToolManager.canRedo() ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                    .foregroundColor(drawingToolManager.canRedo() ? .white : .secondary)
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!drawingToolManager.canRedo())
            }
            
            // Clear all button
            Button(action: {
                drawingToolManager.clearAllDrawings()
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear All")
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Element count
            Text("\(drawingToolManager.elementCount) drawing elements")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentColorLabel() -> String {
        switch selectedColorTab {
        case .stroke: return "Stroke Color"
        case .fill: return "Fill Color"
        case .text: return "Text Color"
        }
    }
    
    private func getCurrentColor() -> NSColor {
        switch selectedColorTab {
        case .stroke: return drawingToolManager.currentColor
        case .fill: return drawingToolManager.fillColor ?? NSColor.clear
        case .text: return drawingToolManager.textColor
        }
    }
    
    private func setCurrentColor(_ color: NSColor) {
        switch selectedColorTab {
        case .stroke: drawingToolManager.setStrokeColor(color)
        case .fill: drawingToolManager.setFillColor(color)
        case .text: drawingToolManager.setTextColor(color)
        }
    }
    
    private func applyTransparency(_ alpha: CGFloat) {
        let currentColor = getCurrentColor()
        let transparentColor = currentColor.withAlphaComponent(alpha)
        setCurrentColor(transparentColor)
    }
}

// MARK: - Color Picker View

struct ColorPickerView: View {
    let selectedTab: ToolPalette.ColorTab
    let drawingToolManager: DrawingToolManager
    @State private var selectedColor: Color = .blue
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Custom Color Picker")
                .font(.headline)
            
            ColorPicker("Select Color", selection: $selectedColor, supportsOpacity: true)
                .labelsHidden()
                .frame(height: 200)
            
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Apply") {
                    applySelectedColor()
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 300, height: 280)
        .onAppear {
            selectedColor = Color(getCurrentColor())
        }
    }
    
    private func getCurrentColor() -> NSColor {
        switch selectedTab {
        case .stroke: return drawingToolManager.currentColor
        case .fill: return drawingToolManager.fillColor ?? NSColor.clear
        case .text: return drawingToolManager.textColor
        }
    }
    
    private func applySelectedColor() {
        let nsColor = NSColor(selectedColor)
        
        switch selectedTab {
        case .stroke: drawingToolManager.setStrokeColor(nsColor)
        case .fill: drawingToolManager.setFillColor(nsColor)
        case .text: drawingToolManager.setTextColor(nsColor)
        }
    }
}

// MARK: - Font Picker View

struct FontPickerView: View {
    let drawingToolManager: DrawingToolManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedFontName: String = ""
    @State private var fontSize: Double = 16
    
    private let commonFonts = [
        "Helvetica", "Arial", "Times New Roman", "Courier New",
        "Georgia", "Verdana", "Comic Sans MS", "Impact",
        "Trebuchet MS", "Lucida Grande", "Monaco", "Menlo"
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Font Picker")
                .font(.headline)
            
            // Font list
            List(commonFonts, id: \.self, selection: $selectedFontName) { fontName in
                HStack {
                    Text(fontName)
                        .font(.custom(fontName, size: 16))
                    
                    Spacer()
                    
                    if selectedFontName == fontName {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedFontName = fontName
                }
            }
            .frame(height: 200)
            
            // Font size
            HStack {
                Text("Size:")
                Slider(value: $fontSize, in: 8...72, step: 1)
                Text("\(Int(fontSize))pt")
                    .frame(width: 40)
            }
            
            // Preview
            Text("Sample Text")
                .font(.custom(selectedFontName.isEmpty ? "Helvetica" : selectedFontName, size: CGFloat(fontSize)))
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Apply") {
                    applySelectedFont()
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedFontName.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400, height: 400)
        .onAppear {
            selectedFontName = drawingToolManager.selectedFont.fontName
            fontSize = Double(drawingToolManager.selectedFont.pointSize)
        }
    }
    
    private func applySelectedFont() {
        guard !selectedFontName.isEmpty else { return }
        
        let newFont = NSFont(name: selectedFontName, size: CGFloat(fontSize)) ?? 
                     NSFont.systemFont(ofSize: CGFloat(fontSize))
        
        drawingToolManager.setTextFont(newFont)
    }
}

// MARK: - Preview

struct ToolPalette_Previews: PreviewProvider {
    static var previews: some View {
        ToolPalette()
            .frame(width: 300, height: 600)
    }
} 