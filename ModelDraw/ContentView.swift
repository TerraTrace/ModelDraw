//
//  ContentView.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/12/25.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: ModelDrawDocument
    
    var body: some View {
        VStack(spacing: 20) {
            Text("ModelDraw - Document Test")
                .font(.title)
                .padding()
            
            // Document metadata display
            VStack(alignment: .leading, spacing: 8) {
                Text("Document Info:")
                    .font(.headline)
                
                Text("Author: \(document.metadata.author ?? "Unknown")")
                Text("Created: \(document.metadata.createdDate, style: .date)")
                Text("Notes: \(document.metadata.notes ?? "None")")
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            
            // Primitives display
            VStack(alignment: .leading, spacing: 8) {
                Text("Primitives (\(document.primitives.count)):")
                    .font(.headline)
                
                ForEach(document.primitives.indices, id: \.self) { index in
                    let primitive = document.primitives[index]
                    
                    HStack {
                        Text("\(primitive.primitiveType.rawValue.capitalized):")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if let cylinder = primitive as? Cylinder {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Radius: \(cylinder.radius, specifier: "%.3f")m")
                                Text("Height: \(cylinder.height, specifier: "%.3f")m")
                                Text("Wall: \(cylinder.wallThickness, specifier: "%.3f")m")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            
            // Test instructions
            VStack(alignment: .leading, spacing: 8) {
                Text("Test Instructions:")
                    .font(.headline)
                
                Text("• File > Save to save this document")
                Text("• File > Open to load saved documents")
                Text("• File > New to create new documents")
                Text("• Check JSON format in saved files")
            }
            .padding()
            .background(Color(.quaternaryLabelColor).opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    ContentView(document: .constant(ModelDrawDocument()))
}
