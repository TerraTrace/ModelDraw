//
//  ContentView.swift - Updated for ViewModel-Driven Architecture
//  ModelDraw
//

import SwiftUI

struct ContentView: View {
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        Group {
            if let _ = model.currentProject {
                // Main project view
                HSplitView {
                    // Left Palette - Project Navigator
                    LeftPaletteView()
                        .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
                    
                    // Center - RealityKit 3D View
                    CenterRealityView()
                        .frame(minWidth: 400)
                    
                    // Right Palette - Properties
                    RightPaletteView()
                        .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
                }
            } else if model.isLoadingProjects {
                // Loading state
                VStack {
                    ProgressView()
                    Text("Loading projects...")
                        .foregroundColor(.secondary)
                }
            } else if let error = model.projectError {
                // Error state
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Error Loading Projects")
                        .font(.headline)
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        model.refreshProjects()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                // Project selection view
                ProjectSelectionView()
            }
        }
        .onAppear {
            model.loadAvailableProjects()
        }
    }
}

// MARK: - Project Selection View
struct ProjectSelectionView: View {
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select Project")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if model.availableProjects.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No projects found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Create a project in ~/Documents/ModelDraw/Projects/")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Refresh") {
                        model.refreshProjects()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List(model.availableProjects, id: \.name) { project in
                    ProjectRowView(project: project)
                }
                .listStyle(.plain)
                .frame(maxWidth: 600, maxHeight: 400)
            }
        }
        .padding()
    }
}

// MARK: - Project Row View
struct ProjectRowView: View {
    @Environment(ViewModel.self) private var model
    let project: ProjectInfo
    
    var body: some View {
        Button(action: {
            model.loadProject(project)
        }) {
            HStack {
                Image(systemName: "folder")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Modified: \(project.lastModified, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 8)
    }
}
