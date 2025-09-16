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
    
    private let contentGenerator = USDContentGenerator()

    
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
        let usdContent = try contentGenerator.generateUSDContent(usdFile)
        
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
    /// Read USD file from disk - Phase 2: Implementation
    func readUSDFile(from url: URL) throws -> USDFile {
        // Validate file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw USDFileError.fileNotFound(path: url.path)
        }
        
        // Validate file extension
        guard url.pathExtension.lowercased() == "usd" else {
            throw USDFileError.invalidFileExtension(expected: ".usd", actual: ".\(url.pathExtension)")
        }
        
        // Read file content
        let content = try String(contentsOf: url, encoding: .utf8)
        
        // Parse stage header and root prims
        let stage = try parseStageHeader(content)
        let rootPrims = try parseRootPrims(content)
        
        return USDFile(stage: stage, rootPrims: rootPrims)
    }

    
}

// MARK: - USD Content Generation

private extension USDFileManager {
    
    /// Generate complete USD file content string
    /*func generateUSDContent(_ usdFile: USDFile) throws -> String {
        let header = generateStageHeader(usdFile.stage)
        let prims = try usdFile.rootPrims.map { try generatePrimContent($0) }.joined(separator: "\n\n")
        
        return header + "\n\n" + prims + "\n"
    } */
    
    /// Generate USD stage header with metadata
    /*func generateStageHeader(_ stage: USDStage) -> String {
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
    } */
    
    /// Generate USD primitive content - Phase 1B: Cylinder and Cone support
    /*func generatePrimContent(_ prim: USDPrim) throws -> String {
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
    } */
    
    
    /// Generate USD content for a cylinder primitive - Updated structure with customData at end
    /*func generateCylinderUSD(_ prim: USDPrim) throws -> String {
        let sanitizedName = prim.name.replacingOccurrences(of: " ", with: "_")
        
        var lines: [String] = []
        
        // Clean prim definition header (no parentheses)
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
    } */
    
    /// Generate USD content for a cone primitive - Updated structure with customData at end
    /*func generateConeUSD(_ prim: USDPrim) throws -> String {
        let sanitizedName = prim.name.replacingOccurrences(of: " ", with: "_")
        
        var lines: [String] = []
        
        // Clean prim definition header (no parentheses)
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
    } */
    
    /// Generate USD content for an Xform assembly primitive - Updated structure with customData at end
    /*func generateXformUSD(_ prim: USDPrim) throws -> String {
        let sanitizedName = prim.name.replacingOccurrences(of: " ", with: "_")
        
        var lines: [String] = []
        
        // Clean prim definition header (no parentheses)
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
    } */
    
    
    /// Helper method to format attribute values for USD output
    /*private func formatAttributeValue(_ value: Any, valueType: String) -> String {
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
    } */
    
}


// MARK: - USD File Parsing Helper Methods

extension USDFileManager {
    
    // MARK: - USD File Reading Implementation

    /// Parse USD stage header by reversing generateStageHeader logic
    private func parseStageHeader(_ content: String) throws -> USDStage {
    //public func parseStageHeader(_ content: String) throws -> USDStage {
        let lines = content.components(separatedBy: .newlines)
        
        // Find #usda version line
        guard lines.first(where: { $0.hasPrefix("#usda") }) != nil else {
            throw USDFileError.invalidUSDSyntax(line: 1, message: "Missing #usda header")
        }
        
        // Find stage metadata section between first ( and matching )
        guard let openParenIndex = content.firstIndex(of: "("),
              let closeParenIndex = findMatchingCloseParen(in: content, startingAt: openParenIndex) else {
            // No stage metadata - return minimal stage
            return USDStage(defaultPrim: nil, metersPerUnit: 1.0, upAxis: "Y", customLayerData: [:])
        }
        
        // Extract content between parentheses
        let startIndex = content.index(after: openParenIndex)
        let metadataContent = String(content[startIndex..<closeParenIndex])
        
        // Parse stage metadata fields
        var defaultPrim: String?
        var metersPerUnit: Double = 1.0
        var upAxis: String = "Y"
        var customLayerData: [String: String] = [:]
        
        // Parse each line of metadata
        let metadataLines = metadataContent.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var i = 0
        while i < metadataLines.count {
            let line = metadataLines[i]
            
            if line.hasPrefix("defaultPrim = ") {
                defaultPrim = parseQuotedValue(from: line, key: "defaultPrim")
                
            } else if line.hasPrefix("metersPerUnit = ") {
                if let value = parseNumericValue(from: line, key: "metersPerUnit") {
                    metersPerUnit = value
                }
                
            } else if line.hasPrefix("upAxis = ") {
                upAxis = parseQuotedValue(from: line, key: "upAxis") ?? "Y"
                
            } else if line.hasPrefix("customLayerData = {") {
                // Parse customLayerData block
                i += 1  // Skip opening line
                while i < metadataLines.count && !metadataLines[i].contains("}") {
                    let dataLine = metadataLines[i].trimmingCharacters(in: .whitespaces)
                    if dataLine.hasPrefix("string ") {
                        parseCustomDataLine(dataLine, into: &customLayerData)
                    }
                    i += 1
                }
                // i will be incremented again at end of loop, which is correct
            }
            
            i += 1
        }
        
        return USDStage(
            defaultPrim: defaultPrim,
            metersPerUnit: metersPerUnit,
            upAxis: upAxis,
            customLayerData: customLayerData
        )
    }

