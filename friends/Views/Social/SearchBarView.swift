//
//  SearchBarView.swift
//  friends
//
//  Created by Bryan Hoang on 10/7/24.
//

import SwiftUI
import Firebase

class FriendRequestViewModel: ObservableObject {
    @Published var requestStatuses: [String: String] = [:] // Store statuses for each user
    
    private var listeners: [String: ListenerRegistration] = [:] // Track listeners for each user

    func startListeningForRequestStatus(fromUserId: String, toUserId: String) {
        // Remove any existing listener to prevent duplicates
        listeners[toUserId]?.remove()

        // Query for the friend request status
        let query = UserManager.shared.userNotificationsList(uid: toUserId)
            .whereField("from_uid", isEqualTo: fromUserId)
            .whereField("type", isEqualTo: notificationType.friendRequest.rawValue)
            .whereField("status", isEqualTo: "pending")

        // Add the snapshot listener
        listeners[toUserId] = query.addSnapshotListener { [weak self] snapshot, error in
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                // No pending request found
                DispatchQueue.main.async {
                    self?.requestStatuses[toUserId] = "none"
                }
                return
            }

            // Update the request status based on the notification
            if let notification = try? documents.first?.data(as: Notification.self) {
                DispatchQueue.main.async {
                    self?.requestStatuses[toUserId] = notification.status
                }
            }
        }
    }

    func stopListeningForRequestStatus(toUserId: String) {
        // Remove the listener
        listeners[toUserId]?.remove()
        listeners[toUserId] = nil
    }
}

struct SearchBarView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var tvm: TypesenseVM
    @StateObject private var friendRequestVM = FriendRequestViewModel() // ViewModel for friend requests
    
    var body: some View {
        NavigationStack {
            // Main content here
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
                        requestStatus: friendRequestVM.requestStatuses[user.uid] ?? "none",
                        fromUserId: avm.user?.uid ?? "",
                        toUserId: user.uid,
                        sendFriendRequest: {
                            Task {
                                try? await UserManager.shared.sendFriendRequest(fromUserId: avm.user?.uid ?? "", toUserId: user.uid)
                                friendRequestVM.requestStatuses[user.uid] = "pending"
                            }
                        },
                        cancelFriendRequest: {
                            Task {
                                try? await UserManager.shared.cancelFriendRequest(fromUserId: avm.user?.uid ?? "", toUserId: user.uid)
                                friendRequestVM.requestStatuses[user.uid] = "none"
                            }
                        }
                    )
                    .onAppear {
                        friendRequestVM.startListeningForRequestStatus(fromUserId: avm.user?.uid ?? "", toUserId: user.uid)
                    }
                    .onDisappear {
                        friendRequestVM.stopListeningForRequestStatus(toUserId: user.uid)
                    }
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
        .onChange(of: tvm.searchText, perform: { value in
            Task {
                await tvm.searchUsers(query: tvm.searchText, excludedName: avm.user?.username ?? "Error")
            }
        })
        .onDisappear {
            tvm.searchText = ""
            tvm.searchResults = []
        }
    }
}



struct FriendRequestButton: View {
    let requestStatus: String
    let fromUserId: String
    let toUserId: String
    let sendFriendRequest: () -> Void
    let cancelFriendRequest: () -> Void
    
    var body: some View {
        Button {
            if requestStatus == "none" {
                sendFriendRequest()
            } else if requestStatus == "pending" {
                cancelFriendRequest()
            }
        } label: {
            buttonIcon
                .padding(10) // Add padding for better touch size
                .background(Color(.systemGray6)) // Optional: Add background for clearer boundaries
                .clipShape(Circle()) // Optional: make the button circular or customize as needed
        }
        .buttonStyle(PlainButtonStyle()) // Prevents any unintended button expansion
        .frame(width: 44, height: 44) // Explicit size for the button
        .contentShape(Rectangle()) // Ensure button is the only tappable area
    }
    
    @ViewBuilder
    private var buttonIcon: some View {
        if requestStatus == "none" {
            Image(systemName: "plus")
        } else if requestStatus == "pending" {
            Image(systemName: "clock")
        } else if requestStatus == "accepted" {
            Image(systemName: "checkmark")
        } else if requestStatus == "rejected" {
            Image(systemName: "xmark")
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
    }
}
