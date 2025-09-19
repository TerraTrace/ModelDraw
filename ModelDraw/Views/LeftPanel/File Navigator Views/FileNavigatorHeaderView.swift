//
//  FileNavigatorHeaderView.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/18/25.
//

import SwiftUI


// MARK: - File Navigator Header
struct FileNavigatorHeaderView: View {
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        HStack {
            Text("File Navigator")
                .font(.headline)
                .fontWeight(.medium)
            Spacer()
            
            // Add button (moved from right panel)
            Button(action: {
                model.enterPlacementMode()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 12))
                    .fontWeight(model.isAddButtonEnabled ? .bold : .regular)
                    .foregroundColor(model.isAddButtonEnabled ? .blue : .secondary)
            }
            .buttonStyle(.borderless)
            .disabled(!model.isAddButtonEnabled)
            .help("Add selected item to canvas")
            
            // Refresh button
            Button(action: {
                model.refreshNavigator()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .help("Refresh file tree")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor))
    }
}

