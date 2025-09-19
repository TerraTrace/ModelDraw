//
//  LeftPaletteView.swift
//  ModelDraw - Updated for OutlineGroup file system navigator
//

import SwiftUI

struct LeftPaletteView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top Section - Project Navigator
            ProjectNavigatorSection()
            
            // Divider between sections
            Divider()
            
            // Bottom Section - File Navigator
            FileNavigatorSection()
        }
        .background(Color(.textBackgroundColor).opacity(0.5))
    }
}
