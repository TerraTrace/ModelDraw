//
//  USDFileManager.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/15/25.
//


import Foundation



// MARK: - Error Types

enum USDFileError: Error, LocalizedError {
    case fileNotFound(path: String)
    case invalidUSDSyntax(line: Int, message: String)
    case unsupportedPrimType(type: String)
    case missingRequiredAttribute(prim: String, attribute: String)
    case writePermissionDenied(path: String)
    case invalidFileExtension(expected: String, actual: String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "USD file not found: \(path)"
        case .invalidUSDSyntax(let line, let message):
            return "Invalid USD syntax at line \(line): \(message)"
        case .unsupportedPrimType(let type):
            return "Unsupported USD primitive type: \(type)"
        case .missingRequiredAttribute(let prim, let attribute):
            return "Missing required attribute '\(attribute)' on prim '\(prim)'"
        case .writePermissionDenied(let path):
            return "Write permission denied: \(path)"
        case .invalidFileExtension(let expected, let actual):
            return "Invalid file extension. Expected \(expected), got \(actual)"
        }
    }
}

// MARK: - USDFileManager Service

/// USD file service for ModelDraw - Phase 1A: Cylinder write support only
class USDFileManager {
    static let shared = USDFileManager()
    private init() {}
    
    // MARK: - Public Interface
    
    /// Write USD file to disk - Phase 1A: Basic implementation
    /// - Parameters:
    ///   - usdFile: Complete USD file structure to write
    ///   - url: Target file URL (.usd extension)
    /// - Throws: USDFileError for file system or formatting errors
    func writeUSDFile(_ usdFile: USDFile, to url: URL) throws {
        // Validate file extension
        guard url.pathExtension.lowercased() == "usd" else {
            throw USDFileError.invalidFileExtension(expected: ".usd", actual: ".\(url.pathExtension)")
        }
        
        // Generate USD content
        let usdContent = try generateUSDContent(usdFile)
        
        // Write to file
        do {
            try usdContent.write(to: url, atomically: true, encoding: .utf8)
            print("✅ USD file written successfully: \(url.path)")
        } catch {
            throw USDFileError.writePermissionDenied(path: url.path)
        }
    }
    
    /// Validate USD file syntax - Phase 1A: Basic file existence check
    /// - Parameter url: File URL to validate
    /// - Returns: True if file exists and has .usd extension
    func validateUSDFile(at url: URL) -> Bool {
        guard url.pathExtension.lowercased() == "usd" else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    // MARK: - Phase 1A: Read operation placeholder
    /// Read USD file from disk - Phase 1A: Not implemented yet
    func readUSDFile(from url: URL) throws -> USDFile {
        throw USDFileError.unsupportedPrimType(type: "Reading not implemented in Phase 1A")
    }
}

// MARK: - USD Content Generation

private extension USDFileManager {
    
    /// Generate complete USD file content string
    func generateUSDContent(_ usdFile: USDFile) throws -> String {
        let header = generateStageHeader(usdFile.stage)
        let prims = try usdFile.rootPrims.map { try generatePrimContent($0) }.joined(separator: "\n\n")
        
        return header + "\n\n" + prims + "\n"
    }
    
