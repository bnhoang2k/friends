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
    @EnvironmentObject private var svm: SocialVM

    @State private var selectedTab: Int = 0
    @State private var firstAppear: Bool = false
    @State private var showAddHangout: Bool = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Friends List
            FriendsListView()
                .environmentObject(svm)
                .tabItem {Image(systemName: "calendar")}
                .tag(0)
            NotificationsView()
                .environmentObject(svm)
                .tabItem{Image(systemName: "tray")}
                .tag(1)
            UserProfileView(firstAppear: $firstAppear)
                .environmentObject(avm)
                .environmentObject(svm)
                .tabItem { Image(systemName: "person.crop.circle") }
                .tag(2)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("friends")
                    .font(.custom(GlobalVariables.shared.APP_FONT, size: 25, relativeTo: .largeTitle))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddHangout.toggle()
                } label: {
                    Image(systemName: "plus")
                }

            }
        }
        .onAppear {
            customizeAppearance()
        }
        .sheet(isPresented: $showAddHangout, content: {
            AddHangoutView()
        })
        .tint(.primary)
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
                .environmentObject(SocialVM())
        }
    }
}
