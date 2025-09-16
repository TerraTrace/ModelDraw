//
//  USDContentGenerator.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/16/25.
//

import Foundation


// MARK: - USDContentGenerator Helper Class

/// Specialized helper for generating USD file content from USDPrim structures
class USDContentGenerator {
    
    // MARK: - Public Interface
    
    /// Generate complete USD file content string from USDFile structure
    func generateUSDContent(_ usdFile: USDFile) throws -> String {
        let header = generateStageHeader(usdFile.stage)
        let prims = try usdFile.rootPrims.map { try generatePrimContent($0) }.joined(separator: "\n\n")
        
        return header + "\n\n" + prims + "\n"
    }
    
    // MARK: - Stage Generation
    
    /// Generate USD stage header with metadata
    private func generateStageHeader(_ stage: USDStage) -> String {
        var headerLines: [String] = ["#usda 1.0"]
        
        // Stage metadata in parentheses
        var stageMetadata: [String] = []
        
        if let defaultPrim = stage.defaultPrim {
            stageMetadata.append("    defaultPrim = \"\(defaultPrim)\"")
        }
        
        stageMetadata.append("    metersPerUnit = \(stage.metersPerUnit)")
        stageMetadata.append("    upAxis = \"\(stage.upAxis)\"")
        
        if !stage.customLayerData.isEmpty {
            stageMetadata.append("    customLayerData = {")
            for (key, value) in stage.customLayerData.sorted(by: { $0.key < $1.key }) {
                stageMetadata.append("        string \(key) = \"\(value)\"")
            }
            stageMetadata.append("    }")
        }
        
        if !stageMetadata.isEmpty {
            headerLines.append("(")
            headerLines.append(contentsOf: stageMetadata)
            headerLines.append(")")
        }
        
        return headerLines.joined(separator: "\n")
    }
    
    // MARK: - Prim Content Generation
    
    /// Generate USD primitive content - dispatches to specific prim type generators
    func generatePrimContent(_ prim: USDPrim) throws -> String {
        switch prim.type {
        case "Cylinder":
            return try generateCylinderUSD(prim)
        case "Cone":
            return try generateConeUSD(prim)
        case "Xform":
            return try generateXformUSD(prim)
        default:
            throw USDFileError.unsupportedPrimType(type: prim.type)
        }
    }
    
    /// Generate USD content for a cylinder primitive
    private func generateCylinderUSD(_ prim: USDPrim) throws -> String {
        let sanitizedName = prim.name.replacingOccurrences(of: " ", with: "_")
        
        var lines: [String] = []
        
        // Clean prim definition header
        lines.append("def Cylinder \"\(sanitizedName)\"")
        lines.append("{")
        
        // Core geometry attributes first
        for (_, attribute) in prim.attributes.sorted(by: { $0.key < $1.key }) {
            let valueString = formatAttributeValue(attribute.value, valueType: attribute.valueType)
            lines.append("    \(attribute.valueType) \(attribute.name) = \(valueString)")
        }
        
        // Transform attributes (if present)
        if let transform = prim.transform {
            lines.append("    double3 xformOp:translate = (\(transform.position.x), \(transform.position.y), \(transform.position.z))")
            lines.append("    quatf xformOp:orient = (\(transform.orientation.w), \(transform.orientation.x), \(transform.orientation.y), \(transform.orientation.z))")
            lines.append("    uniform token[] xformOpOrder = [\"xformOp:translate\", \"xformOp:orient\"]")
        }
        
        // CustomData at the end (optional, can fail gracefully)
        if !prim.metadata.isEmpty {
            lines.append("")  // Blank line for readability
            lines.append("    customData = {")
            for (key, value) in prim.metadata.sorted(by: { $0.key < $1.key }) {
                lines.append("        string \(key) = \"\(value)\"")
            }
            lines.append("    }")
        }
        
        lines.append("}")
        
        return lines.joined(separator: "\n")
    }
    
