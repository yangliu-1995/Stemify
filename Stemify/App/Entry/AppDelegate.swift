//
//  AppDelegate.swift
//  Stemify
//
//  Created by XueyuanXiao on 2025/8/28.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if connectingSceneSession.role == .windowApplication {
            return UISceneConfiguration(name: "Default", sessionRole: .windowApplication)
        }
        return connectingSceneSession.configuration
    }
}
