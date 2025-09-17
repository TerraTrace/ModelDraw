//
//  LeftPaletteView.swift - Updated for OutlineGroup with Direct UUID Mapping
//  ModelDraw
//

import SwiftUI

struct LeftPaletteView: View {
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with project info
            VStack(alignment: .leading, spacing: 4) {
                Text("Projects")
                    .font(.headline)
                Text(model.projectName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
        }
    }
}
