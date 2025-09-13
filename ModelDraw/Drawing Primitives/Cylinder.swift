//
//  Cylinder.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/12/25.
//

import SwiftUI
import Foundation



// MARK: - Cylinder Primitive
struct Cylinder: GeometricPrimitive {
    let id: UUID
    let primitiveType: PrimitiveType
    
    // Cylinder parameters
    let radius: Double        // Outer radius in meters
    let height: Double        // Height in meters
    let wallThickness: Double // Wall thickness in meters
    
    init(radius: Double, height: Double, wallThickness: Double) {
        self.id = UUID()
        self.primitiveType = .cylinder
        self.radius = radius
        self.height = height
        self.wallThickness = wallThickness
    }
}




