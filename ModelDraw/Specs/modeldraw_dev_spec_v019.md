# ModelDraw Development Specification v0.19
**Date:** September 17, 2025  
**Changes:** ✅ **PHASE 1 COMPLETE** - File System Navigator with OutlineGroup Selection  
**Architecture:** USD-based file system with clean three-pane Xcode-style interface  
**Status:** 🚀 **NAVIGATOR OPERATIONAL** - Ready for Phase 2 drag-and-drop implementation

## Executive Summary

ModelDraw is positioned as the **"preliminary design CAD"** tool within the Demeter spacecraft engineering ecosystem. Version 0.19 represents a major milestone with the completion of Phase 1 - a fully functional file system navigator that provides clean, hierarchical browsing of the ModelDraw directory structure using Apple's modern OutlineGroup patterns.

### ✅ Phase 1 Achievements (COMPLETE)

1. **USD File System Navigator**: Complete hierarchical tree view of Projects/, Library/, Templates/
2. **OutlineGroup Selection**: Modern SwiftUI selection with proper Xcode-style disclosure triangles
3. **Clean Three-Pane Layout**: Navigator | 3D View | Properties with resizable panels
4. **Smart File Filtering**: Shows only folders and USD files, hiding irrelevant file types
5. **Properties Panel**: Detailed file system information with toggle visibility
6. **Responsive UI**: Smooth animations, proper frame constraints, toolbar integration

## Current Implementation Status

### ✅ **File System Architecture (COMPLETE)**

```
~/Documents/ModelDraw/
├── Projects/
│   ├── CargoDragon/
│   │   ├── ModelDrawTest_Cone.usd
│   │   ├── ModelDrawTest_Cylinder.usd
│   │   └── ModelDrawTest_Space...usd
│   └── StarLiner/
├── Library/
│   └── Standard-Components/
└── Templates/
    └── Mission-Class-Templates/
```

### ✅ **Navigator Implementation (COMPLETE)**

**ViewModel Architecture:**
- `navigatorData: [NavigatorItem]` - Hierarchical tree structure
- `selectedItem: NavigatorItem?` - Current selection state  
- `buildFileSystemNavigatorData()` - Recursive directory scanning
- `selectItem()` / `refreshNavigator()` - User interaction methods

**NavigatorItem Structure:**
```swift
struct NavigatorItem: Identifiable, Hashable, Equatable {
    var id: UUID
    var name: String
    var itemType: NavigatorItemType  // .folder or .usdFile
    var children: [NavigatorItem]?
    var url: URL?  // For drag-and-drop operations
}
```

**UI Components:**
- `LeftPaletteView` - OutlineGroup navigator with sidebar styling
- `NavigatorRowView` - Clean rows with small system icons (11pt)
- `RightPaletteView` - File properties with system info
- `ContentView` - Three-pane HSplitView with toolbar toggle

### ✅ **UX Features (COMPLETE)**

1. **Xcode-Style Navigator**: Disclosure triangles, clean selection, sidebar styling
2. **Small System Icons**: 11pt folder/document icons for compact display
3. **Properties Panel Toggle**: Toolbar button with smooth slide animation
4. **Smart Frame Constraints**: Left panel resizable (160-250px), center gets remaining space
5. **File System Integration**: Real-time directory scanning, modification dates, file sizes

### ✅ **Integration with USD Foundation (COMPLETE)**

- **USDFileManager v1.2**: Full read/write cycle operational
- **Directory Structure**: Compatible with DrawingManager three-folder architecture  
- **URL-Based Navigation**: Direct file system access for drag-and-drop readiness
- **Error Handling**: Graceful failure for missing files, access permissions

## Phase 2: Drag-and-Drop Implementation (IN PROGRESS)

### 🔄 Current Design Direction

**Drag-and-Drop Strategy:**
- **Custom DraggedItem type**: Wraps NavigatorItem with drag metadata
- **Both files and folders draggable**: USD files = components, folders = assemblies
- **Y=0 ground plane**: Drop at cursor position on workbench plane
- **Smart assembly loading**: Folder drops load all contained USD files with offset positioning

