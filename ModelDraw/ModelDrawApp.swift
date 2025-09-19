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
            //testUSDFileManager()
            //testUSDOrientedSpacecraft()
            //testUSDCone()
            //testUSDSpacecraftAssembly()
            //testFullPrimParsing()
            //testSpacecraftAssemblyParsing()
            //testAttributeParsingDebug()
            //testSimpleSpacecraftParsing()
            //testSimpleSpacecraftBlockExtraction()
            //testUSDReadWriteCycle()
            //try USDFileManager.testUSDReferenceParsingCargoDragon()
            
        } catch {
            print("❌ Failed to initialize DrawingManager: \(error)")
            // Could add additional error handling here if needed
        }
    }
    
    var body: some Scene {
        
        WindowGroup {
            ContentView()
                .environment(model)
        }
    }
    
    

    
}