    // MARK: - Stage Header Parsing Helpers

    /// Find matching closing parenthesis, accounting for nested parentheses
    private func findMatchingCloseParen(in content: String, startingAt openIndex: String.Index) -> String.Index? {
        var parenCount = 1
        var currentIndex = content.index(after: openIndex)
        
        while currentIndex < content.endIndex && parenCount > 0 {
            let char = content[currentIndex]
            if char == "(" {
                parenCount += 1
            } else if char == ")" {
                parenCount -= 1
            }
            
            if parenCount == 0 {
                return currentIndex
            }
            
            currentIndex = content.index(after: currentIndex)
        }
        
        return nil
    }

    /// Parse quoted string value from line like: defaultPrim = "OrientedSpacecraft"
    private func parseQuotedValue(from line: String, key: String) -> String? {
        let prefix = "\(key) = \""
        guard line.hasPrefix(prefix) else { return nil }
        
        let valueStart = line.index(line.startIndex, offsetBy: prefix.count)
        guard let valueEnd = line.lastIndex(of: "\""), valueEnd > valueStart else { return nil }
        
        return String(line[valueStart..<valueEnd])
    }

    /// Parse numeric value from line like: metersPerUnit = 1.0
    private func parseNumericValue(from line: String, key: String) -> Double? {
        let prefix = "\(key) = "
        guard line.hasPrefix(prefix) else { return nil }
        
        let valueStart = line.index(line.startIndex, offsetBy: prefix.count)
        let valueString = String(line[valueStart...]).trimmingCharacters(in: .whitespaces)
        
        return Double(valueString)
    }

    /// Parse custom data line like: string modelDrawType = "spacecraft"
    private func parseCustomDataLine(_ line: String, into customData: inout [String: String]) {
        // Expected format: string key = "value"
        guard line.hasPrefix("string ") else { return }
        
        let withoutString = String(line.dropFirst(7))  // Remove "string "
        guard let equalIndex = withoutString.firstIndex(of: "=") else { return }
        
        let key = String(withoutString[..<equalIndex]).trimmingCharacters(in: .whitespaces)
        let valueWithQuotes = String(withoutString[withoutString.index(after: equalIndex)...])
            .trimmingCharacters(in: .whitespaces)
        
        // Remove quotes
        if valueWithQuotes.hasPrefix("\"") && valueWithQuotes.hasSuffix("\"") {
            let value = String(valueWithQuotes.dropFirst().dropLast())
            customData[key] = value
        }
    }
    
    // MARK: - Root Prim Parsing Helpers
    
    /// Parse root-level USD prims from file content
    private func parseRootPrims(_ content: String) throws -> [USDPrim] {
        var rootPrims: [USDPrim] = []
        
        // Find all prim definition blocks
        let primBlocks = extractPrimBlocks(from: content)
        
        // Parse each prim block
        for primBlock in primBlocks {
            let prim = try parsePrimDefinition(primBlock)
            rootPrims.append(prim)
        }
        
        return rootPrims
    }

    /// Extract individual prim definition blocks from USD content
    private func extractPrimBlocks(from content: String) -> [String] {
    //public func extractPrimBlocks(from content: String) -> [String] {
        var primBlocks: [String] = []
        let lines = content.components(separatedBy: .newlines)
        
        var i = 0
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            
            // Look for prim definition start: "def [Type] "[Name]""
            if line.hasPrefix("def ") && line.contains("\"") {
                // Found a prim definition - extract the complete block
                if let primBlock = extractSinglePrimBlock(from: lines, startingAt: i) {
                    primBlocks.append(primBlock.block)
                    i = primBlock.endIndex + 1  // Move past this block
                } else {
                    i += 1  // Skip this line if extraction failed
                }
            } else {
                i += 1
            }
        }
        
