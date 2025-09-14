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
    
    // Add some test content
    var yOffset: Float = 0.0
    
    for primitive in primitives {
        let entity = createPrimitiveEntity(primitive: primitive)
        entity.position = SIMD3<Float>(0, yOffset, 0)
        rootEntity.addChild(entity)
        yOffset += 2.0  // Space them out vertically for now
    }
    
    // Add basic lighting
    let lightEntity = Entity()
    lightEntity.components.set(DirectionalLightComponent(
        color: .white,
        intensity: 1000
    ))
    lightEntity.orientation = simd_quatf(angle: -Float.pi/4, axis: SIMD3(1, 1, 0))
    rootEntity.addChild(lightEntity)
    
    print("🔧 Created scene with \(primitives.count) primitives")
    return rootEntity
}

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
    
    return entity
}
