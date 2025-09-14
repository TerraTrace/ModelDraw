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

    
    var body: some Scene {
        
        DocumentGroup(newDocument: ModelDrawDocument()) { file in
            ContentView(document: file.$document)
                .environment(model)
        }
    }
    
    

    
}
