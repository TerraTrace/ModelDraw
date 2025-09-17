//
//  ViewModel.swift - Updated for Project-Based Architecture
//  ModelDraw
//

import SwiftUI
import RealityKit

@Observable
class ViewModel {
    



    
}


extension ViewModel {
    
    // MARK: - File System Navigator Methods
    
    /// Build hierarchical NavigatorItem tree from ModelDraw file system
    func buildFileSystemNavigatorData() -> [NavigatorItem] {
        do {
            let modelDrawURL = getModelDrawURL()
            
            // Create the three main folders: Projects, Library, Templates
            var rootNodes: [NavigatorItem] = []
            
            let mainFolders = ["Projects", "Library", "Templates"]
            
            for folderName in mainFolders {
                let folderURL = modelDrawURL.appendingPathComponent(folderName)
                
                if FileManager.default.fileExists(atPath: folderURL.path) {
                    let folderNode = try buildNavigatorNode(from: folderURL)
                    rootNodes.append(folderNode)
                } else {
                    // Create empty folder node if directory doesn't exist
                    let emptyFolder = NavigatorItem(
                        name: folderName,
                        itemType: .folder,
                        children: [],
                        url: folderURL
                    )
                    rootNodes.append(emptyFolder)
                }
            }
            
            print("✅ ViewModel: Built file system navigator with \(rootNodes.count) root folders")
            return rootNodes
            
        } catch {
            print("❌ ViewModel: Failed to build file system navigator: \(error)")
            return []
        }
    }
    
    /// Recursively build NavigatorItem from directory URL
    private func buildNavigatorNode(from url: URL) throws -> NavigatorItem {
        let fileManager = FileManager.default
        
        // Get folder/file name
        let itemName = url.lastPathComponent
        
        // Check if it's a directory
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw NavigatorError.itemNotFound(path: url.path)
        }
        
        if !isDirectory.boolValue {
            // It's a file - check if it's a USD file
            if url.pathExtension.lowercased() == "usd" {
                return NavigatorItem(
                    name: itemName,
                    itemType: .usdFile,
                    children: nil,
                    url: url
                )
            } else {
                // Skip non-USD files
                throw NavigatorError.unsupportedFileType(path: url.path)
            }
        }
        
        // It's a directory - scan its contents
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        
        // Build child nodes (folders and USD files only)
        var childNodes: [NavigatorItem] = []
        
        for itemURL in contents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            do {
                let childNode = try buildNavigatorNode(from: itemURL)
                childNodes.append(childNode)
            } catch NavigatorError.unsupportedFileType {
                // Skip unsupported files silently
                continue
            } catch {
                print("⚠️ ViewModel: Skipping item \(itemURL.lastPathComponent): \(error)")
                continue
            }
        }
        
        return NavigatorItem(
            name: itemName,
            itemType: .folder,
            children: childNodes.isEmpty ? [] : childNodes,
            url: url
        )
    }
    
    /// Get the ModelDraw root directory URL
    private func getModelDrawURL() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent("ModelDraw")
    }
}

// MARK: - Navigator Error Types
enum NavigatorError: Error, LocalizedError {
    case itemNotFound(path: String)
    case unsupportedFileType(path: String)
    case accessDenied(path: String)
    
    var errorDescription: String? {
        switch self {
        case .itemNotFound(let path):
            return "Item not found: \(path)"
        case .unsupportedFileType(let path):
            return "Unsupported file type: \(path)"
        case .accessDenied(let path):
            return "Access denied: \(path)"
        }
    }
}
