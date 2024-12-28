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
                Button {
                    showAddFriendView.toggle()
                } label: {
                    Image(systemName: "plus")
                }

            }
        }
        .onAppear {
            if firstAppear {
                Task {
//                    try await tvm.createClient()
                    guard let uid = avm.user?.uid else {return}
                    try await svm.loadData(uid: uid)
//                    try await PlacesManager.shared.fetchAPIKey()
                    firstAppear = false
                }
            }
        }
        .sheet(isPresented: $showAddFriendView, content: {
            SearchForFriendsView()
                .environmentObject(avm)
                .environmentObject(tvm)
                .environmentObject(svm)
        })
        .tint(.primary)
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
