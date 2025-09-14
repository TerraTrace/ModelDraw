//
//  ContentView.swift - Updated with Assembly Display
//  ModelDraw
//

import SwiftUI

struct ContentView: View {
    @Binding var document: ModelDrawDocument
    
    var body: some View {
        HSplitView {
            // Left Palette - Assembly Information
            LeftPaletteView(assemblies: document.assemblies, primitives: document.primitives)
                .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
            
            // Center - RealityKit 3D View
            CenterRealityView(
                primitives: document.primitives,
                assemblies: document.assemblies
            )
            .frame(minWidth: 400)
            
            // Right Palette - Primitive Details
            RightPaletteView(primitives: document.primitives)
                .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
        }
    }
}
