//
//  ProjectNavigatorRowView.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/18/25.
//

import SwiftUI


// MARK: - Project Navigator Row
struct ProjectNavigatorRowView: View {
    let item: LoadedUSDItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Entity icon
            Image(systemName: "cube")
                .foregroundColor(.orange)
                .font(.system(size: 14))
            
            // Entity name
            Text(item.entity.name)
                .font(.system(size: 13))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
        .cornerRadius(4)
        .onTapGesture {
            onTap()
        }
    }
}


