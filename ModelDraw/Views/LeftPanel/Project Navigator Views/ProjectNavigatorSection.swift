//
//  ProjectNavigatorSection.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/18/25.
//

import SwiftUI

// MARK: - Project Navigator Section (Top)
struct ProjectNavigatorSection: View {
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Project Navigator Header
            ProjectNavigatorHeaderView()
            
            // Project Content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    if model.loadedUSDItems.isEmpty {
                        ProjectNavigatorEmptyView()
                    } else {
                        ForEach(model.loadedUSDItems) { item in
                            ProjectNavigatorRowView(
                                item: item,
                                isSelected: model.selectedSceneEntityID == item.id,
                                onTap: {
                                    model.selectSceneEntity(item.id)
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(minHeight: 200) // Minimum height for project section
    }
}