    /// Generate USD content for a cone primitive
    private func generateConeUSD(_ prim: USDPrim) throws -> String {
        let sanitizedName = prim.name.replacingOccurrences(of: " ", with: "_")
        
        var lines: [String] = []
        
        // Clean prim definition header
        lines.append("def Cone \"\(sanitizedName)\"")
        lines.append("{")
        
        // Core geometry attributes first
        for (_, attribute) in prim.attributes.sorted(by: { $0.key < $1.key }) {
            let valueString = formatAttributeValue(attribute.value, valueType: attribute.valueType)
            lines.append("    \(attribute.valueType) \(attribute.name) = \(valueString)")
        }
        
        // Transform attributes (if present)
        if let transform = prim.transform {
            lines.append("    double3 xformOp:translate = (\(transform.position.x), \(transform.position.y), \(transform.position.z))")
            lines.append("    quatf xformOp:orient = (\(transform.orientation.w), \(transform.orientation.x), \(transform.orientation.y), \(transform.orientation.z))")
            lines.append("    uniform token[] xformOpOrder = [\"xformOp:translate\", \"xformOp:orient\"]")
        }
        
        // CustomData at the end (optional, can fail gracefully)
        if !prim.metadata.isEmpty {
            lines.append("")  // Blank line for readability
            lines.append("    customData = {")
            for (key, value) in prim.metadata.sorted(by: { $0.key < $1.key }) {
                lines.append("        string \(key) = \"\(value)\"")
            }
            lines.append("    }")
        }
        
        lines.append("}")
        
        return lines.joined(separator: "\n")
    }
    
    /// Generate USD content for an Xform assembly primitive
    private func generateXformUSD(_ prim: USDPrim) throws -> String {
        let sanitizedName = prim.name.replacingOccurrences(of: " ", with: "_")
        
        var lines: [String] = []
        
        // Clean prim definition header
        lines.append("def Xform \"\(sanitizedName)\"")
        lines.append("{")
        
        // Xform attributes (if any) - typically just transforms
        for (_, attribute) in prim.attributes.sorted(by: { $0.key < $1.key }) {
            let valueString = formatAttributeValue(attribute.value, valueType: attribute.valueType)
            lines.append("    \(attribute.valueType) \(attribute.name) = \(valueString)")
        }
        
        // Transform attributes (if present)
        if let transform = prim.transform {
            lines.append("    double3 xformOp:translate = (\(transform.position.x), \(transform.position.y), \(transform.position.z))")
            lines.append("    quatf xformOp:orient = (\(transform.orientation.w), \(transform.orientation.x), \(transform.orientation.y), \(transform.orientation.z))")
            lines.append("    uniform token[] xformOpOrder = [\"xformOp:translate\", \"xformOp:orient\"]")
        }
        
        // Child prims (the main content of assemblies)
        for child in prim.children {
            lines.append("")  // Blank line before each child for readability
            let childContent = try generatePrimContent(child)
            // Indent child content by 4 spaces
            let indentedChildContent = childContent.components(separatedBy: .newlines)
                .map { "    " + $0 }
                .joined(separator: "\n")
            lines.append(indentedChildContent)
        }
        
        // CustomData at the end (optional, can fail gracefully)
        if !prim.metadata.isEmpty {
            lines.append("")  // Blank line for readability
            lines.append("    customData = {")
            for (key, value) in prim.metadata.sorted(by: { $0.key < $1.key }) {
                lines.append("        string \(key) = \"\(value)\"")
            }
            lines.append("    }")
        }
        
        lines.append("}")
        
        return lines.joined(separator: "\n")
    }
    
    // MARK: - Attribute Formatting
    
    /// Format attribute values for USD output based on value type
    private func formatAttributeValue(_ value: Any, valueType: String) -> String {
        switch valueType {
        case "double":
            if let doubleValue = value as? Double {
                return String(doubleValue)
            }
        case "float":
            if let floatValue = value as? Float {
                return String(floatValue)
            }
        case "string":
            if let stringValue = value as? String {
                return "\"\(stringValue)\""
            }
        case "token":
            if let tokenValue = value as? String {
                return "\"\(tokenValue)\""
            }
        default:
            break
        }
        
        return String(describing: value)
    }
}

