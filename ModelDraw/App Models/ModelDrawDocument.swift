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

// MARK: - File Format Structure
struct ModelDrawFile: Codable {
    var version: String { "1.0" }
    let primitives: [AnyPrimitive]
    let assemblies: [Assembly]
    let metadata: DocumentMetadata
    
    init(primitives: [AnyPrimitive], assemblies: [Assembly], metadata: DocumentMetadata) {
        self.primitives = primitives
        self.assemblies = assemblies
        self.metadata = metadata
    }
}

// MARK: - Document Implementation

struct ModelDrawDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.modelDrawDocument]
    
    var primitives: [GeometricPrimitive] = []
    var assemblies: [Assembly] = []
    var metadata: DocumentMetadata = DocumentMetadata()
    
    // MARK: - FileDocument Conformance
    init() {
        print("🟢 Document init() called")
        
        // Create the test assembly
        let (testPrimitives, testAssembly) = createCargoDragonAssembly()
        
        self.primitives = testPrimitives
        self.assemblies = [testAssembly]
        
        self.metadata = DocumentMetadata(
            author: "ModelDraw Test",
            notes: "Test document with Cargo Dragon assembly (cylinder + cone)"
        )
        
        // Print assembly info
        print("Created assembly: \(testAssembly.name)")
        print("Contains \(testAssembly.children.count) primitives")
        print("Has \(testAssembly.matingRules.count) mating rules")
        print("Mating: cone.base -> cylinder.top")
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let modelDrawFile = try decoder.decode(ModelDrawFile.self, from: data)
        
        self.primitives = modelDrawFile.primitives.map { $0.primitive }
        self.assemblies = modelDrawFile.assemblies
        self.metadata = modelDrawFile.metadata
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let modelDrawFile = ModelDrawFile(
            primitives: primitives.map { AnyPrimitive($0) },
            assemblies: assemblies,
            metadata: metadata
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(modelDrawFile)
        return FileWrapper(regularFileWithContents: data)
    }
    
    
    // MARK: - Test Assembly Function
    func createCargoDragonAssembly() -> (primitives: [GeometricPrimitive], assembly: Assembly) {
        
        // Create the cylinder (pressurized section)
        let cylinder = Cylinder(
            radius: 1.8,          // 3.6m diameter like Cargo Dragon
            height: 3.0,          // 3m height
            wallThickness: 0.05   // 5cm wall thickness
        )
        
        // Create the cone (unpressurized trunk section)
        let cone = Cone(
            baseRadius: 1.8,      // Matches cylinder radius
            topRadius: 0.9,       // Tapers to smaller radius
            height: 2.5,          // 2.5m trunk height
            wallThickness: 0.03   // 3cm wall thickness
        )
        
        // Create the assembly
        var cargoDragon = Assembly(name: "Cargo Dragon Capsule")
        
        // Add the primitives to the assembly
        cargoDragon.addPrimitive(cylinder.id)
        cargoDragon.addPrimitive(cone.id)
        
        // Define mating: cone base mates to cylinder top
        cargoDragon.addMating(
            from: cone.id, anchor: "base",
            to: cylinder.id, anchor: "top"
        )
        
        // Return both the primitives and assembly
        let primitives: [GeometricPrimitive] = [cylinder, cone]
        
        return (primitives: primitives, assembly: cargoDragon)
    }
    
    
    
}



// MARK: - Uniform Type Identifier
extension UTType {
    static var modelDrawDocument: UTType {
        UTType(exportedAs: "com.demeter.modeldraw.document")
    }
}
