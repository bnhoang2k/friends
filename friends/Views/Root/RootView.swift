//
//  RootView.swift
//  friends
//
//  Created by Bryan Hoang on 8/7/24.
//

import SwiftUI

struct RootView: View {
    
    @StateObject var avm: AuthenticationVM = AuthenticationVM()
    @State private var isLoading: Bool = true
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            }
            else {
                if avm.showSignInView {
                    SignInView(showSignInView: $avm.showSignInView)
                        .environmentObject(avm)
                }
                else if avm.showGetInformationView {
                    GetInformationView()
                        .environmentObject(avm)
                }
                else {
                    SettingsView()
                }
            }
        }
        .task {
            do {
                try await avm.loadCurrentUser()
                avm.getAuthProviders()
                avm.showSignInView = (avm.user == nil)
            } catch {
                print("RootView Error Loading User: \(error)")
            }
            isLoading = false
        }
        .animation(.easeIn, value: avm.showSignInView)
    }
}

extension RootView {
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(avm: AuthenticationVM())
    }
}
