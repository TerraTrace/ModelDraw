## Overview

USDFileManager is a specialized service that handles USD file reading and writing for ModelDraw. It operates as a pure file service with no business logic, spacecraft engineering knowledge, or UI concerns. DrawingManager calls USDFileManager for all file I/O operations.

**✅ Production Status:** Core functionality is complete and validated. Ready for integration with DrawingManager.## Development Phases

### Phase 1: USD Foundation (Current Priority)
- USDFileManager service implementation
- Basic cylinder and cone USD generation/parsing
- Geometric center transform system
- USD file validation and error handling
- Integration with existing DrawingManager

### Phase 2: USD Component System  
- Library component USD references
- Assembly hierarchy in USD format
- Component instance positioning and transform management
- USD composition arc utilization for library dependencies

### Phase 3: Advanced USD Integration
- Project navigator with USD hierarchy display
- Component selection and properties display from USD attributes
- 3D visualization improvements with direct USD loading
- Camera controls and scene management

### Phase 4: Production USD System
- Mission-class template creation in USD format
- Template-based project generation
- Export optimizations for MissionViz integration
- Mass properties calculation from USD geometry
- Reality Composer Pro workflow integration# USDFileManager Specification v1.1

**Date:** September 15, 2025  
**Status:** Phase 1B Complete - Production Ready for Cylinder and Cone primitives  
**Architecture:** Service manager called by DrawingManager for all USD file operations  
**Validation:** ✅ Tested and validated in Reality Composer Pro

## Implementation Status

### ✅ Phase 1A: Complete (Cylinder Support)
- **USD file writing** - Fully implemented and tested
- **Cylinder primitives** - Perfect geometry generation
- **Error handling** - Comprehensive error types and validation
- **File system operations** - Sandboxed app compatibility
- **RCP validation** - Successfully imports generated USD files

### ✅ Phase 1B: Complete (Cone Support + Assemblies)  
- **Cone primitives** - Full geometry support with proper orientation
- **Assembly hierarchies** - Multi-component spacecraft models
- **Transform system** - Geometric center positioning with quaternion rotations
- **Spacecraft modeling** - Validated complete rocket (cylinder + cone assembly)
- **Production ready** - All core functionality working perfectly

### 🔄 Phase 2: Next (DrawingManager Integration)
- **USD conversion methods** - Convert ModelDraw objects to/from USD
- **File operation integration** - Replace JSON persistence in DrawingManager
- **Library reference system** - USD composition arcs for component libraries

### 📋 Phase 3: Future (Advanced Features)
- **USD file reading** - Parse USD files back to USDPrim structures
- **Additional primitives** - Sphere, custom meshes
- **Animation support** - Time-varying attributes
- **Material schemas** - Advanced material properties

## Key Design Principles

1. **Pure file service** - No spacecraft engineering logic or anchor calculations ✅
2. **USD-native data structures** - Uses USD prim/attribute model directly ✅
3. **Geometric center transforms** - Compatible with USD, RCP, and RealityKit conventions ✅
4. **Type-safe interface** - Leverages existing Vector3D and Quaternion infrastructure ✅
5. **No UI dependencies** - Service can be tested independently ✅
6. **RCP compatibility** - Generates USD files that load perfectly in Reality Composer Pro ✅

## Data Structures

### Core USD Data Types

