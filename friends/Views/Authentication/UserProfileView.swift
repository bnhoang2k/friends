//
//  UserProfileView.swift
//  friends
//
//  Created by Bryan Hoang on 8/7/24.
//

import SwiftUI

struct UserProfileView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    
    var body: some View {
        NavigationStack {
            List {
                Section{
                    userInfo
                }
                Section{
                    logoutButton
                }
            }
            .padding(.top, 1) // Prevents scroll past camera
            .listRowInsets(EdgeInsets())
//            .scrollContentBackground(.hidden)
            .listStyle(.grouped)
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
        }
    }
    private var logoutButton: some View {
        Button(role: .destructive) {
            Task {
                do {
                    try avm.signOut()
                    avm.showSignInView = true
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
            .padding([.top, .bottom], 5)
        }
        .buttonStyle(.borderless)
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            UserProfileView()
                .environmentObject(AuthenticationVM())
        }
    }
}
