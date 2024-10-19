//
//  FriendView.swift
//  friends
//
//  Created by Bryan Hoang on 10/19/24.
//

import SwiftUI

struct FriendView: View {
    
    @EnvironmentObject private var svm: SocialVM
    @State private var showAddHangout: Bool = false
    
    let friend: Friend
    
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
            AddHangoutView()
                .environmentObject(svm)
        })
        .tint(.primary)
    }
}

#Preview {
    NavigationStack {
        FriendView(friend: Friend(uid: "1",
                                  timestamp: Date(),
                                  photoURL: "",
                                  fullName: "John Doe",
                                  username: "johndoe"))
            .environmentObject(SocialVM())
    }
}
