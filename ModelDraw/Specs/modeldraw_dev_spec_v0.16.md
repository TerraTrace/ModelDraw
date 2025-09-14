# ModelDraw Development Specification v0.16
**Date:** September 14, 2025  
**Changes:** Major architectural update - Project-based file system, Demeter workflow integration, preliminary design CAD positioning

## Executive Summary

ModelDraw is positioned as the **"preliminary design CAD"** tool within the Demeter spacecraft engineering ecosystem. It bridges mission requirements (established in Demeter PM interviews) and mission performance validation (done in MissionViz) by providing rapid spacecraft geometry modeling, mass properties calculation, and subsystem layout capabilities.

### Key Architectural Decisions

1. **Project-Based File System**: Moving from single-document to folder-tree project organization
2. **Component Library System**: Shared library components referenced in place, not copied
3. **Demeter Workflow Integration**: Templates based on mission class from PM interview process
4. **Preliminary Design Focus**: Sizing, mass properties, and performance optimization - not manufacturing details

## System Architecture

### File System Organization

```
~/Documents/ModelDraw/
├── Projects/
│   ├── Lunar-Lander-Project/
│   │   ├── Lunar_Lander_Project.project         # Project metadata
│   │   ├── Flight-Configuration/
│   │   │   ├── Flight_Configuration.modeldraw   # Assembly definition
│   │   │   ├── Descent-Stage/
│   │   │   │   ├── Descent_Stage.modeldraw
│   │   │   │   ├── Engine_Module.modeldraw      # Primitive
│   │   │   │   └── Propellant_Tank.modeldraw    # Primitive
│   │   │   └── Ascent-Stage/
│   │   └── Ground-Test-Configuration/
│   └── ISS-Cargo-Vehicle/
├── Library/
│   ├── Standard-Components/
│   │   ├── Reaction-Wheels/
│   │   │   └── Standard_10Nms_RWA.modeldraw
│   │   └── Thrusters/
│   │       └── Standard_100N_Thruster.modeldraw
│   └── Common-Assemblies/
│       └── Avionics-Bay/
└── Templates/
    ├── CubeSat-3U/
    ├── Small-Spacecraft/
    └── Cargo-Vehicle/
```

### File Type Definitions

#### .project Files
```json
{
  "version": "1.0",
  "metadata": {
    "name": "Lunar Lander Project",
    "description": "Artemis III Commercial Lunar Lander",
    "responsibleEngineer": "Jane Smith",
    "missionClass": "Lunar Surface",
    "targetLaunchDate": "2026-Q3",
    "createdDate": "2025-09-14T12:00:00Z"
  },
  "configurations": [
    "Flight-Configuration",
    "Ground-Test-Configuration"
  ],
  "libraryDependencies": [
    "Library/Propulsion/Standard-100N-Thruster",
    "Library/GNC/Reaction-Wheel-Assembly"
  ]
}
```

#### .modeldraw Assembly Files with Library References
```json
{
  "version": "1.0",
  "metadata": {
    "name": "Aft Propulsion Module",
    "assemblyType": "propulsion",
    "massEstimate": 45.2
  },
  "components": [
    {
      "type": "libraryReference",
      "libraryPath": "Library/Propulsion/Standard-100N-Thruster",
      "instanceID": "thruster-aft-port",
      "position": [1.2, -0.8, -2.5],
      "orientation": [0, 0, 0, 1],
      "anchorPoint": "mounting-flange"
    },
    {
      "type": "libraryReference", 
      "libraryPath": "Library/Propulsion/Standard-100N-Thruster",
      "instanceID": "thruster-aft-starboard",
      "position": [-1.2, -0.8, -2.5],
      "orientation": [0, 0, 0.707, 0.707],
      "anchorPoint": "mounting-flange"
    },
    {
      "type": "localPrimitive",
      "primitiveID": "mounting-structure-id",
      "position": [0, 0, 0],
      "orientation": [0, 0, 0, 1]
    }
  ]
}
```

## Data Architecture

### Core Classes

