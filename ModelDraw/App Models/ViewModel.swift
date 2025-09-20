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
    
    private let lastProjectKey = "ModelDraw_LastActiveProject"
    private let cameraNavigationModeKey = "ModelDraw_CameraNavigationMode"


    // MARK: - Navigator State
    private(set) var navigatorData: [NavigatorItem] = []
    private(set) var selectedItem: NavigatorItem?
    
    /// ID of currently selected entity in the 3D scene
    var selectedSceneEntityID: UUID? = nil

    
    // MARK: - 3D Scene State (for future drag/drop)
    private(set) var loadedUSDItems: [LoadedUSDItem] = []
    
    // MARK: - Camera State
    
    // MARK: - Camera Control Properties
    
    //var cameraMode: CameraMode = .sceneCenter
    //var cameraViewPreset: ViewPreset? = nil  // .front, .side, .iso, etc.
    
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
    
    // MARK: - Camera Properties
    
    var cameraMode: CameraMode = .sceneCenter {
        didSet {
            saveCameraNavigationMode()
        }
    }
        
    /// Current camera position in 3D space
    /// Updated by CameraController based on orbit/pan/zoom gestures
    var cameraPosition: SIMD3<Float> = [0, 0, 5]
    
    /// Camera rotation quaternion for smooth orientation changes
    /// Calculated by CameraController for orbit and pan movements
    var cameraRotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])
    
    /// Camera distance from target for orbit calculations
    /// Used by CameraController to maintain consistent orbit radius
    var cameraDistance: Float = 10.0
    
        
    // MARK: - Properties for Adding Entities
    /// Tracks if user clicked "+" button and is waiting for canvas placement
    private(set) var isPlacementMode: Bool = false

    /// Computed property for + button enabled state
    /// Enabled when: selectedItem exists (no canvas click required)
    var isAddButtonEnabled: Bool {
        return selectedItem != nil
    }
    
    var hasNewEntities: Bool = false

    // MARK: - Initialization
    init() {
        loadNavigatorData()
        loadLastActiveProject()
        loadCameraNavigationMode()
    }
    

    // MARK: - Public Methods
    
    /// Load camera navigation mode from UserDefaults
    private func loadCameraNavigationMode() {
        let savedModeRawValue = UserDefaults.standard.string(forKey: cameraNavigationModeKey) ?? "sceneCenter"
        cameraMode = CameraMode(rawValue: savedModeRawValue) ?? .sceneCenter
        print("🎯 ViewModel: Loaded camera mode: \(cameraMode)")
    }

    /// Save camera navigation mode to UserDefaults
    private func saveCameraNavigationMode() {
        UserDefaults.standard.set(cameraMode.rawValue, forKey: cameraNavigationModeKey)
        print("💾 ViewModel: Saved camera mode: \(cameraMode)")
    }
    
    
    /// Refresh the navigator tree from file system
    func loadNavigatorData() {
        navigatorData = buildFileSystemNavigatorData()
    }
        
    /// Reload navigator data (for when files change)
    func refreshNavigator() {
        loadNavigatorData()
        selectedItem = nil
        print("🔄 ViewModel: Navigator data refreshed")
    }
    
    /// Select an entity in the 3D scene by ID
    func selectSceneEntity(_ entityID: UUID) {
        selectedSceneEntityID = entityID
        print("🎯 Selected scene entity with ID: \(entityID)")
    }
    
    // MARK: - Pproject Persistence Methods
    
    /// Load the last active project using DrawingManager
    func loadLastActiveProject() {
        guard let projectFolder = findActiveProject() else {
            print("📂 No active project found")
            return
        }
        
        print("📂 Loading active project: \(projectFolder.name)")
        
        // Use DrawingManager to load the project
        let loadedItems = drawingManager.loadProjectFromSceneFile(projectFolder)
        
        // Update ViewModel state
        self.loadedUSDItems = loadedItems
        self.hasNewEntities = !loadedItems.isEmpty
        
        print("✅ ViewModel: Loaded \(loadedItems.count) items from scene file")
    }
    
    /// Find the active project folder in navigator data
    /// - Returns: NavigatorItem for active project or nil if not found
    private func findActiveProject() -> NavigatorItem? {
        guard let lastProject = UserDefaults.standard.string(forKey: lastProjectKey) else {
            return nil
        }
        
        // Find the project folder in navigatorData
        guard let projectsFolder = navigatorData.first(where: { $0.name == "Projects" }),
              let targetProject = projectsFolder.children?.first(where: { $0.name == lastProject }) else {
            print("⚠️ Project '\(lastProject)' not found in navigator")
            return nil
        }
        
        return targetProject
    }
    
    /// Set the active project (call when user selects a new project folder)
    func setActiveProject(_ projectName: String) {
        UserDefaults.standard.set(projectName, forKey: lastProjectKey)
        print("💾 Set active project: \(projectName)")
    }
    

    
    
    // MARK: - USD File Placement Methods

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
            
            // Check if user selected a project folder
            if item.itemType == .folder && (item.name == "CargoDragon" || item.name == "StarLiner") {
                setActiveProject(item.name)
                //autoLoadProjectUSDFiles(item)  // Load the USD files immediately
            }
            
            print("✅ ViewModel: + button enabled")
        } else {
            print("📋 ViewModel: Cleared selection")
            print("❌ ViewModel: + button disabled")
        } 
    }

    // Helper to detect if a folder is a project folder
    private func isProjectFolder(_ item: NavigatorItem) -> Bool {
        // Check if this folder is directly under "Projects"
        // You'd need to track parent relationships or check the path
        return item.name == "CargoDragon" || item.name == "StarLiner" // Simple for now
    }
    
    /// Enter placement mode when + button is clicked
    func enterPlacementMode() {
        guard selectedItem != nil else { return }
        
        isPlacementMode = true
        print("🎯 ViewModel: Entered placement mode - waiting for canvas click")
    }

    /// Get entities that need to be added to the scene
    func getNewEntitiesForScene() -> [Entity] {
        let newEntities = loadedUSDItems.compactMap { $0.entity }
        
        hasNewEntities = false  // Clear flag

        return newEntities
    }
    
    /// Place item at canvas location and exit placement mode
    func placeItemAtLocation(_ location: SIMD3<Float>) {
        guard isPlacementMode, let item = selectedItem else { return }
        
        print("📍 ViewModel: Placing \(item.name) at \(location)")
        
        // Use USDEntityConverter instead of stub
        switch item.itemType {
        case .usdFile:
            loadAndPlaceSingleUSDFile(item, at: location)
        case .folder:
            loadAndPlaceFolderAsAssembly(item, at: location)
        }
        
        // Exit placement mode
        isPlacementMode = false
        print("✅ ViewModel: Item placed - exited placement mode")
    }

    /// Load single USD file using USDEntityConverter
    /// Load single USD file using USDEntityConverter
    private func loadAndPlaceSingleUSDFile(_ item: NavigatorItem, at location: SIMD3<Float>) {
        guard let url = item.url else {
            print("❌ ViewModel: No URL for item \(item.name)")
            return
        }
        
        do {
            // Read USD file using USDFileManager
            let usdFile = try usdFileManager.readUSDFile(from: url)
            
            // Convert first root prim to entity
            if let firstPrim = usdFile.rootPrims.first {
                if let entity = USDEntityConverter.shared.convertToEntity(usdPrim: firstPrim) {
                    // Position entity at click location
                    entity.position = location
                    
                    // Create LoadedUSDItem for tracking
                    let loadedItem = LoadedUSDItem(
                        sourceURL: url,
                        entity: entity,
                        position: location
                    )
                    
                    loadedUSDItems.append(loadedItem)
                    hasNewEntities = true  // Set flag to trigger RealityView update
                    print("✅ ViewModel: Loaded and placed \(item.name) at \(location)")
                } else {
                    print("❌ ViewModel: Failed to convert USD prim to entity")
                }
            } else {
                print("❌ ViewModel: No root prims found in USD file")
            }
            
        } catch {
            print("❌ ViewModel: Failed to load USD file \(item.name): \(error)")
        }
    }

    /// Load folder as assembly (stub for now)
    private func loadAndPlaceFolderAsAssembly(_ item: NavigatorItem, at location: SIMD3<Float>) {
        print("📁 ViewModel: Folder assembly loading not yet implemented for \(item.name)")
        // TODO: Implement folder → assembly loading
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
