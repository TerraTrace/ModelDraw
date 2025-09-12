# ModelDraw Development Specification - Document Architecture Update
**Version:** 0.15  
**Date:** September 12, 2025  
**Changes:** Updated document architecture decisions based on Apple framework constraints and format analysis

## Document Architecture Decision Summary

### Key Decisions Made:
1. **Document Protocol**: Use SwiftUI `FileDocument` (struct-based) for simplicity and performance
2. **Native Format**: JSON-based .modeldraw files for human-readable, extensible storage  
3. **Export Format**: USD/USDZ via Apple's ModelIO framework for Reality Composer Pro compatibility
4. **Framework Constraint**: Native Apple frameworks only - no third-party libraries for file I/O

### Rationale:
- `FileDocument` provides background saving without UI blocking
- Struct-based documents avoid ObservableObject complexity in document layer
- JSON format enables easy debugging, version control, and future extensibility
- Separation of concerns: document handles data persistence, view models handle UI state

## Updated Data Model Architecture

### Core Document Structure
```swift
import SwiftUI
import RealityKit
import ModelIO
import UniformTypeIdentifiers

// MARK: - Document Protocol Implementation
struct ModelDrawDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.modelDrawDocument]
    
    var primitives: [GeometricPrimitive] = []
    var metadata: DocumentMetadata = DocumentMetadata()
    
    // FileDocument conformance
    init() {}
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let modelDrawFile = try JSONDecoder().decode(ModelDrawFile.self, from: data)
        self.primitives = modelDrawFile.primitives.map { $0.primitive }
        self.metadata = modelDrawFile.metadata
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let modelDrawFile = ModelDrawFile(
            primitives: primitives.map { AnyPrimitive($0) },
            metadata: metadata
        )
        
        let data = try JSONEncoder().encode(modelDrawFile)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Uniform Type Identifier
extension UTType {
    static var modelDrawDocument: UTType {
        UTType(exportedAs: "com.demeter.modeldraw.document")
    }
}
```

### JSON File Format Structure
```swift
// MARK: - File Format (JSON serialization)
struct ModelDrawFile: Codable {
    let version: String = "1.0"
    let primitives: [AnyPrimitive]
    let metadata: DocumentMetadata
    
    init(primitives: [AnyPrimitive], metadata: DocumentMetadata) {
        self.primitives = primitives
        self.metadata = metadata
    }
}

struct DocumentMetadata: Codable {
    let createdDate: Date
    let modifiedDate: Date
    let author: String?
    let notes: String?
    
    init() {
        let now = Date()
        self.createdDate = now
        self.modifiedDate = now
        self.author = NSFullUserName().isEmpty ? nil : NSFullUserName()
        self.notes = nil
    }
}

// MARK: - Type Erasure for Primitives
struct AnyPrimitive: Codable {
    let primitive: GeometricPrimitive
    
    init(_ primitive: GeometricPrimitive) {
        self.primitive = primitive
    }
    
    // Simple type discriminator approach
    private enum PrimitiveType: String, Codable {
        case box, sphere, cylinder, cone, torus
    }
    
    private enum CodingKeys: String, CodingKey {
        case type, data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(PrimitiveType.self, forKey: .type)
        
        switch type {
        case .box:
            primitive = try container.decode(BoxPrimitive.self, forKey: .data)
        case .sphere:
            primitive = try container.decode(SpherePrimitive.self, forKey: .data)
        case .cylinder:
            primitive = try container.decode(CylinderPrimitive.self, forKey: .data)
        case .cone:
            primitive = try container.decode(ConePrimitive.self, forKey: .data)
        case .torus:
            primitive = try container.decode(TorusPrimitive.self, forKey: .data)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch primitive {
        case let box as BoxPrimitive:
            try container.encode(PrimitiveType.box, forKey: .type)
            try container.encode(box, forKey: .data)
        case let sphere as SpherePrimitive:
            try container.encode(PrimitiveType.sphere, forKey: .type)
            try container.encode(sphere, forKey: .data)
        case let cylinder as CylinderPrimitive:
            try container.encode(PrimitiveType.cylinder, forKey: .type)
            try container.encode(cylinder, forKey: .data)
        case let cone as ConePrimitive:
            try container.encode(PrimitiveType.cone, forKey: .type)
            try container.encode(cone, forKey: .data)
        case let torus as TorusPrimitive:
            try container.encode(PrimitiveType.torus, forKey: .type)
            try container.encode(torus, forKey: .data)
        default:
            throw EncodingError.invalidValue(primitive, 
                EncodingError.Context(codingPath: encoder.codingPath, 
                                    debugDescription: "Unknown primitive type"))
        }
    }
}
```

