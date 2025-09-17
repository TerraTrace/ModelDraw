//
//  NavigatorRowView.swift
//  ModelDraw - Updated for file system navigation with small system icons
//

import SwiftUI

// MARK: - Navigator Row View (Clean, Xcode-style with small icons)
struct NavigatorRowView: View {
    let item: NavigatorItem
    
    var body: some View {
        HStack(spacing: 6) {
            // Small system icon
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.system(size: 11, weight: .regular))
                .frame(width: 12, height: 12)
            
            // Item name
            Text(item.name)
                .font(.system(size: 13))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .contentShape(Rectangle())
    }
    
    private var iconName: String {
        switch item.itemType {
        case .folder:
            return "folder"
        case .usdFile:
            return "doc"
        }
    }
    
    private var iconColor: Color {
        switch item.itemType {
        case .folder:
            return .blue
        case .usdFile:
            return .orange
        }
    }
}
