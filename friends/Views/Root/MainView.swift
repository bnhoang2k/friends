//
//  MainView.swift
//  friends
//
//  Created by Bryan Hoang on 8/14/24.
//

import SwiftUI

struct MainView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var tvm: TypesenseVM
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: Int = 0
    @State private var firstAppear: Bool = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Friends List
            DummyListWrapped()
                .tabItem {Image(systemName: "calendar")}
                .tag(0)
            TestFunctions()
                .tabItem {Image(systemName: "wrench.and.screwdriver")}
                .tag(1)
            UserProfileView(firstAppear: $firstAppear)
                .environmentObject(avm)
                .tabItem { Image(systemName: "person.crop.circle") }
                .tag(2)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SearchBarView()
                        .environmentObject(tvm)
                        .environmentObject(avm)
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    Text("Notifications")
                } label: {
                    Image(systemName: "tray")
//                        .padding(.trailing)
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
        .task {
            if !firstAppear {
                do {
                    try await avm.loadCurrentUser()
                    avm.getAuthProviders()
                    try await tvm.createClient()
                }
                catch {}
                firstAppear = true
            }
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
                .environmentObject(TypesenseVM())
        }
    }
}
