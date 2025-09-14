//
//  ProjectManager.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/14/25.
//

import SwiftUI

enum ProjectError: Error {
    case noProjectLoaded
}


class ProjectManager {
    static let shared = ProjectManager()
    private init() {}
    
    private let fileManager = FileManager.default
    private var currentProjectURL: URL?
    
    func loadProject(from folderURL: URL) throws -> (assemblies: [Assembly], primitives: [GeometricPrimitive]) {
        currentProjectURL = folderURL
        // Scan folder structure and load .modeldraw files
        return scanProjectHierarchy(folderURL)
    }
    
    func saveProject(_ assemblies: [Assembly], _ primitives: [GeometricPrimitive]) throws {
        guard let projectURL = currentProjectURL else { throw ProjectError.noProjectLoaded }
        // Write assembly and primitive files to appropriate folders
    }
    
    private func scanProjectHierarchy(_ rootURL: URL) throws -> (assemblies: [Assembly], primitives: [GeometricPrimitive]) {
        // Recursively scan folders looking for {FolderName}.modeldraw files
        // Build assembly hierarchy based on folder structure
    }
}
