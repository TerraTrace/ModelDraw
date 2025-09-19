//
//  DrawingManager.swift
//  ModelDraw
//
//  Singleton for managing ModelDraw projects, library components, and file system operations
//  Handles the three-tier hierarchy: Project → Configuration → Assembly
//

import Foundation
import RealityKit
import SwiftUI


// MARK: - Error Types
enum DrawingManagerError: Error, LocalizedError {
    case projectAlreadyExists(name: String)
    case templateNotFound(name: String)
    case configurationNotFound(path: String)
    case missingLibraryComponent(path: String)
    case invalidProjectFile(path: String)
    case corruptedData(description: String)
    
    var errorDescription: String? {
        switch self {
        case .projectAlreadyExists(let name):
            return "Project '\(name)' already exists"
        case .templateNotFound(let name):
            return "Template '\(name)' not found"
        case .configurationNotFound(let path):
            return "Configuration not found at '\(path)'"
        case .missingLibraryComponent(let path):
            return "Library component not found at '\(path)'"
        case .invalidProjectFile(let path):
            return "Invalid project file at '\(path)'"
        case .corruptedData(let description):
            return "Corrupted data: \(description)"
        }
    }
}



/// Singleton manager for ModelDraw project file system operations.
/// Handles project discovery, loading, library component resolution, and template-based project creation.
/// Manages the three-tier hierarchy: Project → Configuration → Assembly with library component references.
class DrawingManager {
    static let shared = DrawingManager()
    private init() {}
    
    private let fileManager = FileManager.default
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var modelDrawURL: URL {
        documentsURL.appendingPathComponent("ModelDraw")
    }
    
    // MARK: - Directory Structure
    private var projectsURL: URL { modelDrawURL.appendingPathComponent("Projects") }
    private var libraryURL: URL { modelDrawURL.appendingPathComponent("Library") }
    private var templatesURL: URL { modelDrawURL.appendingPathComponent("Templates") }
    
    // MARK: - Current State
    private var currentProjectURL: URL?
    
    // MARK: - Initialization
    func initializeAppDirectories() throws {
        // Create main ModelDraw directory structure
        try fileManager.createDirectory(at: projectsURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: libraryURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: templatesURL, withIntermediateDirectories: true)
        
        // Create basic library structure
        try createInitialLibraryStructure()
        
        // Create basic template
        try createInitialTemplate()
        
        print("📁 DrawingManager: Initialized directory structure at \(modelDrawURL.path)")
    }
    
    private func createInitialLibraryStructure() throws {
        let standardComponents = libraryURL.appendingPathComponent("Standard-Components")
        let commonAssemblies = libraryURL.appendingPathComponent("Common-Assemblies")
        
        try fileManager.createDirectory(at: standardComponents, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: commonAssemblies, withIntermediateDirectories: true)
        
        // Add a README
        let readmeContent = """
        # ModelDraw Component Library
        
        This directory contains reusable spacecraft components and assemblies.
        
        ## Structure
        - Standard-Components/: Individual components (thrusters, reaction wheels, etc.)
        - Common-Assemblies/: Complete subsystem assemblies
        
        ## Usage
        Components in this library can be referenced by projects without copying.
        Updates to library components will affect all projects that reference them.
        """
        
        let readmeURL = libraryURL.appendingPathComponent("README.md")
        try readmeContent.write(to: readmeURL, atomically: true, encoding: .utf8)
    }
    
    private func createInitialTemplate() throws {
        
    }
    
    
    // Add this method to DrawingManager class

    func loadUSDEntity(from url: URL) -> Entity? {
        do {
            // Read USD file using existing infrastructure
            let usdFile = try USDFileManager.shared.readUSDFile(from: url)
            
            // Create parent container entity
            let parentEntity = Entity()
            parentEntity.name = url.deletingPathExtension().lastPathComponent
            
            // Process each top-level prim in the USD file
            for prim in usdFile.rootPrims {
                if let childEntity = createEntity(from: prim) {
                    parentEntity.addChild(childEntity)
                }
            }
            
            print("✅ USD entity created with \(parentEntity.children.count) children: \(parentEntity.name)")
            return parentEntity
            
        } catch {
            print("❌ Failed to load USD entity: \(error)")
            return nil
        }
    }

    
    // MARK: - USD Scene File Loading (ADD TO DrawingManager)
    
