//
//  ViewModel.swift - Updated for Project-Based Architecture
//  ModelDraw
//

import SwiftUI
import RealityKit

@Observable
class ViewModel {
    
    // MARK: - Services
    private let drawingManager = DrawingManager.shared
    private let usdFileManager = USDFileManager.shared

    // MARK: - Navigator State
    private(set) var navigatorData: [NavigatorItem] = []
    private(set) var selectedItem: NavigatorItem?
    
    // MARK: - 3D Scene State (for future drag/drop)
    private(set) var loadedUSDItems: [LoadedUSDItem] = []
    
    // MARK: - Camera State
    
    // MARK: - Camera Control Properties
    
    /// Current camera mode - determines how camera behaves
    var cameraMode: CameraMode = .sceneCenter
    //var cameraMode: CameraMode = .freeFlier
    
    var shiftPressed = false
    
    /// Computed camera configuration from current mode and target
    /// Automatically updates when cameraMode changes
    var cameraConfiguration: CameraConfiguration {
        switch cameraMode {
        case .sceneCenter:
            return .sceneCenter
        case .freeFlier:
            return .freeFlierMode
        }
    }
    
    // MARK: - Camera Transform Properties
        
    /// Current camera position in 3D space
    /// Updated by CameraController based on orbit/pan/zoom gestures
    var cameraPosition: SIMD3<Float> = [0, 0, 5]
    
    /// Camera rotation quaternion for smooth orientation changes
    /// Calculated by CameraController for orbit and pan movements
    var cameraRotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])
    
    /// Camera distance from target for orbit calculations
    /// Used by CameraController to maintain consistent orbit radius
    var cameraDistance: Float = 10.0
    
        
    // MARK: - + Button State
    /// Tracks if user clicked "+" button and is waiting for canvas placement
    private(set) var isPlacementMode: Bool = false

    /// Computed property for + button enabled state
    /// Enabled when: selectedItem exists (no canvas click required)
    var isAddButtonEnabled: Bool {
        return selectedItem != nil
    }

    // MARK: - Initialization
    init() {
        loadNavigatorData()
    }
    
    // MARK: - Public Methods
    
    /// Refresh the navigator tree from file system
    func loadNavigatorData() {
        navigatorData = buildFileSystemNavigatorData()
    }
        
    /// Reload navigator data (for when files change)
    func refreshNavigator() {
        loadNavigatorData()
        print("🔄 ViewModel: Navigator data refreshed")
    }

    /// Select a navigator item
    func selectItem(_ item: NavigatorItem?) {
        selectedItem = item
        
        // Exit placement mode when selecting a different item
        if isPlacementMode {
            isPlacementMode = false
            print("🚪 ViewModel: Exited placement mode due to new selection")
        }
        
        if let item = item {
            print("📋 ViewModel: Selected \(item.itemType == .folder ? "folder" : "USD file"): \(item.name)")
            print("✅ ViewModel: + button enabled")
        } else {
            print("📋 ViewModel: Cleared selection")
            print("❌ ViewModel: + button disabled")
        }
    }

    /// Enter placement mode when + button is clicked
    func enterPlacementMode() {
        guard selectedItem != nil else { return }
        
        isPlacementMode = true
        print("🎯 ViewModel: Entered placement mode - waiting for canvas click")
    }

    /// Place item at canvas location and exit placement mode
    func placeItemAtLocation(_ location: SIMD3<Float>) {
        guard isPlacementMode, let item = selectedItem else { return }
        
        print("📍 ViewModel: Placing \(item.name) at \(location)")
        //addUSDItemToScene(item: item, at: location)
        
        // Exit placement mode
        isPlacementMode = false
        print("✅ ViewModel: Item placed - exited placement mode")
    }

    
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
