//
//  LeftPaletteView.swift
//  ModelDraw - Updated for OutlineGroup file system navigator
//

import SwiftUI

struct LeftPaletteView: View {
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Project Navigator")
                        .font(.headline)
                        .fontWeight(.medium)
                    Spacer()
                    
                    // Refresh button
                    Button(action: {
                        model.refreshNavigator()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.borderless)
                    .help("Refresh file tree")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.controlBackgroundColor))
            }
            Spacer().frame(height: 200)
                //.background(Color(.controlBackgroundColor))
            Divider()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("File Navigator")
                        .font(.headline)
                        .fontWeight(.medium)
                    Spacer()
                    
                    // Add button (disabled by default until selection + canvas click)
                    Button(action: {
                        addSelectedItemToCanvas()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.borderless)
                    .help("Add selected item to canvas")
                    .disabled(!model.isAddButtonEnabled) // This will control enable/disable state
                    Spacer().frame(width: 20)

                    // Refresh button
                    Button(action: {
                        model.refreshNavigator()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.borderless)
                    .help("Refresh file tree")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.controlBackgroundColor))
                
                // File system navigator with OutlineGroup
                List(
                    model.navigatorData,
                    children: \.children,
                    selection: Binding(
                        get: { model.selectedItem },
                        set: { selectedItem in
                            model.selectItem(selectedItem)
                        }
                    )
                ) { item in
                    NavigatorRowView(item: item)
                        .tag(item)
                }
                .listStyle(.sidebar)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 220)
        .onAppear {
            // Load navigator data when view appears
            if model.navigatorData.isEmpty {
                model.loadNavigatorData()
            }
        }
    }
    
    
    private func addSelectedItemToCanvas() {
            // Stub implementation - this will add the selected item to canvas
            print("🎯 Adding selected item to canvas")
            
            guard let selectedItem = model.selectedItem else {
                print("❌ No item selected")
                return
            }
            
            print("📁 Selected item: \(selectedItem.name) (\(selectedItem.itemType))")
            
            if let canvasClickLocation = model.canvasClickLocation {
                print("📍 Canvas click location: \(canvasClickLocation)")
                // TODO: Implement actual USD loading and 3D placement here
                //model.addUSDItemToScene(item: selectedItem, at: canvasClickLocation)
            } else {
                print("❌ No canvas click location available")
            }
        }
    
}
