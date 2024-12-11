//
//  SearchForFriendsView.swift
//  friends
//
//  Created by Bryan Hoang on 10/7/24.
//

import SwiftUI
import Firebase

struct SearchForFriendsView: View {
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var tvm: TypesenseVM
    @EnvironmentObject private var svm: SocialVM
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var toUserId: String? = nil
    @State private var keyboardHeight: CGFloat = 0.0
    
    var body: some View {
        VStack {
            Text("Search and Add Friends")
                .font(.custom(GlobalVariables.shared.APP_FONT,
                              size: GlobalVariables.shared.textBody))
                .fontWeight(.bold)
                .padding(.vertical)
            
            // Search bar at the top
            HStack {
                SearchBar(placeholderText: "Search for Friends", searchText: $tvm.searchText)
                    .onChange(of: tvm.searchText) { _ in
                        Task {
                            await tvm.searchUsers(
                                query: tvm.searchText,
                                excludedName: avm.user?.username ?? "Error"
                            )
                        }
                    }
            }
            
            // ScrollView for search results
            if !tvm.searchText.isEmpty {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(tvm.searchResults, id: \.uid) { user in
                            HStack {
                                UserCard(user: user)
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        selectUser(user)
                                    }
                                }) {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // "Add Friend" button at the bottom
            Button(action: addFriend) {
                Text("Add Friend")
                    .font(.custom(GlobalVariables.shared.APP_FONT,
                                  size: GlobalVariables.shared.textBody))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.primary)
        }
        .padding([.horizontal])
        .offset(y: -self.keyboardHeight)
        .animation(.spring(), value: keyboardHeight)
        .onAppear {
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification,
                                                   object: nil,
                                                   queue: .main) { (notification) in
                guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                self.keyboardHeight = keyboardFrame.height
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification,
                                                   object: nil,
                                                   queue: .main) { (notification) in
                self.keyboardHeight = 0
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            UIApplication.shared.dismissKeyboard()
            clearSearchState()
        }
    }
    
    // Select user action
    private func selectUser(_ user: DBUser) {
        tvm.searchText = user.username ?? ""
        toUserId = user.uid
    }
    
    // Add friend action
    private func addFriend() {
        Task {
            guard let fromUserId = avm.user?.uid,
                  let fromUsername = avm.user?.username,
                  let fromUserPP = avm.user?.photoURL,
                  let toUserId = toUserId else {
                print("Error: Missing user details")
                return
            }
            try await svm.sendFriendRequest(
                fromUserId: fromUserId,
                fromUsername: fromUsername,
                fromUserPP: [fromUserPP],
                toUserId: toUserId
            )
            dismiss()
        }
    }
    
    // Clear search state when view disappears
    private func clearSearchState() {
        Task {
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
        SearchForFriendsView()
            .environmentObject(TypesenseVM())
            .environmentObject(AuthenticationVM())
            .environmentObject(SocialVM())
    }
}
