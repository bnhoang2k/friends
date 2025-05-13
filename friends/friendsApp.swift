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
        
        let settings = FirestoreSettings()
        settings.cacheSettings = MemoryCacheSettings(garbageCollectorSettings: MemoryLRUGCSettings())
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: FirestoreCacheSizeUnlimited as NSNumber)
        Firestore.firestore().settings = settings
        
        customizeAppearance()
        return true
    }
    private func customizeAppearance() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }
}

@main
struct friendsApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var avm: AuthenticationVM = AuthenticationVM()
    @StateObject private var tvm: TypesenseVM = TypesenseVM()
    @StateObject private var svm: SocialVM = SocialVM()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(avm)
                .environmentObject(tvm)
                .environmentObject(svm)
        }
    }
}

struct Previews_friendsApp_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
