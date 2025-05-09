//
//  RootView.swift
//  friends
//
//  Created by Bryan Hoang on 8/7/24.
//

import SwiftUI

struct RootView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var tvm: TypesenseVM
    @EnvironmentObject private var svm: SocialVM
    @State var isLoading: Bool = true
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .task {
                        // TODO: Need to implement cache and make this better.
                        do {
                            // Load user data.
                            try await avm.loadCurrentUser()
                            avm.getAuthProviders()
                            
                            // Load client if user was already signed in.
                            if (avm.user != nil) {
//                                try await tvm.createClient()
                                guard let uid = avm.user?.uid else {return}
                                try await svm.loadData(uid: uid)
                            }
//                            try await PlacesManager.shared.fetchAPIKey()
                            // Load screen after everything is done and complete
                            avm.showSignInView = (avm.user == nil)
                        } catch {
                            print("RootView Error Loading User: \(error)")
                        }
                        isLoading = false
                    }
            }
            else {
                if avm.showSignInView {
                    NavigationStack {
                        SignInView(showSignInView: $avm.showSignInView)
                    }
                }
                else if avm.showGetInformationView {
                    GetInformationView()
                }
                else {
                    NavigationStack {
                        MainView()
                    }
                }
            }
        }
        .animation(.easeIn, value: avm.showSignInView)
        .animation(.easeIn, value: avm.showGetInformationView)
    }
}

extension RootView {
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
