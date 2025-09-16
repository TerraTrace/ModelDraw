//
//  USDFileManagerTest.swift
//  ModelDraw
//
//  Phase 1A Test: Create cylinder USD file for RCP validation
//  Add this to your ModelDraw project for testing
//

import Foundation

// MARK: - Phase 1A Test Function

/// Test USDFileManager by creating a simple cylinder USD file
/// Call this from your app to generate a test file you can drag into RCP
func testUSDFileManager() {
    print("🧪 Testing USDFileManager Phase 1A...")
    
    // 1. Create test cylinder
    let testCylinder = USDFileManager.createTestCylinder(
        name: "PropellantTank",
        height: 3.0,
        radius: 1.0,
        position: Vector3D(x: 0, y: 1.5, z: 0)  // Geometric center at y=1.5 (half height above origin)
    )
    
    // 2. Get app's Documents directory (sandboxed)
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let testFileURL = documentsURL.appendingPathComponent("ModelDrawTest_Cylinder.usd")
    
    // 3. Write USD file
    do {
        try USDFileManager.shared.writeUSDFile(testCylinder, to: testFileURL)
        print("✅ Test cylinder USD created at: \(testFileURL.path)")
        print("📱 Open Finder → Go → Go to Folder → ~/Library/Containers/[YourAppID]/Data/Documents/")
        print("📱 Or check the app's Documents directory to find the .usd file")
        
        // 4. Validate the file we just wrote
        let isValid = USDFileManager.shared.validateUSDFile(at: testFileURL)
        print("🔍 File validation: \(isValid ? "PASS" : "FAIL")")
        
    } catch {
        print("❌ Test failed: \(error.localizedDescription)")
    }
}

// MARK: - Extended Test with Multiple Cylinders

/// Test USDFileManager with an assembly of multiple cylinders
func testUSDAssembly() {
    print("🧪 Testing USDFileManager Assembly...")
    
    // Create main tank
    let mainTankAttributes: [String: USDAttribute] = [
        "height": USDAttribute(name: "height", value: 4.0, valueType: "double"),
        "radius": USDAttribute(name: "radius", value: 1.2, valueType: "double")
    ]
    
    let mainTank = USDPrim(
        name: "MainTank",
        type: "Cylinder",
        attributes: mainTankAttributes,
        transform: USDTransform(position: Vector3D(x: 0, y: 2.0, z: 0)),
        metadata: [
            "modelDrawType": "cylinder",
            "modelDrawID": UUID().uuidString,
            "material": "aluminum",
            "wallThickness": "0.08"
        ]
    )
    
    // Create smaller auxiliary tank
    let auxTankAttributes: [String: USDAttribute] = [
        "height": USDAttribute(name: "height", value: 1.5, valueType: "double"),
        "radius": USDAttribute(name: "radius", value: 0.6, valueType: "double")
    ]
    
    let auxTank = USDPrim(
        name: "AuxiliaryTank",
        type: "Cylinder",
        attributes: auxTankAttributes,
        transform: USDTransform(position: Vector3D(x: 2.5, y: 0.75, z: 0)),
        metadata: [
            "modelDrawType": "cylinder",
            "modelDrawID": UUID().uuidString,
            "material": "aluminum",
            "wallThickness": "0.05"
        ]
    )
    
    // Create assembly Xform containing both tanks
    let assembly = USDPrim(
        name: "TankAssembly",
        type: "Xform",
        transform: USDTransform(position: Vector3D.zero),
        children: [mainTank, auxTank],
        metadata: [
            "modelDrawType": "assembly",
            "assemblyType": "propulsion"
        ]
    )
    
    let stage = USDStage(
        defaultPrim: "TankAssembly",
        customLayerData: [
            "modelDrawType": "assembly",
            "createdBy": "USDFileManager Phase 1A Assembly Test"
        ]
    )
    
    let assemblyFile = USDFile(stage: stage, rootPrims: [assembly])
    
    // Write assembly file to app's Documents directory
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let assemblyFileURL = documentsURL.appendingPathComponent("ModelDrawTest_Assembly.usd")
    
    do {
        try USDFileManager.shared.writeUSDFile(assemblyFile, to: assemblyFileURL)
        print("✅ Test assembly USD created at: \(assemblyFileURL.path)")
        print("📱 Find the files in your app's Documents directory and drag to RCP!")
        
    } catch {
        print("❌ Assembly test failed: \(error.localizedDescription)")
    }
}


// MARK: - Phase 1B: Cone Test

