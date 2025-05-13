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
            VStack {
                SearchBar(placeholderText: "Search Friends", searchText: $searchText)
                List(svm.fvm.filteredFriends(query: searchText), id: \.uid) { friend in
                    NavigationLink {
                        FriendView(friend: friend)
                    } label: {
                        UserCard(user: friend)
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
            .padding()
        }
        .navigationTitle("Friends List")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FriendsListView()
    }
}
