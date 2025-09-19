//
//  NavigatorRowView.swift
//  ModelDraw - Restored original working row view
//

import SwiftUI

struct NavigatorRowView: View {
    let item: NavigatorItem
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.itemType == .folder ? "folder" : "doc")
                .foregroundColor(item.itemType == .folder ? .blue : .orange)
                .font(.system(size: 14))
            
            Text(item.name)
                .font(.system(size: 13))
            
            Spacer()
        }
        // Remove all padding - let OutlineGroup handle layout
        .contentShape(Rectangle())
        .onTapGesture {
            model.selectItem(item)
        }
    }
}
