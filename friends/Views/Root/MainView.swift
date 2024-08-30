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
    
    // Customize toolbar and tab bar.
    init() {
        // Customize Tab Bar Appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor.white
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        
        // Customize Navigation Bar Appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor.white
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DummyListWrapped()
                .tabItem {Image(systemName: "calendar")}
                .tag(0)
            TestFunctions()
                .tabItem {Image(systemName: "wrench.and.screwdriver")}
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    Text("bruh")
                } label: {
                    Image(systemName: "magnifyingglass")
                }

            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    UserProfileView().environmentObject(avm)
                } label: {
                    // TODO: Display User Picture Instead
                    Image(systemName: "person.fill")
                        .padding([.trailing])
                }
            }
        }
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
