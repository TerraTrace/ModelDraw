// File: PropertyRowView.swift
//
//  PropertyRowView.swift
//  ModelDraw
//

import SwiftUI

struct PropertyRowView: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
}
