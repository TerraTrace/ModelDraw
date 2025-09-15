# USDFileManager Specification v1.0

**Date:** September 15, 2025  
**Purpose:** USD-based file service for ModelDraw replacing JSON persistence  
**Architecture:** Service manager called by DrawingManager for all USD file operations

## Overview

USDFileManager is a specialized service that handles USD file reading and writing for ModelDraw. It operates as a pure file service with no business logic, spacecraft engineering knowledge, or UI concerns. DrawingManager calls USDFileManager for all file I/O operations.

### Key Design Principles

1. **Pure file service** - No spacecraft engineering logic or anchor calculations
2. **USD-native data structures** - Uses USD prim/attribute model directly  
3. **Geometric center transforms** - Compatible with USD, RCP, and RealityKit conventions
4. **Type-safe interface** - Leverages existing Vector3D and Quaternion infrastructure
5. **No UI dependencies** - Service can be tested independently

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
    
    // MARK: - File Operations
    
    /// Write USD file to disk
    /// - Parameters:
    ///   - usdFile: Complete USD file structure to write
    ///   - url: Target file URL (.usd extension)
    /// - Throws: USDFileError for file system or formatting errors
    func writeUSDFile(_ usdFile: USDFile, to url: URL) throws
    
    /// Read USD file from disk  
    /// - Parameter url: Source file URL
    /// - Returns: Parsed USD file structure
    /// - Throws: USDFileError for missing files or parse errors
    func readUSDFile(from url: URL) throws -> USDFile
    
    /// Validate USD file syntax without full parsing
    /// - Parameter url: File URL to validate
    /// - Returns: True if file is valid USD format
    func validateUSDFile(at url: URL) -> Bool
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

### Geometric Primitives

**Cylinder Primitive:**
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
        orientation: Quaternion.identity
    ),
    children: [],
    metadata: [
        "modelDrawType": "cylinder",
        "modelDrawID": "12345-abcd",
        "wallThickness": "0.05",
        "material": "aluminum"
    ]
)

// Output USD format
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
    quatf xformOp:orient = (1, 0, 0, 0)
    uniform token[] xformOpOrder = ["xformOp:translate", "xformOp:orient"]
}
```

**Assembly Primitive:**
```swift
// Input from DrawingManager
let assembly = USDPrim(
    name: "PropulsionModule",
    type: "Xform",  // USD transform group
    attributes: [:], // No geometry attributes
    transform: USDTransform(
        position: Vector3D(x: 0, y: 0, z: -3),
        orientation: Quaternion.identity
    ),
    children: [cylinderPrim, conePrim],  // Child components
    metadata: [
        "modelDrawType": "assembly",
        "modelDrawID": "assembly-5678"
    ]
)

// Output USD format  
def Xform "PropulsionModule" (
    customData = {
        string modelDrawType = "assembly"
        string modelDrawID = "assembly-5678"
    }
)
{
    double3 xformOp:translate = (0, 0, -3)
    quatf xformOp:orient = (1, 0, 0, 0)
    uniform token[] xformOpOrder = ["xformOp:translate", "xformOp:orient"]
    
    # Child primitives defined here...
}
```

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

### Geometric Center Positioning

**All primitives use geometric center as anchor point:**
- **Cylinder**: Center of height, center of circular cross-section
- **Cone**: Geometric center (1/3 up from base)  
- **Sphere**: Center of sphere
- **Assembly**: Calculated center of mass or designated assembly center

**Transform Composition:**
1. **Position**: Vector3D specifying where geometric center goes
2. **Orientation**: Quaternion rotation applied around geometric center
3. **USD Output**: Direct mapping to xformOp:translate and xformOp:orient

**Coordinate System:**
- **Units**: Meters (spacecraft engineering standard)
- **Up Axis**: +Y (USD/RealityKit standard)
- **Handedness**: Right-handed coordinate system

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

**Status**: Specification v1.0 - Ready for implementation  
**Dependencies**: Vector3D, Quaternion infrastructure  
**Next Steps**: Implement core USDFileManager class with basic cylinder/cone support