```swift
/// Primary data structure representing a USD primitive
struct USDPrim {
    let name: String                    // Prim name in USD hierarchy
    let type: String                    // "Cylinder", "Cone", "Xform", "Assembly"
    let attributes: [String: USDAttribute]  // All prim attributes
    let transform: USDTransform?        // Position/orientation (nil for non-geometric prims)
    let children: [USDPrim]             // Child prims in hierarchy
    let metadata: [String: String]      // CustomData for ModelDraw-specific info
}

/// USD attribute with typed values
struct USDAttribute {
    let name: String        // Attribute name ("height", "radius", etc.)
    let value: Any          // Typed value (Double, String, etc.)
    let valueType: String   // USD type ("double", "string", "float3", etc.)
    let timeVarying: Bool   // Whether attribute changes over time (default: false)
}

/// Transform using geometric center convention
struct USDTransform {
    let position: Vector3D      // Geometric center location in 3D space
    let orientation: Quaternion // Rotation around geometric center
}

/// Stage-level metadata and settings
struct USDStage {
    let defaultPrim: String?        // Default prim name
    let metersPerUnit: Double       // Scale factor (default: 1.0)
    let upAxis: String             // "Y", "Z" (default: "Y")
    let startTimeCode: Double?     // Animation start time
    let endTimeCode: Double?       // Animation end time
    let customLayerData: [String: String]  // Stage-level metadata
}

/// Complete USD file representation
struct USDFile {
    let stage: USDStage         // Stage settings and metadata
    let rootPrims: [USDPrim]    // Top-level prims in the file
}
```

## Service Interface

### Primary Operations

```swift
class USDFileManager {
    static let shared = USDFileManager()
    private init() {}
    
    // MARK: - Core Operations (✅ Implemented and Tested)
    
    /// Write USD file to disk
    /// - Parameters:
    ///   - usdFile: Complete USD file structure to write
    ///   - url: Target file URL (.usd extension)
    /// - Throws: USDFileError for file system or formatting errors
    /// - Status: ✅ Production ready, fully tested with RCP validation
    func writeUSDFile(_ usdFile: USDFile, to url: URL) throws
    
    /// Validate USD file syntax without full parsing
    /// - Parameter url: File URL to validate  
    /// - Returns: True if file is valid USD format
    /// - Status: ✅ Basic validation implemented
    func validateUSDFile(at url: URL) -> Bool
    
    // MARK: - Phase 2 Operations (🔄 Planned)
    
    /// Read USD file from disk  
    /// - Parameter url: Source file URL
    /// - Returns: Parsed USD file structure
    /// - Throws: USDFileError for missing files or parse errors
    /// - Status: 🔄 Not yet implemented
    func readUSDFile(from url: URL) throws -> USDFile
}
```

### Error Handling

```swift
enum USDFileError: Error, LocalizedError {
    case fileNotFound(path: String)
    case invalidUSDSyntax(line: Int, message: String)
    case unsupportedPrimType(type: String)
    case missingRequiredAttribute(prim: String, attribute: String)
    case writePermissionDenied(path: String)
    case invalidFileExtension(expected: String, actual: String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "USD file not found: \(path)"
        case .invalidUSDSyntax(let line, let message):
            return "Invalid USD syntax at line \(line): \(message)"
        case .unsupportedPrimType(let type):
            return "Unsupported USD primitive type: \(type)"
        case .missingRequiredAttribute(let prim, let attribute):
            return "Missing required attribute '\(attribute)' on prim '\(prim)'"
        case .writePermissionDenied(let path):
            return "Write permission denied: \(path)"
        case .invalidFileExtension(let expected, let actual):
            return "Invalid file extension. Expected \(expected), got \(actual)"
        }
    }
}
```

## USD Format Mapping

### ✅ Implemented Primitives

**Cylinder Primitive:** (✅ Production Ready)
```swift
// Input from DrawingManager
let cylinder = USDPrim(
    name: "PropellantTank",
    type: "Cylinder", 
    attributes: [
        "height": USDAttribute(name: "height", value: 2.5, valueType: "double"),
        "radius": USDAttribute(name: "radius", value: 0.8, valueType: "double")
    ],
    transform: USDTransform(
        position: Vector3D(x: 0, y: 1.25, z: 0),  // Geometric center
        orientation: Quaternion.from(axis: Vector3D.unitX, angle: -Double.pi/2)  // Upright orientation
    ),
    children: [],
    metadata: [
        "modelDrawType": "cylinder",
        "modelDrawID": "12345-abcd",
        "wallThickness": "0.05",
        "material": "aluminum"
    ]
)

// Output USD format - Validated in Reality Composer Pro ✅
#usda 1.0
(
    defaultPrim = "PropellantTank"
    metersPerUnit = 1
    upAxis = "Y"
)

def Cylinder "PropellantTank" (
    customData = {
        string modelDrawType = "cylinder"
        string modelDrawID = "12345-abcd"
        string wallThickness = "0.05"
        string material = "aluminum"
    }
)
{
    double height = 2.5
    double radius = 0.8
    double3 xformOp:translate = (0, 1.25, 0)
    quatf xformOp:orient = (0.707, -0.707, 0, 0)
    uniform token[] xformOpOrder = ["xformOp:translate", "xformOp:orient"]
}
```

