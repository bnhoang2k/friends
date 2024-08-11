//
//  RootView.swift
//  friends
//
//  Created by Bryan Hoang on 8/7/24.
//

import SwiftUI

struct RootView: View {
    
    @StateObject var avm: AuthenticationVM = AuthenticationVM()
    @State private var showSignInView: Bool = false
    
    var body: some View {
        ZStack {
            NavigationStack {
                SettingsView(showSignIn: $showSignInView)
                    .environmentObject(avm)
            }
        }
        .onAppear {
            let authUser = try? AuthenticationManager.shared.getAuthenticatedUserData()
            self.showSignInView = authUser == nil
        }
        .fullScreenCover(isPresented: $showSignInView) {
            NavigationStack {
                SignInView(showSignInView: $showSignInView)
                    .environmentObject(avm)
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(avm: AuthenticationVM())
    }
}
