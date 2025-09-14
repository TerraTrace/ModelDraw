//
//  LeftPaletteView.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/14/25.
//

import SwiftUI


// MARK: - Left Palette (Assembly Information)
struct LeftPaletteView: View {
    let assemblies: [Assembly]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Assemblies")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(assemblies, id: \.id) { assembly in
                        AssemblyCardView(assembly: assembly)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .background(Color(.controlBackgroundColor).opacity(0.5))
    }
}

struct AssemblyCardView: View {
    let assembly: Assembly
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("📦")
                Text(assembly.name)
                    .font(.headline)
                    .fontWeight(.medium)
            }
            
            Text("Children: \(assembly.children.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Mating Rules
            ForEach(assembly.matingRules, id: \.childA) { rule in
                HStack {
                    Text("🔗")
                        .font(.caption)
                    Text("\(rule.anchorA) → \(rule.anchorB)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}
