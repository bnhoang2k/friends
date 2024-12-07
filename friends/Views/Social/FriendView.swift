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
    
    var body: some View {
        NavigationStack {
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
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
        .tint(.primary)
    }
}

#Preview {
    NavigationStack {
        FriendView(friend: DBUser(uid: "1"))
            .environmentObject(AuthenticationVM())
            .environmentObject(SocialVM())
    }
}
