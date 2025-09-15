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
    
    init(id: UUID = UUID(), name: String, itemType: NavigatorItemType, children: [NavigatorItem]?) {
        self.id = id
        self.name = name
        self.itemType = itemType
        self.children = children
    }
}

enum NavigatorItemType: Hashable, Equatable {
    case assembly
    case primitive(PrimitiveType)
    case matingRule
}

