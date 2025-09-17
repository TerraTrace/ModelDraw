//
//  ContentView.swift
//  ModelDraw - Clean three-pane layout for file system navigation
//

import SwiftUI

struct ContentView: View {
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        HSplitView {
            // Left Panel - File System Navigator
            LeftPaletteView()
                .frame(minWidth: 220, idealWidth: 280, maxWidth: 350)
            
            // Center Panel - 3D View (placeholder for now)
            CenterView()
                .frame(minWidth: 400)
            
            // Right Panel - Properties
            RightPaletteView()
                .frame(minWidth: 220, idealWidth: 280, maxWidth: 350)
        }
        .onAppear {
            print("📱 ContentView appeared - file system navigator ready")
        }
    }
}

// MARK: - Simple Center View Placeholder
struct CenterView: View {
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        VStack {
            Text("3D View")
                .font(.largeTitle)
                .fontWeight(.light)
                .foregroundColor(.secondary)
            
            if let selectedItem = model.selectedItem {
                Text("Selected: \(selectedItem.name)")
                    .font(.headline)
                    .padding(.top)
                
                Text("Type: \(selectedItem.itemType == .folder ? "Folder" : "USD File")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let url = selectedItem.url {
                    Text("Path: \(url.path)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            } else {
                Text("No selection")
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.textBackgroundColor))
    }
}
