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
    /*private func parseVertexPositions(from attribute: USDAttribute) -> [SIMD3<Float>]? {
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
    } */
    
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
                
                // Try string format (might need parsing)
                if let stringValue = attribute.value as? String {
                    return parseStringVertexArray(stringValue)
                }
                
                print("❌ USDMeshConverter: Unable to parse points attribute format")
                //print("❌ DEBUG: Actual type = \(type(of: attribute.value))")
                return nil
            }
            
            //print("🔍 DEBUG: Found nested array format with \(pointsArray.count) points")
            
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
        
        /// Parse vertex positions from string format like "[(-1.0, 0.0, -0.5), (1.0, 0.0, -0.5), ...]"
        /// - Parameter stringValue: String containing array of points
        /// - Returns: Array of SIMD3<Float> positions or nil if parsing fails
        private func parseStringVertexArray(_ stringValue: String) -> [SIMD3<Float>]? {
            // Remove brackets and split by parentheses groups
            let cleaned = stringValue.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
            
            // Find all coordinate groups like "(x, y, z)"
            let pattern = #"\(\s*(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)\s*\)"#
            let regex = try? NSRegularExpression(pattern: pattern)
            
            let range = NSRange(cleaned.startIndex..<cleaned.endIndex, in: cleaned)
            let matches = regex?.matches(in: cleaned, range: range) ?? []
            
            var vertices: [SIMD3<Float>] = []
            
            for match in matches {
                guard match.numberOfRanges == 4 else { continue }
                
                let xRange = Range(match.range(at: 1), in: cleaned)!
                let yRange = Range(match.range(at: 2), in: cleaned)!
                let zRange = Range(match.range(at: 3), in: cleaned)!
                
                let xStr = String(cleaned[xRange])
                let yStr = String(cleaned[yRange])
                let zStr = String(cleaned[zRange])
                
                guard let x = Double(xStr),
                      let y = Double(yStr),
                      let z = Double(zStr) else {
                    continue
                }
                
                let vertex = SIMD3<Float>(Float(x), Float(y), Float(z))
                vertices.append(vertex)
            }
            
            print("🔍 DEBUG: Parsed \(vertices.count) vertices from string format")
            return vertices.isEmpty ? nil : vertices
        }
    
        
    /// Parse face indices from USD faceVertexIndices attribute
    /// - Parameter attribute: USD attribute containing face vertex indices
    /// - Returns: Array of UInt32 indices for triangles or nil if parsing fails
    /*private func parseFaceIndices(from attribute: USDAttribute) -> [UInt32]? {
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
    } */
    
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
    
    
    /// Parse face indices from USD faceVertexIndices attribute
    private func parseFaceIndices(from attribute: USDAttribute) -> [UInt32]? {
        //print("🔍 DEBUG: Indices attribute type = \(type(of: attribute.value))")
        //print("🔍 DEBUG: Indices attribute value = \(attribute.value)")
        
        var indices: [UInt32] = []
        
        if let intArray = attribute.value as? [Int] {
            indices = intArray.map { UInt32($0) }
            //print("🔍 DEBUG: Found Int array format with \(indices.count) indices")
        } else if let int32Array = attribute.value as? [Int32] {
            indices = int32Array.map { UInt32($0) }
            //print("🔍 DEBUG: Found Int32 array format with \(indices.count) indices")
        } else if let uint32Array = attribute.value as? [UInt32] {
            indices = uint32Array
            //print("🔍 DEBUG: Found UInt32 array format with \(indices.count) indices")
        } else if let stringValue = attribute.value as? String {
            //print("🔍 DEBUG: Found string format for indices: \(stringValue)")
            indices = parseStringIndicesArray(stringValue)
        } else {
            //print("❌ USDMeshConverter: Unable to parse faceVertexIndices format")
            //print("❌ DEBUG: Actual type = \(type(of: attribute.value))")
            return nil
        }
        
        // Validate triangle count (should be divisible by 3 for triangle meshes)
        guard indices.count % 3 == 0 else {
            print("❌ USDMeshConverter: Face indices count \(indices.count) not divisible by 3 (not triangle mesh)")
            return nil
        }
        
        //print("🔍 DEBUG: Successfully parsed \(indices.count) indices (\(indices.count/3) triangles)")
        return indices
    }
    
    /// Parse face indices from string format like "[0, 2, 1, 0, 3, 2, ...]"
    private func parseStringIndicesArray(_ stringValue: String) -> [UInt32] {
        // Remove brackets and split by commas
        let cleaned = stringValue.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        let components = cleaned.components(separatedBy: ",")
        
        var indices: [UInt32] = []
        
        for component in components {
            let trimmed = component.trimmingCharacters(in: .whitespaces)
            if let intValue = Int(trimmed), intValue >= 0 {
                indices.append(UInt32(intValue))
            }
        }
        
        //print("🔍 DEBUG: Parsed \(indices.count) indices from string format")
        return indices
    }
    
}
