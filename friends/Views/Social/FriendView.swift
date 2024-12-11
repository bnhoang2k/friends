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
    
    var body: some View {
        NavigationStack {
            if !hangoutList.isEmpty {
                ScrollView {
                    ForEach(hangoutList) { hangout in
                        Text(hangout.hangoutToText(userID: avm.user?.uid ?? "", cachedFriendsList: svm.cachedFriendsList))
                    }
                }
            }
            else {
                ProgressView()
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
            AddHangoutView(accessType: .fromFriend)
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
    NavigationStack {
        FriendView(friend: DBUser(uid: "1"), hangoutList: [])
            .environmentObject(AuthenticationVM())
            .environmentObject(SocialVM())
    }
}
