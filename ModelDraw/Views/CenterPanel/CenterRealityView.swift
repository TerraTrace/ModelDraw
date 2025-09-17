//
//  CenterRealityView.swift - Updated for ViewModel-Driven Architecture
//  ModelDraw
//

import SwiftUI
import RealityKit

// MARK: - Center RealityKit View
struct CenterRealityView: View {
    @Environment(ViewModel.self) private var model
    
    var body: some View {

    }
}

// MARK: - RealityKit Scene Creation

extension CenterRealityView {
    
    /// Create a 20m x 20m engineering grid with 1m spacing using thin cylinder entities
    /// Returns a single parent Entity containing all grid lines for easy management
    private func createEngineeringGrid() -> Entity {
        let gridContainer = Entity()
        gridContainer.name = "EngineeringGrid"
        
        // Grid parameters
        let gridSize: Float = 20.0  // 20m x 20m total
        let spacing: Float = 1.0    // 1m spacing
        let lineRadius: Float = 0.005  // Very thin lines (5mm radius)
        let lineLength = gridSize
        let numLines = Int(gridSize / spacing) + 1  // 21 lines (0 to 20m, every 1m)
        
        // Create material for grid lines
        var material = PhysicallyBasedMaterial()
        material.baseColor = PhysicallyBasedMaterial.BaseColor(tint: .gray.withAlphaComponent(0.3))
        material.blending = .transparent(opacity: 0.3)
        
        print("🔲 Creating engineering grid: \(numLines)x\(numLines) lines with \(spacing)m spacing")
        
        // Create X-direction lines (running east-west, parallel to X-axis)
        for i in 0..<numLines {
            let zPosition = -gridSize/2 + Float(i) * spacing  // -10m to +10m
            
            let cylinder = MeshResource.generateCylinder(height: lineLength, radius: lineRadius)
            let lineEntity = ModelEntity(mesh: cylinder, materials: [material])
            lineEntity.name = "GridLine_X_\(i)"
            
            // Position line: center at origin, extend along X-axis
            lineEntity.transform.translation = SIMD3<Float>(0, 0, zPosition)
            
            // Rotate cylinder to align along X-axis (90° around Z-axis)
            lineEntity.transform.rotation = simd_quatf(angle: Float.pi/2, axis: [0, 0, 1])
            
            gridContainer.addChild(lineEntity)
        }
        
        // Create Z-direction lines (running north-south, parallel to Z-axis)
        for i in 0..<numLines {
            let xPosition = -gridSize/2 + Float(i) * spacing  // -10m to +10m
            
            let cylinder = MeshResource.generateCylinder(height: lineLength, radius: lineRadius)
            let lineEntity = ModelEntity(mesh: cylinder, materials: [material])
            lineEntity.name = "GridLine_Z_\(i)"
            
            // Position line: center at origin, extend along Z-axis
            lineEntity.transform.translation = SIMD3<Float>(xPosition, 0, 0)
            
            // No rotation needed - cylinder default orientation aligns with Z-axis
            
            gridContainer.addChild(lineEntity)
        }
        
        print("✅ Engineering grid created: \(numLines * 2) total lines")
        return gridContainer
    }
    
}