/// Test USDFileManager cone support
func testUSDCone() {
    print("🧪 Testing USDFileManager Cone Support...")
    
    // Create test cone - positioned with geometric center
    let testCone = USDFileManager.createTestCone(
        name: "NoseCone",
        height: 2.5,
        radius: 0.8,
        position: Vector3D(x: 0, y: 1.25, z: 0)  // Geometric center at y=1.25 (1/3 up from base)
    )
    
    // Write to app's Documents directory
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let testFileURL = documentsURL.appendingPathComponent("ModelDrawTest_Cone.usd")
    
    do {
        try USDFileManager.shared.writeUSDFile(testCone, to: testFileURL)
        print("✅ Test cone USD created at: \(testFileURL.path)")
        print("📱 Find ModelDrawTest_Cone.usd in your app's Documents directory!")
        
        let isValid = USDFileManager.shared.validateUSDFile(at: testFileURL)
        print("🔍 Cone file validation: \(isValid ? "PASS" : "FAIL")")
        
    } catch {
        print("❌ Cone test failed: \(error.localizedDescription)")
    }
}

// MARK: - Combined Cylinder + Cone Assembly Test

/// Test USDFileManager with cylinder and cone in one assembly
func testUSDSpacecraftAssembly() {
    print("🧪 Testing USDFileManager Spacecraft Assembly (Cylinder + Cone)...")
    
    // Create main propellant tank (cylinder)
    let tankAttributes: [String: USDAttribute] = [
        "height": USDAttribute(name: "height", value: 3.0, valueType: "double"),
        "radius": USDAttribute(name: "radius", value: 1.0, valueType: "double")
    ]
    
    let propellantTank = USDPrim(
        name: "PropellantTank",
        type: "Cylinder",
        attributes: tankAttributes,
        transform: USDTransform(position: Vector3D(x: 0, y: 1.5, z: 0)),
        metadata: [
            "modelDrawType": "cylinder",
            "modelDrawID": UUID().uuidString,
            "material": "aluminum",
            "wallThickness": "0.08"
        ]
    )
    
    // Create nose cone
    let noseAttributes: [String: USDAttribute] = [
        "height": USDAttribute(name: "height", value: 1.5, valueType: "double"),
        "radius": USDAttribute(name: "radius", value: 1.0, valueType: "double")
    ]
    
    let noseCone = USDPrim(
        name: "NoseCone",
        type: "Cone",
        attributes: noseAttributes,
        transform: USDTransform(position: Vector3D(x: 0, y: 4.0, z: 0)),  // Above the tank
        metadata: [
            "modelDrawType": "cone",
            "modelDrawID": UUID().uuidString,
            "material": "carbonFiber",
            "wallThickness": "0.05"
        ]
    )
    
    // Create spacecraft assembly
    let spacecraft = USDPrim(
        name: "SimpleSpacecraft",
        type: "Xform",
        transform: USDTransform(position: Vector3D.zero),
        children: [propellantTank, noseCone],
        metadata: [
            "modelDrawType": "assembly",
            "assemblyType": "spacecraft"
        ]
    )
    
    let stage = USDStage(
        defaultPrim: "SimpleSpacecraft",
        customLayerData: [
            "modelDrawType": "spacecraft",
            "createdBy": "USDFileManager Phase 1B - Spacecraft Assembly"
        ]
    )
    
    let spacecraftFile = USDFile(stage: stage, rootPrims: [spacecraft])
    
    // Write spacecraft assembly
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let spacecraftFileURL = documentsURL.appendingPathComponent("ModelDrawTest_Spacecraft.usd")
    
    do {
        try USDFileManager.shared.writeUSDFile(spacecraftFile, to: spacecraftFileURL)
        print("✅ Test spacecraft USD created at: \(spacecraftFileURL.path)")
        print("📱 Find ModelDrawTest_Spacecraft.usd and drag to RCP - should see cylinder + cone!")
        
    } catch {
        print("❌ Spacecraft test failed: \(error.localizedDescription)")
    }
}


