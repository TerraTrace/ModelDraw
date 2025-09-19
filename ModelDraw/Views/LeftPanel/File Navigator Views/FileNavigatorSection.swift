//
//  FileNavigatorSection.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/18/25.
//

import SwiftUI


// MARK: - File Navigator Section (Bottom)
struct FileNavigatorSection: View {
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // File Navigator Header
            FileNavigatorHeaderView()
            
            // File Navigator Content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(model.navigatorData, id: \.id) { item in
                        FileNavigatorItemView(item: item, level: 0)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minHeight: 300) // Minimum height for file section
    }
}


