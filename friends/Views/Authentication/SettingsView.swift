//
//  SettingsView.swift
//  friends
//
//  Created by Bryan Hoang on 8/7/24.
//

import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @StateObject private var upvm: UserProfileVM = UserProfileVM()
    @Binding var showSignIn: Bool
    
    var body: some View {
        NavigationStack {
            List {
                Section {userInfo}
                if upvm.authProviders.contains(.email) {
                    changeEmail
                    // TODO: Add changePassword.
                }
                Section {logoutButton}
                Section {deleteUserButton}
            }
            .listStyle(.insetGrouped)
        }
        .onAppear {
            upvm.getAuthProviders()
            upvm.resetFields()
        }
    }
}

extension SettingsView {
    private var userInfo: some View {
        HStack {
            Image(systemName: "person.circle")
                .resizable()
                .scaledToFit()
                .frame(width: GlobalVariables.shared.PROFILE_PICTUREWIDTH)
        }
    }
    private var deleteUserButton: some View {
        Button(role: .destructive) {
            Task {
                do {
                    try await upvm.deleteUser()
                    showSignIn = true
                } catch {
                    // TODO: Create actualy errors.
                    print("SettingsView: \(error)")
                }
            }
        } label: {
            HStack {
                Spacer()
                Text("Delete Account")
                Spacer()
            }
        }
    }
    private var logoutButton: some View {
        Button(role: .destructive) {
            Task {
                do {
                    try avm.signOut()
                    showSignIn = true
                } catch {
                    // TODO: Create actualy errors.
                    print("SettingsView: \(error)")
                }
            }
        } label: {
            HStack {
                Spacer()
                Text("Log Out")
                Spacer()
            }
        }
    }
    private var changeEmail: some View {
        NavigationLink {
            changeEmailView(newEmail: $upvm.string1, pwd: $upvm.string2)
                .navigationTitle("Change Email")
        } label: {
            HStack {
                Label("Email",
                      systemImage: "envelope")
                Spacer()
            }
        }
        
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(showSignIn: .constant(true))
            .environmentObject(AuthenticationVM())
    }
}
