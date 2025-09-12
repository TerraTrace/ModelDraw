# ModelDraw Development Specification

## Project Overview
**ModelDraw** is a macOS CAD warm-up application for creating 3D geometric models that export to Reality Composer Pro via USDC format. The app enables rapid prototyping of spacecraft components with proper hierarchical structure for downstream animation/articulation.

## Technical Architecture

### Platform Requirements
- **Target Platform:** macOS 13.0+
- **Development:** Xcode 15+, Swift 5.9+
- **UI Framework:** SwiftUI
- **3D Framework:** RealityKit
- **Export Format:** USDC (binary USD)

### Core Frameworks
```swift
import SwiftUI
import RealityKit
import ModelIO          // For USD export
import Combine          // For reactive updates
import UniformTypeIdentifiers  // For file handling
```

## Data Model Architecture

### Core Data Structures
```swift
// Main document model
class ModelDrawDocument: ObservableObject {
    @Published var primitives: [GeometricPrimitive] = []
    @Published var selectedPrimitiveIDs: Set<UUID> = []
    var documentURL: URL?
    var documentName: String = "Untitled"
}

// Base primitive protocol
protocol GeometricPrimitive: Identifiable, Codable {
    var id: UUID { get }
    var name: String { get set }
    var transform: Transform3D { get set }
    var wallThickness: Float { get set }
    
    func generateMeshResource() -> MeshResource
    func generateUSDGeometry() -> USDGeometry
}

// Transform representation
struct Transform3D: Codable {
    var translation: SIMD3<Float> = SIMD3(0, 0, 0)
    var rotation: simd_quatf = simd_quatf(angle: 0, axis: SIMD3(0, 1, 0))
    var scale: SIMD3<Float> = SIMD3(1, 1, 1)
}

// Primitive implementations
struct BoxPrimitive: GeometricPrimitive {
    let id = UUID()
    var name: String = "Box"
    var transform: Transform3D = Transform3D()
    var wallThickness: Float = 0.1
    
    // Box-specific parameters
    var width: Float = 1.0
    var height: Float = 1.0
    var depth: Float = 1.0
}

struct SpherePrimitive: GeometricPrimitive {
    let id = UUID()
    var name: String = "Sphere"
    var transform: Transform3D = Transform3D()
    var wallThickness: Float = 0.1
    
    // Sphere-specific parameters
    var radius: Float = 0.5
}

struct CylinderPrimitive: GeometricPrimitive {
    let id = UUID()
    var name: String = "Cylinder"
    var transform: Transform3D = Transform3D()
    var wallThickness: Float = 0.1
    
    // Cylinder-specific parameters
    var radius: Float = 0.5
    var height: Float = 1.0
}

// Additional primitives: ConePrimitive, TorusPrimitive
```

### File Format
```swift
// Native document format (JSON-based)
struct ModelDrawFile: Codable {
    let version: String = "1.0"
    let primitives: [AnyPrimitive] // Type-erased primitives
    let metadata: DocumentMetadata
}

struct DocumentMetadata: Codable {
    let createdDate: Date
    let modifiedDate: Date
    let author: String
    let description: String
}
```

## UI Architecture

### App Structure
```swift
@main
struct ModelDrawApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: ModelDrawDocument()) { file in
            ContentView(document: file.$document)
        }
        .commands {
            ModelDrawCommands()
        }
    }
}

struct ContentView: View {
    @Binding var document: ModelDrawDocument
    
    var body: some View {
        HSplitView {
            HierarchySidebar(document: document)
                .frame(minWidth: 200, maxWidth: 300)
            
            VSplitView {
                ViewportView(document: document)
                ToolPalette(document: document)
                    .frame(height: 200)
            }
        }
        .navigationTitle(document.documentName)
    }
}
```

