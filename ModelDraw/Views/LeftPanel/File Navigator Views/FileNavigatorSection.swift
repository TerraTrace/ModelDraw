//
//  FileNavigatorSection.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/18/25.
//

import SwiftUI


struct FileNavigatorSection: View {
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // File Navigator Header
            FileNavigatorHeaderView()
            
            // File Navigator Content - RESTORED OutlineGroup
            List {
                OutlineGroup(model.navigatorData, children: \.children) { item in
                    NavigatorRowView(item: item)
                }
            }
            .listStyle(.sidebar)  // This gives proper macOS sidebar styling
        }
        .frame(minHeight: 300) // Minimum height for file section
    }
}

