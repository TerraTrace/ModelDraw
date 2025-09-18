// File: ToolsSection.swift
//
//  ToolsSection.swift
//  ModelDraw
//

import SwiftUI

struct ToolsSection: View {
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tools Header
            ToolsHeaderView()
            
            // Tools Content
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ToolGroupView(
                        groupName: "Navigation",
                        tools: [
                            ("Select", "cursorarrow.click", true),
                            ("Pan", "hand.draw", false),
                            ("Orbit", "arrow.triangle.2.circlepath", false),
                            ("Zoom", "plus.magnifyingglass", false)
                        ]
                    )
                    
                    ToolGroupView(
                        groupName: "Placement",
                        tools: [
                            ("Place", "plus", model.isPlacementMode),
                            ("Move", "arrow.up.and.down.and.arrow.left.and.right", false),
                            ("Rotate", "arrow.clockwise", false),
                            ("Scale", "arrow.up.left.and.down.right.magnifyingglass", false)
                        ]
                    )
                    
                    ToolGroupView(
                        groupName: "Drawing",
                        tools: [
                            ("Line", "line.diagonal", false),
                            ("Circle", "circle", false),
                            ("Rectangle", "rectangle", false),
                            ("Extrude", "cube", false)
                        ]
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minHeight: 300) // Minimum height for tools section
    }
}
