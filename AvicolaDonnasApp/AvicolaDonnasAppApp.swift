//
//  AvicolaDonnasAppApp.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 19/05/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      FirebaseApp.configure()
      return true
  }
}

@main
struct AvicolaDonnasAppApp: App {
    // Registramos el AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