**Cone Primitive:** (✅ Production Ready)
```swift
// Input from DrawingManager - Same structure as cylinder
let cone = USDPrim(
    name: "NoseCone",
    type: "Cone",
    attributes: [
        "height": USDAttribute(name: "height", value: 1.5, valueType: "double"),
        "radius": USDAttribute(name: "radius", value: 1.0, valueType: "double")
    ],
    transform: USDTransform(
        position: Vector3D(x: 0, y: 4.0, z: 0),
        orientation: Quaternion.from(axis: Vector3D.unitX, angle: -Double.pi/2)  // Pointy end up
    ),
    metadata: [
        "modelDrawType": "cone",
        "material": "carbonFiber"
    ]
)

// Output USD format - Validated in Reality Composer Pro ✅
def Cone "NoseCone" (
    customData = {
        string modelDrawType = "cone"
        string material = "carbonFiber"
    }
)
{
    double height = 1.5
    double radius = 1.0
    double3 xformOp:translate = (0, 4.0, 0)
    quatf xformOp:orient = (0.707, -0.707, 0, 0)
    uniform token[] xformOpOrder = ["xformOp:translate", "xformOp:orient"]
}
```

**Assembly Primitive:** (✅ Production Ready)
```swift
// Spacecraft assembly combining cylinder + cone - Validated in RCP ✅
let spacecraft = USDPrim(
    name: "OrientedSpacecraft",
    type: "Xform",
    transform: USDTransform(position: Vector3D.zero),
    children: [propellantTank, noseCone],  // Cylinder + Cone
    metadata: [
        "modelDrawType": "assembly",
        "assemblyType": "spacecraft"
    ]
)

// Output USD format - Perfect hierarchy in RCP ✅
def Xform "OrientedSpacecraft" (
    customData = {
        string modelDrawType = "assembly"
        string assemblyType = "spacecraft"
    }
)
{
    double3 xformOp:translate = (0, 0, 0)
    quatf xformOp:orient = (1, 0, 0, 0)
    uniform token[] xformOpOrder = ["xformOp:translate", "xformOp:orient"]
    
    # Child primitives (PropellantTank and NoseCone)
    # Each with their own transforms and metadata
}
```

### 🔄 Planned Primitives (Phase 3)
- **Sphere** - Basic spherical geometry
- **Custom Meshes** - Complex imported geometry
- **Materials** - Advanced material schemas

### Custom Attributes

**Engineering Metadata Storage:**
- **modelDrawType**: Component type for ModelDraw recognition
- **modelDrawID**: Unique identifier for component tracking
- **wallThickness**: Engineering parameter (stored as string for flexibility)
- **material**: Material specification
- **Additional**: Any key-value pairs needed for spacecraft engineering

**Storage Location:**
All ModelDraw-specific data goes in USD `customData` dictionary to avoid conflicts with standard USD attributes.

## Transform Convention

### ✅ Validated Geometric Center Positioning

**Spacecraft Transform Best Practices:**
All primitives use geometric center as anchor point with proven orientation:
- **Cylinder**: Center of height, center of circular cross-section
- **Cone**: Geometric center (1/3 up from base)  
- **Assembly**: Calculated center of mass or designated assembly center