    /// Load project from USD scene file
    /// - Parameter projectFolder: NavigatorItem representing the project folder
    /// - Returns: Array of LoadedUSDItem entities ready for 3D scene
    func loadProjectFromSceneFile(_ projectFolder: NavigatorItem) -> [LoadedUSDItem] {
        guard projectFolder.itemType == .folder,
              let projectURL = projectFolder.url else {
            print("❌ DrawingManager: Invalid project folder")
            return []
        }
        
        // Look for matching scene file: CargoDragon.usd in CargoDragon/ folder
        let sceneFileName = "\(projectFolder.name).usd"
        let sceneFileURL = projectURL.appendingPathComponent(sceneFileName)
        
        // Scene file MUST exist
        guard FileManager.default.fileExists(atPath: sceneFileURL.path) else {
            print("❌ DrawingManager: Scene file REQUIRED but not found: \(sceneFileName)")
            print("   💡 Create \(sceneFileName) to define this project")
            return []
        }
        
        print("🎬 DrawingManager: Loading project from scene file: \(sceneFileName)")
        
        do {
            // Read the scene file
            let sceneFile = try USDFileManager.shared.readUSDFile(from: sceneFileURL)
            
            // Extract scene information
            if let sceneAssembly = sceneFile.rootPrims.first {
                print("📦 DrawingManager: Scene '\(sceneAssembly.name)' has \(sceneAssembly.children.count) components")
                
                // Load each referenced component
                let loadedItems = loadReferencedComponents(from: sceneAssembly, sceneURL: sceneFileURL)
                
                // Store scene metadata for later use
                storeSceneMetadata(sceneAssembly.metadata)
                
                return loadedItems
            }
            
        } catch {
            print("❌ DrawingManager: Failed to read scene file: \(error)")
        }
        
        return []
    }
    
    /// Load all components referenced in the scene assembly
    /// - Parameters:
    ///   - sceneAssembly: Root prim from scene file
    ///   - sceneURL: URL of the scene file for resolving relative paths
    /// - Returns: Array of loaded USD items
    private func loadReferencedComponents(from sceneAssembly: USDPrim, sceneURL: URL) -> [LoadedUSDItem] {
        let sceneDir = sceneURL.deletingLastPathComponent()
        var loadedItems: [LoadedUSDItem] = []
        
        for (index, component) in sceneAssembly.children.enumerated() {
            print("🔍 DrawingManager: Processing component '\(component.name)'")
            
            if component.hasReferences, let reference = component.primaryReference {
                // Load referenced component
                let componentURL = reference.resolveURL(relativeTo: sceneDir)
                if let loadedItem = loadReferencedComponent(component, from: componentURL) {
                    loadedItems.append(loadedItem)
                }
            } else {
                // Component has no references - treat as inline geometry
                print("⚠️ DrawingManager: Component '\(component.name)' has no references, treating as inline")
                if let loadedItem = loadInlineComponent(component, index: index) {
                    loadedItems.append(loadedItem)
                }
            }
        }
        
        return loadedItems
    }
    
    /// Load a single referenced component with its scene transform
    /// - Parameters:
    ///   - component: Component prim from scene file
    ///   - componentURL: URL to the referenced component file
    /// - Returns: LoadedUSDItem or nil if loading fails
    private func loadReferencedComponent(_ component: USDPrim, from componentURL: URL) -> LoadedUSDItem? {
        guard FileManager.default.fileExists(atPath: componentURL.path) else {
            print("❌ DrawingManager: Referenced file not found: \(componentURL.path)")
            return nil
        }
        
        do {
            // Read the referenced component file
            let componentFile = try USDFileManager.shared.readUSDFile(from: componentURL)
            
            // Convert first root prim to entity
            if let firstPrim = componentFile.rootPrims.first,
               let entity = USDEntityConverter.shared.convertToEntity(usdPrim: firstPrim) {
                
                // Apply scene transform (position from scene file)
                if let transform = component.transform {
                    entity.position = SIMD3<Float>(
                        Float(transform.position.x),
                        Float(transform.position.y),
                        Float(transform.position.z)
                    )
                    // TODO: Apply orientation from transform.orientation
                } else {
                    // Default position if no transform specified
                    entity.position = SIMD3<Float>(0, 0, 0)
                }
                
                // Use component name from scene (not original file name)
                entity.name = component.name
                
                // Create LoadedUSDItem for tracking
                let loadedItem = LoadedUSDItem(
                    sourceURL: componentURL,
                    entity: entity,
                    position: entity.position
                )
                
                print("✅ DrawingManager: Loaded referenced component '\(component.name)' from '\(componentURL.lastPathComponent)'")
                return loadedItem
            }
            
        } catch {
            print("❌ DrawingManager: Failed to read referenced component '\(component.name)': \(error)")
        }
        
        return nil
    }
    
