// File: ToolButtonView.swift
//
//  ToolButtonView.swift
//  ModelDraw
//

import SwiftUI

struct ToolButtonView: View {
    let name: String
    let icon: String
    let isActive: Bool
    
    var body: some View {
        Button(action: {
            // TODO: Implement tool selection
            print("🔧 Tool selected: \(name)")
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isActive ? .white : .primary)
                
                Text(name)
                    .font(.caption)
                    .foregroundColor(isActive ? .white : .primary)
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(isActive ? Color.blue : Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .help("\(name) Tool")
    }
}
