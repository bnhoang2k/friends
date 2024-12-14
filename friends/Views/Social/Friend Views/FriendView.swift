//
//  FriendView.swift
//  friends
//
//  Created by Bryan Hoang on 10/19/24.
//

import SwiftUI

struct FriendView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var svm: SocialVM
    @State private var showAddHangout: Bool = false
    
    let friend: DBUser
    @State var hangoutList: [Hangout] = []
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                FriendStatisticsView(friendId: friend.uid,
                                     hangoutList: $hangoutList)
                NavigationLink {
                    HangoutListView(hangoutList: $hangoutList,
                                    searchText: $searchText)
                } label: {
                    VStack {
                        HStack {
                            Text("Your most recent hangouts")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        // Show up to five most recent hangouts
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(hangoutList.indices, id: \.self) { index in
                                    if index < 5 {
                                        HangoutCardView(hangout: hangoutList[index])
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddHangout.toggle()
                } label: {
                    Image(systemName: "plus")
                }
                
            }
        }
        .sheet(isPresented: $showAddHangout, content: {
            AddHangoutView(accessType: .fromFriend, friendID: friend.uid)
                .environmentObject(avm)
                .environmentObject(svm)
        })
        .onAppear {
            hangoutList = svm.getFilteredHangoutsByFriend(friendId: friend.uid)
        }
        .tint(.primary)
    }
}

#Preview {
    var hangoutList = Utilities.shared.generateRandomHangouts(count: 20)
    NavigationStack {
        FriendView(friend: DBUser(uid: "1"), hangoutList: hangoutList)
            .environmentObject(AuthenticationVM())
            .environmentObject(SocialVM())
    }
}
