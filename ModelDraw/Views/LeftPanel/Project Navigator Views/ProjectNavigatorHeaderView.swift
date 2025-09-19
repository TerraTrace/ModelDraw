//
//  ProjectNavigatorHeaderView.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/18/25.
//

import SwiftUI


// MARK: - Project Navigator Header
struct ProjectNavigatorHeaderView: View {
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        HStack {
            if let activeProject = getActiveProjectName() {
                Text("\(activeProject)")
                    .font(.headline)
                    .fontWeight(.medium)
            } else {
                Text("Project Navigator")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor))
    }
    
    // Helper to get the active project name
    private func getActiveProjectName() -> String? {
        return UserDefaults.standard.string(forKey: "ModelDraw_LastActiveProject")
    }
}