**✅ Proven Transform Composition:**
1. **Position**: Vector3D specifying where geometric center goes
2. **Orientation**: Quaternion rotation applied around geometric center
   - **Upright spacecraft orientation**: `Quaternion.from(axis: Vector3D.unitX, angle: -Double.pi/2)`
   - **Critical discovery**: -90° X rotation needed for "pointy end up" spacecraft
3. **USD Output**: Direct mapping to xformOp:translate and xformOp:orient

**✅ RCP Validation Results:**
- Perfect cylinder positioning and orientation
- Correct cone orientation (pointy end up)
- Proper assembly hierarchy (PropellantTank + NoseCone)
- Accurate geometric center calculations
- Clean transform inheritance

**Coordinate System:**
- **Units**: Meters (spacecraft engineering standard) ✅
- **Up Axis**: +Y (USD/RealityKit standard) ✅  
- **Handedness**: Right-handed coordinate system ✅
- **Orientation**: -90° X rotation for upright spacecraft geometry ✅

## Integration with DrawingManager

### Workflow Pattern

```swift
// DrawingManager calls USDFileManager for save operation
func saveAssembly(_ assembly: Assembly, to url: URL) throws {
    // 1. Convert Assembly to USDPrim structure
    let usdPrim = convertAssemblyToUSDPrim(assembly)
    
    // 2. Create USD file structure
    let usdFile = USDFile(
        stage: USDStage(defaultPrim: assembly.name, metersPerUnit: 1.0, upAxis: "Y"),
        rootPrims: [usdPrim]
    )
    
    // 3. Call USDFileManager to write file
    try USDFileManager.shared.writeUSDFile(usdFile, to: url)
}

// DrawingManager calls USDFileManager for load operation  
func loadAssembly(from url: URL) throws -> Assembly {
    // 1. Call USDFileManager to read file
    let usdFile = try USDFileManager.shared.readUSDFile(from: url)
    
    // 2. Convert USDPrim structure to Assembly
    let assembly = try convertUSDPrimToAssembly(usdFile.rootPrims[0])
    
    return assembly
}
```

### Responsibility Division

**USDFileManager Responsibilities:**
- USD file format reading/writing
- USD syntax validation
- Prim/attribute parsing and generation
- Error handling for file operations

**DrawingManager Responsibilities:**  
- ModelDraw ↔ USDPrim conversion
- Anchor point calculations (if still needed)
- Assembly hierarchy management
- Library reference resolution
- Project-level file organization

## Performance Considerations

### File Size Optimization
- **Minimal USD**: Only essential prims and attributes
- **Efficient transforms**: Single transform per prim
- **Compact metadata**: String-based custom data for flexibility

### Memory Management
- **Lazy loading**: Read only requested file sections when possible
- **Streaming**: For large assembly files with many components
- **Caching**: Reuse parsed USD structures when appropriate

## Future Extensions

### Version 1.1 Planned Features
- **Animation support**: Time-varying attributes for kinematic analysis
- **Material schemas**: Enhanced material property storage
- **Reference handling**: USD references for library components
- **Multi-file assemblies**: USD composition arcs for complex projects

### Integration Points
- **RealityKit loading**: Direct USD file loading for 3D visualization
- **Export formats**: Additional USD variants (USDA, USDC, USDZ)
- **Validation**: Enhanced USD schema validation for spacecraft requirements

---

**Status**: Specification v1.1 - ✅ Phase 1B Complete, Production Ready  
**Dependencies**: Vector3D, Quaternion infrastructure (✅ Available and working)  
**Validation**: ✅ Tested and verified in Reality Composer Pro  
**Next Steps**: Phase 2 - Integration with DrawingManager for complete USD workflow  

**Key Achievements**: 
- ✅ Complete cylinder and cone USD generation
- ✅ Perfect assembly hierarchies  
- ✅ RCP compatibility validated
- ✅ Transform system proven
- ✅ Ready for production use