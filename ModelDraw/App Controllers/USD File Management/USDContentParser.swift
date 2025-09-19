//
//  USDContentParser.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/16/25.
//

import Foundation


// MARK: - USDContentParser Helper Class

/// Specialized helper for parsing USD file content into USDFile structures
class USDContentParser {
    
    // MARK: - Public Interface
    
    /// Parse complete USD file content into USDFile structure
    func parseUSDContent(_ content: String) throws -> USDFile {
        let stage = try parseStageHeader(content)
        let rootPrims = try parseRootPrims(content)
        return USDFile(stage: stage, rootPrims: rootPrims)
    }
    
    // MARK: - Stage Header Parsing
    
    /// Parse USD stage header by reversing generateStageHeader logic
    private func parseStageHeader(_ content: String) throws -> USDStage {
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
    
    
    // MARK: - USD Reference Parsing
    
    /// Parse USD references from prim metadata (UPDATED METHOD)
    /// - Parameter metadata: Complete metadata content from prim header
    /// - Returns: Array of parsed USDReference objects
    func parseReferences(from metadata: String) -> [USDReference] {
        var references: [USDReference] = []
        
        // Parse references = @./filename.usd@ syntax
        if let referencePath = extractReferencePath(from: metadata) {
            let reference = USDReference(referencePath: referencePath)
            references.append(reference)
            //print("🔍 DEBUG: Found reference: '\(referencePath)' → '\(reference.filePath)'")
        } else {
            //print("🔍 DEBUG: No references found in metadata: '\(metadata)'")
        }
        
        return references
    }
    
    
    /// Extract reference path from metadata section
    /// - Parameter metadata: Content between parentheses
    /// - Returns: Reference path string like "@./filename.usd@" or nil
    private func extractReferencePath(from metadata: String) -> String? {
        // Look for pattern: references = @./filename.usd@
        let trimmed = metadata.trimmingCharacters(in: .whitespaces)
        
        // Simple pattern matching for references line
        if trimmed.contains("references = ") {
            // Find everything after "references = "
            if let equalIndex = trimmed.range(of: "references = ") {
                let afterEquals = String(trimmed[equalIndex.upperBound...]).trimmingCharacters(in: .whitespaces)
                
                // Extract @...@ path
                if let startAt = afterEquals.firstIndex(of: "@"),
                   let endAt = afterEquals.lastIndex(of: "@"),
                   startAt != endAt {
                    return String(afterEquals[startAt...endAt])
                }
            }
        }
        
        return nil
    }
    
    
    
    // MARK: - Root Prim Parsing
    
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
    func extractPrimBlocks(from content: String) -> [String] {
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
    
    
    // MARK: - Prim Definition Parsing
    
    /// Parse prim definition with multi-line reference support (UPDATED METHOD)
    func parsePrimDefinition(_ primBlock: String) throws -> USDPrim {
        let lines = primBlock.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw USDFileError.invalidUSDSyntax(line: 1, message: "Empty prim block")
        }
        
        // Parse header to get type and name
        let headerLine = lines[0]
        let (primType, primName) = try parsePrimHeader(headerLine)
        
        // Extract multi-line prim metadata (everything between ( and ) )
        let primMetadata = extractPrimMetadata(from: lines)
        let references = parseReferences(from: primMetadata)  // ← NEW: Use full metadata
        
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
            metadata: metadata,
            references: references  // ← Include references
        )
    }
    
    
    /// Extract prim metadata from multi-line prim header
    /// - Parameter lines: All lines from the prim definition
    /// - Returns: Complete metadata content between ( and )
    private func extractPrimMetadata(from lines: [String]) -> String {
        var metadataLines: [String] = []
        var insideMetadata = false
        var parenCount = 0
        
        for line in lines {
            // Track parentheses to find metadata section
            for char in line {
                if char == "(" {
                    parenCount += 1
                    insideMetadata = true
                } else if char == ")" {
                    parenCount -= 1
                    if parenCount == 0 {
                        insideMetadata = false
                    }
                }
            }
            
            // Collect lines that are inside metadata parentheses
            if insideMetadata || parenCount > 0 {
                // Remove the opening/closing parentheses from the content
                let cleanLine = line.replacingOccurrences(of: "(", with: "")
                    .replacingOccurrences(of: ")", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if !cleanLine.isEmpty && !cleanLine.hasPrefix("def ") {
                    metadataLines.append(cleanLine)
                }
            }
            
            // Stop when we hit the opening brace (end of prim header)
            if line.contains("{") {
                break
            }
        }
        
        return metadataLines.joined(separator: " ")
    }
    
    
    /// Parse the prim header line to extract type and name (ROBUST VERSION)
    /// Handles both formats: def Type "Name" and def "Name"
    private func parsePrimHeader(_ headerLine: String) throws -> (type: String, name: String) {
        let components = headerLine.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        guard components.count >= 2,
              components[0] == "def" else {
            throw USDFileError.invalidUSDSyntax(line: 1, message: "Invalid prim header format")
        }
        
        // Check if we have format: def Type "Name" or def "Name"
        let remainingText = components[1...].joined(separator: " ")
        
        // Find the quoted name
        guard let startQuote = remainingText.firstIndex(of: "\""),
              let endQuote = remainingText.lastIndex(of: "\""),
              startQuote < endQuote else {
            throw USDFileError.invalidUSDSyntax(line: 1, message: "Could not extract prim name from quotes")
        }
        
        let nameStart = remainingText.index(after: startQuote)
        let primName = String(remainingText[nameStart..<endQuote])
        
        // Determine the type
        let primType: String
        let textBeforeQuote = String(remainingText[..<startQuote]).trimmingCharacters(in: .whitespaces)
        
        if textBeforeQuote.isEmpty {
            // Format: def "Name" - no explicit type, use default
            primType = "Scope"  // USD default for typeless prims
        } else {
            // Format: def Type "Name" - use the specified type
            primType = textBeforeQuote
        }
        
        return (type: primType, name: primName)
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
    
    // MARK: - Content Parsing Helpers
    
    /// Parse customData block from prim lines
    func parseCustomData(from lines: [String]) throws -> [String: String] {
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
    
    /// Parse geometry and other attributes from prim lines (ENHANCED for arrays)
    func parseAttributes(from lines: [String]) throws -> [String: USDAttribute] {
        var attributes: [String: USDAttribute] = [:]
        var i = 0
        
        while i < lines.count {
            let line = lines[i]
            
            // Skip customData lines and structural lines
            if line.contains("customData") || line.contains("{") || line.contains("}") ||
                line.hasPrefix("def ") || line.hasPrefix("string ") || line.hasPrefix("uniform token") {
                i += 1
                continue
            }
            
            // Check if this line starts a multi-line array attribute
            if isMultiLineArrayStart(line) {
                let (attribute, nextIndex) = try parseMultiLineArrayAttribute(from: lines, startingAt: i)
                if let attribute = attribute {
                    attributes[attribute.name] = attribute
                }
                i = nextIndex
            } else {
                // Parse single-line attribute
                if let attribute = parseAttributeLine(line) {
                    attributes[attribute.name] = attribute
                }
                i += 1
            }
        }
        
        return attributes
    }
    
    /// Check if a line starts a multi-line array attribute
    private func isMultiLineArrayStart(_ line: String) -> Bool {
        // Look for pattern like: point3f[] points = [
        // or: int[] faceVertexIndices = [
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Must contain [] for array type and end with = [
        return trimmed.contains("[]") && trimmed.hasSuffix("= [")
    }

    /// Parse multi-line array attribute starting from a given line index
    private func parseMultiLineArrayAttribute(from lines: [String], startingAt startIndex: Int) throws -> (USDAttribute?, Int) {
        guard startIndex < lines.count else { return (nil, startIndex + 1) }
        
        let headerLine = lines[startIndex]
        
        // Parse header line: point3f[] points = [
        let components = headerLine.components(separatedBy: "=")
        guard components.count == 2 else { return (nil, startIndex + 1) }
        
        let leftSide = components[0].trimmingCharacters(in: .whitespaces)
        let leftComponents = leftSide.components(separatedBy: .whitespaces)
        guard leftComponents.count == 2 else { return (nil, startIndex + 1) }
        
        let valueType = leftComponents[0]  // e.g., "point3f[]"
        let attributeName = leftComponents[1]  // e.g., "points"
        
        // Collect all lines until we find the closing ]
        var arrayContent: [String] = []
        var i = startIndex + 1  // Start after the header line
        var foundClosing = false
        
        while i < lines.count && !foundClosing {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            
            if line == "]" || line.hasSuffix("]") {
                // Found closing bracket
                if line != "]" {
                    // Line contains content before the ]
                    let contentBeforeBracket = line.replacingOccurrences(of: "]", with: "").trimmingCharacters(in: .whitespaces)
                    if !contentBeforeBracket.isEmpty {
                        arrayContent.append(contentBeforeBracket)
                    }
                }
                foundClosing = true
            } else if !line.isEmpty && !line.hasPrefix("#") {
                // Add non-empty, non-comment lines
                arrayContent.append(line)
            }
            
            i += 1
        }
        
        // Parse the collected array content
        let fullArrayString = arrayContent.joined(separator: ", ")
        let cleanedContent = fullArrayString.replacingOccurrences(of: ",", with: ", ")
        
        // Create the attribute
        let attribute = USDAttribute(
            name: attributeName,
            value: cleanedContent,
            valueType: valueType
        )
        
        //print("🔍 DEBUG: Parsed multi-line array '\(attributeName)' with content: \(cleanedContent)")
        
        return (attribute, i)
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
    
    /// Parse transform information from xformOp attributes
    func parseTransform(from lines: [String]) throws -> USDTransform? {
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
    
    /// Parse Vector3 from string like "(0.0, 1.5, 0.0)"
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
    
    /// Parse Quaternion from string like "(1.0, 0.0, 0.0, 0.0)"
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
}
