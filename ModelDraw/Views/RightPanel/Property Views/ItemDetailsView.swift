// File: ItemDetailsView.swift
//
//  ItemDetailsView.swift
//  ModelDraw
//

import SwiftUI

struct ItemDetailsView: View {
    let item: NavigatorItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PropertyRowView(label: "Type", value: item.itemType == .folder ? "Folder" : "USD File")
            
            if let url = item.url {
                PropertyRowView(label: "Location", value: url.path)
                
                // File system info
                if let fileInfo = getFileInfo(for: url) {
                    PropertyRowView(label: "Modified", value: fileInfo.modificationDate)
                    
                    if item.itemType == .usdFile {
                        PropertyRowView(label: "Size", value: fileInfo.fileSize)
                    }
                }
            }
            
            if item.itemType == .folder, let children = item.children {
                PropertyRowView(label: "Contents", value: "\(children.count) items")
            }
        }
    }
    
    // Helper to get file system info
    private func getFileInfo(for url: URL) -> (modificationDate: String, fileSize: String)? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            
            let modificationDate = formatter.string(from: resourceValues.contentModificationDate ?? Date())
            let fileSize = ByteCountFormatter.string(fromByteCount: Int64(resourceValues.fileSize ?? 0), countStyle: .file)
            
            return (modificationDate: modificationDate, fileSize: fileSize)
        } catch {
            return nil
        }
    }
}
