//
//  LeftPaletteView.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/14/25.
//


import SwiftUI

// Add this enum
enum SelectedItem: Hashable {
    case assembly(UUID)
    case primitive(UUID)
}

// MARK: - Updated Left Palette with Navigator Style
// LeftPaletteView.swift - Simple version
struct LeftPaletteView: View {
    @Environment(ViewModel.self) private var model
    let assemblies: [Assembly]
    let primitives: [GeometricPrimitive]

    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Project Navigator")
                .font(.headline)
                .padding()
                .background(Color(.controlBackgroundColor))
            
            // List with selection
            List(selection: $selection) {
                ForEach(assemblies, id: \.id) { assembly in
                    DisclosureGroup(assembly.name, isExpanded: .constant(true)) {
                        ForEach(primitivesIn(assembly), id: \.id) { primitive in
                            HStack {
                                Image(systemName: primitive.primitiveType == .cylinder ? "cylinder" : "cone")
                                    .foregroundColor(primitive.primitiveType == .cylinder ? .blue : .orange)
                                Text(primitive.primitiveType.rawValue.capitalized)
                            }
                            .tag(SelectedItem.primitive(primitive.id))
                        }
                    }
                    .tag(SelectedItem.assembly(assembly.id))
                }
            }
            .listStyle(.sidebar)
            .onAppear {
                if let firstAssembly = assemblies.first {
                    selection = .assembly(firstAssembly.id)
                }
            }
            .onChange(of: selection) {
                print("Selected: \(String(describing: selection))")
            }
        }
    }
    
    private func primitivesIn(_ assembly: Assembly) -> [GeometricPrimitive] {
        assembly.children.compactMap { child in
            if case .primitive(let id) = child {
                return primitives.first { $0.id == id }
            }
            return nil
        }
    }
}
    