### Example .modeldraw File Content
```json
{
  "version": "1.0",
  "metadata": {
    "createdDate": "2024-12-20T15:30:00Z",
    "modifiedDate": "2024-12-20T16:45:00Z",
    "author": "John Engineer",
    "notes": "Propulsion module mockup v1"
  },
  "primitives": [
    {
      "type": "box",
      "data": {
        "id": "A1B2C3D4-E5F6-7890-ABCD-EF1234567890",
        "name": "Main Tank",
        "transform": {
          "translation": [0.0, 0.0, 0.0],
          "rotation": [0.0, 0.0, 0.0, 1.0],
          "scale": [1.0, 1.0, 1.0]
        },
        "wallThickness": 0.05,
        "width": 2.0,
        "height": 3.0,
        "depth": 1.0
      }
    },
    {
      "type": "cylinder", 
      "data": {
        "id": "B2C3D4E5-F6G7-8901-BCDE-F23456789012",
        "name": "Thruster Nozzle",
        "transform": {
          "translation": [0.0, -1.6, 0.0],
          "rotation": [0.0, 0.0, 0.0, 1.0], 
          "scale": [1.0, 1.0, 1.0]
        },
        "wallThickness": 0.02,
        "radius": 0.3,
        "height": 0.8
      }
    }
  ]
}
```

## Updated Development Plan

### Phase 1: Project Setup & Core Architecture (Week 1-2)
**Goal:** Establish project foundation with FileDocument architecture

#### Step 1.1: Xcode Project Setup
- [x] Create new macOS Document-based SwiftUI app
- [x] Configure deployment target (macOS 13.0+)
- [x] Add required frameworks (RealityKit, ModelIO, UniformTypeIdentifiers)
- [x] Set up basic project structure

#### Step 1.2: Document Model Implementation  
- [ ] Define `GeometricPrimitive` protocol with Codable conformance
- [ ] Implement `Transform3D` struct for 3D transformations
- [ ] Create basic primitive types (Box, Sphere, Cylinder)
- [ ] Implement `ModelDrawDocument` struct conforming to FileDocument
- [ ] Add `AnyPrimitive` type erasure with simple type discriminator
- [ ] Configure UTType for .modeldraw file extension

#### Step 1.3: File I/O Testing
- [ ] Create test documents with sample primitives
- [ ] Verify JSON serialization/deserialization 
- [ ] Test document save/load cycle
- [ ] Validate file format readability

**Deliverable:** Robust FileDocument implementation with JSON persistence

### Phase 5: USD Export System (Week 7-8)
**Goal:** Export .modeldraw to USD format for Reality Composer Pro

#### Step 5.1: USD Foundation (Apple ModelIO)
- [ ] Research ModelIO USD export capabilities and limitations
- [ ] Create `USDExporter` class using MDLAsset
- [ ] Implement scene graph structure building
- [ ] Add named hierarchy support for RCP compatibility

#### Step 5.2: Geometry Export Pipeline
- [ ] Implement `generateMeshResource()` for each primitive
- [ ] Convert hollow meshes to USD format via ModelIO
- [ ] Add material assignments for visual differentiation
- [ ] Preserve transform hierarchies in USD structure

#### Step 5.3: Export Workflow
- [ ] Add "Export to USD" menu command
- [ ] Implement file save dialog with .usdz extension  
- [ ] Add export progress feedback
- [ ] Test compatibility with Reality Composer Pro import

**Deliverable:** Working USD export compatible with Reality Composer Pro

## Technical Implementation Notes

### FileDocument Benefits for ModelDraw:
- Background saving without UI blocking
- Simple struct-based implementation  
- No ObservableObject complexity in document layer
- Clean separation: document persistence vs. UI state management

### JSON Format Advantages:
- Human-readable for debugging and version control
- Easy extensibility for future primitive types
- Simple parsing with Foundation JSONDecoder/JSONEncoder
- Lightweight for typical model sizes (100s of primitives)

### USD Export Strategy:
- Use ModelIO's MDLAsset for USD generation
- Work around known SceneKit USD writing issues by using ModelIO directly  
- Maintain proper scene graph hierarchy for RCP animation support
- Export with meter units for RealityKit compatibility

### Future Extensibility:
- Add new primitive types by extending PrimitiveType enum
- Version field in JSON supports format migration
- Metadata structure allows additional document properties
- Type erasure pattern scales to additional primitive categories

## Success Criteria:
- ✅ Clean FileDocument implementation 
- ✅ Reliable JSON save/load cycle
- ✅ Extensible primitive type system
- ✅ USD export compatible with Reality Composer Pro
- ✅ Native Apple framework usage only
