//
//  CenterRealityView.swift - Updated for ViewModel-Driven Architecture
//  ModelDraw
//

import SwiftUI
import RealityKit

// MARK: - Center RealityKit View
struct CenterRealityView: View {
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        RealityView { content in
            // Create the 3D scene
            let scene = createScene(assemblies: model.assemblies)
            content.add(scene)
            
        } update: { content in
            // Handle updates when project changes
            content.entities.removeAll()
            let scene = createScene(assemblies: model.assemblies)
            content.add(scene)
        }
        .gesture(
            // Add basic orbit camera controls
            DragGesture()
                .onChanged { value in
                    let deltaX = Float(value.translation.width * 0.01)
                    let deltaY = Float(value.translation.height * 0.01)
                    model.rotateCamera(deltaX: deltaX, deltaY: deltaY)
                }
        )
        .onAppear {
            //print("🌍 RealityKit view appeared with \(model.primitives.count) primitives")
        }
    }
}

// MARK: - RealityKit Scene Creation

func createScene(assemblies: [Assembly]) -> Entity {
    let rootEntity = Entity()
    
    // Add your primitives, but scaled down and positioned properly
    var yOffset: Float = -1.0  // Start below the red box
    
    for assembly in assemblies {
        let entity = createPrimitiveEntity(assembly: assembly)
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
    
    // Add basic lighting
    let lightEntity = Entity()
    lightEntity.components.set(DirectionalLightComponent(
        color: .white,
        intensity: 1000
    ))
    lightEntity.orientation = simd_quatf(angle: -Float.pi/4, axis: SIMD3(1, 1, 0))
    rootEntity.addChild(lightEntity)
    
    print("🔧 Created minimal test scene with red box at origin")
    print("🔧 Scene contains \(assemblies.count) assemblies")
    
    return rootEntity
}

func createPrimitiveEntity(assembly: Assembly) -> Entity {
    let entity = Entity()
    

    
    return entity
}
