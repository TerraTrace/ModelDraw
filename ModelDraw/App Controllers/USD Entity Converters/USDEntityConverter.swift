//
//  USDEntityConverter.swift
//  ModelDraw - Converts USDPrims to RealityKit Entities
//
//  Singleton service following USDFileManager pattern
//  Designed for extensibility as new primitive types are added
//

import Foundation
import RealityKit

/// Converts USDPrim structures to RealityKit Entity objects
/// Singleton service that coordinates specialized converters for different geometry types
class USDEntityConverter {
    
    // MARK: - Singleton Instance
    static let shared = USDEntityConverter()
    private init() {}
    
    // MARK: - Specialized Converters (Conductor's Band Sections)
    private let primitiveConverter = PrimitiveConverter()
    private let meshConverter = USDMeshConverter()
    // Future: private let assemblyConverter = USDAssemblyConverter()
    
    // MARK: - Main Conductor Method
    
    /// Convert USDPrim to RealityKit Entity
    /// Routes to appropriate specialized converter based on prim type
    /// - Parameter usdPrim: The USD primitive to convert
    /// - Returns: RealityKit Entity or nil if conversion fails
    func convertToEntity(usdPrim: USDPrim) -> Entity? {
        print("🎯 USDEntityConverter: Converting prim '\(usdPrim.name)' of type '\(usdPrim.type)'")
        
        switch usdPrim.type {
        case "Cylinder":
            return primitiveConverter.convertCylinder(usdPrim)
        case "Cone":
            return primitiveConverter.convertCone(usdPrim)
        case "Mesh":
            return meshConverter.convertMesh(usdPrim)
        case "GeomMesh":
            return meshConverter.convertMesh(usdPrim)
        case "Xform":
            // Assembly - has children, needs special handling
            return convertAssembly(usdPrim)
        default:
            print("⚠️ USDEntityConverter: Unsupported prim type: \(usdPrim.type)")
            return nil
        }
    }
    
    // MARK: - Assembly Handling (Temporary - will move to AssemblyConverter)
    
    /// Convert assembly prim (Xform with children) to Entity with child entities
    /// - Parameter prim: Assembly prim with children
    /// - Returns: Entity containing converted child entities
    private func convertAssembly(_ prim: USDPrim) -> Entity? {
        print("📁 USDEntityConverter: Converting assembly '\(prim.name)' with \(prim.children.count) children")
        
        let assemblyEntity = Entity()
        assemblyEntity.name = prim.name
        
        // Apply transform if present
        if let transform = prim.transform {
            assemblyEntity.position = SIMD3<Float>(
                Float(transform.position.x),
                Float(transform.position.y),
                Float(transform.position.z)
            )
            // TODO: Apply orientation from transform.orientation
        }
        
        // Convert and add child entities
        for childPrim in prim.children {
            if let childEntity = convertToEntity(usdPrim: childPrim) {
                assemblyEntity.addChild(childEntity)
            }
        }
        
        return assemblyEntity
    }
}

// MARK: - Primitive Converter (Brass Section)

/// Handles conversion of basic geometric primitives (Cylinder, Cone, Sphere, etc.)
class PrimitiveConverter {
    
    /// Convert USD Cylinder prim to RealityKit Entity with cylinder mesh
    /// - Parameter prim: USD cylinder primitive
    /// - Returns: Entity with cylinder geometry or nil if conversion fails
    func convertCylinder(_ prim: USDPrim) -> Entity? {
        print("🟢 PrimitiveConverter: Converting cylinder '\(prim.name)'")
        
        // Extract cylinder geometry attributes
        guard let heightAttr = prim.attributes["height"],
              let radiusAttr = prim.attributes["radius"],
              let height = heightAttr.value as? Double,
              let radius = radiusAttr.value as? Double else {
            print("❌ PrimitiveConverter: Missing required cylinder attributes (height, radius)")
            return nil
        }
        
        // Create RealityKit cylinder mesh
        let mesh = MeshResource.generateCylinder(
            height: Float(height),
            radius: Float(radius)
        )
        
        // Create entity with mesh
        let entity = ModelEntity(mesh: mesh)
        entity.name = prim.name
        
        // Apply transform if present
        if let transform = prim.transform {
            entity.position = SIMD3<Float>(
                Float(transform.position.x),
                Float(transform.position.y),
                Float(transform.position.z)
            )
            // TODO: Apply orientation from transform.orientation
        }
        
        print("✅ PrimitiveConverter: Created cylinder entity '\(prim.name)'")
        return entity
    }
    
    /// Convert USD Cone prim to RealityKit Entity with cone mesh
    /// - Parameter prim: USD cone primitive
    /// - Returns: Entity with cone geometry or nil if conversion fails
    func convertCone(_ prim: USDPrim) -> Entity? {
        print("🔺 PrimitiveConverter: Converting cone '\(prim.name)'")
        
        // Extract cone geometry attributes
        guard let heightAttr = prim.attributes["height"],
              let radiusAttr = prim.attributes["radius"],
              let height = heightAttr.value as? Double,
              let radius = radiusAttr.value as? Double else {
            print("❌ PrimitiveConverter: Missing required cone attributes (height, radius)")
            return nil
        }
        
        // Create RealityKit cone mesh
        let mesh = MeshResource.generateCone(
            height: Float(height),
            radius: Float(radius)
        )
        
        // Create entity with mesh
        let entity = ModelEntity(mesh: mesh)
        entity.name = prim.name
        
        // Apply transform if present
        if let transform = prim.transform {
            entity.position = SIMD3<Float>(
                Float(transform.position.x),
                Float(transform.position.y),
                Float(transform.position.z)
            )
            // TODO: Apply orientation from transform.orientation
        }
        
        print("✅ PrimitiveConverter: Created cone entity '\(prim.name)'")
        return entity
    }
}
