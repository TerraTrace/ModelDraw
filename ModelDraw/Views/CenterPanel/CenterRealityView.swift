//
//  CenterRealityView.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/14/25.
//

import SwiftUI
import RealityKit


// MARK: - Center RealityKit View
struct CenterRealityView: View {
    @Environment(ViewModel.self) private var model
    let primitives: [GeometricPrimitive]
    let assemblies: [Assembly]
    
    var body: some View {
        RealityView { content in
            // Create the 3D scene
            let scene = createScene(primitives: primitives, assemblies: assemblies)
            content.add(scene)
            
        } update: { content in
            // Handle updates when document changes
            // For now, we'll rebuild the scene
            content.entities.removeAll()
            let scene = createScene(primitives: primitives, assemblies: assemblies)
            content.add(scene)
        }
        .gesture(
            // Add basic orbit camera controls
            DragGesture()
                .onChanged { value in
                    // TODO: Implement orbit rotation
                }
        )
        .onAppear {
            print("🌍 RealityKit view appeared")
        }
    }
}

// MARK: - RealityKit Scene Creation

func createScene(primitives: [GeometricPrimitive], assemblies: [Assembly]) -> Entity {
    let rootEntity = Entity()
    
    // Add your primitives, but scaled down and positioned properly
    var yOffset: Float = -1.0  // Start below the red box
    
    for primitive in primitives {
        let entity = createPrimitiveEntity(primitive: primitive)
        // Scale them down so they're not huge
        entity.scale = SIMD3<Float>(0.3, 0.3, 0.3)  // Make them 30% of original size
        entity.position = SIMD3<Float>(0, yOffset, 0)
        rootEntity.addChild(entity)
        yOffset -= 1.5  // Stack them going down
    }
    
    // Create the simplest possible test - a small red box at origin
    let testEntity = Entity()
    let mesh = MeshResource.generateBox(size: 0.5)  // Small box
    let material = SimpleMaterial(color: .red, roughness: 1.0, isMetallic: false)
    testEntity.components.set(ModelComponent(mesh: mesh, materials: [material]))
    testEntity.position = SIMD3<Float>(0, 0, 0)
    rootEntity.addChild(testEntity)
    
    print("🔧 Created minimal test scene with red box at origin")
    print("🔧 Box bounds: \(testEntity.visualBounds(relativeTo: nil))")
    
    return rootEntity
}

/*func createScene(primitives: [GeometricPrimitive], assemblies: [Assembly]) -> Entity {
    let rootEntity = Entity()
    
    // Add some test content
    var yOffset: Float = 0.0
    
    // Add after creating rootEntity but before adding primitives
    /*let cameraEntity = Entity()
    cameraEntity.position = SIMD3<Float>(4, 0, 0)  // Pull back and up
    cameraEntity.look(at: SIMD3<Float>(0, 1, 0), from: cameraEntity.position, relativeTo: nil)
    rootEntity.addChild(cameraEntity) */

    
    for primitive in primitives {
        let entity = createPrimitiveEntity(primitive: primitive)
        entity.position = SIMD3<Float>(0, yOffset, 0)
        rootEntity.addChild(entity)
        yOffset += 2.0  // Space them out vertically for now
    }
    
    // Add this test entity to the scene
    let testBox = Entity()
    let testMesh = MeshResource.generateBox(size: 1.0)
    let testMaterial = SimpleMaterial(color: .red, isMetallic: false)
    testBox.components.set(ModelComponent(mesh: testMesh, materials: [testMaterial]))
    //testBox.position = SIMD3<Float>(0, 0, -5) // Place it in front of camera
    testBox.position = SIMD3<Float>(0, 0, 0) // Place it in front of camera
    rootEntity.addChild(testBox)
    print("🔧 Added test red box at (0,0,-5)")
    
    // Add basic lighting
    let lightEntity = Entity()
    lightEntity.components.set(DirectionalLightComponent(
        color: .white,
        intensity: 1000
    ))
    lightEntity.orientation = simd_quatf(angle: -Float.pi/4, axis: SIMD3(1, 1, 0))
    rootEntity.addChild(lightEntity)
    
    // Add after creating the scene
    print("🔧 Created scene with \(primitives.count) primitives")
    print("🔧 Scene bounds: \(rootEntity.visualBounds(relativeTo: nil))")

    return rootEntity
} */

func createPrimitiveEntity(primitive: GeometricPrimitive) -> Entity {
    let entity = Entity()
    
    switch primitive {
    case let cylinder as Cylinder:
        let mesh = MeshResource.generateCylinder(
            height: Float(cylinder.height),
            radius: Float(cylinder.radius)
        )
        let material = SimpleMaterial(color: .blue, isMetallic: false)
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))
        
    case let cone as Cone:
        // For now, use a simple cylinder - we'll create proper cone geometry later
        let mesh = MeshResource.generateCylinder(
            height: Float(cone.height),
            radius: Float(cone.baseRadius)
        )
        let material = SimpleMaterial(color: .orange, isMetallic: false)
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))
        
    default:
        print("⚠️ Unknown primitive type: \(type(of: primitive))")
    }
    
    // And in createPrimitiveEntity, add:
    print("🔧 Creating \(primitive.primitiveType) at default position")
    print("🔧 Entity bounds: \(entity.visualBounds(relativeTo: nil))")

    return entity
}
