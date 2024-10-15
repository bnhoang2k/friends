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
    @EnvironmentObject private var svm: SocialViewModel
    
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var searchText: String = ""
    @State private var showAddFriendView: Bool = false
    
    @State private var friendsList: [Friend] = []
    
    var filteredData: [Friend] {
        if searchText.isEmpty {
            return friendsList
        } else {
            return friendsList.filter { friend in
                friend.fullName?.localizedCaseInsensitiveContains(searchText) == true ||
                friend.username?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredData, id: \.uid) { friend in
                HStack {
                    if let photoURL = friend.photoURL, let url = URL(string: photoURL) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 40, height: 40)
                    }
                    
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
        .onAppear {
            if friendsList.isEmpty {
                friendsList = svm.cachedFriendsList
                print(friendsList)
                print(svm.cachedFriendsList)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FriendsListView()
            .environmentObject(AuthenticationVM())
            .environmentObject(TypesenseVM())
            .environmentObject(SocialViewModel())
    }
}