### Component Views
```swift
// Hierarchy sidebar
struct HierarchySidebar: View {
    @ObservedObject var document: ModelDrawDocument
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Scene Hierarchy")
                .font(.headline)
            
            List(document.primitives, selection: $document.selectedPrimitiveIDs) { primitive in
                HierarchyRow(primitive: primitive)
            }
        }
    }
}

// 3D viewport
struct ViewportView: UIViewRepresentable {
    @ObservedObject var document: ModelDrawDocument
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        // Configure orbit camera
        arView.cameraMode = .nonAR
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update scene based on document changes
        updateScene(uiView, with: document.primitives)
    }
}

// Tool palette with tabs
struct ToolPalette: View {
    @ObservedObject var document: ModelDrawDocument
    @State private var selectedTab = "Create"
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CreateTab(document: document)
                .tabItem { Text("Create") }
            
            TransformTab(document: document)
                .tabItem { Text("Transform") }
            
            EditTab(document: document)
                .tabItem { Text("Edit") }
        }
    }
}
```

## Step-by-Step Development Plan

### Phase 1: Project Setup & Core Architecture (Week 1-2)
**Goal:** Establish project foundation and basic data model

#### Step 1.1: Xcode Project Setup
- [ ] Create new macOS Document-based SwiftUI app
- [ ] Configure deployment target (macOS 13.0+)
- [ ] Add required frameworks (RealityKit, ModelIO)
- [ ] Set up basic project structure

#### Step 1.2: Core Data Model Implementation
- [ ] Define `GeometricPrimitive` protocol
- [ ] Implement `Transform3D` struct
- [ ] Create basic primitive types (Box, Sphere, Cylinder)
- [ ] Implement `ModelDrawDocument` class
- [ ] Add Codable support for persistence

#### Step 1.3: Basic UI Structure
- [ ] Create three-pane layout (HSplitView)
- [ ] Implement placeholder views for sidebar, viewport, palette
- [ ] Add basic navigation and window management

**Deliverable:** App launches with basic UI structure and data model in place

### Phase 2: Hierarchy Management (Week 3)
**Goal:** Functional hierarchy sidebar with selection

#### Step 2.1: Hierarchy Sidebar Implementation
- [ ] Build `HierarchySidebar` with List view
- [ ] Implement primitive name editing (inline)
- [ ] Add selection handling (highlight in list)
- [ ] Connect selection to document state

#### Step 2.2: Primitive Management
- [ ] Add primitive creation methods to document
- [ ] Implement delete functionality
- [ ] Add basic primitive duplication
- [ ] Test hierarchy updates and selection sync

**Deliverable:** Working hierarchy sidebar that manages primitive list

### Phase 3: 3D Viewport (Week 4-5)
**Goal:** Display primitives in 3D viewport with orbit camera

#### Step 3.1: RealityKit Integration
- [ ] Implement `ViewportView` with ARView
- [ ] Configure non-AR camera mode
- [ ] Add basic orbit camera controls (pan, zoom, rotate)
- [ ] Set up scene lighting and environment

#### Step 3.2: Primitive Visualization
- [ ] Implement `generateMeshResource()` for each primitive type
- [ ] Create hollow geometry with wall thickness
- [ ] Add basic material system (colors for identification)
- [ ] Connect document changes to scene updates

#### Step 3.3: Selection Visualization
- [ ] Add highlight rendering for selected primitives
- [ ] Implement visual feedback (outline, color change)
- [ ] Sync selection between sidebar and viewport

**Deliverable:** 3D viewport displays primitives with working selection

### Phase 4: Tool Palette & Primitive Creation (Week 6)
**Goal:** Create tab and basic primitive placement

#### Step 4.1: Tabbed Tool Palette
- [ ] Implement `ToolPalette` with TabView
- [ ] Create placeholder tabs (Create, Transform, Edit)
- [ ] Add basic tab styling and layout

#### Step 4.2: Create Tab Implementation  
- [ ] Add primitive type buttons (Box, Sphere, Cylinder, Cone, Torus)
- [ ] Implement click-to-place workflow
- [ ] Place primitives at origin with default parameters
- [ ] Add primitive to document and update viewport

#### Step 4.3: Basic Parameter Editing
- [ ] Add properties panel for selected primitive
- [ ] Implement wall thickness editing
- [ ] Add size parameter controls (width, height, radius, etc.)
- [ ] Update mesh when parameters change

**Deliverable:** Can create and modify basic primitives

### Phase 5: File I/O System (Week 7-8)
**Goal:** Save/load native document format

#### Step 5.1: Document Persistence
- [ ] Implement `ModelDrawFile` encoding/decoding
- [ ] Add type erasure for `AnyPrimitive` serialization
- [ ] Create document save/load methods
- [ ] Add file extension registration (.modeldraw)