```swift
// Project Management (Singleton)
class ProjectManager {
    static let shared = ProjectManager()
    private init() {}
    
    func loadProject(from folderURL: URL) throws -> ProjectData
    func saveProject(_ project: ProjectData) throws
    func createProject(from template: String, named: String) throws -> ProjectData
    func scanDocumentsDirectory() -> [ProjectInfo]
}

// UI State Management (Observable)
@Observable
class ViewModel {
    var selectedItem: SelectedItem?
    var currentProject: ProjectData?
    var cameraPosition: SIMD3
    var cameraRotation: simd_quatf
    
    func loadProject(_ projectInfo: ProjectInfo)
    func selectItem(_ item: SelectedItem?)
    func rotateCamera(deltaX: Float, deltaY: Float)
}

// Data Models
struct ProjectData {
    let metadata: ProjectMetadata
    let configurations: [Configuration]
    let assemblies: [Assembly]
    let primitives: [GeometricPrimitive]
}

struct LibraryReference {
    let libraryPath: String
    let instanceID: String
    let position: SIMD3
    let orientation: simd_quatf
    let anchorPoint: String
}
```

### Component Reference System

**Library Components**: Referenced in place to avoid duplication
- Mass properties calculated from library component + instance transform
- Geometry loaded from library location
- Updates to library components propagate to all referencing projects

**Instance Data**: Stored in project assembly files
- Position and orientation transforms
- Anchor point specifications
- Instance-specific properties (if any)

**Error Handling**: Type-safe, fail-fast approach
- Missing library components throw clear errors
- Component version mismatches require explicit resolution
- No silent failures or placeholder objects

## User Interface Architecture

### Three-Panel Layout
- **Left Panel**: Project Navigator showing project hierarchy
- **Center Panel**: RealityKit 3D visualization with orbit camera controls
- **Right Panel**: Properties view for selected components

### Navigator Hierarchy Display
```
▼ Lunar-Lander-Project
  ▼ Flight-Configuration
    ▼ Descent-Stage
      • Engine-Module (local)
      • Standard-100N-Thruster (library)
      • Propellant-Tank (local)
    ▼ Ascent-Stage
      • Crew-Module (local)
  ▼ Ground-Test-Configuration
    • Test-Fixtures (local)
```

### Selection System
- Single observable ViewModel manages all selection state
- Type-safe selection enum: `.assembly(UUID)` or `.primitive(UUID)`
- Selection updates propagate reactively across all panels

## Demeter Workflow Integration

### Mission-Class Templates

Based on PM interview results, engineers select appropriate templates:

**CubeSat Templates** (1U, 3U, 6U)
- Standard subsystem layouts
- Typical mass/power budgets
- Common component selections

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

ModelDraw provides geometry and mass properties for:
- Solar array tracking analysis
- Thruster plume impingement studies
- Attitude control authority validation
- Communication link budgets
- Structural dynamics modeling

## Development Phases

### Phase 1: Project System Foundation
- ProjectManager singleton implementation
- Document directory scanning and project enumeration
- Basic project loading/saving
- Simple template system

### Phase 2: Library Reference System
- Library component discovery and loading
- Reference resolution with error handling
- Instance positioning and transform management
- Library dependency tracking

### Phase 3: Advanced UI Integration
- Project navigator with hierarchy display
- Component selection and properties display
- 3D visualization improvements
- Camera controls and scene management

### Phase 4: Template and Export Systems
- Mission-class template creation
- Template-based project generation
- Export formats for MissionViz integration
- Mass properties calculation and validation

## Technical Requirements

### File System
- Cross-platform file operations
- Robust error handling for missing/corrupted files
- Security-scoped bookmarks for folder access
- File system change monitoring (future)

### Performance
- Lazy loading of project components
- Efficient 3D scene updates
- Smooth camera controls at 60 FPS
- Memory management for large component libraries

### Data Integrity
- JSON schema validation
- Reference integrity checking
- Component version tracking
- Atomic save operations

## Success Criteria

- **Project Management**: Engineers can create, organize, and manage multi-configuration spacecraft projects
- **Component Reuse**: Library system enables efficient sharing of standard components across projects
- **Rapid Prototyping**: Template system accelerates initial spacecraft design from mission requirements
- **MissionViz Integration**: Exported models provide accurate geometry and mass properties for mission analysis
- **Preliminary Design Focus**: Tool supports sizing, layout, and performance optimization without manufacturing complexity

---

**Status**: Specification v0.16 - Architecture defined, ready for Phase 1 implementation  
**Next Review**: Scheduled after ProjectManager singleton implementation