**Technical Challenges Identified:**
- NavigatorItem Codable conformance for drag serialization
- 2D cursor → 3D world coordinate conversion  
- Recursive folder loading with spatial arrangement
- RealityKit entity creation from USD data

### 📋 Phase 2 Implementation Plan

1. **Drag System Foundation**
   - [ ] Fix NavigatorItem Codable conformance
   - [ ] Implement DraggedItem transferable type
   - [ ] Add drag providers to NavigatorRowView

2. **Drop Zone Implementation**  
   - [ ] CenterView drop destination with coordinate conversion
   - [ ] Ground plane (Y=0) positioning logic
   - [ ] Visual drop feedback and validation

3. **USD Loading Pipeline**
   - [ ] Single USD file → RealityKit entity conversion
   - [ ] Folder assembly loading with spatial offset
   - [ ] Recursive sub-assembly support
   - [ ] LoadedUSDItem management in ViewModel

4. **3D Visualization**
   - [ ] Replace CenterView placeholder with RealityKit
   - [ ] Basic USD geometry rendering (Cylinder, Cone)
   - [ ] Camera controls and scene management

## Technical Requirements

### File System
- ✅ Cross-platform USD file operations via USDFileManager
- ✅ Robust error handling for missing/corrupted USD files  
- ✅ Security-scoped bookmarks for folder access
- [ ] USD file change monitoring (Phase 3)

### Performance  
- ✅ Lazy loading of USD project components
- ✅ Efficient tree view updates with OutlineGroup
- ✅ Smooth 60 FPS UI animations for panel transitions
- [ ] Memory management for large USD component libraries

### Data Integrity
- ✅ USD schema validation via USDFileManager
- [ ] USD reference integrity checking
- [ ] Component version tracking through USD metadata
- [ ] Atomic USD save operations

### USD Compatibility
- ✅ RealityKit native USD loading support (ready)
- [ ] Reality Composer Pro import/export compatibility
- ✅ Standard USD primitive types (Cylinder, Cone, Sphere, etc.)
- ✅ USD custom attributes for spacecraft engineering metadata

## Success Criteria

### ✅ Phase 1 Success Criteria (ACHIEVED)
- **File System Navigation**: Engineers can browse and explore ModelDraw directory structure
- **Clean Selection Model**: Proper OutlineGroup selection with visual feedback  
- **Responsive Interface**: Smooth panel resizing and toggle animations
- **Professional UX**: Xcode-style navigator with appropriate information density

### 📋 Phase 2 Success Criteria (TARGET)
- **Intuitive Drag-and-Drop**: Users can drag USD files and folders into 3D workspace
- **Spatial Control**: Drop-at-cursor prevents component stacking issues
- **Assembly Loading**: Folders load as complete assemblies with proper component arrangement
- **Visual Feedback**: Clear indication of loaded components and their positions

### 🎯 Phase 3 Success Criteria (FUTURE)
- **Real-Time 3D Visualization**: USD geometry renders accurately in RealityKit
- **Interactive 3D Scene**: Camera controls, selection, and manipulation
- **Performance Optimization**: Smooth interaction with complex assemblies
- **Export Integration**: Seamless handoff to MissionViz for analysis

---

**Status**: Specification v0.19 - ✅ **PHASE 1 COMPLETE** - Navigator fully operational  
**Next Milestone**: Phase 2 - Drag-and-drop USD loading with RealityKit visualization  
**Dependencies**: NavigatorItem Codable conformance, RealityKit integration  
**Key Achievement**: Professional-grade file system navigator matching Xcode UX standards

**Major Progress v0.19:**
- ✅ Complete file system navigator with OutlineGroup
- ✅ Three-pane layout with resizable panels and toolbar toggle
- ✅ Small system icons and clean Xcode-style interface
- ✅ Smart file filtering (folders + USD files only)
- ✅ Properties panel with file system metadata
- ✅ Foundation ready for drag-and-drop implementation
