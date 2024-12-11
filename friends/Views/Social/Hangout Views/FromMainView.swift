//
//  FromMainView.swift
//  friends
//
//  Created by Bryan Hoang on 11/9/24.
//

import SwiftUI

struct FromMainView: View {
    @EnvironmentObject private var svm: SocialVM
    @Binding var searchText: String
    @Binding var hangout: Hangout
    
    var body: some View {
        VStack {
            SearchBar(searchText: $searchText)
            if !searchText.isEmpty {
                List(svm.filteredFriends(query: searchText, returnEmptyIfNoQuery: true), id: \ .uid) { friend in
                    HStack {
                        UserCard(user: friend)
                        Spacer()
                        Image(systemName: hangout.participantIds.contains(friend.uid) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(hangout.participantIds.contains(friend.uid) ? .blue : .gray)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring()) {
                            if let index = hangout.participantIds.firstIndex(of: friend.uid) {
                                hangout.participantIds.remove(at: index)
                            } else {
                                hangout.participantIds.append(friend.uid)
                            }
                        }
                    }
                }.listStyle(.plain)
                SelectedFriendsView(participantIds: $hangout.participantIds)
                    .environmentObject(svm)
                    .padding([.horizontal, .bottom])
            }
            Spacer()
        }
    }
}

struct SelectedFriendsView: View {
    @Binding var participantIds: [String]
    @EnvironmentObject var svm: SocialVM
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(participantIds, id: \.self) { participantId in
                    if let friend = svm.getFriendFromID(participantId) {
                        HStack {
                            UserCard(user: friend, showUsername: false)
                            Button(action: {
                                withAnimation(.spring()) {
                                    if let index = participantIds.firstIndex(of: participantId) {
                                        participantIds.remove(at: index)
                                    }
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray5)))
                    }
                }
            }
        }
    }
}
