// File: SelectedItemPropertiesView.swift
//
//  SelectedItemPropertiesView.swift
//  ModelDraw
//

import SwiftUI

struct SelectedItemPropertiesView: View {
    let item: NavigatorItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Item header
            ItemHeaderView(item: item)
            
            Divider()
            
            // Item details
            ItemDetailsView(item: item)
            
            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

