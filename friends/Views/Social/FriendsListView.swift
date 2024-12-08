//
//  FriendsListView.swift
//  friends
//
//  Created by Bryan Hoang on 10/11/24.
//

import SwiftUI

struct FriendsListView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var svm: SocialVM
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            SearchBar(searchText: $searchText)
            List(svm.filteredFriends(query: searchText), id: \.uid) { friend in
                NavigationLink {
                    FriendView(friend: friend)
                        .environmentObject(avm)
                        .environmentObject(svm)
                } label: {
                    UserCard(user: friend)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Friends List")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FriendsListView()
            .environmentObject(AuthenticationVM())
            .environmentObject(SocialVM())
    }
}
