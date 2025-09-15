# ModelDraw Development Specification v0.18
**Date:** September 15, 2025  
**Changes:** USD-based file system architecture, USDFileManager service integration, geometric center transform convention

## Executive Summary

ModelDraw is positioned as the **"preliminary design CAD"** tool within the Demeter spacecraft engineering ecosystem. It bridges mission requirements (established in Demeter PM interviews) and mission performance validation (done in MissionViz) by providing rapid spacecraft geometry modeling, mass properties calculation, and subsystem layout capabilities.

### Key Architectural Decisions

1. **USD-Based File System**: Native USD format for all persistence, replacing JSON
2. **USDFileManager Service**: Specialized service for USD file operations called by DrawingManager
3. **Geometric Center Transforms**: Compatible with USD, RCP, and RealityKit conventions
4. **Component Library System**: Shared library components referenced via USD composition arcs
5. **Demeter Workflow Integration**: Templates based on mission class from PM interview process
6. **Preliminary Design Focus**: Sizing, mass properties, and performance optimization - not manufacturing details

## System Architecture

### File System Organization

```
~/Documents/ModelDraw/
├── Projects/
│   ├── Lunar-Lander-Project/
│   │   ├── Lunar_Lander_Project.usd             # Project metadata (USD format)
│   │   ├── Flight-Configuration/
│   │   │   ├── Flight_Configuration.usd         # Assembly definition (USD)
│   │   │   ├── Descent-Stage/
│   │   │   │   ├── Descent_Stage.usd            # Sub-assembly (USD)
│   │   │   │   ├── Engine_Module.usd            # Primitive component (USD)
│   │   │   │   └── Propellant_Tank.usd          # Primitive component (USD)
│   │   │   └── Ascent-Stage/
│   │   └── Ground-Test-Configuration/
│   └── ISS-Cargo-Vehicle/
├── Library/
│   ├── Standard-Components/
│   │   ├── Reaction-Wheels/
│   │   │   └── Standard_10Nms_RWA.usd           # Library component (USD)
│   │   └── Thrusters/
│   │       └── Standard_100N_Thruster.usd       # Library component (USD)
│   └── Common-Assemblies/
│       └── Avionics-Bay/
└── Templates/
    ├── CubeSat-3U/
    ├── Small-Spacecraft/
    └── Cargo-Vehicle/
```

### File Type Definitions

#### .usd Project Files
```
#usda 1.0
(
    defaultPrim = "Lunar_Lander_Project"
    metersPerUnit = 1
    upAxis = "Y"
    customLayerData = {
        string modelDrawType = "project"
        string projectName = "Lunar Lander Project"
        string description = "Artemis III Commercial Lunar Lander"
        string responsibleEngineer = "Jane Smith"
        string missionClass = "Lunar Surface"
        string targetLaunchDate = "2026-Q3"
        string createdDate = "2025-09-15T12:00:00Z"
    }
)

def Xform "Lunar_Lander_Project" (
    customData = {
        string modelDrawType = "project"
        string[] configurations = ["Flight-Configuration", "Ground-Test-Configuration"]
        string[] libraryDependencies = ["Library/Propulsion/Standard-100N-Thruster", "Library/GNC/Reaction-Wheel-Assembly"]
    }
)
{
    # Project hierarchy and references defined here
}
```

#### .usd Assembly Files with Library References
```
#usda 1.0
(
    defaultPrim = "Aft_Propulsion_Module"
    metersPerUnit = 1
    upAxis = "Y"
)

def Xform "Aft_Propulsion_Module" (
    customData = {
        string modelDrawType = "assembly"
        string modelDrawID = "12345-abcd"
        string assemblyType = "propulsion"
        double massEstimate = 45.2
    }
)
{
    double3 xformOp:translate = (0, 0, -2.5)
    quatf xformOp:orient = (1, 0, 0, 0)
    uniform token[] xformOpOrder = ["xformOp:translate", "xformOp:orient"]
    
    def "Thruster_Aft_Port" (
        customData = {
            string modelDrawType = "libraryReference"
            string libraryPath = "Library/Propulsion/Standard-100N-Thruster"
            string instanceID = "thruster-aft-port"
        }
        references = @Library/Propulsion/Standard-100N-Thruster.usd@
    )
    {
        double3 xformOp:translate = (1.2, -0.8, 0)
        quatf xformOp:orient = (1, 0, 0, 0)
        uniform token[] xformOpOrder = ["xformOp:translate", "xformOp:orient"]
    }
    
    def Cylinder "Mounting_Structure" (
        customData = {
            string modelDrawType = "localPrimitive"
            string primitiveID = "mounting-structure-id"
            string material = "aluminum"
            double wallThickness = 0.05
        }
    )
    {
        double height = 0.5
        double radius = 0.8
        double3 xformOp:translate = (0, 0, 0)
        quatf xformOp:orient = (1, 0, 0, 0)
        uniform token[] xformOpOrder = ["xformOp:translate", "xformOp:orient"]
    }
}
```

## Data Architecture

### Core Classes

