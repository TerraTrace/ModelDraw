//
//  ModelDrawDocument.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/13/25.
//

import SwiftUI
import UniformTypeIdentifiers
import Foundation



// MARK: - Document Metadata
struct DocumentMetadata: Codable {
    let createdDate: Date
    let modifiedDate: Date
    let author: String?
    let notes: String?
    
    init(author: String? = nil, notes: String? = nil) {
        let now = Date()
        self.createdDate = now
        self.modifiedDate = now
        self.author = author
        self.notes = notes
    }
}


// MARK: - File Format Structure

struct ModelDrawFile: Codable {
    var version: String { "1.0" }
    let primitives: [AnyPrimitive]
    let metadata: DocumentMetadata
    
    init(primitives: [AnyPrimitive], metadata: DocumentMetadata) {
        self.primitives = primitives
        self.metadata = metadata
    }
}


// MARK: - Document Implementation

struct ModelDrawDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.modelDrawDocument]
    
    var primitives: [GeometricPrimitive] = []
    var metadata: DocumentMetadata = DocumentMetadata()
    
    
    // MARK: - FileDocument Conformance
    init() {
        print("🟢 Document init() called")
        // Create a test cylinder for initial testing
        let testCylinder = Cylinder(
            radius: 0.3,        // 30cm radius
            height: 0.8,        // 80cm height
            wallThickness: 0.02 // 2cm wall thickness
        )
        
        self.primitives = [testCylinder]
        self.metadata = DocumentMetadata(
            author: "ModelDraw Test",
            notes: "Initial test document with hollow cylinder"
        )
    }
    
    /*init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let modelDrawFile = try JSONDecoder().decode(ModelDrawFile.self, from: data)
        self.primitives = modelDrawFile.primitives.map { $0.primitive }
        self.metadata = modelDrawFile.metadata
    } */
    
    init(configuration: ReadConfiguration) throws {
        print("🔍 Attempting to read document...")
        
        guard let data = configuration.file.regularFileContents else {
            print("❌ Failed to get file contents")
            throw CocoaError(.fileReadCorruptFile)
        }
        
        print("✅ Got file data: \(data.count) bytes")
        
        do {
            let modelDrawFile = try JSONDecoder().decode(ModelDrawFile.self, from: data)
            print("✅ JSON decoded successfully")
            
            self.primitives = modelDrawFile.primitives.map { $0.primitive }
            self.metadata = modelDrawFile.metadata
            print("✅ Document initialized successfully")
        } catch {
            print("❌ JSON decode error: \(error)")
            throw error
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let modelDrawFile = ModelDrawFile(
            primitives: primitives.map { AnyPrimitive($0) },
            metadata: metadata
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(modelDrawFile)
        return FileWrapper(regularFileWithContents: data)
    }
}


// MARK: - Uniform Type Identifier
extension UTType {
    static var modelDrawDocument: UTType {
        UTType(exportedAs: "com.demeter.modeldraw.document")
    }
}
