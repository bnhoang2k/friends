//
//  UserProfileView.swift
//  friends
//
//  Created by Bryan Hoang on 8/7/24.
//

import SwiftUI

struct UserProfileView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var svm: SocialVM
    @Binding var firstAppear: Bool
    
    var body: some View {
        ScrollView {
            userInfo
            logoutButton
        }
        .padding(.top)
        .font(.custom(GlobalVariables.shared.APP_FONT,
                      size: GlobalVariables.shared.textBody))
    }
}

extension UserProfileView {
    private var userInfo: some View {
        NavigationLink {
            SettingsView()
                .environmentObject(avm)
        } label: {
            HStack {
                ImageView(urlString: avm.user?.photoURL, pictureWidth: 50)
                VStack (alignment: .leading) {
                    Text(avm.user?.username ?? "Username Error")
                    Text(avm.user?.fullName ?? "Full Name Error")
                }
                .padding([.leading])
                Spacer()
                Image(systemName: "chevron.right")
                    .padding([.trailing])
            }
            .padding(.horizontal)
            .tint(.primary)
        }
    }
    private var logoutButton: some View {
        Button(role: .destructive) {
            Task {
                do {
                    svm.stopAllListeners()
                    try avm.signOut()
                    avm.resetFields()
                    avm.showSignInView = true
                    firstAppear = true
                } catch {
                    print("Log Out Fail")
                }
            }
        } label: {
            HStack {
                Spacer()
                Text("Log Out")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    .background(
                        RoundedRectangle(cornerRadius: GlobalVariables.shared.TEXTFIELD_RRRADIUS)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                Spacer()
            }
        }
        .buttonStyle(.borderless)
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            UserProfileView(firstAppear: .constant(false))
                .environmentObject(AuthenticationVM())
                .environmentObject(SocialVM())
        }
    }
}