/// Test USDFileManager with properly oriented spacecraft (90° X rotation)
func testUSDOrientedSpacecraft() {
    print("🧪 Testing USD Oriented Spacecraft (Standing Upright)...")
    
    // 90 degree rotation around X axis to make cylinders/cones stand upright
    let uprightRotation = Quaternion.from(axis: Vector3D.unitX, angle: -Double.pi/2)
    
    // Create upright propellant tank
    let tankAttributes: [String: USDAttribute] = [
        "height": USDAttribute(name: "height", value: 3.0, valueType: "double"),
        "radius": USDAttribute(name: "radius", value: 1.0, valueType: "double")
    ]
    
    let propellantTank = USDPrim(
        name: "PropellantTank",
        type: "Cylinder",
        attributes: tankAttributes,
        transform: USDTransform(position: Vector3D(x: 0, y: 1.5, z: 0), orientation: uprightRotation),
        metadata: [
            "modelDrawType": "cylinder",
            "material": "aluminum"
        ]
    )
    
    // Create upright nose cone
    let noseAttributes: [String: USDAttribute] = [
        "height": USDAttribute(name: "height", value: 1.5, valueType: "double"),
        "radius": USDAttribute(name: "radius", value: 1.0, valueType: "double")
    ]
    
    let noseCone = USDPrim(
        name: "NoseCone",
        type: "Cone",
        attributes: noseAttributes,
        transform: USDTransform(position: Vector3D(x: 0, y: 4.0, z: 0), orientation: uprightRotation),
        metadata: [
            "modelDrawType": "cone",
            "material": "carbonFiber"
        ]
    )
    
    // Create oriented spacecraft assembly
    let spacecraft = USDPrim(
        name: "OrientedSpacecraft",
        type: "Xform",
        transform: USDTransform(position: Vector3D.zero),
        children: [propellantTank, noseCone],
        metadata: [
            "modelDrawType": "assembly",
            "assemblyType": "spacecraft"
        ]
    )
    
    let stage = USDStage(
        defaultPrim: "OrientedSpacecraft",
        customLayerData: [
            "modelDrawType": "spacecraft",
            "createdBy": "USDFileManager - Properly Oriented"
        ]
    )
    
    let spacecraftFile = USDFile(stage: stage, rootPrims: [spacecraft])
    
    // Write oriented spacecraft
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let spacecraftFileURL = documentsURL.appendingPathComponent("ModelDrawTest_OrientedSpacecraft.usd")
    
    do {
        try USDFileManager.shared.writeUSDFile(spacecraftFile, to: spacecraftFileURL)
        print("✅ Oriented spacecraft USD created at: \(spacecraftFileURL.path)")
        print("📱 Drag ModelDrawTest_OrientedSpacecraft.usd to RCP - should stand upright!")
        
    } catch {
        print("❌ Oriented spacecraft test failed: \(error.localizedDescription)")
    }
}


// MARK: - Test Methods for USD Parsing

/// Test parseStageHeader method with existing USD files
/*func testParseStageHeader() {
    print("🧪 Testing parseStageHeader() method...")
    
    // Get path to Library folder where test files are stored
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let libraryURL = documentsURL.appendingPathComponent("ModelDraw").appendingPathComponent("Library")
    
    // Test files to parse
    let testFiles = [
        "ModelDrawTest_Cylinder.usd",
        "ModelDrawTest_Cone.usd",
        "ModelDrawTest_OrientedSpacecraft.usd"
    ]
    
    for fileName in testFiles {
        print("\n📄 Testing file: \(fileName)")
        let testFileURL = libraryURL.appendingPathComponent(fileName)
        
        do {
            // Read file content
            let content = try String(contentsOf: testFileURL, encoding: .utf8)
            print("✅ File read successfully")
            
            // Parse stage header
            let stage = try USDFileManager.shared.parseStageHeader(content)
            
            // Print parsed results
            print("🔍 Parsed Stage Header:")
            print("   defaultPrim: \(stage.defaultPrim ?? "nil")")
            print("   metersPerUnit: \(stage.metersPerUnit)")
            print("   upAxis: \(stage.upAxis)")
            
            if !stage.customLayerData.isEmpty {
                print("   customLayerData:")
                for (key, value) in stage.customLayerData.sorted(by: { $0.key < $1.key }) {
                    print("      \(key): \(value)")
                }
            } else {
                print("   customLayerData: (empty)")
            }
            
        } catch {
            print("❌ Failed to parse \(fileName): \(error)")
        }
    }
    
    print("\n✅ parseStageHeader() testing complete!")
} */

// MARK: - Enhanced Test with File Content Preview

