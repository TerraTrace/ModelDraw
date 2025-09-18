// File: ItemHeaderView.swift
//
//  ItemHeaderView.swift
//  ModelDraw
//

import SwiftUI

struct ItemHeaderView: View {
    let item: NavigatorItem
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.itemType == .folder ? "folder" : "doc")
                .foregroundColor(item.itemType == .folder ? .blue : .orange)
                .font(.system(size: 16))
            
            Text(item.name)
                .font(.headline)
                .fontWeight(.medium)
        }
    }
}
