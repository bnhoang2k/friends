//
//  GetInformationView.swift
//  friends
//
//  Created by Bryan Hoang on 8/13/24.
//

import SwiftUI

struct GetInformationView: View {
    @EnvironmentObject var avm: AuthenticationVM
    @EnvironmentObject var tvm: TypesenseVM
    @EnvironmentObject var svm: SocialViewModel
    @State private var fullName: String = ""
    @State private var username: String = ""
    
    private var fontSize: CGFloat = 15
    
    private var isValid: Bool {
        // TODO: Add functionality to detect if username is already picked or not.
        !fullName.isEmpty &&
        !username.isEmpty
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text("It looks like it's your first time logging in. Please write your full name and pick a username.")
                .font(.custom(GlobalVariables.shared.APP_FONT, size: 15))
            CustomTF(filler_text: "Full Name", size: fontSize, text_binding: $fullName)
            CustomTF(filler_text: "Username", size: fontSize,text_binding: $username)
            okButton
            Spacer()
            Spacer()
        }
        .padding([.trailing, .leading])
    }
}

extension GetInformationView {
    private var okButton: some View {
        Button {
            Task {
                do {
                    try await avm.setUpProfile(username: username, fullName: fullName)
                    avm.showGetInformationView = false
                    try await avm.loadCurrentUser()
                    avm.getAuthProviders()
                    try await tvm.createClient()
                    guard let uid = avm.user?.uid else {
                        throw AuthError.noUserSignedIn
                    }
                    svm.listenForNotificationChanges(uid: uid)
                    svm.listenForFriendsListChanges(uid: uid)
                    svm.listenForPendingFriendRequests(uid: uid)
                    try await svm.fetchNotifications(uid: uid)
                    try await svm.fetchPendingFR(uid: uid)
                    try await svm.fetchFriendsList(uid: uid)
                }
            }
        } label: {
            Text("Ok")
                .frame(maxWidth: .infinity)
                .padding(5)
                .background(RoundedRectangle(cornerRadius: GlobalVariables.shared.TEXTFIELD_RRRADIUS).fill(isValid ? Color.blue : Color.gray.opacity(0.2)))
                .foregroundColor(isValid ? Color.white : Color(UIColor.systemGray))
                .font(.custom(GlobalVariables.shared.APP_FONT, size: fontSize))
        }
        .disabled(!isValid)
    }
}

struct GetInformationView_Previews: PreviewProvider {
    static var previews: some View {
        GetInformationView()
            .environmentObject(AuthenticationVM())
            .environmentObject(TypesenseVM())
            .environmentObject(SocialViewModel())
    }
}