    /// Load inline component (no external references)
    /// - Parameters:
    ///   - component: Inline component prim
    ///   - index: Component index for positioning
    /// - Returns: LoadedUSDItem or nil if conversion fails
    private func loadInlineComponent(_ component: USDPrim, index: Int) -> LoadedUSDItem? {
        // Convert inline prim directly to entity
        if let entity = USDEntityConverter.shared.convertToEntity(usdPrim: component) {
            // Position inline components in a simple layout
            let position = SIMD3<Float>(Float(index * 3), 0, 0)
            entity.position = position
            
            // Create LoadedUSDItem (no source URL for inline)
            let loadedItem = LoadedUSDItem(
                sourceURL: URL(fileURLWithPath: "inline://\(component.name)"),
                entity: entity,
                position: position
            )
            
            print("✅ DrawingManager: Loaded inline component '\(component.name)'")
            return loadedItem
        }
        
        return nil
    }
    
    /// Store scene metadata for application state
    /// - Parameter metadata: CustomData from scene file
    private func storeSceneMetadata(_ metadata: [String: String]) {
        print("🎛️ DrawingManager: Storing scene metadata...")
        
        // Store in UserDefaults for now (could be more sophisticated later)
        for (key, value) in metadata {
            let prefKey = "SceneMetadata_\(key)"
            UserDefaults.standard.set(value, forKey: prefKey)
            print("   📊 \(key): \(value)")
        }
    }
    
    /// Get stored scene metadata
    /// - Parameter key: Metadata key to retrieve
    /// - Returns: Stored value or nil
    func getSceneMetadata(_ key: String) -> String? {
        let prefKey = "SceneMetadata_\(key)"
        return UserDefaults.standard.string(forKey: prefKey)
    }
    
    /// Check if a project folder has a scene file
    /// - Parameter projectFolder: NavigatorItem for project folder
    /// - Returns: True if scene file exists
    func hasSceneFile(_ projectFolder: NavigatorItem) -> Bool {
        guard projectFolder.itemType == .folder,
              let projectURL = projectFolder.url else {
            return false
        }
        
        let sceneFileName = "\(projectFolder.name).usd"
        let sceneFileURL = projectURL.appendingPathComponent(sceneFileName)
        return FileManager.default.fileExists(atPath: sceneFileURL.path)
    }
    
    
    
    // MARK: - Private Helper Methods

    private func createEntity(from prim: USDPrim) -> Entity? {
        switch prim.type {
        case "Xform":
            return createXformEntity(from: prim)
        case "Cylinder":
            return createCylinderEntity(from: prim)
        case "Cone":
            return createConeEntity(from: prim)
        default:
            print("⚠️ Unsupported prim type: \(prim.type)")
            return nil
        }
    }

    private func createXformEntity(from prim: USDPrim) -> Entity? {
        let entity = Entity()
        entity.name = prim.name
        
        // Apply transform if available
        if let transform = prim.transform {
            applyTransform(transform, to: entity)
        }
        
        // Process children recursively
        for childPrim in prim.children {
            if let childEntity = createEntity(from: childPrim) {
                entity.addChild(childEntity)
            }
        }
        
        return entity
    }

    private func createCylinderEntity(from prim: USDPrim) -> ModelEntity? {
        guard let heightAttr = prim.attributes["height"],
              let radiusAttr = prim.attributes["radius"],
              let height = heightAttr.value as? Double,
              let radius = radiusAttr.value as? Double else {
            print("⚠️ Invalid cylinder parameters for: \(prim.name)")
            return nil
        }
        
        // Create cylinder geometry
        let mesh = MeshResource.generateCylinder(height: Float(height), radius: Float(radius))
        
        // Create basic material (can be enhanced later)
        let material = SimpleMaterial(color: .gray, isMetallic: false)
        
        // Create ModelEntity
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = prim.name
        
        // Apply transform if available
        if let transform = prim.transform {
            applyTransform(transform, to: entity)
        }
        
        return entity
    }

    private func createConeEntity(from prim: USDPrim) -> ModelEntity? {
        guard let heightAttr = prim.attributes["height"],
              let radiusAttr = prim.attributes["radius"],
              let height = heightAttr.value as? Double,
              let radius = radiusAttr.value as? Double else {
            print("⚠️ Invalid cone parameters for: \(prim.name)")
            return nil
        }
        
        // Create cone geometry
        let mesh = MeshResource.generateCone(height: Float(height), radius: Float(radius))
        
        // Create basic material (can be enhanced later)
        let material = SimpleMaterial(color: .lightGray, isMetallic: false)
        
        // Create ModelEntity
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = prim.name
        
        // Apply transform if available
        if let transform = prim.transform {
            applyTransform(transform, to: entity)
        }
        
        return entity
    }

    private func applyTransform(_ transform: USDTransform, to entity: Entity) {
        // Apply position
        entity.position = SIMD3<Float>(
            Float(transform.position.x),
            Float(transform.position.y),
            Float(transform.position.z)
        )
        
        // Apply orientation (quaternion)
        entity.orientation = simd_quatf(
            ix: Float(transform.orientation.w),
            iy: Float(transform.orientation.x),
            iz: Float(transform.orientation.y),
            r: Float(transform.orientation.z)
        )
    }
    
}
    