/// Test parseStageHeader with detailed file content preview
/*func testParseStageHeaderWithPreview() {
    print("🧪 Testing parseStageHeader() with content preview...")
    
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let libraryURL = documentsURL.appendingPathComponent("ModelDraw").appendingPathComponent("Library")
    let testFileURL = libraryURL.appendingPathComponent("ModelDrawTest_Cylinder.usd")
    
    do {
        let content = try String(contentsOf: testFileURL, encoding: .utf8)
        
        // Show first 20 lines of file content
        print("📄 File content preview (first 20 lines):")
        let lines = content.components(separatedBy: .newlines)
        for (index, line) in lines.prefix(20).enumerated() {
            print("   \(index + 1): \(line)")
        }
        
        print("\n🔍 Parsing stage header...")
        let stage = try USDFileManager.shared.parseStageHeader(content)
        
        print("✅ Successfully parsed!")
        print("   defaultPrim: \(stage.defaultPrim ?? "nil")")
        print("   metersPerUnit: \(stage.metersPerUnit)")
        print("   upAxis: \(stage.upAxis)")
        print("   customLayerData count: \(stage.customLayerData.count)")
        
    } catch {
        print("❌ Test failed: \(error)")
    }
} */


// MARK: - Test Prim Block Extraction

/// Test the prim block extraction logic
/*func testPrimBlockExtraction() {
    print("🧪 Testing prim block extraction...")
    
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let libraryURL = documentsURL.appendingPathComponent("ModelDraw").appendingPathComponent("Library")
    
    // Test with the cylinder file first (simplest case)
    let testFileURL = libraryURL.appendingPathComponent("ModelDrawTest_Cylinder.usd")
    
    do {
        let content = try String(contentsOf: testFileURL, encoding: .utf8)
        print("✅ File read successfully")
        
        // Extract prim blocks
        let primBlocks = USDFileManager.shared.extractPrimBlocks(from: content)
        print("🔍 Found \(primBlocks.count) prim blocks")
        
        // Print each extracted block
        for (index, block) in primBlocks.enumerated() {
            print("\n📦 Prim Block \(index + 1):")
            print("─────────────────────────")
            
            // Show first few lines of each block
            let blockLines = block.components(separatedBy: .newlines)
            let previewLines = blockLines.prefix(10)
            
            for (lineNum, line) in previewLines.enumerated() {
                print("   \(lineNum + 1): \(line)")
            }
            
            if blockLines.count > 10 {
                print("   ... (\(blockLines.count - 10) more lines)")
            }
            print("─────────────────────────")
        }
        
        // Test header parsing on each block
        print("\n🔍 Testing header parsing:")
        for (index, block) in primBlocks.enumerated() {
            let lines = block.components(separatedBy: .newlines)
            if let firstLine = lines.first?.trimmingCharacters(in: .whitespaces) {
                do {
                    let (primType, primName) = try USDFileManager.shared.parsePrimHeader(firstLine)
                    print("   Block \(index + 1): \(primType) \"\(primName)\"")
                } catch {
                    print("   Block \(index + 1): ❌ Header parsing failed - \(error)")
                }
            }
        }
        
    } catch {
        print("❌ Test failed: \(error)")
    }
    
    print("\n✅ Prim block extraction test complete!")
} */

/// Test with the more complex spacecraft assembly file
/*func testComplexPrimExtraction() {
    print("🧪 Testing complex prim extraction (OrientedSpacecraft)...")
    
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let libraryURL = documentsURL.appendingPathComponent("ModelDraw").appendingPathComponent("Library")
    let testFileURL = libraryURL.appendingPathComponent("ModelDrawTest_OrientedSpacecraft.usd")
    
    do {
        let content = try String(contentsOf: testFileURL, encoding: .utf8)
        let primBlocks = USDFileManager.shared.extractPrimBlocks(from: content)
        
        print("✅ Found \(primBlocks.count) prim blocks in spacecraft assembly")
        
        for (index, block) in primBlocks.enumerated() {
            let firstLine = block.components(separatedBy: .newlines).first ?? ""
            print("   \(index + 1): \(firstLine.trimmingCharacters(in: .whitespaces))")
        }
        
    } catch {
        print("❌ Complex test failed: \(error)")
    }
} */


// MARK: - Test Full Prim Definition Parsing

