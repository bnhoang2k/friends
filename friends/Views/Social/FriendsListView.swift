//
//  FriendsListView.swift
//  friends
//
//  Created by Bryan Hoang on 10/11/24.
//

import SwiftUI

struct FriendsListView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var tvm: TypesenseVM
    @EnvironmentObject private var svm: SocialVM
    
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var searchText: String = ""
    @State private var showAddFriendView: Bool = false
    
    var filteredData: [Friend] {
        if searchText.isEmpty {
            return svm.cachedFriendsList
        } else {
            return svm.cachedFriendsList.filter { friend in
                friend.fullName?.localizedCaseInsensitiveContains(searchText) == true ||
                friend.username?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredData, id: \.uid) { friend in
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
            .listStyle(.plain)
            .searchable(text: $searchText,
                        placement: .navigationBarDrawer(displayMode: .automatic),
                        prompt: "Search friends")
        }
        .navigationTitle("Friends List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddFriendView.toggle()
                } label: {
                    Image(systemName: "plus")
                        .resizable()
                        .font(.callout)
                        .tint(.primary)
                }
            }
        }
        .sheet(isPresented: $showAddFriendView, content: {
            SearchBarView()
                .environmentObject(avm)
                .environmentObject(tvm)
                .environmentObject(svm)
        })
    }
}

#Preview {
    NavigationStack {
        FriendsListView()
            .environmentObject(AuthenticationVM())
            .environmentObject(TypesenseVM())
            .environmentObject(SocialVM())
    }
}
