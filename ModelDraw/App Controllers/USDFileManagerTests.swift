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
func testParseStageHeader() {
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
}

// MARK: - Enhanced Test with File Content Preview

/// Test parseStageHeader with detailed file content preview
func testParseStageHeaderWithPreview() {
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
}
