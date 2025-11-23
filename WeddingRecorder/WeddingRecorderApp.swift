//
//  WeddingRecorderApp.swift
//  WeddingRecorder
//
//  Created by Jorge on 8/2/25.
//

import SwiftUI

@main
struct WeddingRecorderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var settings = Settings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}
