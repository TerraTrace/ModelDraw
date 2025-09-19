//
//  FileNavigatorItemView.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/18/25.
//

import SwiftUI


// MARK: - File Navigator Item
struct FileNavigatorItemView: View {
    let item: NavigatorItem
    let level: Int
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Item row
            HStack(spacing: 4) {
                // Indentation
                HStack(spacing: 0) {
                    ForEach(0..<level, id: \.self) { _ in
                        Spacer().frame(width: 16)
                    }
                }
                
                // Disclosure triangle for folders with children
                if item.itemType == .folder && item.children?.isEmpty == false {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded(item) ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded(item))
                } else {
                    Spacer().frame(width: 12)
                }
                
                // Icon
                Image(systemName: item.itemType == .folder ? "folder" : "doc")
                    .foregroundColor(item.itemType == .folder ? .blue : .orange)
                    .font(.system(size: 14))
                
                // Name
                Text(item.name)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(isSelected(item) ? Color.blue.opacity(0.3) : Color.clear)
            .cornerRadius(4)
            .onTapGesture {
                model.selectItem(item)
            }
            
            // Children (if expanded)
            if item.itemType == .folder,
               let children = item.children,
               isExpanded(item) {
                ForEach(children, id: \.id) { child in
                    FileNavigatorItemView(item: child, level: level + 1)
                }
            }
        }
    }
    
    private func isSelected(_ item: NavigatorItem) -> Bool {
        return model.selectedItem?.id == item.id
    }
    
    private func isExpanded(_ item: NavigatorItem) -> Bool {
        // For now, show all folders as expanded
        // You could add expansion state tracking later
        return true
    }
}
