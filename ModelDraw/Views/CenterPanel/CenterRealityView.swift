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

    /// Primary perspective camera for mode-aware navigation
    @State private var camera: PerspectiveCamera = PerspectiveCamera()

    
    var body: some View {
        RealityView { content in
            content.camera = .virtual
            content.add(camera)

            // Create and add the engineering grid immediately
            let grid = createEngineeringGrid()
            content.add(grid)
            
            print("🎯 CenterRealityView: Engineering grid added to scene")
        } update: { content in
            // Enhanced camera update - routes based on camera MODE, not shift state
            switch model.cameraMode {
            case .sceneCenter:
                // Scene center mode: Always use camera.look() to look at origin
                // (Pivot gestures in scene center mode are temporary - camera snaps back)
                camera.look(at: .zero, from: model.cameraPosition, relativeTo: nil)
                //print("🎯 Camera update: SceneCenter mode - looking at origin")
                
            case .freeFlier:
                // FreeFlier mode: Always apply position and rotation directly
                camera.position = model.cameraPosition
                camera.orientation = model.cameraRotation
                //print("🎯 Camera update: FreeFlier mode - pos=\(model.cameraPosition)")
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
                                cameraController.handleSimpleOrbitGesture(translation: value.translation)
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
                        cameraController.handleZoomGesture(zoomFactor: Float(value))
                    }
            )
        )
        // Add this to CenterRealityView after your existing .gesture() modifier
        // This handles single USD file drops only

        /*.dropDestination(for: URL.self) { urls, location in
            // Get the first URL only (simplified approach)
            guard let firstUrl = urls.first else { return false }
            
            // Handle different types of drops
            if firstUrl.hasDirectoryPath {
                print("📁 Folder drop not yet implemented: \(firstUrl.lastPathComponent)")
                return false
            }
            
            // Check if it's a USD file
            guard firstUrl.pathExtension.lowercased() == "usd" else {
                print("⚠️ Only USD files supported: \(firstUrl.lastPathComponent)")
                return false
            }
            
            // Get view size for ray casting (you'll need to capture this properly)
            let viewSize = CGSize(width: 800, height: 600) // TODO: Use actual view size
            
            // Use ray casting to get world position
            let worldPosition = cameraController.worldPositionFromCursor(location, viewSize: viewSize)
            
            print("🎯 Dropping USD file: \(firstUrl.lastPathComponent) at position: \(worldPosition)")
            
            // Load USD file asynchronously
            Task {
                do {
                    if let entity = await drawingManager.loadUSDFile(at: firstUrl, position: worldPosition) {
                        await MainActor.run {
                            content.add(entity)
                            print("✅ USD entity added to scene")
                        }
                    } else {
                        print("❌ Failed to load USD file")
                    }
                } catch {
                    print("❌ Error loading USD file: \(error)")
                }
            }
            
            return true // Accept the drop
        } isTargeted: { isTargeted in
            if isTargeted {
                print("🎯 Drop target active - ready for USD file")
            }
        } */
        .onAppear {
            print("🎯 SolarSystemView.onAppear called")
            cameraController.viewModel = model
            cameraController.configure(for: model.cameraConfiguration)
        }
        .onChange(of: model.cameraConfiguration) { _, newConfiguration in
            cameraController.configure(for: newConfiguration)
        }

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
