//
//  CIDemoApp.swift
//  CIDemo
//
//  Created by Ahmed on 18/05/2026.
//

import SwiftUI

@main
struct CIDemoApp: App {
    init() {
        #if DEV
        print("DEV")
        #endif
        
        #if DEBUG
        print("DEBUG")
        #endif
        
        #if RELEASE
        print("RELEASE")
        #endif
    }
    var body: some Scene {
        WindowGroup {
            
            ContentView()
        }
    }
}
