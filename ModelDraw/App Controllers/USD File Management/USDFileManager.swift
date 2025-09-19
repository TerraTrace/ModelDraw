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
    private let contentParser = USDContentParser()

    
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
        
        // Replace the old parsing calls with:
        return try contentParser.parseUSDContent(content)
    }
}



// MARK: - USD File Parsing Helper Methods

extension USDFileManager {
    
    
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




// MARK: - Testing & Debug Helpers - Remove for Flight

extension USDFileManager {
    
    // MARK: - Reference Parsing Test (Add to USDFileManagerTests.swift extension)
    
    /// Test USD reference parsing with the real CargoDragon.usd scene file
    /// Add this method to the existing USDFileManager test extension
    static func testUSDReferenceParsingCargoDragon() throws {
        print("\n🧪 Testing USD Reference Parsing - Real CargoDragon Scene...")
        
        // Use the real CargoDragon.usd file
        let cargodragonURL = URL(fileURLWithPath: "/Users/michaelraftery_1/Library/Containers/com.TerraTrace.ModelDraw/Data/Documents/ModelDraw/Projects/CargoDragon/CargoDragon.usd")

        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: cargodragonURL.path) else {
            print("⚠️ CargoDragon.usd not found at expected location")
            print("   Expected: \(cargodragonURL.path)")
            return
        }
        
        print("   📂 Found CargoDragon.usd at: \(cargodragonURL.path)")
        
        // Read it using USDFileManager
        let usdFile = try USDFileManager.shared.readUSDFile(from: cargodragonURL)
        
        // Validate stage
        print("   🏗️ Stage defaultPrim: \(usdFile.stage.defaultPrim ?? "nil")")
        print("   🏗️ Root prims count: \(usdFile.rootPrims.count)")
        
        // Find the scene assembly
        guard let sceneAssembly = usdFile.rootPrims.first else {
            print("❌ No root prims found")
            return
        }
        
        print("   📦 Scene assembly: '\(sceneAssembly.name)' type: '\(sceneAssembly.type)'")
        print("   👶 Children count: \(sceneAssembly.children.count)")
        
        // Check each child for references
        for (index, child) in sceneAssembly.children.enumerated() {
            print("   🔍 Child \(index + 1): '\(child.name)' type: '\(child.type)'")
            print("      hasReferences: \(child.hasReferences)")
            print("      references count: \(child.references.count)")
            
            if let primaryRef = child.primaryReference {
                print("      reference path: '\(primaryRef.filePath)'")
                
                // Test URL resolution
                let sceneDir = cargodragonURL.deletingLastPathComponent()
                let resolvedURL = primaryRef.resolveURL(relativeTo: sceneDir)
                print("      resolved URL: \(resolvedURL.path)")
                print("      file exists: \(FileManager.default.fileExists(atPath: resolvedURL.path))")
            }
        }
        
        // Check customData
        print("   📊 CustomData: \(sceneAssembly.metadata)")
        
        print("   ✅ USD Reference Parsing Test completed!")
    
    }

    
    
    
    
    
    
    


}




