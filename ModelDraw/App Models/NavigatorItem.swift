//
//  NavigatorItem.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/15/25.
//

import SwiftUI


// MARK: - Hierarchical Data Structure for Navigator Panel
struct NavigatorItem: Identifiable, Hashable, Equatable {
    var id: UUID
    var name: String
    var itemType: NavigatorItemType
    var children: [NavigatorItem]? = nil
    
    // Store the file system URL for drag/drop operations
    var url: URL?
    
    init(id: UUID = UUID(), name: String, itemType: NavigatorItemType, children: [NavigatorItem]?, url: URL? = nil) {
        self.id = id
        self.name = name
        self.itemType = itemType
        self.children = children
        self.url = url
    }
}

// MARK: - Simplified Navigator Item Types
enum NavigatorItemType: Hashable, Equatable {
    case folder
    case usdFile
}
