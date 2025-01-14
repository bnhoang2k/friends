//
//  FriendsVM.swift
//  friends
//
//  Created by Bryan Hoang on 1/14/25.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions

@MainActor
class FriendsVM: ObservableObject {
    /// Dictionary to store Friend UID and corresponding DBUser data
    @Published var cachedFriendsList: [String: DBUser] = [:]
    @Published var cachedFriendRequests: [friendRequest] = []
    
    private var listeners: [ListenerRegistration] = []
}

/// Initial Fetch Functions
extension FriendsVM {
    
    func fetchFriendsList(uid: String) async throws {
        let friendsList = UserManager.shared.userFriendsList(uid: uid)
        let snapshot = try await friendsList.getDocuments()
        for doc in snapshot.documents {
            let friendUID = doc.documentID
            await fetchUserDetails(uid: friendUID)
        }
    }
    
    func fetchUserDetails(uid: String, forceUpdate: Bool = false) async {
        // Check if the user details are already cached
        if let _ = cachedFriendsList[uid], !forceUpdate {
            return
        }
        // Fetch user details from db_user collection
        let userRef = UserManager.shared.userDocument(uid: uid)
        do {
            let document = try await userRef.getDocument()
            if let user = try? document.data(as: DBUser.self) {
                // Remove sensitive information
                var sanitizedUser = user
                sanitizedUser.email = nil
                sanitizedUser.dateCreated = nil
                // Cache the user details
                self.cachedFriendsList[uid] = sanitizedUser
            }
        } catch {
            print("Error fetching user details: \(error.localizedDescription)")
        }
    }
    
    func fetchPendingFR(uid: String) async throws {
        let requests = UserManager.shared.userPendingFR(uid: uid)
        let snapshot = try await requests.getDocuments()
        self.cachedFriendRequests = snapshot.documents.compactMap({ doc in
            guard let request = try? doc.data(as: friendRequest.self) else {
                return nil
            }
            return request
        })
    }
    
}

/// Friends List Functions
extension FriendsVM {
    func filteredFriends(query: String) -> [DBUser] {
        if query.isEmpty {
            return Array(cachedFriendsList.values)
        } else {
            return cachedFriendsList.values.filter { friend in
                (friend.fullName?.localizedCaseInsensitiveContains(query) == true ||
                 friend.username?.localizedCaseInsensitiveContains(query) == true)
            }
        }
    }
    
    // Overloaded version: returns an empty list if the query is empty
    func filteredFriends(query: String, returnEmptyIfNoQuery: Bool) -> [DBUser] {
        if query.isEmpty {
            return returnEmptyIfNoQuery ? [] : Array(cachedFriendsList.values)
        } else {
            return cachedFriendsList.values.filter { friend in
                (friend.fullName?.localizedCaseInsensitiveContains(query) == true ||
                 friend.username?.localizedCaseInsensitiveContains(query) == true)
            }
        }
    }
    
    func getFriendFromID(_ id: String) -> DBUser? {
        return cachedFriendsList[id]
    }
}

/// Friend Request Functions
extension FriendsVM {
    func sendFriendRequest(fromUserId: String,
                           fromUsername: String,
                           fromUserPP: [String],
                           toUserId: String) async throws {
        if cachedFriendRequests.contains(where: { $0.friendId == toUserId }) {
            print("A pending friend request already exists.")
            return
        }
        // Check if any of the values are null or empty ("")
        guard !fromUserId.isEmpty, !toUserId.isEmpty, !fromUsername.isEmpty, !fromUserPP.isEmpty else {
            print("Error: One or more parameters are missing | fromUserId: \(fromUserId.isEmpty) | fromUserName: \(fromUsername.isEmpty) | fromUserPP: \(fromUserPP.isEmpty) | toUserId: \(toUserId.isEmpty) ")
            return
        }
        
        let functions = Functions.functions()
        let data: [String: Any] = [
            "from_uid": fromUserId,
            "to_uid": toUserId,
            "from_username": fromUsername,
            "from_pp": fromUserPP,
        ]
        
        do {
            let result = try await functions.httpsCallable("sendFriendRequest").call(data)
            guard let notificationData = result.data as? [String: Any],
                  let notificationId = notificationData["notification_id"] as? String else {
                print("Error: Invalid data received from Cloud Function.")
                return
            }
            
            // Store the friend request in the current user's friend request subcollection.
            // The notification is sent to the other user through google cloud within the https call.
            let friendRequest = friendRequest(friendId: toUserId,
                                              requestDate: Date(),
                                              recipientNId: notificationId,
                                              status: .pending)
            
            // Update cachedFriendRequests to include the new friend request
            cachedFriendRequests.append(friendRequest)
            print("Friend request successfully sent via Cloud Function: \(friendRequest)")
        } catch {
            print("Error sending friend request via Cloud Function: \(error.localizedDescription)")
        }
    }
    
