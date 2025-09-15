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

/// USD primitive representation
struct USDPrim {
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
}

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
