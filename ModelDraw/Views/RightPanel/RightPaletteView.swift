//
//  RightPaletteView.swift
//  ModelDraw - Clean properties panel for NavigatorItem selection
//

import SwiftUI

struct RightPaletteView: View {
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Properties")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.controlBackgroundColor))
            
            // Properties content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let selectedItem = model.selectedItem {
                        selectedItemProperties(selectedItem)
                    } else {
                        emptySelectionView()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.textBackgroundColor).opacity(0.5))
    }
    
    @ViewBuilder
    private func selectedItemProperties(_ item: NavigatorItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Item header
            HStack(spacing: 8) {
                Image(systemName: item.itemType == .folder ? "folder" : "doc")
                    .foregroundColor(item.itemType == .folder ? .blue : .orange)
                    .font(.system(size: 16))
                
                Text(item.name)
                    .font(.headline)
                    .fontWeight(.medium)
            }
            
            Divider()
            
            // Item details
            VStack(alignment: .leading, spacing: 8) {
                propertyRow("Type", value: item.itemType == .folder ? "Folder" : "USD File")
                
                if let url = item.url {
                    propertyRow("Location", value: url.path)
                    
                    // File system info
                    if let fileInfo = getFileInfo(for: url) {
                        propertyRow("Modified", value: fileInfo.modificationDate)
                        
                        if item.itemType == .usdFile {
                            propertyRow("Size", value: fileInfo.fileSize)
                        }
                    }
                }
                
                if item.itemType == .folder, let children = item.children {
                    propertyRow("Contents", value: "\(children.count) items")
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func emptySelectionView() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "cursorarrow.click")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No Selection")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Select a folder or USD file in the navigator to view its properties.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    @ViewBuilder
    private func propertyRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
    
    // Helper to get file system info
    private func getFileInfo(for url: URL) -> (modificationDate: String, fileSize: String)? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            
            let modDate = resourceValues.contentModificationDate.map { dateFormatter.string(from: $0) } ?? "Unknown"
            let fileSize = resourceValues.fileSize.map { ByteCountFormatter().string(fromByteCount: Int64($0)) } ?? "Unknown"
            
            return (modificationDate: modDate, fileSize: fileSize)
        } catch {
            return nil
        }
    }
}
