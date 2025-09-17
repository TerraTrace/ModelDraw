//
//  RightPaletteView.swift - Updated for ViewModel-Driven Architecture
//  ModelDraw
//

import SwiftUI

// MARK: - Right Palette (Selection Properties)
struct RightPaletteView: View {
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Properties")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let selection = model.selectedItem {
                        selectedItemView(selection)
                    } else {
                        Text("No selection")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .background(Color(.controlBackgroundColor).opacity(0.5))
    }
    
    @ViewBuilder
    private func selectedItemView(_ item: SelectedItem) -> some View {
    }
}

// MARK: - Assembly Properties View
struct AssemblyPropertiesView: View {
    @Environment(ViewModel.self) private var model
    let assembly: Assembly
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "folder")
                    .foregroundColor(.blue)
                Text(assembly.name)
                    .font(.headline)
                    .fontWeight(.medium)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Assembly Details")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Children: \(assembly.children.count)")
                    .font(.caption)
                
            }
            
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Primitive Properties View
struct PrimitivePropertiesView: View {
    let primitive: Assembly
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Primitive Details")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}
