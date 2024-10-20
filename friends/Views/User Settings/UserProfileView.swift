//
//  UserProfileView.swift
//  friends
//
//  Created by Bryan Hoang on 8/7/24.
//

import SwiftUI

struct UserProfileView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var tvm: TypesenseVM
    @EnvironmentObject private var svm: SocialVM
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAddFriendView: Bool = false
    @Binding var firstAppear: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10, pinnedViews: [.sectionHeaders]) {
                Section(header: HeaderView(headerText: "User Information")) {
                    userInfo
                }
                addFriendButton
                logoutButton
            }
        }
        .font(.custom(GlobalVariables.shared.APP_FONT, size: GlobalVariables.shared.textBody))
        .navigationTitle("User Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddFriendView, content: {
            SearchBarView()
                .environmentObject(avm)
                .environmentObject(tvm)
                .environmentObject(svm)
        })
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
            .tint(colorScheme == .dark ? Color.white : Color.black)
        }
    }
    private var addFriendButton: some View {
        Button {
            showAddFriendView.toggle()
        } label: {
            HStack {
                Spacer()
                Text("Add Friend")
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
    private var logoutButton: some View {
        Button(role: .destructive) {
            Task {
                do {
                    svm.stopAllListeners()
                    try avm.signOut()
                    avm.resetFields()
                    avm.showSignInView = true
                    firstAppear = false
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
                .environmentObject(TypesenseVM())
                .environmentObject(SocialVM())
        }
    }
}
