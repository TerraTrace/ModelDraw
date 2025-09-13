//
//  GeometricPrimitives.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/12/25.
//

import SwiftUI
import Foundation


// MARK: - Geometric Primitive Protocol
protocol GeometricPrimitive: Codable {
    var id: UUID { get }
    var primitiveType: PrimitiveType { get }
}


// MARK: - Primitive Types
enum PrimitiveType: String, Codable, CaseIterable {
    case cylinder = "cylinder"
}


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


// MARK: - Type Erasure for Codable Collections
struct AnyPrimitive: Codable {
    let primitive: GeometricPrimitive
    
    init(_ primitive: GeometricPrimitive) {
        self.primitive = primitive
    }
    
    enum CodingKeys: String, CodingKey {
        case type, data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(PrimitiveType.self, forKey: .type)
        
        switch type {
        case .cylinder:
            self.primitive = try container.decode(Cylinder.self, forKey: .data)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(primitive.primitiveType, forKey: .type)
        
        switch primitive.primitiveType {
        case .cylinder:
            try container.encode(primitive as! Cylinder, forKey: .data)
        }
    }
}



