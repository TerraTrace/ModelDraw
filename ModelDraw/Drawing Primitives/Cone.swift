//
//  Cone.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/13/25.
//

import SwiftUI
import Foundation


// MARK: - Cone Primitive
struct Cone: GeometricPrimitive {
    let id: UUID
    let primitiveType: PrimitiveType
    
    // Cone parameters
    let baseRadius: Double     // Base radius in meters
    let topRadius: Double      // Top radius in meters (0 for full cone)
    let height: Double         // Height in meters
    let wallThickness: Double  // Wall thickness in meters
    
    init(baseRadius: Double, topRadius: Double = 0.0, height: Double, wallThickness: Double) {
        self.id = UUID()
        self.primitiveType = .cone
        self.baseRadius = baseRadius
        self.topRadius = topRadius
        self.height = height
        self.wallThickness = wallThickness
    }
}
