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
    
    // 2. Get desktop URL for easy access
    let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
    let testFileURL = desktopURL.appendingPathComponent("ModelDrawTest_Cylinder.usd")
    
    // 3. Write USD file
    do {
        try USDFileManager.shared.writeUSDFile(testCylinder, to: testFileURL)
        print("✅ Test cylinder USD created at: \(testFileURL.path)")
        print("📱 Next: Drag this file into Reality Composer Pro to validate!")
        
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
    
    // Write assembly file
    let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
    let assemblyFileURL = desktopURL.appendingPathComponent("ModelDrawTest_Assembly.usd")
    
    do {
        try USDFileManager.shared.writeUSDFile(assemblyFile, to: assemblyFileURL)
        print("✅ Test assembly USD created at: \(assemblyFileURL.path)")
        print("📱 Drag this assembly into Reality Composer Pro!")
        
    } catch {
        print("❌ Assembly test failed: \(error.localizedDescription)")
    }
}
