//
//  ViewModel.swift - Updated for Project-Based Architecture
//  ModelDraw
//

import SwiftUI
import RealityKit

@Observable
class ViewModel {
    
    // MARK: - Project Data
    var availableProjects: [ProjectInfo] = []
    var currentProject: ProjectData?
    var isLoadingProjects = false
    var projectError: String?
    
    // MARK: - Selection State
    var selectedItem: SelectedItem?
    
    // MARK: - UI State
    var isProjectExpanded = true
    var expandedConfigurations: Set<String> = []
    var expandedAssemblies: Set<UUID> = []
    
    // MARK: - 3D View State
    var cameraPosition = SIMD3<Float>(0, 0, 5)
    var cameraRotation = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
    
    // MARK: - Convenience Properties
    var assemblies: [Assembly] {
        currentProject?.assemblies ?? []
    }
    
    var primitives: [GeometricPrimitive] {
        currentProject?.primitives ?? []
    }
    
    var projectName: String {
        currentProject?.metadata.name ?? "No Project"
    }
    
    var configurations: [String] {
        currentProject?.configurations ?? []
    }
    
    // MARK: - Project Management Methods
    func loadAvailableProjects() {
        isLoadingProjects = true
        projectError = nil
        
        do {
            availableProjects = try DrawingManager.shared.scanProjectsDirectory()
            print("📁 ViewModel: Loaded \(availableProjects.count) available projects")
            
            // Auto-load first project if available and no current project
            if currentProject == nil, let firstProject = availableProjects.first {
                loadProject(firstProject)
            }
        } catch {
            projectError = "Failed to scan projects: \(error.localizedDescription)"
            print("❌ ViewModel: Failed to scan projects: \(error)")
        }
        
        isLoadingProjects = false
    }
    
    func loadProject(_ projectInfo: ProjectInfo) {
        isLoadingProjects = true
        projectError = nil
        
        do {
            currentProject = try DrawingManager.shared.loadProject(from: projectInfo)
            print("✅ ViewModel: Loaded project '\(projectInfo.name)'")
            
            // Auto-select first assembly
            if let firstAssembly = assemblies.first {
                selectItem(.assembly(firstAssembly.id))
            } else {
                selectedItem = nil
            }
        } catch {
            projectError = "Failed to load project '\(projectInfo.name)': \(error.localizedDescription)"
            print("❌ ViewModel: Failed to load project: \(error)")
        }
        
        isLoadingProjects = false
    }
    
    func refreshProjects() {
        loadAvailableProjects()
    }
    
    // MARK: - Selection Methods
    func selectItem(_ item: SelectedItem?) {
        selectedItem = item
        print("ViewModel: Selected \(item?.description ?? "nothing")")
    }
    
    func clearSelection() {
        selectedItem = nil
    }
    
    // MARK: - 3D View Methods
    func rotateCamera(deltaX: Float, deltaY: Float) {
        let rotationX = simd_quatf(angle: deltaY * 0.01, axis: SIMD3<Float>(1, 0, 0))
        let rotationY = simd_quatf(angle: deltaX * 0.01, axis: SIMD3<Float>(0, 1, 0))
        cameraRotation = rotationY * cameraRotation * rotationX
    }
    
    func zoomCamera(delta: Float) {
        let forward = simd_act(cameraRotation, SIMD3<Float>(0, 0, -1))
        cameraPosition += forward * delta * 0.1
    }
    
    func resetCamera() {
        cameraPosition = SIMD3<Float>(0, 0, 5)
        cameraRotation = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
    }
    
    // MARK: - Data Access Helpers
    func assembly(withId id: UUID) -> Assembly? {
        assemblies.first { $0.id == id }
    }
    
    func primitive(withId id: UUID) -> GeometricPrimitive? {
        primitives.first { $0.id == id }
    }
    
    func primitivesIn(assembly: Assembly) -> [GeometricPrimitive] {
        assembly.children.compactMap { child in
            if case .primitive(let id) = child {
                return primitive(withId: id)
            }
            return nil
        }
    }
}

