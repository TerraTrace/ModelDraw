//
//  CenterRealityView.swift - Updated for ViewModel-Driven Architecture
//  ModelDraw
//

import SwiftUI
import RealityKit

// MARK: - Center RealityKit View
struct CenterRealityView: View {
    @Environment(ViewModel.self) private var model
    @State private var cameraController = CameraController()
    private let drawingManager = DrawingManager.shared

    @State private var camera: PerspectiveCamera = PerspectiveCamera()
    @State private var mousePosition: CGPoint = .zero
    @State private var isMouseInCanvas: Bool = false
    @State private var realityViewSize: CGSize = .zero

    
    var body: some View {
        RealityView { content in
            content.camera = .virtual
            content.add(camera)
            cameraController.primaryCamera? = camera
            
            camera.look(at: .zero, from: model.cameraPosition, relativeTo: nil)
            
            if model.hasNewEntities {
                let newEntities = model.getNewEntitiesForScene()
                for entity in newEntities {
                    content.add(entity)
                    print("🎯 CenterRealityView: Added entity '\(entity.name)' to scene")
                }
            }

            // Create and add the engineering grid immediately
            let grid = createEngineeringGrid()
            content.add(grid)
            
            print("🎯 CenterRealityView: Engineering grid added to scene")
        } update: { content in }  // trying to keep .update empty if possible
        .overlay {
            // Cursor circle overlay for placement mode
            if model.isPlacementMode && isMouseInCanvas {
                Circle()
                    .stroke(Color.blue, lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                    .position(mousePosition)
                    .allowsHitTesting(false) // Let clicks pass through to RealityView
            }
        }
        /*.onContinuousHover { phase in
            switch phase {
            case .active(let location):
                mousePosition = location
                isMouseInCanvas = true
            case .ended:
                isMouseInCanvas = false
            }
        } */
        .onTapGesture { location in
            if model.isPlacementMode {
                let worldPosition = cameraController.worldPositionFromCursor(location, viewSize: realityViewSize)
                model.placeItemAtLocation(worldPosition)
            }
        }
        .gesture(
            SimultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        // Route gesture based on current camera mode
                        switch model.cameraMode {
                        case .sceneCenter:
                            // Scene center mode: orbit vs pivot based on shift
                            if model.shiftPressed {
                                print("🎯 SceneCenter + Shift: pivot gesture")
                                cameraController.handleCameraPivotGesture(translation: value.translation)
                            } else {
                                print("🎯 SceneCenter: orbit gesture")
                                cameraController.handleSimpleOrbitGesture(translation: value.translation, camera: camera)
                            }
                            
                        case .freeFlier:
                            // FreeFlier mode: translate vs pivot based on shift
                            if model.shiftPressed {
                                print("🎯 FreeFlier + Shift: pivot gesture")
                                cameraController.handleFreeFlierTranslateGesture(translation: value.translation)
                            } else {
                                print("🎯 FreeFlier: translate gesture")
                                cameraController.handleCameraPivotGesture(translation: value.translation)
                            }
                        }
                    },
                MagnificationGesture()
                    .onChanged { value in
                        cameraController.handleZoomGesture(zoomFactor: Float(value), camera: camera)
                    }
            )
        )
        // Add this to CenterRealityView after your existing .gesture() modifier
        // This handles single USD file drops only

        // Replace the incomplete .dropDestination in CenterRealityView with this:

        // Replace the incomplete .dropDestination in CenterRealityView with this:

        .onAppear {
            print("🎯 SolarSystemView.onAppear called")
            cameraController.viewModel = model
            cameraController.configure(for: model.cameraConfiguration)
        }
        .onChange(of: model.cameraConfiguration) { _, newConfiguration in
            cameraController.configure(for: newConfiguration)
        }
        .background(
            // Use a clear color with GeometryReader to get the dimensions
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        realityViewSize = proxy.size
                        print("RealityView size: \(realityViewSize)")
                    }
                    .onChange(of: proxy.size) { newSize in
                        realityViewSize = newSize
                        print("RealityView size changed to: \(newSize)")
                    }
            }
        )
        //.frame(maxWidth: .infinity, maxHeight: .infinity)
        
    }
    
}

// MARK: - RealityKit Scene Creation

extension CenterRealityView {
    
    /// Create a 20m x 20m engineering grid with 1m spacing using thin cylinder entities
    /// Returns a single parent Entity containing all grid lines for easy management
    /// FIXED: Proper cylinder rotations to ensure all lines lie flat on X-Z plane at Y=0
    private func createEngineeringGrid() -> Entity {
        let gridContainer = Entity()
        gridContainer.name = "EngineeringGrid"
        
        // Grid parameters
        let gridSize: Float = 20.0  // 20m x 20m total
        let spacing: Float = 1.0    // 1m spacing
        let lineRadius: Float = 0.005  // Very thin lines (5mm radius)
        let lineLength = gridSize
        let numLines = Int(gridSize / spacing) + 1  // 21 lines (0 to 20m, every 1m)
        
        // Create material for grid lines
        var material = PhysicallyBasedMaterial()
        material.baseColor = PhysicallyBasedMaterial.BaseColor(tint: .gray.withAlphaComponent(0.3))
        material.blending = .transparent(opacity: 0.3)
        
        print("🔲 Creating engineering grid: \(numLines)x\(numLines) lines with \(spacing)m spacing")
        
        // Create X-direction lines (running east-west, parallel to X-axis)
        for i in 0..<numLines {
            let zPosition = -gridSize/2 + Float(i) * spacing  // -10m to +10m
            
            let cylinder = MeshResource.generateCylinder(height: lineLength, radius: lineRadius)
            let lineEntity = ModelEntity(mesh: cylinder, materials: [material])
            lineEntity.name = "GridLine_X_\(i)"
            
            // Position line: center at origin, extend along X-axis
            lineEntity.transform.translation = SIMD3<Float>(0, 0, zPosition)
            
            // FIXED: Rotate cylinder from Y-axis to X-axis, lying flat on X-Z plane
            // 90° rotation around Z-axis puts cylinder along X-axis
            lineEntity.transform.rotation = simd_quatf(angle: Float.pi/2, axis: [0, 0, 1])
            
            gridContainer.addChild(lineEntity)
        }
        
        // Create Z-direction lines (running north-south, parallel to Z-axis)
        for i in 0..<numLines {
            let xPosition = -gridSize/2 + Float(i) * spacing  // -10m to +10m
            
            let cylinder = MeshResource.generateCylinder(height: lineLength, radius: lineRadius)
            let lineEntity = ModelEntity(mesh: cylinder, materials: [material])
            lineEntity.name = "GridLine_Z_\(i)"
            
            // Position line: center at origin, extend along Z-axis
            lineEntity.transform.translation = SIMD3<Float>(xPosition, 0, 0)
            
            // FIXED: Rotate cylinder from Y-axis to Z-axis, lying flat on X-Z plane
            // 90° rotation around X-axis puts cylinder along Z-axis
            lineEntity.transform.rotation = simd_quatf(angle: Float.pi/2, axis: [1, 0, 0])
            
            gridContainer.addChild(lineEntity)
        }
        
        print("✅ Engineering grid created: \(numLines * 2) total lines, all lying flat on X-Z plane at Y=0")
        return gridContainer
    }
    
    
}