        return primBlocks
    }

    /// Extract a single prim block starting at the given line index
    /// Returns the complete prim block text and the ending line index
    private func extractSinglePrimBlock(from lines: [String], startingAt startIndex: Int) -> (block: String, endIndex: Int)? {
        guard startIndex < lines.count else { return nil }
        
        var blockLines: [String] = []
        var braceCount = 0
        var foundOpenBrace = false
        var i = startIndex
        
        // Process each line starting from the def line
        while i < lines.count {
            let line = lines[i]
            blockLines.append(line)
            
            // Count braces to find the matching closing brace
            for char in line {
                if char == "{" {
                    braceCount += 1
                    foundOpenBrace = true
                } else if char == "}" {
                    braceCount -= 1
                }
            }
            
            // If we've found the opening brace and closed all braces, we're done
            if foundOpenBrace && braceCount == 0 {
                return (block: blockLines.joined(separator: "\n"), endIndex: i)
            }
            
            i += 1
        }
        
        // If we get here, we never found a complete block
        return nil
    }
    
    
    /// Parse a complete USD prim definition block with nested children support
    private func parsePrimDefinition(_ primBlock: String) throws -> USDPrim {
    //public func parsePrimDefinition(_ primBlock: String) throws -> USDPrim {
        let lines = primBlock.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw USDFileError.invalidUSDSyntax(line: 1, message: "Empty prim block")
        }
        
        // Parse header to get type and name
        let (primType, primName) = try parsePrimHeader(lines[0])
        
        // Split content into parent content and child blocks
        let (parentLines, childBlocks) = try separateParentAndChildContent(from: lines)
        
        // Parse parent content only
        let metadata = try parseCustomData(from: parentLines)
        let attributes = try parseAttributes(from: parentLines)
        let transform = try parseTransform(from: parentLines)
        
        // Recursively parse child prims
        var children: [USDPrim] = []
        for childBlock in childBlocks {
            let childPrim = try parsePrimDefinition(childBlock)
            children.append(childPrim)
        }
        
        return USDPrim(
            name: primName,
            type: primType,
            attributes: attributes,
            transform: transform,
            children: children,
            metadata: metadata
        )
    }

    /// Separate parent prim content from nested child prim blocks
    private func separateParentAndChildContent(from lines: [String]) throws -> (parentLines: [String], childBlocks: [String]) {
        var parentLines: [String] = []
        var childBlocks: [String] = []
        
        var i = 1 // Skip the first line (def statement)
        
        // Skip opening brace line
        if i < lines.count && lines[i] == "{" {
            i += 1
        }
        
        // Process lines until we hit nested def statements
        while i < lines.count {
            let line = lines[i]
            
            // Check if this is a nested prim definition
            if line.hasPrefix("def ") && line.contains("\"") {
                // Found a child prim - extract its complete block
                let childBlock = try extractNestedPrimBlock(from: lines, startingAt: i)
                childBlocks.append(childBlock.block)
                i = childBlock.endIndex + 1 // Move past this child block
            } else if line == "}" && i == lines.count - 1 {
                // This is the final closing brace - stop processing
                break
            } else {
                // This is parent content
                parentLines.append(line)
                i += 1
            }
        }
        
        return (parentLines: parentLines, childBlocks: childBlocks)
    }

    /// Extract a nested child prim block from within a parent prim
    private func extractNestedPrimBlock(from lines: [String], startingAt startIndex: Int) throws -> (block: String, endIndex: Int) {
        guard startIndex < lines.count else {
            throw USDFileError.invalidUSDSyntax(line: startIndex, message: "Invalid child prim start index")
        }
        
        var blockLines: [String] = []
        var braceCount = 0
        var foundOpenBrace = false
        var i = startIndex
        
        // Extract the complete child prim block
        while i < lines.count {
            let line = lines[i]
            blockLines.append(line)
            
            // Count braces to find the matching closing brace
            for char in line {
                if char == "{" {
                    braceCount += 1
                    foundOpenBrace = true
                } else if char == "}" {
                    braceCount -= 1
                }
            }
            
            // If we've closed all braces for this child, we're done
            if foundOpenBrace && braceCount == 0 {
                return (block: blockLines.joined(separator: "\n"), endIndex: i)
            }
            
            i += 1
        }
        
        // If we get here, we never found a complete child block
        throw USDFileError.invalidUSDSyntax(line: startIndex, message: "Incomplete nested prim block")
    }

    /// Parse the prim header line to extract type and name
    /// Example: "def Cylinder \"PropellantTank\" (" -> ("Cylinder", "PropellantTank")
    private func parsePrimHeader(_ headerLine: String) throws -> (type: String, name: String) {
    //public func parsePrimHeader(_ headerLine: String) throws -> (type: String, name: String) {
        // Expected format: def [Type] "[Name]" (
        let components = headerLine.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        guard components.count >= 3,
              components[0] == "def" else {
            throw USDFileError.invalidUSDSyntax(line: 1, message: "Invalid prim header format")
        }
        
        let primType = components[1]
        
        // Extract name from quoted string in remaining components
        let remainingText = components[2...].joined(separator: " ")
        guard let startQuote = remainingText.firstIndex(of: "\""),
              let endQuote = remainingText.lastIndex(of: "\""),
              startQuote < endQuote else {
            throw USDFileError.invalidUSDSyntax(line: 1, message: "Could not extract prim name from quotes")
        }
        
        let nameStart = remainingText.index(after: startQuote)
        let primName = String(remainingText[nameStart..<endQuote])
        
        return (type: primType, name: primName)
    }
    
    
    // MARK: - Prim Definition Parsing Helpers

    /// Parse customData block from prim lines
    private func parseCustomData(from lines: [String]) throws -> [String: String] {
        var customData: [String: String] = [:]
        var insideCustomData = false
        
        for line in lines {
            if line.contains("customData = {") {
                insideCustomData = true
                continue
            }
            
            if insideCustomData {
                if line.contains("}") {
                    insideCustomData = false
                    continue
                }
                
                // Parse line like: string material = "aluminum"
                if line.hasPrefix("string ") {
                    parseCustomDataLine(line, into: &customData)
                }
            }
        }
        
        return customData
    }

    /// Parse geometry and other attributes from prim lines
    private func parseAttributes(from lines: [String]) throws -> [String: USDAttribute] {
        var attributes: [String: USDAttribute] = [:]
        
        for line in lines {
            // Skip customData lines and structural lines
            if line.contains("customData") || line.contains("{") || line.contains("}") ||
               line.hasPrefix("def ") || line.hasPrefix("string ") || line.hasPrefix("uniform token") {
                continue
            }
            
            // Parse attribute lines like: double height = 2.0
            if let attribute = parseAttributeLine(line) {
                attributes[attribute.name] = attribute
            }
        }
        
        return attributes
    }

    /// Parse a single attribute line
    private func parseAttributeLine(_ line: String) -> USDAttribute? {
        // Handle different attribute formats:
        // double height = 2.0
        // double3 xformOp:translate = (0, 1, 0)
        // quatf xformOp:orient = (0.707, -0.707, 0, 0)
        
        let components = line.components(separatedBy: "=")
        guard components.count == 2 else { return nil }
        
        let leftSide = components[0].trimmingCharacters(in: .whitespaces)
        let rightSide = components[1].trimmingCharacters(in: .whitespaces)
        
        // Parse left side: "double height" or "double3 xformOp:translate"
        let leftComponents = leftSide.components(separatedBy: .whitespaces)
        guard leftComponents.count == 2 else { return nil }
        
        let valueType = leftComponents[0]
        let attributeName = leftComponents[1]
        
        // Skip transform attributes - they'll be handled by parseTransform
        if attributeName.hasPrefix("xformOp:") {
            return nil
        }
        
        // Parse right side value based on type
        let value = parseAttributeValue(rightSide, valueType: valueType)
        
        return USDAttribute(name: attributeName, value: value, valueType: valueType)
    }

    /// Parse attribute value based on USD type
    private func parseAttributeValue(_ valueString: String, valueType: String) -> Any {
        let cleanValue = valueString.trimmingCharacters(in: .whitespaces)
        
        switch valueType {
        case "double":
            return Double(cleanValue) ?? 0.0
        case "float":
            return Float(cleanValue) ?? 0.0
        case "int":
            return Int(cleanValue) ?? 0
        case "string":
            // Remove quotes
            if cleanValue.hasPrefix("\"") && cleanValue.hasSuffix("\"") {
                return String(cleanValue.dropFirst().dropLast())
            }
            return cleanValue
        case "double3":
            return parseVector3(cleanValue)
        case "quatf":
            return parseQuaternion(cleanValue)
        default:
            return cleanValue
        }
    }

    
    /// Parse Vector3 from string like "(0.0, 1.5, 0.0)" - Enhanced version
    private func parseVector3(_ valueString: String) -> Vector3D {
        let cleanValue = valueString.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
        let components = cleanValue.components(separatedBy: ",").map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        
        guard components.count == 3,
              let x = Double(components[0]),
              let y = Double(components[1]),
              let z = Double(components[2]) else {
            print("⚠️ Failed to parse Vector3 from: '\(valueString)'")
            return Vector3D.zero
        }
        
        return Vector3D(x: x, y: y, z: z)
    }

    /// Parse Quaternion from string like "(1.0, 0.0, 0.0, 0.0)" - Enhanced version
    private func parseQuaternion(_ valueString: String) -> Quaternion {
        let cleanValue = valueString.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
        let components = cleanValue.components(separatedBy: ",").map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        
        guard components.count == 4,
              let w = Double(components[0]),
              let x = Double(components[1]),
              let y = Double(components[2]),
              let z = Double(components[3]) else {
            print("⚠️ Failed to parse Quaternion from: '\(valueString)'")
            return Quaternion.identity
        }
        
        return Quaternion(w: w, x: x, y: y, z: z)
    }

    /// Parse transform information from xformOp attributes - Fixed pattern matching
    private func parseTransform(from lines: [String]) throws -> USDTransform? {
        var position = Vector3D.zero
        var orientation = Quaternion.identity
        var hasTransform = false
        
        for line in lines {
            // More specific pattern matching to avoid xformOpOrder line
            if line.contains("xformOp:translate =") {
                // Parse line like: double3 xformOp:translate = (0.0, 1.5, 0.0)
                if let vector = parseTranslateLine(line) {
                    position = vector
                    hasTransform = true
                }
            } else if line.contains("xformOp:orient =") {
                // Parse line like: quatf xformOp:orient = (1.0, 0.0, 0.0, 0.0)
                if let quat = parseOrientLine(line) {
                    orientation = quat
                    hasTransform = true
                }
            }
            // Skip xformOpOrder lines - they don't contain transform values
        }
        
        return hasTransform ? USDTransform(position: position, orientation: orientation) : nil
    }
    

    /// Parse translate line directly: double3 xformOp:translate = (0.0, 1.5, 0.0)
    private func parseTranslateLine(_ line: String) -> Vector3D? {
        // Find the equals sign and extract the value part
        guard let equalsIndex = line.firstIndex(of: "=") else { return nil }
        
        let valueStart = line.index(after: equalsIndex)
        let valueString = String(line[valueStart...]).trimmingCharacters(in: .whitespaces)
        
        // Parse Vector3 from string like "(0.0, 1.5, 0.0)"
        return parseVector3(valueString)
    }

    /// Parse orient line directly: quatf xformOp:orient = (1.0, 0.0, 0.0, 0.0)
    private func parseOrientLine(_ line: String) -> Quaternion? {
        // Find the equals sign and extract the value part
        guard let equalsIndex = line.firstIndex(of: "=") else { return nil }
        
        let valueStart = line.index(after: equalsIndex)
        let valueString = String(line[valueStart...]).trimmingCharacters(in: .whitespaces)
        
        // Parse Quaternion from string like "(1.0, 0.0, 0.0, 0.0)"
        return parseQuaternion(valueString)
    }
    

    /// Parse child prims for assemblies (Xform types)
    private func parseChildren(from lines: [String], parentType: String) throws -> [USDPrim] {
        // For now, return empty - child parsing will be handled by the main parseRootPrims
        // since children appear as separate def blocks in the file
        return []
    }
    
    
    
    
}