```swift
// USD File Management (Service)
class USDFileManager {
    static let shared = USDFileManager()
    private init() {}
    
    func writeUSDFile(_ usdFile: USDFile, to url: URL) throws
    func readUSDFile(from url: URL) throws -> USDFile
    func validateUSDFile(at url: URL) -> Bool
}

// Drawing Management (Singleton) - Updated for USD
class DrawingManager {
    static let shared = DrawingManager()
    private init() {}
    
    func loadProject(from folderURL: URL) throws -> ProjectData
    func saveProject(_ project: ProjectData) throws
    func createProject(from template: String, named: String) throws -> ProjectData
    func scanDocumentsDirectory() -> [ProjectInfo]
    
    // USD conversion methods
    private func convertAssemblyToUSDPrim(_ assembly: Assembly) -> USDPrim
    private func convertUSDPrimToAssembly(_ prim: USDPrim) throws -> Assembly
}

// UI State Management (Observable)
@Observable
class ViewModel {
    var selectedItem: SelectedItem?
    var currentProject: ProjectData?
    var cameraPosition: SIMD3<Float>
    var cameraRotation: simd_quatf
    
    func loadProject(_ projectInfo: ProjectInfo)
    func selectItem(_ item: SelectedItem?)
    func rotateCamera(deltaX: Float, deltaY: Float)
}

// Data Models - Enhanced for USD
struct ProjectData {
    let metadata: ProjectMetadata
    let configurations: [Configuration]
    let assemblies: [Assembly]
    let primitives: [GeometricPrimitive]
}

// USD Data Structures
struct USDPrim {
    let name: String
    let type: String
    let attributes: [String: USDAttribute]
    let transform: USDTransform?
    let children: [USDPrim]
    let metadata: [String: String]
}

struct USDTransform {
    let position: Vector3D      // Geometric center location
    let orientation: Quaternion // Rotation around geometric center
}
```

### Component Reference System

**Library Components**: Referenced using USD reference composition arcs
- USD references maintain live links to library components
- Mass properties calculated from library component + instance transform
- Geometry loaded from library location via USD reference system
- Updates to library components propagate automatically through USD composition

**Instance Data**: Stored as USD transform overrides on referenced prims
- Position and orientation transforms (geometric center based)
- Instance-specific custom attributes when needed
- USD composition allows local overrides without modifying library source

**Error Handling**: USD-native reference resolution
- Missing library components result in USD composition errors
- Component version mismatches handled by USD reference system
- Clear USD error reporting for broken references

**Transform Convention**: Geometric center positioning
- All components positioned by their geometric center
- Rotations applied around geometric center
- Compatible with USD, RCP, and RealityKit conventions
- No anchor point conversion needed in file format

## User Interface Architecture

### Three-Panel Layout
- **Left Panel**: Project Navigator showing USD hierarchy
- **Center Panel**: RealityKit 3D visualization with direct USD loading
- **Right Panel**: Properties view for selected USD prims and attributes

### Navigator Hierarchy Display
```
▼ Lunar-Lander-Project
  ▼ Flight-Configuration
    ▼ Descent-Stage
      • Engine-Module (local USD)
      • Standard-100N-Thruster (library reference)
      • Propellant-Tank (local USD)
    ▼ Ascent-Stage
      • Crew-Module (local USD)
  ▼ Ground-Test-Configuration
    • Test-Fixtures (local USD)
```

### Selection System
- Single observable ViewModel manages all selection state
- Type-safe selection enum: `.assembly(UUID)` or `.primitive(UUID)`
- Selection updates propagate reactively across all panels
- Direct mapping to USD prim selection in RealityView

## Demeter Workflow Integration

### Mission-Class Templates

Based on PM interview results, engineers select appropriate USD-based templates:

**CubeSat Templates** (1U, 3U, 6U)
- Standard subsystem layouts in USD format
- Typical mass/power budgets as USD custom attributes
- Common component selections via USD references

**Small Spacecraft** (100-500kg)
- Propulsion system configurations
- Solar array and power subsystem layouts
- Attitude control arrangements

**Large Spacecraft** (500kg+)
- GEO communications satellite layouts
- Deep space probe configurations
- Advanced propulsion systems

**Cargo Vehicles**
- ISS resupply configurations
- Lunar delivery vehicles
- Pressurized vs unpressurized variants

### Export to MissionViz

ModelDraw provides USD files directly compatible with RealityKit for:
- Solar array tracking analysis
- Thruster plume impingement studies  
- Attitude control authority validation
- Communication link budgets
- Structural dynamics modeling

**USD Integration Benefits:**
- Direct RealityKit loading without conversion
- Compatible with Reality Composer Pro for advanced editing
- Industry-standard format for 3D content pipelines
- Future integration with external CAD and simulation tools

## Development Phases

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
- Reality Composer Pro workflow integration

## Technical Requirements

### File System
- Cross-platform USD file operations via USDFileManager
- Robust error handling for missing/corrupted USD files
- Security-scoped bookmarks for folder access
- USD file change monitoring (future)

### Performance
- Lazy loading of USD project components
- Efficient 3D scene updates with direct USD loading
- Smooth camera controls at 60 FPS
- Memory management for large USD component libraries

### Data Integrity
- USD schema validation via USDFileManager
- USD reference integrity checking
- Component version tracking through USD metadata
- Atomic USD save operations

### USD Compatibility
- RealityKit native USD loading support
- Reality Composer Pro import/export compatibility
- Standard USD primitive types (Cylinder, Cone, Sphere, etc.)
- USD custom attributes for spacecraft engineering metadata

## Success Criteria

- **Project Management**: Engineers can create, organize, and manage multi-configuration spacecraft projects in USD format
- **Component Reuse**: Library system enables efficient sharing of standard USD components across projects
- **Rapid Prototyping**: USD template system accelerates initial spacecraft design from mission requirements
- **MissionViz Integration**: USD files provide direct geometry compatibility for mission analysis
- **Preliminary Design Focus**: Tool supports sizing, layout, and performance optimization without manufacturing complexity
- **Industry Standard Format**: Full USD compatibility enables integration with external tools and workflows

---

**Status**: Specification v0.18 - USD architecture defined, USDFileManager specified, ready for Phase 1 implementation  
**Next Review**: Scheduled after USDFileManager basic implementation  
**Dependencies**: Vector3D, Quaternion infrastructure (✅ Available)  
**Key Changes from v0.17**: JSON → USD file format, USDFileManager service, geometric center transforms