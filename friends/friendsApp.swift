//
//  friendsApp.swift
//  friends
//
//  Created by Bryan Hoang on 6/5/24.
//

import SwiftUI
import Firebase

// Some functions in Firebase require appDelegate even though SwiftUI doesn't need it.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct friendsApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct Previews_friendsApp_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
