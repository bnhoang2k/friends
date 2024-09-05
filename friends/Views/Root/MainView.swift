//
//  MainView.swift
//  friends
//
//  Created by Bryan Hoang on 8/14/24.
//

import SwiftUI

struct MainView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: Int = 0
    
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
                    ImageView(urlString: avm.user?.photoURL, pictureWidth: 25)
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Text("friends")
                    .font(.custom(GlobalVariables.shared.APP_FONT, size: 35, relativeTo: .largeTitle))
            }
        }
        .onAppear {
            customizeAppearance()
        }
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

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MainView()
                .environmentObject(AuthenticationVM())
        }
    }
}
