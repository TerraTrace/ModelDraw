// File: PropertiesSection.swift
//
//  PropertiesSection.swift
//  ModelDraw
//

import SwiftUI

struct PropertiesSection: View {
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Properties Header
            PropertiesHeaderView()
            
            // Properties Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let selectedItem = model.selectedItem {
                        SelectedItemPropertiesView(item: selectedItem)
                    } else {
                        EmptySelectionView()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(minHeight: 200) // Minimum height for properties section
    }
}