#### Step 5.2: File Management Integration
- [ ] Integrate with SwiftUI DocumentGroup
- [ ] Add File menu commands (New, Open, Save, Save As)
- [ ] Implement document dirty state tracking
- [ ] Add save confirmation dialogs

#### Step 5.3: Error Handling
- [ ] Add comprehensive error handling for file operations
- [ ] Create user-friendly error messages
- [ ] Implement recovery for corrupted files
- [ ] Add file validation

**Deliverable:** Robust save/load functionality for native format

### Phase 6: USDC Export (Week 9-10)
**Goal:** Export models to Reality Composer Pro compatible format

#### Step 6.1: USD Foundation
- [ ] Research ModelIO USD export capabilities
- [ ] Create `USDExporter` class
- [ ] Implement scene graph structure building
- [ ] Add named hierarchy support

#### Step 6.2: Geometry Export
- [ ] Implement `generateUSDGeometry()` for each primitive
- [ ] Convert hollow meshes to USD format
- [ ] Add material assignments
- [ ] Preserve transform hierarchies

#### Step 6.3: Export Pipeline
- [ ] Add "Export to USD" menu command
- [ ] Implement file save dialog with .usdc extension
- [ ] Add export progress feedback
- [ ] Test compatibility with Reality Composer Pro

#### Step 6.4: Validation & Testing
- [ ] Create test models with various primitives
- [ ] Verify imports in Reality Composer Pro
- [ ] Test hierarchy preservation
- [ ] Validate animation-ready structure

**Deliverable:** Working USDC export that Reality Composer Pro can import

### Phase 7: Polish & Testing (Week 11-12)
**Goal:** Production-ready MVP

#### Step 7.1: UI Polish
- [ ] Add keyboard shortcuts for common operations
- [ ] Improve visual design and spacing
- [ ] Add tooltips and user guidance
- [ ] Implement undo/redo system

#### Step 7.2: Performance Optimization
- [ ] Optimize viewport rendering for many primitives
- [ ] Improve file I/O performance
- [ ] Add progress indicators for slow operations
- [ ] Memory usage optimization

#### Step 7.3: Testing & Bug Fixes
- [ ] Comprehensive testing of all features
- [ ] Edge case handling (empty documents, invalid parameters)
- [ ] Cross-component integration testing
- [ ] Performance testing with large models

#### Step 7.4: Documentation
- [ ] Code documentation and architecture notes
- [ ] User guide for basic operations
- [ ] Reality Composer Pro workflow documentation
- [ ] Known limitations and future roadmap

**Deliverable:** Polished MVP ready for use and feedback

## Technical Implementation Notes

### RealityKit Considerations
- Use `ModelEntity` for primitive visualization
- Implement custom mesh generation for hollow geometries
- Handle material assignment for visual differentiation
- Consider LOD for performance with many primitives

### USD Export Technical Details
- Use ModelIO's `MDLAsset` for USD generation
- Maintain proper scene graph hierarchy
- Export with appropriate units (meters for RealityKit compatibility)
- Include material definitions for RCP import

### Performance Targets
- Smooth 60fps viewport interaction with 100+ primitives
- Sub-second file save/load for typical models
- Instant primitive parameter updates
- Responsive UI throughout all operations

### Future Extension Points
- Plugin architecture for additional primitive types
- Scripting/automation interface (for Claude integration)
- Advanced constraint system
- Collaborative editing features

## Testing Strategy

### Unit Tests
- Primitive geometry generation
- Document serialization/deserialization
- Transform calculations
- USD export functionality

### Integration Tests
- Complete save/load cycles
- Viewport-sidebar synchronization
- Export-import workflow with RCP
- Multi-primitive scene handling

### User Testing
- Basic modeling workflow
- File management operations
- Export to Reality Composer Pro
- Performance with realistic models

## Estimated Timeline
**Total Development Time:** 12 weeks (3 months)
- **Core Foundation:** 4 weeks
- **UI Implementation:** 4 weeks  
- **Export System:** 2 weeks
- **Polish & Testing:** 2 weeks

This timeline assumes one full-time developer with SwiftUI and RealityKit experience.