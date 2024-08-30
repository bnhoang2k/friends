//
//  UserProfileView.swift
//  friends
//
//  Created by Bryan Hoang on 8/7/24.
//

import SwiftUI

struct UserProfileView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @Environment(\.colorScheme) private var colorScheme
    @State var isLoading: Bool = true
    
    var body: some View {
        if isLoading {
            ProgressView()
                .task {
                    isLoading = true
                    do {
                        try await avm.loadCurrentUser()
                        isLoading = false
                    } catch {
                        print("Error refreshing user information.")
                        isLoading = true
                    }
                }
        }
        else {
            List {
                Section {
                    userInfo
                }
                Section {
                    logoutButton
                }
            }
            .font(.custom(GlobalVariables.shared.APP_FONT, size: GlobalVariables.shared.textBody))
            .listRowInsets(EdgeInsets())
            .listStyle(.grouped )
            .navigationTitle("User Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension UserProfileView {
    private var userInfo: some View {
        NavigationLink {
            SettingsView()
                .environmentObject(avm)
        } label: {
            HStack {
                // TODO: Change to actual profile
                Image(systemName: "person.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: GlobalVariables.shared.PROFILE_PICTUREWIDTH)
                VStack (alignment: .leading) {
                    Text(avm.user?.username ?? "Username Error")
                    Text(avm.user?.fullName ?? "Full Name Error")
                }
                .padding([.leading])
                Spacer()
            }
            .foregroundStyle(.black)
        }
    }
    private var logoutButton: some View {
        Button(role: .destructive) {
            Task {
                do {
                    try avm.signOut()
                    avm.resetFields()
                    avm.showSignInView = true
                    print(avm.showSignInView)
                } catch {
                    print("Log Out Fail")
                }
            }
        } label: {
            HStack {
                Spacer()
                Text("Log Out")
                Spacer()
            }
            .padding(10)
        }
        .buttonStyle(.borderless)
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            UserProfileView(isLoading: false)
                .environmentObject(AuthenticationVM())
        }
    }
}
