// File: RightPanelView.swift
//
//  RightPanelView.swift
//  ModelDraw - Split right panel with Properties (top) and Tools (bottom)
//

import SwiftUI

struct RightPanelView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top Section - Properties
            PropertiesSection()
            
            // Divider between sections
            Divider()
            
            // Bottom Section - Tools
            ToolsSection()
        }
        .background(Color(.textBackgroundColor).opacity(0.5))
    }
}

