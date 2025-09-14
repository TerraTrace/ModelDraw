//
//  ViewModel.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/12/25.
//
/// The data that the app uses to configure its views.



import SwiftUI
import RealityKit


@Observable
class ViewModel {
    
    // MARK: - Selection State
    var selectedItem: SelectedItem?
    
    // MARK: - 3D Scene State
    var cameraPosition: SIMD3<Float> = SIMD3<Float>(0, 2, 8)
    var cameraRotation: simd_quatf = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
    
    // MARK: - UI State
    var showRedTestBox: Bool = true  // For debugging 3D scene
    
    // MARK: - Methods
    func selectItem(_ item: SelectedItem?) {
        selectedItem = item
    }
    
    func rotateCamera(deltaX: Float, deltaY: Float) {
        let sensitivity: Float = 0.01
        cameraRotation = cameraRotation * simd_quatf(angle: -deltaX * sensitivity, axis: SIMD3(0, 1, 0))
        cameraRotation = cameraRotation * simd_quatf(angle: deltaY * sensitivity, axis: SIMD3(1, 0, 0))
    }
    
}
