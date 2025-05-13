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

    let friend: DBUser
    @State private var hangoutList: [HangoutReference] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(hangoutList) { ref in
                    Text(ref.title)
                }
            }
            .padding()
        }
        .onAppear {
            let uid = avm.user?.uid ?? ""
            svm.hvm.startListeningToMySummaries(uid: uid)
            svm.hvm.loadMySummariesCacheFirst(uid: uid)
            // initialize immediately if cache was already populated
            hangoutList = svm.hvm.filterHangoutByFriend(friend.uid)
        }
        .onReceive(svm.hvm.$references) { _ in
            hangoutList = svm.hvm.filterHangoutByFriend(friend.uid)
        }
    }
}
