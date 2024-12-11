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
    @State private var firstAppear: Bool = true
    @State private var showAddFriendView: Bool = false
    @State private var showAddHangoutView: Bool = false
    
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
                    .font(.custom(GlobalVariables.shared.APP_FONT,
                                  size: GlobalVariables.shared.textHeader))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: {
                        showAddHangoutView.toggle()
                    }) {
                        Label("Add Hangout", systemImage: "person.3.fill")
                    }
                    Button(action: {
                        showAddFriendView.toggle()
                    }) {
                        Label("Add Friend", systemImage: "person.crop.circle.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            customizeAppearance()
            if firstAppear {
                Task {
                    try await tvm.createClient()
                    guard let uid = avm.user?.uid else {return}
                    try await svm.loadData(uid: uid)
                    firstAppear = false
                }
            }
        }
        .sheet(isPresented: $showAddHangoutView, content: {
            AddHangoutView(accessType: .fromMain)
                .environmentObject(avm)
                .environmentObject(svm)
                .presentationDragIndicator(.visible)
        })
        .sheet(isPresented: $showAddFriendView, content: {
            SearchBarView()
                .environmentObject(avm)
                .environmentObject(tvm)
                .environmentObject(svm)
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
