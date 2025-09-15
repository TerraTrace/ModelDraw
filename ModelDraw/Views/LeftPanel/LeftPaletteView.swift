//
//  LeftPaletteView.swift - Updated for ViewModel-Driven Architecture
//  ModelDraw
//

import SwiftUI

// MARK: - Left Palette with Project Navigator
struct LeftPaletteView: View {
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with project info
            VStack(alignment: .leading, spacing: 4) {
                Text("Projects")
                    .font(.headline)
                Text(model.projectName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            // Project hierarchy
            List(selection: Binding(
                get: { model.selectedItem },
                set: { model.selectItem($0) }
            )) {
                // Project level
                DisclosureGroup(model.projectName, isExpanded: Binding(
                    get: { model.isProjectExpanded },
                    set: { model.isProjectExpanded = $0 }
                )) {
                    
                    // Configuration level
                    ForEach(model.configurations, id: \.self) { configName in
                        DisclosureGroup(configName, isExpanded: Binding(
                            get: { model.expandedConfigurations.contains(configName) },
                            set: { isExpanded in
                                if isExpanded {
                                    model.expandedConfigurations.insert(configName)
                                } else {
                                    model.expandedConfigurations.remove(configName)
                                }
                            }
                        )) {
                            
                            // Assembly level
                            ForEach(assembliesForConfiguration(configName), id: \.id) { assembly in
                                DisclosureGroup(assembly.name, isExpanded: Binding(
                                    get: { model.expandedAssemblies.contains(assembly.id) },
                                    set: { isExpanded in
                                        if isExpanded {
                                            model.expandedAssemblies.insert(assembly.id)
                                        } else {
                                            model.expandedAssemblies.remove(assembly.id)
                                        }
                                    }
                                )) {
                                    
                                    // Primitives in assembly
                                    ForEach(model.primitivesIn(assembly: assembly), id: \.id) { primitive in
                                        HStack {
                                            Image(systemName: iconName(for: primitive.primitiveType))
                                                .foregroundColor(iconColor(for: primitive.primitiveType))
                                                .frame(width: 16)
                                            Text(primitive.primitiveType.rawValue.capitalized)
                                                .font(.system(size: 13))
                                        }
                                        .tag(SelectedItem.primitive(primitive.id))
                                    }
                                }
                                .tag(SelectedItem.assembly(assembly.id))
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .onChange(of: model.selectedItem) {
                print("Selected: \(String(describing: model.selectedItem))")
            }
        }
    }
    
    // MARK: - Helper Methods
    private func assembliesForConfiguration(_ configName: String) -> [Assembly] {
        // For now, return all assemblies - could be filtered by configuration in the future
        return model.assemblies
    }
    
    private func iconName(for primitiveType: PrimitiveType) -> String {
        switch primitiveType {
        case .cylinder:
            return "cylinder"
        case .cone:
            return "cone"
        }
    }
    
    private func iconColor(for primitiveType: PrimitiveType) -> Color {
        switch primitiveType {
        case .cylinder:
            return .blue
        case .cone:
            return .orange
        }
    }
}
