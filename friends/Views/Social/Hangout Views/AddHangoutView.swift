//
//  AddHangoutView.swift
//  friends
//
//  Created by Bryan Hoang on 10/16/24.
//

import SwiftUI

struct AddHangoutView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var svm: SocialVM
    
    var friendID: String? = nil
    
    @StateObject private var vvm: VertexViewModel = VertexViewModel()
    @State private var hangout: Hangout = Hangout.defaultHangout()
    @State private var searchText: String = ""
    
    @State var selectedTab: Int = 0
    
    var body: some View {
        NavigationStack {
            FormView(hangout: $hangout)
                .environmentObject(vvm)
                .navigationTitle("Add Hangout")
                .navigationBarTitleDisplayMode(.inline)
                .padding(.top)
                .tint(.primary)
                .onAppear {
                    // Add yourself and friend to the hangout
                    if let user = avm.user {
                        if !hangout.participantIds.contains(user.uid) {
                            hangout.participantIds.append(user.uid)
                        }
                    }
                    hangout.participantIds.append(friendID ?? "ERROR")
                }
        }
    }
}

#Preview {
    AddHangoutView()
        .environmentObject(AuthenticationVM())
        .environmentObject(SocialVM())
}
