// File: PropertiesHeaderView.swift
//
//  PropertiesHeaderView.swift
//  ModelDraw
//

import SwiftUI

struct PropertiesHeaderView: View {
    var body: some View {
        HStack {
            Text("Properties")
                .font(.headline)
                .fontWeight(.medium)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor))
    }
}
