//
//  MainView.swift
//  friends
//
//  Created by Bryan Hoang on 8/14/24.
//

import SwiftUI

struct MainView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @State private var selectedTab: Int = 0
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        
        appearance.shadowImage = UIImage()
        appearance.backgroundColor = UIColor.white
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            EventsView()
                .tabItem {
                    Image(systemName: "calendar")
                }
                .tag(0)
            MapView()
                .tabItem {
                    Image(systemName: "map")
                }
                .tag(1)
            UserProfileView()
                .tabItem {
                    Image(systemName: "person")
                }
                .tag(2)
        }
        .foregroundColor(.primary)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MainView()
                .environmentObject(AuthenticationVM())
        }
    }
}
