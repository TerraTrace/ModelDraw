//
//  LoadedUSDItem.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/17/25.
//

import SwiftUI
import Foundation
import RealityKit


// MARK: - Future USD Loading Support
struct LoadedUSDItem: Identifiable {
    let id = UUID()
    let sourceURL: URL
    let name: String
    let entity: Entity
    var position: SIMD3<Float>?
    
    init(sourceURL: URL, entity: Entity, position: SIMD3<Float>) {
        self.sourceURL = sourceURL
        self.name = sourceURL.deletingPathExtension().lastPathComponent
        self.entity = entity
        self.position = position
    }
}
