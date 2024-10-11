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
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var toUserId: String? = nil
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search", text: $tvm.searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onChange(of: tvm.searchText) { _ in
                        Task {
                            await tvm.searchUsers(query: tvm.searchText, excludedName: avm.user?.username ?? "Error")
                        }
                    }
                Button {
                    Task {
                        guard let fromUserId = avm.user?.uid,
                              let fromUsername = avm.user?.username,
                              let fromUserPP = avm.user?.photoURL,
                              let toUserId = toUserId else {
                            print("Error: Missing user details")
                            return
                        }
                        await nvm.sendFriendRequest(fromUserId: fromUserId,
                                                    fromUsername: fromUsername,
                                                    fromUserPP: [fromUserPP],
                                                    toUserId: toUserId)
                        dismiss()
                    }
                } label: {
                    Text("Add Friend")
                        .bold()
                }
            }
            .padding()
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
                }
                .contentShape(.rect)
                .onTapGesture {
                    guard let username = user.username else {return}
                    tvm.searchText = username
                    toUserId = user.uid
                }
            }
            .listStyle(PlainListStyle())
            Spacer()
        }
        .navigationTitle("Search and Add Friends")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            tvm.searchText = ""
            tvm.searchResults = []
            toUserId = ""
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
