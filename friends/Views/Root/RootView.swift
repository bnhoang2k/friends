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
        VStack {
            if showSignInView {
                SignInView(showSignInView: $showSignInView)
                    .environmentObject(avm)
            }
            else {
                SettingsView(showSignIn: $showSignInView)
                    .environmentObject(avm)
            }
        }
        .animation(.easeIn, value: showSignInView)
    }
}

extension RootView {
    static func == (lhs: RootView, rhs: RootView) -> Bool {
        return lhs.showSignInView == rhs.showSignInView
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(avm: AuthenticationVM())
    }
}
