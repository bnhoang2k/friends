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
    
    let accessType: AccessType
    
    @StateObject private var vvm: VertexViewModel = VertexViewModel()
    @State private var hangout: Hangout = Hangout.defaultHangout()
    @State private var searchText: String = ""
    
    @State var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            if accessType == .fromMain {
                FromMainView(searchText: $searchText, hangout: $hangout)
                    .environmentObject(svm)
                    .tag(0)
            }
            FormView(hangout: $hangout, selectedTab: $selectedTab)
                .environmentObject(avm)
                .environmentObject(svm)
                .tag(1)
            GenerateLocationsView(vvm: vvm, hangout: $hangout)
                .tag(2)
        }
        .padding(.top)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .tint(.primary)
        .onAppear {
            // Add yourself to the hangout
            if let user = avm.user {
                if !hangout.participantIds.contains(user.uid) {
                    hangout.participantIds.append(user.uid)
                }
            }
        }
    }
}

extension AddHangoutView {
    enum AccessType {
        case fromMain
        case fromFriend
    }
}

#Preview {
    AddHangoutView(accessType: .fromFriend)
        .environmentObject(AuthenticationVM())
        .environmentObject(SocialVM())
}
