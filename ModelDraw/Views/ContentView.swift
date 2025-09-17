//
//  ContentView.swift
//  ModelDraw - Clean three-pane layout for file system navigation
//

import SwiftUI

struct ContentView: View {
    @Environment(ViewModel.self) private var model
    @State private var showRightPanel: Bool = false
    
    var body: some View {
        HSplitView {
            // Left Panel - File System Navigator (resizable)
            LeftPaletteView()
                .frame(minWidth: 160, idealWidth: 180, maxWidth: 250)

            // Center Panel - 3D View (takes all remaining space)
            CenterRealityView()
                .frame(maxWidth: .infinity)
            
            // Right Panel - Properties (conditionally shown, fixed width)
            if showRightPanel {
                RightPaletteView()
                    .frame(width: 280)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showRightPanel.toggle()
                    }
                }) {
                    Image(systemName: showRightPanel ? "sidebar.trailing" : "sidebar.trailing")
                        .symbolVariant(showRightPanel ? .fill : .none)
                }
                .help(showRightPanel ? "Hide Properties" : "Show Properties")
            }
        }
        .onAppear {
            print("📱 ContentView appeared - file system navigator ready")
        }
    }
}

// MARK: - Simple Center View Placeholder
/*struct CenterView: View {
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
} */
