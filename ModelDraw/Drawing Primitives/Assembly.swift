//
//  Assembly.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/13/25.
//


import Foundation

// MARK: - Assembly Structure
struct Assembly: Codable, Identifiable {
    let id: UUID
    var name: String
    var children: [AssemblyChild]
    var matingRules: [MatingRule]
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.children = []
        self.matingRules = []
    }
}

// MARK: - Assembly Child (can be primitive or sub-assembly)
enum AssemblyChild: Codable {
    case primitive(UUID)  // References a primitive by ID
    case assembly(UUID)   // References another assembly by ID
    
    var id: UUID {
        switch self {
        case .primitive(let id), .assembly(let id):
            return id
        }
    }
}

// MARK: - Simple Mating Rules
struct MatingRule: Codable {
    let childA: UUID          // First component ID
    let anchorA: String       // Anchor point on first component (e.g., "top")
    let childB: UUID          // Second component ID
    let anchorB: String       // Anchor point on second component (e.g., "base")
    
    init(childA: UUID, anchorA: String, childB: UUID, anchorB: String) {
        self.childA = childA
        self.anchorA = anchorA
        self.childB = childB
        self.anchorB = anchorB
    }
}

// MARK: - Assembly Extensions
extension Assembly {
    mutating func addPrimitive(_ primitiveId: UUID) {
        children.append(.primitive(primitiveId))
    }
    
    mutating func addSubAssembly(_ assemblyId: UUID) {
        children.append(.assembly(assemblyId))
    }
    
    mutating func addMating(from childA: UUID, anchor anchorA: String,
                           to childB: UUID, anchor anchorB: String) {
        let rule = MatingRule(childA: childA, anchorA: anchorA,
                             childB: childB, anchorB: anchorB)
        matingRules.append(rule)
    }
}
