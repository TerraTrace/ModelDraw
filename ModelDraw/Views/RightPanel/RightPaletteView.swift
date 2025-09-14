//
//  RightPaletteView.swift
//  ModelDraw
//

import SwiftUI

// MARK: - Right Palette (Selection Properties)
struct RightPaletteView: View {
    let assemblies: [Assembly]
    let primitives: [GeometricPrimitive]
    let selection: SelectedItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Properties")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let selection = selection {
                        selectedItemView(selection)
                    } else {
                        Text("No selection")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .background(Color(.controlBackgroundColor).opacity(0.5))
    }
    
    @ViewBuilder
    private func selectedItemView(_ item: SelectedItem) -> some View {
        switch item {
        case .assembly(let id):
            if let assembly = assemblies.first(where: { $0.id == id }) {
                AssemblyPropertiesView(assembly: assembly, primitives: primitives)
            } else {
                Text("Assembly not found")
                    .foregroundColor(.secondary)
            }
        case .primitive(let id):
            if let primitive = primitives.first(where: { $0.id == id }) {
                PrimitivePropertiesView(primitive: primitive)
            } else {
                Text("Primitive not found")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Assembly Properties View
struct AssemblyPropertiesView: View {
    let assembly: Assembly
    let primitives: [GeometricPrimitive]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "folder")
                    .foregroundColor(.blue)
                Text(assembly.name)
                    .font(.headline)
                    .fontWeight(.medium)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Assembly Details")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("ID: \(assembly.id.uuidString.prefix(8))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Children: \(assembly.children.count)")
                    .font(.caption)
                
                if !assembly.matingRules.isEmpty {
                    Text("Mating Rules: \(assembly.matingRules.count)")
                        .font(.caption)
                }
            }
            
            if !assembly.children.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Contains")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(primitivesInAssembly, id: \.id) { primitive in
                        HStack {
                            Image(systemName: primitive.primitiveType == .cylinder ? "cylinder" : "cone")
                                .foregroundColor(primitive.primitiveType == .cylinder ? .blue : .orange)
                                .frame(width: 16)
                            Text(primitive.primitiveType.rawValue.capitalized)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var primitivesInAssembly: [GeometricPrimitive] {
        assembly.children.compactMap { child in
            if case .primitive(let id) = child {
                return primitives.first { $0.id == id }
            }
            return nil
        }
    }
}

// MARK: - Primitive Properties View
struct PrimitivePropertiesView: View {
    let primitive: GeometricPrimitive
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: primitive.primitiveType == .cylinder ? "cylinder" : "cone")
                    .foregroundColor(primitive.primitiveType == .cylinder ? .blue : .orange)
                Text(primitive.primitiveType.rawValue.capitalized)
                    .font(.headline)
                    .fontWeight(.medium)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Primitive Details")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("ID: \(primitive.id.uuidString.prefix(8))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let cylinder = primitive as? Cylinder {
                    Text("Radius: \(String(format: "%.2f", cylinder.radius))m")
                        .font(.caption)
                    Text("Height: \(String(format: "%.2f", cylinder.height))m")
                        .font(.caption)
                    Text("Wall Thickness: \(String(format: "%.3f", cylinder.wallThickness))m")
                        .font(.caption)
                } else if let cone = primitive as? Cone {
                    Text("Base Radius: \(String(format: "%.2f", cone.baseRadius))m")
                        .font(.caption)
                    Text("Top Radius: \(String(format: "%.2f", cone.topRadius))m")
                        .font(.caption)
                    Text("Height: \(String(format: "%.2f", cone.height))m")
                        .font(.caption)
                    Text("Wall Thickness: \(String(format: "%.3f", cone.wallThickness))m")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}
