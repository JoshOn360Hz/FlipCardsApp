import SwiftUI
import PencilKit

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var isDirty: Bool
    @Binding var toolPicker: PKToolPicker
    @Binding var selectedTool: PKTool
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator
        canvasView.backgroundColor = UIColor.clear
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        canvasView.tool = selectedTool
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if !toolPicker.isVisible {
            toolPicker.setVisible(true, forFirstResponder: uiView)
        }
        uiView.tool = selectedTool
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: DrawingCanvasView
        
        init(_ parent: DrawingCanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.isDirty = true
        }
    }
}

struct DrawingPreview: View {
    let drawingData: Data?
    let size: CGSize
    let showFullDrawing: Bool
    let onDelete: (() -> Void)?
    let drawingBinding: Binding<Data?>?
    @State private var showingFullScreen = false
    
    init(drawingData: Data?, size: CGSize, showFullDrawing: Bool = false, onDelete: (() -> Void)? = nil, drawingBinding: Binding<Data?>? = nil) {
        self.drawingData = drawingData
        self.size = size
        self.showFullDrawing = showFullDrawing
        self.onDelete = onDelete
        self.drawingBinding = drawingBinding
    }
    
    var body: some View {
        Group {
            if let data = drawingData,
               let drawing = try? PKDrawing(data: data) {
                
                let drawingBounds = drawing.bounds
                let drawingSize = showFullDrawing ? 
                    CGSize(width: min(drawingBounds.width, size.width), 
                           height: min(drawingBounds.height, size.height)) : size
                
                ZStack(alignment: .topTrailing) {
                    Button(action: {
                        showingFullScreen = true
                    }) {
                        Image(uiImage: drawing.image(from: showFullDrawing ? drawingBounds : CGRect(origin: .zero, size: size), scale: UIScreen.main.scale))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: drawingSize.width, maxHeight: drawingSize.height)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if let onDelete = onDelete {
                        Button(action: onDelete) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 20, height: 20)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 4)
                        .padding(.trailing, 4)
                    }
                }
                .sheet(isPresented: $showingFullScreen) {
                    if let binding = drawingBinding, let _ = binding.wrappedValue {
                        FullScreenDrawingView(drawingData: Binding<Data>(
                            get: { binding.wrappedValue! },
                            set: { binding.wrappedValue = $0 }
                        ))
                    } else {
                        ReadOnlyDrawingView(drawingData: data)
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: size.width, height: size.height)
            }
        }
    }
}

struct FullScreenDrawingView: View {
    @Binding var drawingData: Data
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var canvasView = PKCanvasView()
    @State private var isDirty = false
    @State private var toolPicker = PKToolPicker()
    @State private var selectedTool: PKTool = PKInkingTool(.pen, color: .black, width: 3)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ZStack {
                    Color(.systemBackground)
                    
                    DrawingCanvasView(
                        canvasView: $canvasView,
                        isDirty: $isDirty,
                        toolPicker: $toolPicker,
                        selectedTool: $selectedTool
                    )
                    .clipped()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Edit Drawing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        toolPicker.setVisible(false, forFirstResponder: canvasView)
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("Clear") {
                            canvasView.drawing = PKDrawing()
                            isDirty = true
                        }
                        .foregroundColor(.red)
                        
                        Button("Save") {
                            saveDrawing()
                            toolPicker.setVisible(false, forFirstResponder: canvasView)
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .onAppear {
            loadExistingDrawing()
        }
        .onDisappear {
            toolPicker.setVisible(false, forFirstResponder: canvasView)
        }
    }
    
    private func loadExistingDrawing() {
        do {
            canvasView.drawing = try PKDrawing(data: drawingData)
        } catch {
            print("Failed to load drawing: \(error)")
        }
    }
    
    private func saveDrawing() {
        drawingData = canvasView.drawing.dataRepresentation()
        isDirty = false
    }
}

struct ReadOnlyDrawingView: View {
    let drawingData: Data
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let drawing = try? PKDrawing(data: drawingData) {
                    ScrollView([.horizontal, .vertical]) {
                        Image(uiImage: drawing.image(from: drawing.bounds, scale: UIScreen.main.scale))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding()
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding()
                }
            }
            .navigationTitle("Drawing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ToolButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color(.systemGray5))
            )
        }
    }
}

struct DrawingSheet: View {
    @Binding var isPresented: Bool
    @Binding var drawingData: Data?
    let title: String
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var canvasView = PKCanvasView()
    @State private var isDirty = false
    @State private var toolPicker = PKToolPicker()
    @State private var selectedTool: PKTool = PKInkingTool(.pen, color: .black, width: 3)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ZStack {
                    Color(.systemBackground)
                    
                    DrawingCanvasView(
                        canvasView: $canvasView,
                        isDirty: $isDirty,
                        toolPicker: $toolPicker,
                        selectedTool: $selectedTool
                    )
                    .clipped()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        toolPicker.setVisible(false, forFirstResponder: canvasView)
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("Clear") {
                            canvasView.drawing = PKDrawing()
                            isDirty = true
                        }
                        .foregroundColor(.red)
                        
                        Button("Save") {
                            saveDrawing()
                            toolPicker.setVisible(false, forFirstResponder: canvasView)
                            isPresented = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .onAppear {
            loadExistingDrawing()
        }
        .onDisappear {
            toolPicker.setVisible(false, forFirstResponder: canvasView)
        }
    }
    
    private func loadExistingDrawing() {
        if let data = drawingData {
            do {
                canvasView.drawing = try PKDrawing(data: data)
            } catch {
                print("Failed to load drawing: \(error)")
            }
        }
    }
    
    private func saveDrawing() {
        drawingData = canvasView.drawing.dataRepresentation()
        isDirty = false
    }
}

struct DrawingButton: View {
    let action: () -> Void
    let hasDrawing: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(hasDrawing ? themeManager.accentColor : Color(.systemGray4))
                    .frame(width: 32, height: 32)
                
                Image(systemName: hasDrawing ? "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(hasDrawing ? .white : .secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

