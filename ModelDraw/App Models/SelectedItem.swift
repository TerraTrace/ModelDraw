//
//  SelectedItem.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/15/25.
//

import SwiftUI
import Foundation


enum SelectedItem: Hashable {
    case assembly(UUID)
    case primitive(UUID)
}

extension SelectedItem {
    var description: String {
        switch self {
        case .assembly(let id):
            return "Assembly(\(id))"
        case .primitive(let id):
            return "Primitive(\(id))"
        }
    }
}
