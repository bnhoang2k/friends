//
//  UserProfileView.swift
//  friends
//
//  Created by Bryan Hoang on 8/7/24.
//

import SwiftUI

struct UserProfileView: View {
    
    @StateObject var upvm: UserProfileVM = UserProfileVM()
    @Binding var showSignInView: Bool
    
    var body: some View {
        NavigationStack {
            List {
                userInfo
            }
            .task {
                try? await upvm.loadCurrentUser()
                upvm.resetFields()
            }
        }
    }
}

extension UserProfileView {
    private var userInfo: some View {
        NavigationLink {
            SettingsView(showSignIn: $showSignInView)
                .environmentObject(AuthenticationVM())
        } label: {
            HStack {
                Image(systemName: "person.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: GlobalVariables.shared.PROFILE_PICTUREWIDTH)
                Text(upvm.user?.email ?? "")
                Spacer()
            }
        }
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(showSignInView: .constant(false))
    }
}
