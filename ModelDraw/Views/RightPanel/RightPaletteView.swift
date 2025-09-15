//
//  RightPaletteView.swift - Updated for ViewModel-Driven Architecture
//  ModelDraw
//

import SwiftUI

// MARK: - Right Palette (Selection Properties)
struct RightPaletteView: View {
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Properties")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let selection = model.selectedItem {
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
            if let assembly = model.assembly(withId: id) {
                AssemblyPropertiesView(assembly: assembly)
            } else {
                Text("Assembly not found")
                    .foregroundColor(.secondary)
            }
        case .primitive(let id):
            if let primitive = model.primitive(withId: id) {
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
    @Environment(ViewModel.self) private var model
    let assembly: Assembly
    
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
                    
                    ForEach(model.primitivesIn(assembly: assembly), id: \.id) { primitive in
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
                    Text("Radius: \(cylinder.radius, specifier: "%.2f")m")
                        .font(.caption)
                    Text("Height: \(cylinder.height, specifier: "%.2f")m")
                        .font(.caption)
                    Text("Wall Thickness: \(cylinder.wallThickness, specifier: "%.3f")m")
                        .font(.caption)
                } else if let cone = primitive as? Cone {
                    Text("Base Radius: \(cone.baseRadius, specifier: "%.2f")m")
                        .font(.caption)
                    Text("Top Radius: \(cone.topRadius, specifier: "%.2f")m")
                        .font(.caption)
                    Text("Height: \(cone.height, specifier: "%.2f")m")
                        .font(.caption)
                    Text("Wall Thickness: \(cone.wallThickness, specifier: "%.3f")m")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}
