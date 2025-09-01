//
//  StemifyApp.swift
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/27.
//

import SwiftUI

@main
struct StemifyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    private var cardCornerRadius: CGFloat {
        if #available(iOS 26.0, *) {
            return 24
        } else {
            return 12
        }
    }
    
    // Main entry point for the app
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.cardCornerRadius, cardCornerRadius)
        }
    }
}
