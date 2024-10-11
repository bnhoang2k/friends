//
//  SearchBarView.swift
//  friends
//
//  Created by Bryan Hoang on 10/7/24.
//

import SwiftUI
import Firebase

struct SearchBarView: View {
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var tvm: TypesenseVM
    @EnvironmentObject private var nvm: NotificationViewModel
    
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationStack {
            List(tvm.searchResults, id: \.uid) { user in
                HStack {
                    ImageView(urlString: user.photoURL, pictureWidth: 50)
                    VStack(alignment: .leading) {
                        Text(user.username ?? "username error")
                        Text(user.fullName ?? "full name error")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    FriendRequestButton(
                        notificationId: nvm.friendRequestStatuses[user.uid],
                        onSendRequest: {
                            Task {
                                guard let fromUserId = avm.user?.uid,
                                      let fromUsername = avm.user?.username,
                                      let fromUserPP = avm.user?.photoURL else {
                                    print("Error: Missing user details")
                                    return
                                }
                                // Send friend request
                                await nvm.sendFriendRequest(fromUserId: fromUserId,
                                                            fromUsername: fromUsername,
                                                            fromUserPP: [fromUserPP],
                                                            toUserId: user.uid)
                            }
                        },
                        onUnsendRequest: {
                            Task {
                                // Unsend friend request
                                guard nvm.friendRequestStatuses[user.uid] != nil else {
                                    print("Error: No pending request to unsend")
                                    return
                                }
                                guard let FromUserId = avm.user?.uid else {
                                    print("Error can't get from user id.")
                                    return
                                }
                                await nvm.unsendFriendRequest(toUserId: user.uid, fromUserId: FromUserId)
                            }
                        }
                    )
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        TextField("Search", text: $tvm.searchText)
                            .frame(maxWidth: .infinity)
                            .textFieldStyle(.plain)
                            .padding(7)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .autocorrectionDisabled()
                    }
                }
            }
        }
        .onChange(of: presentationMode.wrappedValue.isPresented) { isPresented in
            if !isPresented {
                UIApplication.shared.dismissKeyboard()
            }
        }
        .onChange(of: tvm.searchText) { _ in
            Task {
                await tvm.searchUsers(query: tvm.searchText, excludedName: avm.user?.username ?? "Error")
            }
        }
        .onDisappear {
            tvm.searchText = ""
            tvm.searchResults = []
        }
    }
}

struct FriendRequestButton: View {
    let notificationId: String? // Now we pass the notificationId
    let onSendRequest: () -> Void
    let onUnsendRequest: () -> Void
    
    var body: some View {
        Button {
            if notificationId == nil {
                // Send friend request
                onSendRequest()
            } else {
                // Unsend friend request
                onUnsendRequest()
            }
        } label: {
            if notificationId != nil {
                Image(systemName: "clock") // Display clock for unsending
            } else {
                Image(systemName: "plus") // Display plus for sending
            }
        }
    }
}

extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    NavigationStack {
        SearchBarView()
            .environmentObject(TypesenseVM())
            .environmentObject(AuthenticationVM())
            .environmentObject(NotificationViewModel())
    }
}
