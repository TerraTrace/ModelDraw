//
//  PrimitiveType.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/13/25.
//

import SwiftUI
import Foundation


// MARK: - Primitive Types
enum PrimitiveType: String, Codable, CaseIterable {
    case cylinder = "cylinder"
    case cone = "cone"
}



// MARK: - Geometric Primitive Protocol
protocol GeometricPrimitive: Codable {
    var id: UUID { get }
    var primitiveType: PrimitiveType { get }
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
        case .cone:
            self.primitive = try container.decode(Cone.self, forKey: .data)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(primitive.primitiveType, forKey: .type)
        
        switch primitive.primitiveType {
        case .cylinder:
            try container.encode(primitive as! Cylinder, forKey: .data)
        case .cone:
            try container.encode(primitive as! Cone, forKey: .data)
        }
    }
}

