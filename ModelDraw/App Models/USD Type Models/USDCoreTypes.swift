//
//  USDCoreTypes.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/15/25.
//

import Foundation

// MARK: - USD Data Structures

/// Complete USD file representation
struct USDFile {
    let stage: USDStage
    let rootPrims: [USDPrim]
}


/// Represents a USD reference to another USD file
/// Format: references = @./filename.usd@
struct USDReference {
    /// The referenced file path (e.g., "./SimpleSpacecraft.usd")
    let filePath: String
    
    /// Optional reference type (internal, external, etc.)
    let referenceType: String?
    
    /// Create reference from USD reference syntax
    /// - Parameter referencePath: Path like "@./filename.usd@"
    init(referencePath: String) {
        // Remove @ symbols: "@./filename.usd@" → "./filename.usd"
        self.filePath = referencePath.trimmingCharacters(in: CharacterSet(charactersIn: "@"))
        self.referenceType = nil
    }
    
    /// Create reference with explicit path and type
    init(filePath: String, referenceType: String? = nil) {
        self.filePath = filePath
        self.referenceType = referenceType
    }
    
    /// Resolve reference path relative to a base URL
    /// - Parameter baseURL: The directory containing the scene file
    /// - Returns: Absolute URL to the referenced file
    func resolveURL(relativeTo baseURL: URL) -> URL {
        if filePath.hasPrefix("./") {
            // Relative path: "./filename.usd" → same directory as scene file
            let filename = String(filePath.dropFirst(2))
            return baseURL.appendingPathComponent(filename)
        } else if filePath.hasPrefix("/") {
            // Absolute path: use as-is
            return URL(fileURLWithPath: filePath)
        } else {
            // Relative filename: "filename.usd" → same directory as scene file
            return baseURL.appendingPathComponent(filePath)
        }
    }
}


/// Stage-level metadata and settings
struct USDStage {
    let defaultPrim: String?
    let metersPerUnit: Double
    let upAxis: String
    let customLayerData: [String: String]
    
    init(defaultPrim: String? = nil,
         metersPerUnit: Double = 1.0,
         upAxis: String = "Y",
         customLayerData: [String: String] = [:]) {
        self.defaultPrim = defaultPrim
        self.metersPerUnit = metersPerUnit
        self.upAxis = upAxis
        self.customLayerData = customLayerData
    }
}

typealias Assembly = USDPrim

/// Extended USDPrim to include references
/// This replaces the existing USDPrim definition in USDCoreTypes.swift
struct USDPrim {
    let name: String
    let type: String
    let attributes: [String: USDAttribute]
    let transform: USDTransform?
    let children: [USDPrim]
    let metadata: [String: String]
    let references: [USDReference]  // ← NEW: USD references
    
    /// Create USDPrim with references
    init(name: String,
         type: String,
         attributes: [String: USDAttribute] = [:],
         transform: USDTransform? = nil,
         children: [USDPrim] = [],
         metadata: [String: String] = [:],
         references: [USDReference] = []) {  // ← NEW parameter
        self.name = name
        self.type = type
        self.attributes = attributes
        self.transform = transform
        self.children = children
        self.metadata = metadata
        self.references = references
    }
    
    /// Check if this prim has USD references
    var hasReferences: Bool {
        return !references.isEmpty
    }
    
    /// Get the primary reference (first one if multiple exist)
    var primaryReference: USDReference? {
        return references.first
    }
}

/// USD primitive representation
/*struct USDPrim {
    let name: String
    let type: String
    let attributes: [String: USDAttribute]
    let transform: USDTransform?
    let children: [USDPrim]
    let metadata: [String: String]
    
    init(name: String,
         type: String,
         attributes: [String: USDAttribute] = [:],
         transform: USDTransform? = nil,
         children: [USDPrim] = [],
         metadata: [String: String] = [:]) {
        self.name = name
        self.type = type
        self.attributes = attributes
        self.transform = transform
        self.children = children
        self.metadata = metadata
    }
} */

/// USD attribute with typed values
struct USDAttribute {
    let name: String
    let value: Any
    let valueType: String
    let timeVarying: Bool
    
    init(name: String, value: Any, valueType: String, timeVarying: Bool = false) {
        self.name = name
        self.value = value
        self.valueType = valueType
        self.timeVarying = timeVarying
    }
}

/// Transform using geometric center convention
struct USDTransform {
    let position: Vector3D
    let orientation: Quaternion
    
    init(position: Vector3D, orientation: Quaternion = Quaternion.identity) {
        self.position = position
        self.orientation = orientation
    }
}