    func unsendFriendRequest(toUserId: String, fromUserId: String) async throws {
        guard let request = cachedFriendRequests.first(where: { $0.friendId == toUserId }) else {
            print("Pending friend request does not exist.")
            return
        }
        guard let notificationId = request.recipientNId else {
            print("notification id does not exist.")
            return
        }
        let functions = Functions.functions()
        let data: [String: Any]  = [
            "to_uid": toUserId,
            "notification_id": notificationId,
        ]
        
        do {
            let result = try await functions.httpsCallable("unsendFriendRequest").call(data)
            if let response = result.data as? [String: Any], let success = response["success"] as? Bool, success {
                print("Notification \(notificationId) successfully deleted via Cloud Function")
                cachedFriendRequests.removeAll { $0.friendId == toUserId }
            } else {
                print("Error: Unexpected response from unsendFriendRequest Cloud Function.")
            }
        } catch {
            print("Error unsending friend request via Cloud Function: \(error.localizedDescription)")
        }
    }
    func handleFriendRequest(notification: Notification, status: NotificationStatus) async throws -> Bool {
        // Return a Bool indicating whether the Cloud Function succeeded
        // If user rejects, just handle that here
        guard status == .accepted else {
            let pendingFrRef = UserManager.shared.userPendingFR(uid: notification.fromUserId).document(notification.toUserId)
            try await pendingFrRef.updateData(["status": "rejected"] as [String: String])
            return false
        }
        
        // If user accepts, only do the Cloud Function call
        let functions = Functions.functions()
        let data: [String: Any] = [
            "from_uid": notification.fromUserId,
            "to_uid": notification.toUserId
        ]
        
        let result = try await functions.httpsCallable("handleFriendRequest").call(data)
        if let response = result.data as? [String: Any],
           let success = response["success"] as? Bool, success {
            print("Successfully added friends via Cloud Function.")
            return true
        } else {
            print("Failed to add friends via Cloud Function.")
            return false
        }
    }
}


extension FriendsVM {
    /*
     Listener to see if any changes occur in the friends list of the user.
     Changes that can occur:
     1. Friends are added/deleted
     2. Friend details are modified
     */
    func listenForFriendsListChanges(uid: String) {
        let friendsCollection = UserManager.shared.userFriendsList(uid: uid)
        
        let listener = friendsCollection.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else {return}
            guard let snapshot = snapshot else {
                print("Error fetching friends list: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            snapshot.documentChanges.forEach { diff in
                switch diff.type {
                case .added:
                    let friendUID = diff.document.documentID
                    Task { await self.fetchUserDetails(uid: friendUID) }
                case .modified:
                    let friendUID = diff.document.documentID
                    Task { await self.fetchUserDetails(uid: friendUID, forceUpdate: true) }
                case .removed:
                    let friendUID = diff.document.documentID
                    self.cachedFriendsList.removeValue(forKey: friendUID)
                }
            }
        }
        self.listeners.append(listener)
    }
    /// Listener to see if any new friend requests are sent to the current user.
    func listenForPendingFriendRequests(uid: String) {
        let pendingRequestsCollection = UserManager.shared.userPendingFR(uid: uid)
        
        let listener = pendingRequestsCollection.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            guard let snapshot = snapshot else {
                print("Error fetching pending friend requests: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            snapshot.documentChanges.forEach { diff in
                switch diff.type {
                case .added:
                    if let newRequest = try? diff.document.data(as: friendRequest.self) {
                        if !self.cachedFriendRequests.contains(where: { $0.friendId == newRequest.friendId }) {
                            self.cachedFriendRequests.append(newRequest)
                        }
                    }
                case .modified:
                    if let updatedRequest = try? diff.document.data(as: friendRequest.self),
                       let index = self.cachedFriendRequests.firstIndex(where: { $0.friendId == updatedRequest.friendId }) {
                        self.cachedFriendRequests[index] = updatedRequest
                    }
                case .removed:
                    if let removedRequest = try? diff.document.data(as: friendRequest.self) {
                        self.cachedFriendRequests.removeAll { $0.friendId == removedRequest.friendId }
                    }
                }
            }
        }
        self.listeners.append(listener)
    }
    
    func removeListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
}
