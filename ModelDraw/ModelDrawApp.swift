//
//  ModelDrawApp.swift
//  ModelDraw
//
//  Created by Mike Raftery on 9/12/25.
//

import SwiftUI

@main
struct ModelDrawApp: App {
    
    @State private var model = ViewModel()
    private let drawingManager = DrawingManager.shared

    init() {
        // Initialize DrawingManager directory structure on app launch
        do {
            try drawingManager.initializeAppDirectories()
            
            // Test project discovery
            let projects = try DrawingManager.shared.scanProjectsDirectory()
            print("📁 Found \(projects.count) projects:")
            for project in projects {
                print("  - \(project.name) at \(project.folderURL.lastPathComponent)")
            }

        } catch {
            print("❌ Failed to initialize DrawingManager: \(error)")
            // Could add additional error handling here if needed
        }
    }
    
    var body: some Scene {
        
        WindowGroup {
            ContentView(document: <#Binding<ModelDrawDocument>#>)
                .environment(model)
        }
        
        /*DocumentGroup(newDocument: ModelDrawDocument()) { file in
            ContentView(document: file.$document)
                .environment(model)
        } */
    }
    
    

    
}
