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
    @StateObject private var svm: SocialViewModel = SocialViewModel()

    @State private var selectedTab: Int = 0
    @State private var firstAppear: Bool = false
    @State private var showAddHangout: Bool = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Friends List
            DummyListWrapped()
                .tabItem {Image(systemName: "calendar")}
                .tag(0)
//            TestFunctions()
//                .tabItem {Image(systemName: "wrench.and.screwdriver")}
//                .tag(1)
            NotificationsView()
                .environmentObject(svm)
                .tabItem{Image(systemName: "tray")}
            UserProfileView(firstAppear: $firstAppear)
                .environmentObject(avm)
                .tabItem { Image(systemName: "person.crop.circle") }
                .tag(2)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("friends")
                    .font(.custom(GlobalVariables.shared.APP_FONT, size: 25, relativeTo: .largeTitle))
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    FriendsListView()
                        .environmentObject(avm)
                        .environmentObject(tvm)
                        .environmentObject(svm)
                } label: {
                    Image(systemName: "person.2.fill")
                        .scaleEffect(x: -1, y: 1)
                }
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
        .task {
            if !firstAppear {
                do {
                    try await avm.loadCurrentUser()
                    avm.getAuthProviders()
                    try await tvm.createClient()
                    guard let uid = avm.user?.uid else {
                        throw AuthError.noUserSignedIn
                    }
                    svm.listenForNotificationChanges(uid: uid)
                    svm.listenForFriendsListChanges(uid: uid)
                    svm.listenForPendingFriendRequests(uid: uid)
                    try await svm.fetchNotifications(uid: uid)
                    try await svm.fetchPendingFR(uid: uid)
                    try await svm.fetchFriendsList(uid: uid)
                }
                catch {}
                firstAppear = true
            }
        }
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
        }
    }
}