    /// Generate USD stage header with metadata
    func generateStageHeader(_ stage: USDStage) -> String {
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
    
    /// Generate USD primitive content - Phase 1B: Cylinder and Cone support
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
    func generateCylinderUSD(_ prim: USDPrim) throws -> String {
        let sanitizedName = prim.name.replacingOccurrences(of: " ", with: "_")
        
        var lines: [String] = []
        
        // Prim definition with custom data
        lines.append("def Cylinder \"\(sanitizedName)\" (")
        if !prim.metadata.isEmpty {
            lines.append("    customData = {")
            for (key, value) in prim.metadata.sorted(by: { $0.key < $1.key }) {
                lines.append("        string \(key) = \"\(value)\"")
            }
            lines.append("    }")
        }
        lines.append(")")
        lines.append("{")
        
        // Geometry attributes
        for (_, attribute) in prim.attributes {
            let line = "    \(attribute.valueType) \(attribute.name) = \(formatAttributeValue(attribute.value, type: attribute.valueType))"
            lines.append(line)
        }
        
        // Transform
        if let transform = prim.transform {
            lines.append("    double3 xformOp:translate = (\(transform.position.x), \(transform.position.y), \(transform.position.z))")
            lines.append("    quatf xformOp:orient = (\(transform.orientation.wf), \(transform.orientation.xf), \(transform.orientation.yf), \(transform.orientation.zf))")
            lines.append("    uniform token[] xformOpOrder = [\"xformOp:translate\", \"xformOp:orient\"]")
        }
        
        lines.append("}")
        
        return lines.joined(separator: "\n")
    }
    
    /// Generate USD content for a cone primitive
    func generateConeUSD(_ prim: USDPrim) throws -> String {
        let sanitizedName = prim.name.replacingOccurrences(of: " ", with: "_")
        
        var lines: [String] = []
        
        // Prim definition with custom data
        lines.append("def Cone \"\(sanitizedName)\" (")
        if !prim.metadata.isEmpty {
            lines.append("    customData = {")
            for (key, value) in prim.metadata.sorted(by: { $0.key < $1.key }) {
                lines.append("        string \(key) = \"\(value)\"")
            }
            lines.append("    }")
        }
        lines.append(")")
        lines.append("{")
        
        // Geometry attributes
        for (_, attribute) in prim.attributes {
            let line = "    \(attribute.valueType) \(attribute.name) = \(formatAttributeValue(attribute.value, type: attribute.valueType))"
            lines.append(line)
        }
        
        // Transform
        if let transform = prim.transform {
            lines.append("    double3 xformOp:translate = (\(transform.position.x), \(transform.position.y), \(transform.position.z))")
            lines.append("    quatf xformOp:orient = (\(transform.orientation.wf), \(transform.orientation.xf), \(transform.orientation.yf), \(transform.orientation.zf))")
            lines.append("    uniform token[] xformOpOrder = [\"xformOp:translate\", \"xformOp:orient\"]")
        }
        
        lines.append("}")
        
        return lines.joined(separator: "\n")
    }
    
    /// Generate USD content for an Xform (transform group)
    func generateXformUSD(_ prim: USDPrim) throws -> String {
        let sanitizedName = prim.name.replacingOccurrences(of: " ", with: "_")
        
        var lines: [String] = []
        
        // Prim definition
        lines.append("def Xform \"\(sanitizedName)\" (")
        if !prim.metadata.isEmpty {
            lines.append("    customData = {")
            for (key, value) in prim.metadata.sorted(by: { $0.key < $1.key }) {
                lines.append("        string \(key) = \"\(value)\"")
            }
            lines.append("    }")
        }
        lines.append(")")
        lines.append("{")
        
        // Transform
        if let transform = prim.transform {
            lines.append("    double3 xformOp:translate = (\(transform.position.x), \(transform.position.y), \(transform.position.z))")
            lines.append("    quatf xformOp:orient = (\(transform.orientation.wf), \(transform.orientation.xf), \(transform.orientation.yf), \(transform.orientation.zf))")
            lines.append("    uniform token[] xformOpOrder = [\"xformOp:translate\", \"xformOp:orient\"]")
        }
        
        // Child prims
        for child in prim.children {
            let childContent = try generatePrimContent(child)
            let indentedChild = childContent.components(separatedBy: .newlines)
                .map { "    " + $0 }
                .joined(separator: "\n")
            lines.append("")
            lines.append(indentedChild)
        }
        
        lines.append("}")
        
        return lines.joined(separator: "\n")
    }
    
    /// Format attribute value based on USD type
    func formatAttributeValue(_ value: Any, type: String) -> String {
        switch type {
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

// MARK: - Phase 1A Testing Helper

extension USDFileManager {
    
    /// Create a test cylinder for Phase 1A validation
    /// - Parameters:
    ///   - name: Cylinder name
    ///   - height: Height in meters
    ///   - radius: Radius in meters
    ///   - position: Position in 3D space (geometric center)
    /// - Returns: USDFile ready for writing
    static func createTestCylinder(name: String = "TestCylinder",
                                 height: Double = 2.0,
                                 radius: Double = 0.5,
                                 position: Vector3D = Vector3D.zero) -> USDFile {
        
        let cylinderAttributes: [String: USDAttribute] = [
            "height": USDAttribute(name: "height", value: height, valueType: "double"),
            "radius": USDAttribute(name: "radius", value: radius, valueType: "double")
        ]
        
        let cylinderMetadata: [String: String] = [
            "modelDrawType": "cylinder",
            "modelDrawID": UUID().uuidString,
            "material": "aluminum",
            "wallThickness": "0.05"
        ]
        
        let cylinderPrim = USDPrim(
            name: name,
            type: "Cylinder",
            attributes: cylinderAttributes,
            transform: USDTransform(position: position),
            metadata: cylinderMetadata
        )
        
        let stage = USDStage(
            defaultPrim: name,
            customLayerData: [
                "modelDrawType": "testFile",
                "createdBy": "USDFileManager Phase 1A"
            ]
        )
        
        return USDFile(stage: stage, rootPrims: [cylinderPrim])
    }
    
    /// Create a test cone for Phase 1B validation
    /// - Parameters:
    ///   - name: Cone name
    ///   - height: Height in meters
    ///   - radius: Base radius in meters
    ///   - position: Position in 3D space (geometric center)
    /// - Returns: USDFile ready for writing
    static func createTestCone(name: String = "TestCone",
                              height: Double = 2.0,
                              radius: Double = 1.0,
                              position: Vector3D = Vector3D.zero) -> USDFile {
        
        let coneAttributes: [String: USDAttribute] = [
            "height": USDAttribute(name: "height", value: height, valueType: "double"),
            "radius": USDAttribute(name: "radius", value: radius, valueType: "double")
        ]
        
        let coneMetadata: [String: String] = [
            "modelDrawType": "cone",
            "modelDrawID": UUID().uuidString,
            "material": "aluminum",
            "wallThickness": "0.03"
        ]
        
        let conePrim = USDPrim(
            name: name,
            type: "Cone",
            attributes: coneAttributes,
            transform: USDTransform(position: position),
            metadata: coneMetadata
        )
        
        let stage = USDStage(
            defaultPrim: name,
            customLayerData: [
                "modelDrawType": "testFile",
                "createdBy": "USDFileManager Phase 1B - Cone Support"
            ]
        )
        
        return USDFile(stage: stage, rootPrims: [conePrim])
    }
}

