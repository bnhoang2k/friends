//
//  FriendsListView.swift
//  friends
//
//  Created by Bryan Hoang on 10/11/24.
//

import SwiftUI

struct FriendsListView: View {
    
    @EnvironmentObject private var svm: SocialVM
    
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            List(svm.filteredFriends(query: searchText), id: \.uid) { friend in
                NavigationLink {
                    FriendView(friend: friend)
                        .environmentObject(svm)
                } label: {
                    HStack {
                        ImageView(urlString: friend.photoURL, pictureWidth: 40)
                        VStack(alignment: .leading) {
                            Text(friend.fullName ?? "Unknown Name")
                                .font(.headline)
                            Text(friend.username ?? "@unknown")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText,
                        placement: .navigationBarDrawer(displayMode: .automatic),
                        prompt: "Search friends")
        }
        .navigationTitle("Friends List")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FriendsListView()
            .environmentObject(SocialVM())
    }
}
