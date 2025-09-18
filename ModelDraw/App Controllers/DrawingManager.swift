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
    
