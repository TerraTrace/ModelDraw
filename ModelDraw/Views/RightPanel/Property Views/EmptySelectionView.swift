// File: EmptySelectionView.swift
//
//  EmptySelectionView.swift
//  ModelDraw
//

import SwiftUI

struct EmptySelectionView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "cursorarrow.click")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No Selection")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Select a folder or USD file in the navigator to view its properties.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

