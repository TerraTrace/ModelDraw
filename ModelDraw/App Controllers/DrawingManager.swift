//
//  DrawingManager.swift
//  ModelDraw
//
//  Singleton for managing ModelDraw projects, library components, and file system operations
//  Handles the three-tier hierarchy: Project → Configuration → Assembly
//

import Foundation


// MARK: - Error Types
enum DrawingManagerError: Error, LocalizedError {
    case projectAlreadyExists(name: String)
    case templateNotFound(name: String)
    case configurationNotFound(path: String)
    case missingLibraryComponent(path: String)
    case invalidProjectFile(path: String)
    case corruptedData(description: String)
    
    var errorDescription: String? {
        switch self {
        case .projectAlreadyExists(let name):
            return "Project '\(name)' already exists"
        case .templateNotFound(let name):
            return "Template '\(name)' not found"
        case .configurationNotFound(let path):
            return "Configuration not found at '\(path)'"
        case .missingLibraryComponent(let path):
            return "Library component not found at '\(path)'"
        case .invalidProjectFile(let path):
            return "Invalid project file at '\(path)'"
        case .corruptedData(let description):
            return "Corrupted data: \(description)"
        }
    }
}



/// Singleton manager for ModelDraw project file system operations.
/// Handles project discovery, loading, library component resolution, and template-based project creation.
/// Manages the three-tier hierarchy: Project → Configuration → Assembly with library component references.
class DrawingManager {
    static let shared = DrawingManager()
    private init() {}
    
    private let fileManager = FileManager.default
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var modelDrawURL: URL {
        documentsURL.appendingPathComponent("ModelDraw")
    }
    
    // MARK: - Directory Structure
    private var projectsURL: URL { modelDrawURL.appendingPathComponent("Projects") }
    private var libraryURL: URL { modelDrawURL.appendingPathComponent("Library") }
    private var templatesURL: URL { modelDrawURL.appendingPathComponent("Templates") }
    
    // MARK: - Current State
    private var currentProjectURL: URL?
    
    // MARK: - Initialization
    func initializeAppDirectories() throws {
        // Create main ModelDraw directory structure
        try fileManager.createDirectory(at: projectsURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: libraryURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: templatesURL, withIntermediateDirectories: true)
        
        // Create basic library structure
        try createInitialLibraryStructure()
        
        // Create basic template
        try createInitialTemplate()
        
        print("📁 DrawingManager: Initialized directory structure at \(modelDrawURL.path)")
    }
    
    private func createInitialLibraryStructure() throws {
        let standardComponents = libraryURL.appendingPathComponent("Standard-Components")
        let commonAssemblies = libraryURL.appendingPathComponent("Common-Assemblies")
        
        try fileManager.createDirectory(at: standardComponents, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: commonAssemblies, withIntermediateDirectories: true)
        
        // Add a README
        let readmeContent = """
        # ModelDraw Component Library
        
        This directory contains reusable spacecraft components and assemblies.
        
        ## Structure
        - Standard-Components/: Individual components (thrusters, reaction wheels, etc.)
        - Common-Assemblies/: Complete subsystem assemblies
        
        ## Usage
        Components in this library can be referenced by projects without copying.
        Updates to library components will affect all projects that reference them.
        """
        
        let readmeURL = libraryURL.appendingPathComponent("README.md")
        try readmeContent.write(to: readmeURL, atomically: true, encoding: .utf8)
    }
    
    private func createInitialTemplate() throws {

    }
    
    // MARK: - Project Discovery
    func scanProjectsDirectory() throws -> [ProjectInfo] {
        guard fileManager.fileExists(atPath: projectsURL.path) else {
            try initializeAppDirectories()
            return []
        }
        
        let projectFolders = try fileManager.contentsOfDirectory(at: projectsURL, includingPropertiesForKeys: [.isDirectoryKey])
        var projects: [ProjectInfo] = []
        
        for folderURL in projectFolders {
            if try folderURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true {
                if let projectInfo = try loadProjectInfo(from: folderURL) {
                    projects.append(projectInfo)
                }
            }
        }
        
        return projects.sorted { $0.name < $1.name }
    }
    
    private func loadProjectInfo(from folderURL: URL) throws -> ProjectInfo? {
        // Look for .project file in folder
        let folderName = folderURL.lastPathComponent
        let projectFileName = folderName.replacingOccurrences(of: " ", with: "_") + ".project"
        let projectFileURL = folderURL.appendingPathComponent(projectFileName)
        
        guard fileManager.fileExists(atPath: projectFileURL.path) else {
            print("⚠️ DrawingManager: No .project file found in \(folderName)")
            return nil
        }
        
        let projectFile = try loadProjectFile(from: projectFileURL)
        return ProjectInfo(
            name: projectFile.metadata.name,
            folderURL: folderURL,
            projectFileURL: projectFileURL,
            lastModified: try projectFileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date()
        )
    }
    
    
    // MARK: - Project Loading (Updated for Flexibility)
    func loadProject(from projectInfo: ProjectInfo) throws {

 
    }
    
    private func loadConfiguration(from configURL: URL) throws  {

    }

    
    private func scanAssemblyHierarchy(_ folderURL: URL) throws  {
    }
    
    // MARK: - Library Component Resolution
    func resolveLibraryComponent(at path: String) throws  {

    }
    



// MARK: - ??

extension DrawingManager {

 
    

}


