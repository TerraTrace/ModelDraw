//
//  RightPaletteView.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/14/25.
//


import SwiftUI
import RealityKit



// MARK: - Right Palette (Primitive Details)
struct RightPaletteView: View {
    let primitives: [GeometricPrimitive]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Primitives")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(primitives.enumerated()), id: \.offset) { index, primitive in
                        PrimitiveCardView(primitive: primitive)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .background(Color(.controlBackgroundColor).opacity(0.5))
    }
}


struct PrimitiveCardView: View {
    let primitive: GeometricPrimitive
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(primitiveIcon(primitive))
                Text(primitive.primitiveType.rawValue.capitalized)
                    .font(.headline)
                    .fontWeight(.medium)
            }
            
            PrimitiveDetailsView(primitive: primitive)
            
            Text("ID: \(primitive.id.uuidString.prefix(8))...")
                .font(.caption2)
                .foregroundColor(Color(nsColor: .tertiaryLabelColor))
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func primitiveIcon(_ primitive: GeometricPrimitive) -> String {
        switch primitive.primitiveType {
        case .cylinder:
            return "🔵"
        case .cone:
            return "🔶"
        }
    }
}

struct PrimitiveDetailsView: View {
    let primitive: GeometricPrimitive
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let cylinder = primitive as? Cylinder {
                Text("Radius: \(String(format: "%.1f", cylinder.radius))m")
                Text("Height: \(String(format: "%.1f", cylinder.height))m")
                Text("Wall: \(String(format: "%.2f", cylinder.wallThickness))m")
            } else if let cone = primitive as? Cone {
                Text("Base R: \(String(format: "%.1f", cone.baseRadius))m")
                Text("Top R: \(String(format: "%.1f", cone.topRadius))m")
                Text("Height: \(String(format: "%.1f", cone.height))m")
                Text("Wall: \(String(format: "%.2f", cone.wallThickness))m")
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
}
