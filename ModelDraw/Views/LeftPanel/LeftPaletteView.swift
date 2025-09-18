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
}