// MARK: - Testing & Debug Helpers - Remove for Flight

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
    
    
    /// Debug version of parseAttributes to see what lines are being processed/skipped
    public func debugParseAttributes(from lines: [String]) throws -> [String: USDAttribute] {
        var attributes: [String: USDAttribute] = [:]
        
        print("🔍 DEBUG: Processing \(lines.count) lines for attributes:")
        
        for (index, line) in lines.enumerated() {
            print("   Line \(index + 1): \"\(line)\"")
            
            // Skip customData lines and structural lines
            if line.contains("customData") {
                print("      → SKIPPED: Contains customData")
                continue
            }
            if line.contains("{") || line.contains("}") {
                print("      → SKIPPED: Contains braces")
                continue
            }
            if line.hasPrefix("def ") {
                print("      → SKIPPED: def line")
                continue
            }
            if line.hasPrefix("string ") {
                print("      → SKIPPED: string line")
                continue
            }
            if line.hasPrefix("uniform token") {
                print("      → SKIPPED: uniform token")
                continue
            }
            
            // Try to parse as attribute line
            print("      → PROCESSING: Attempting to parse as attribute")
            if let attribute = parseAttributeLine(line) {
                print("      → SUCCESS: Parsed \(attribute.name) = \(attribute.value)")
                attributes[attribute.name] = attribute
            } else {
                print("      → FAILED: Could not parse as attribute")
            }
        }
        
        print("🔍 DEBUG: Found \(attributes.count) total attributes")
        return attributes
    }
    
}

