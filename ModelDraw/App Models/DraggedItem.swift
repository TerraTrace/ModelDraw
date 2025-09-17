//
//  DraggedItem.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/17/25.
//

import Foundation
import UniformTypeIdentifiers

// MARK: - Custom Drag Data Type
struct DraggedItem: Codable, Transferable {
    let navigatorItem: NavigatorItem
    let draggedAt: Date
    
    init(navigatorItem: NavigatorItem) {
        self.navigatorItem = navigatorItem
        self.draggedAt = Date()
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .modelDrawItem)
    }
}

// MARK: - Custom UTType for ModelDraw Items
extension UTType {
    static let modelDrawItem = UTType(exportedAs: "com.demeter.modeldraw.item")
}