/// Test complete parsing of prim definitions with all attributes and transforms
func testFullPrimParsing() {
    print("🧪 Testing complete prim definition parsing...")
    
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let libraryURL = documentsURL.appendingPathComponent("ModelDraw").appendingPathComponent("Library")
    
    // Test with cylinder file first
    let testFileURL = libraryURL.appendingPathComponent("ModelDrawTest_Cylinder.usd")
    
    do {
        let content = try String(contentsOf: testFileURL, encoding: .utf8)
        let primBlocks = USDFileManager.shared.extractPrimBlocks(from: content)
        
        print("🔍 Parsing \(primBlocks.count) prim blocks...")
        
        for (index, block) in primBlocks.enumerated() {
            print("\n📦 Prim \(index + 1):")
            print("─────────────────────")
            
            do {
                let prim = try USDFileManager.shared.parsePrimDefinition(block)
                
                // Print basic info
                print("   Name: \(prim.name)")
                print("   Type: \(prim.type)")
                
                // Print attributes
                if !prim.attributes.isEmpty {
                    print("   Attributes:")
                    for (key, attribute) in prim.attributes.sorted(by: { $0.key < $1.key }) {
                        print("      \(key): \(attribute.value) (\(attribute.valueType))")
                    }
                } else {
                    print("   Attributes: (none)")
                }
                
                // Print transform
                if let transform = prim.transform {
                    print("   Transform:")
                    print("      Position: (\(transform.position.x), \(transform.position.y), \(transform.position.z))")
                    print("      Orientation: (\(transform.orientation.w), \(transform.orientation.x), \(transform.orientation.y), \(transform.orientation.z))")
                } else {
                    print("   Transform: (none)")
                }
                
                // Print metadata
                if !prim.metadata.isEmpty {
                    print("   Metadata:")
                    for (key, value) in prim.metadata.sorted(by: { $0.key < $1.key }) {
                        print("      \(key): \(value)")
                    }
                } else {
                    print("   Metadata: (none)")
                }
                
                // Print children
                print("   Children: \(prim.children.count)")
                
            } catch {
                print("   ❌ Failed to parse prim: \(error)")
                
                // Show the block content for debugging
                print("   Block content:")
                let blockLines = block.components(separatedBy: .newlines)
                for (lineNum, line) in blockLines.enumerated() {
                    print("      \(lineNum + 1): \(line)")
                }
            }
            
            print("─────────────────────")
        }
        
    } catch {
        print("❌ Test setup failed: \(error)")
    }
    
    print("\n✅ Full prim parsing test complete!")
}

/// Test parsing with the complex spacecraft assembly
func testSpacecraftAssemblyParsing() {
    print("🧪 Testing spacecraft assembly parsing...")
    
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let libraryURL = documentsURL.appendingPathComponent("ModelDraw").appendingPathComponent("Library")
    let testFileURL = libraryURL.appendingPathComponent("ModelDrawTest_OrientedSpacecraft.usd")
    
    do {
        let content = try String(contentsOf: testFileURL, encoding: .utf8)
        let primBlocks = USDFileManager.shared.extractPrimBlocks(from: content)
        
        print("🚀 Found \(primBlocks.count) prims in spacecraft assembly:")
        
        for (index, block) in primBlocks.enumerated() {
            do {
                let prim = try USDFileManager.shared.parsePrimDefinition(block)
                print("   \(index + 1). \(prim.type) \"\(prim.name)\"")
                print("       Attributes: \(prim.attributes.count)")
                print("       Transform: \(prim.transform != nil ? "✅" : "❌")")
                print("       Metadata: \(prim.metadata.count)")
                
                // Show transform details if present
                if let transform = prim.transform {
                    let pos = transform.position
                    let rot = transform.orientation
                    print("       Position: (\(String(format: "%.2f", pos.x)), \(String(format: "%.2f", pos.y)), \(String(format: "%.2f", pos.z)))")
                    print("       Rotation: (\(String(format: "%.3f", rot.w)), \(String(format: "%.3f", rot.x)), \(String(format: "%.3f", rot.y)), \(String(format: "%.3f", rot.z)))")
                }
                
            } catch {
                print("   \(index + 1). ❌ Parse failed: \(error)")
            }
        }
        
    } catch {
        print("❌ Spacecraft test failed: \(error)")
    }
}


/// Test method using the debug version
func testAttributeParsingDebug() {
    print("🧪 Testing attribute parsing with debug output...")
    
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let libraryURL = documentsURL.appendingPathComponent("ModelDraw").appendingPathComponent("Library")
    let testFileURL = libraryURL.appendingPathComponent("ModelDrawTest_Cylinder.usd")
    
    do {
        let content = try String(contentsOf: testFileURL, encoding: .utf8)
        let primBlocks = USDFileManager.shared.extractPrimBlocks(from: content)
        
        if let firstBlock = primBlocks.first {
            print("📄 First prim block content:")
            let blockLines = firstBlock.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            for (index, line) in blockLines.enumerated() {
                print("   \(index + 1): \(line)")
            }
            
            print("\n🔍 Now testing attribute parsing:")
            let _ = try USDFileManager.shared.debugParseAttributes(from: blockLines)
        }
        
    } catch {
        print("❌ Debug test failed: \(error)")
    }
}
