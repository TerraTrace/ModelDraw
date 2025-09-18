// File: ToolGroupView.swift
//
//  ToolGroupView.swift
//  ModelDraw
//

import SwiftUI

struct ToolGroupView: View {
    let groupName: String
    let tools: [(String, String, Bool)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Group header
            Text(groupName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            // Tool buttons in a grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(tools, id: \.0) { tool in
                    ToolButtonView(name: tool.0, icon: tool.1, isActive: tool.2)
                }
            }
        }
        .padding(.bottom, 16)
    }
}
