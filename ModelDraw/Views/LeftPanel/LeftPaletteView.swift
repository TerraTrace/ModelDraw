//
//  LeftPaletteView.swift - Updated for OutlineGroup with Direct UUID Mapping
//  ModelDraw
//

import SwiftUI

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
            
            // OutlineGroup-based navigator with direct UUID selection
            List(model.navigatorData, children: \.children, selection: Binding(
                get: {
                    switch model.selectedItem {
                    case .assembly(let id), .primitive(let id):
                        return id
                    case .none:
                        return nil
                    }
                },
                set: { selectedID in
                    guard let id = selectedID else {
                        model.selectItem(nil)
                        return
                    }
                    
                    // Determine if it's an assembly or primitive based on the data
                    if model.assemblies.contains(where: { $0.id == id }) {
                        model.selectItem(.assembly(id))
                    } else if model.primitives.contains(where: { $0.id == id }) {
                        model.selectItem(.primitive(id))
                    }
                }
            )) { item in
                NavigatorRowView(item: item)
            }
            .listStyle(.sidebar)
            .onChange(of: model.selectedItem) {
                print("Selected: \(String(describing: model.selectedItem))")
            }
        }
    }
}
