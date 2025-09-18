// File: ToolsHeaderView.swift
//
//  ToolsHeaderView.swift
//  ModelDraw
//

import SwiftUI

struct ToolsHeaderView: View {
    var body: some View {
        HStack {
            Text("Tools")
                .font(.headline)
                .fontWeight(.medium)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor))
    }
}

