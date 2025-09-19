//
//  ProjectNavigatorEmptyView.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/18/25.
//

import SwiftUI


// MARK: - Project Navigator Empty View
struct ProjectNavigatorEmptyView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "cube.transparent")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("No objects loaded")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}
