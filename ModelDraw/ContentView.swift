//
//  ContentView.swift - Updated with Assembly Display
//  ModelDraw
//

import SwiftUI

struct ContentView: View {
    @Binding var document: ModelDrawDocument
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HeaderView()
                DocumentMetadataView(metadata: document.metadata)
                AssembliesView(assemblies: document.assemblies)
                PrimitivesView(primitives: document.primitives)
            }
            .padding()
        }
    }
}

struct HeaderView: View {
    var body: some View {
        Text("ModelDraw - Document Test")
            .font(.title)
            .padding()
    }
}

struct DocumentMetadataView: View {
    let metadata: DocumentMetadata
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Document Info:")
                .font(.headline)
            
            Text("Author: \(metadata.author ?? "Unknown")")
            Text("Created: \(metadata.createdDate, style: .date)")
            Text("Notes: \(metadata.notes ?? "None")")
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct AssembliesView: View {
    let assemblies: [Assembly]
    
    var body: some View {
        if !assemblies.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Assemblies (\(assemblies.count)):")
                    .font(.headline)
                
                ForEach(assemblies, id: \.id) { assembly in
                    AssemblyRowView(assembly: assembly)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

struct AssemblyRowView: View {
    let assembly: Assembly
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("📦 \(assembly.name)")
                .font(.subheadline)
                .fontWeight(.bold)
            
            Text("   Children: \(assembly.children.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(assembly.matingRules, id: \.childA) { rule in
                HStack {
                    Text("   🔗 Mating:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(rule.anchorA) → \(rule.anchorB)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if !assemblies.dropLast().contains(where: { $0.id == assembly.id }) {
                Divider()
            }
        }
    }
    
    private var assemblies: [Assembly] { [assembly] } // Helper for comparison
}

struct PrimitivesView: View {
    let primitives: [GeometricPrimitive]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Primitives (\(primitives.count)):")
                .font(.headline)
            
            ForEach(Array(primitives.enumerated()), id: \.offset) { index, primitive in
                PrimitiveRowView(primitive: primitive)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct PrimitiveRowView: View {
    let primitive: GeometricPrimitive
    
    var body: some View {
        HStack {
            Text("🔹 \(primitive.primitiveType.rawValue.capitalized):")
                .font(.subheadline)
                .fontWeight(.medium)
            
            PrimitiveDetailsView(primitive: primitive)
            
            Spacer()
            
            Text("ID: \(primitive.id.uuidString.prefix(8))...")
                .font(.caption2)
                .foregroundColor(Color(nsColor: .tertiaryLabelColor))
        }
    }
}

struct PrimitiveDetailsView: View {
    let primitive: GeometricPrimitive
    
    var body: some View {
        Group {
            if let cylinder = primitive as? Cylinder {
                Text("R=\(String(format: "%.1f", cylinder.radius))m, H=\(String(format: "%.1f", cylinder.height))m")
            } else if let cone = primitive as? Cone {
                Text("Base=\(String(format: "%.1f", cone.baseRadius))m, Top=\(String(format: "%.1f", cone.topRadius))m, H=\(String(format: "%.1f", cone.height))m")
            } else {
                Text("Unknown primitive type")
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
}
