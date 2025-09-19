//
//  USDMeshConverter.swift
//  ModelDraw - USD Mesh to RealityKit Entity Converter
//
//  Handles conversion of USD Mesh primitives to RealityKit entities
//  Part of USDEntityConverter modular architecture
//

import Foundation
import RealityKit

/// Handles conversion of USD Mesh primitives (vertices + faces) to RealityKit entities
/// Follows the same pattern as PrimitiveConverter for architectural consistency
class USDMeshConverter {
    
    /// Convert USD Mesh prim to RealityKit Entity with triangle mesh
    /// - Parameter prim: USD mesh primitive with points and faceVertexIndices
    /// - Returns: Entity with mesh geometry or nil if conversion fails
    func convertMesh(_ prim: USDPrim) -> Entity? {
        print("🔺 USDMeshConverter: Converting mesh '\(prim.name)'")
        
        // Extract mesh geometry attributes
        guard let pointsAttr = prim.attributes["points"],
              let indicesAttr = prim.attributes["faceVertexIndices"] else {
            print("❌ USDMeshConverter: Missing required mesh attributes (points, faceVertexIndices)")
            return nil
        }
        
        // Parse vertex positions
        guard let vertices = parseVertexPositions(from: pointsAttr) else {
            print("❌ USDMeshConverter: Failed to parse vertex positions")
            return nil
        }
        
        // Parse face indices
        guard let indices = parseFaceIndices(from: indicesAttr) else {
            print("❌ USDMeshConverter: Failed to parse face indices")
            return nil
        }
        
        // Create RealityKit mesh from vertices and indices
        guard let mesh = createRealityKitMesh(vertices: vertices, indices: indices) else {
            print("❌ USDMeshConverter: Failed to create RealityKit mesh")
            return nil
        }
        
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
        
        print("✅ USDMeshConverter: Created mesh entity '\(prim.name)' with \(vertices.count) vertices, \(indices.count/3) triangles")
        return entity
    }
    
    // MARK: - Private Parsing Methods
    
    /// Parse vertex positions from USD points attribute
    /// - Parameter attribute: USD attribute containing vertex positions
    /// - Returns: Array of SIMD3<Float> positions or nil if parsing fails
    private func parseVertexPositions(from attribute: USDAttribute) -> [SIMD3<Float>]? {
        // USD points are typically stored as Vec3f array
        // Format: [(x1,y1,z1), (x2,y2,z2), ...]
        
        guard let pointsArray = attribute.value as? [[Double]] else {
            // Try alternative format - flat array [x1,y1,z1,x2,y2,z2,...]
            if let flatArray = attribute.value as? [Double] {
                return parseFlatVertexArray(flatArray)
            }
            print("❌ USDMeshConverter: Unable to parse points attribute format")
            return nil
        }
        
        var vertices: [SIMD3<Float>] = []
        
        for point in pointsArray {
            guard point.count >= 3 else {
                print("❌ USDMeshConverter: Invalid point format - expected 3 coordinates")
                return nil
            }
            
            let vertex = SIMD3<Float>(
                Float(point[0]),
                Float(point[1]),
                Float(point[2])
            )
            vertices.append(vertex)
        }
        
        return vertices
    }
    
    /// Parse flat vertex array format [x1,y1,z1,x2,y2,z2,...]
    /// - Parameter flatArray: Flat array of coordinates
    /// - Returns: Array of SIMD3<Float> positions or nil if invalid
    private func parseFlatVertexArray(_ flatArray: [Double]) -> [SIMD3<Float>]? {
        guard flatArray.count % 3 == 0 else {
            print("❌ USDMeshConverter: Flat vertex array count not divisible by 3")
            return nil
        }
        
        var vertices: [SIMD3<Float>] = []
        
        for i in stride(from: 0, to: flatArray.count, by: 3) {
            let vertex = SIMD3<Float>(
                Float(flatArray[i]),
                Float(flatArray[i + 1]),
                Float(flatArray[i + 2])
            )
            vertices.append(vertex)
        }
        
        return vertices
    }
    
    /// Parse face indices from USD faceVertexIndices attribute
    /// - Parameter attribute: USD attribute containing face vertex indices
    /// - Returns: Array of UInt32 indices for triangles or nil if parsing fails
    private func parseFaceIndices(from attribute: USDAttribute) -> [UInt32]? {
        // USD faceVertexIndices are typically stored as Int array
        // For triangles: [v0,v1,v2, v3,v4,v5, ...] (groups of 3)
        
        var indices: [UInt32] = []
        
        if let intArray = attribute.value as? [Int] {
            indices = intArray.map { UInt32($0) }
        } else if let int32Array = attribute.value as? [Int32] {
            indices = int32Array.map { UInt32($0) }
        } else if let uint32Array = attribute.value as? [UInt32] {
            indices = uint32Array
        } else {
            print("❌ USDMeshConverter: Unable to parse faceVertexIndices format")
            return nil
        }
        
        // Validate triangle count (should be divisible by 3 for triangle meshes)
        guard indices.count % 3 == 0 else {
            print("❌ USDMeshConverter: Face indices count not divisible by 3 (not triangle mesh)")
            return nil
        }
        
        return indices
    }
    
    /// Create RealityKit MeshResource from vertices and indices
    /// - Parameters:
    ///   - vertices: Array of vertex positions
    ///   - indices: Array of triangle indices
    /// - Returns: MeshResource or nil if creation fails
    private func createRealityKitMesh(vertices: [SIMD3<Float>], indices: [UInt32]) -> MeshResource? {
        do {
            // Create mesh descriptor
            var descriptor = MeshDescriptor(name: "USD_Mesh")
            
            // Set vertex positions
            descriptor.positions = MeshBuffers.Positions(vertices)
            
            // Set triangle indices
            descriptor.primitives = .triangles(indices)
            
            // Generate the mesh resource
            let mesh = try MeshResource.generate(from: [descriptor])
            return mesh
            
        } catch {
            print("❌ MeshConverter: Failed to generate MeshResource: \(error)")
            return nil
        }
    }
}
