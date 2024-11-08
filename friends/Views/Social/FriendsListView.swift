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
            TextField("Search friends", text: $searchText)
                .multilineTextAlignment(.center)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                    }
                )
                .font(.custom(GlobalVariables.shared.APP_FONT, size: GlobalVariables.shared.textBody, relativeTo: .headline))
                .padding(.horizontal)
                .padding(.top)
            List(svm.filteredFriends(query: searchText), id: \.uid) { friend in
                NavigationLink {
                    FriendView(friend: friend)
                        .environmentObject(svm)
                } label: {
                    HStack {
                        ImageView(urlString: friend.photoURL, pictureWidth: 40)
                        VStack(alignment: .leading) {
                            Text(friend.fullName ?? "Unknown Name")
                                .font(.custom(GlobalVariables.shared.APP_FONT, size: GlobalVariables.shared.textBody, relativeTo: .headline))
                            Text(friend.username ?? "@unknown")
                                .font(.custom(GlobalVariables.shared.APP_FONT, size: GlobalVariables.shared.textBody, relativeTo: .subheadline))
                                .foregroundColor(.secondary)
                        }
                    }
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
            .environmentObject(SocialVM())
    }
}
