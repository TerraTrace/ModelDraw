//
//  NavigatorRowView.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/14/25.
//

import SwiftUI



// MARK: - Navigator Row View (Clean, Xcode-style)
struct NavigatorRowView: View {
    let item: NavigatorItem
    
    var body: some View {
        HStack(spacing: 8) {
            // Icon based on item type
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .frame(width: 16, height: 16)
            
            // Item name
            Text(item.name)
                .font(.system(size: 13))
            
            Spacer()
        }
        .contentShape(Rectangle())
    }
    
    private var iconName: String {
        switch item.itemType {
        case .assembly:
            return "folder"
        case .primitive(let type):
            switch type {
            case .cylinder:
                return "cylinder"
            case .cone:
                return "cone"
            }
        case .matingRule:
            return "link"
        }
    }
    
    private var iconColor: Color {
        switch item.itemType {
        case .assembly:
            return .blue
        case .primitive(.cylinder):
            return .blue
        case .primitive(.cone):
            return .orange
        case .matingRule:
            return .secondary
        }
    }
}
