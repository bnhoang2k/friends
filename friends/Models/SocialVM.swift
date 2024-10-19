//
//  SocialVM.swift
//  friends
//
//  Created by Bryan Hoang on 10/13/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseFunctions

@MainActor
class SocialVM: ObservableObject {
    @Published var cachedNotifications: [Notification] = []
    @Published var cachedFriendsList: [Friend] = []
    @Published var cachedFriendRequests: [friendRequest] = []
    private var listeners: [ListenerRegistration] = []
}

// MARK: Listener Functions
extension SocialVM {
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
                    if let newFriend = try? diff.document.data(as: Friend.self) {
                        if !self.cachedFriendsList.contains(where: { $0.uid == newFriend.uid }) {
                            self.cachedFriendsList.append(newFriend)
                        }
                    }
                case .modified:
                    if let updatedFriend = try? diff.document.data(as: Friend.self),
                       let index = self.cachedFriendsList.firstIndex(where: { $0.uid == updatedFriend.uid }) {
                        self.cachedFriendsList[index] = updatedFriend
                    }
                case .removed:
                    if let removedFriend = try? diff.document.data(as: Friend.self) {
                        self.cachedFriendsList.removeAll { $0.uid == removedFriend.uid }
                    }
                }
            }
        }
        self.listeners.append(listener)
    }
    
    func listenForNotificationChanges(uid: String) {
        let notifications = UserManager.shared.userNotificationsList(uid: uid)
        
        let listener = notifications.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            guard let snapshot = snapshot else {
                print("Error fetching notifications: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            snapshot.documentChanges.forEach { diff in
                switch diff.type {
                case .added:
                    if let newNotification = try? diff.document.data(as: Notification.self) {
                        // Append only if not already present (to prevent duplicates)
                        if !self.cachedNotifications.contains(where: { $0.notificationId == newNotification.notificationId }) {
                            self.cachedNotifications.append(newNotification)
                        }
                    }
                case .modified:
                    if let updatedNotification = try? diff.document.data(as: Notification.self),
                       let index = self.cachedNotifications.firstIndex(where: { $0.notificationId == updatedNotification.notificationId }) {
                        self.cachedNotifications[index] = updatedNotification
                    }
                case .removed:
                    if let removedNotification = try? diff.document.data(as: Notification.self) {
                        self.cachedNotifications.removeAll { $0.notificationId == removedNotification.notificationId }
                    }
                }
            }
        }
        self.listeners.append(listener)
    }
    
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
    
    // Stop all listeners when not needed
    func stopAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
}

// MARK: Initial Fetch Functions
extension SocialVM {
    func fetchFriendsList(uid: String) async throws {
        let friendsList = UserManager.shared.userFriendsList(uid: uid)
        let snapshot = try await friendsList.getDocuments()
        self.cachedFriendsList = snapshot.documents.compactMap({ doc in
            guard let friend = try? doc.data(as: Friend.self) else {
                return nil
            }
            return friend
        })
    }
    func fetchNotifications(uid: String) async throws {
        let notifications = UserManager.shared
            .userNotificationsList(uid: uid)
            .order(by: "timestamp", descending: true)
            .limit(to: 25)
        let snapshot = try await notifications.getDocuments()
        self.cachedNotifications = snapshot.documents.compactMap({ doc in
            guard let notification = try? doc.data(as: Notification.self) else {
                return nil
            }
            return notification
        })
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

// MARK: Friend Request Functions
extension SocialVM {
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
    func handleFriendRequest(notification: Notification, status: notificationStatus) async throws {
        guard status == .accepted else {
            let pendingFrRef = UserManager.shared.userPendingFR(uid: notification.fromUserId).document(notification.toUserId)
            try await pendingFrRef.updateData(["status": "rejected"] as [String: String])
            return
        }
        let functions = Functions.functions()
        
        do {
            // Prepare the data to be sent to the Cloud Function
            let data: [String: Any] = [
                "from_uid": notification.fromUserId,
                "to_uid": notification.toUserId
            ]
            
            // Call the Cloud Function to handle adding friends
            let result = try await functions.httpsCallable("handleFriendRequest").call(data)
            
            if let response = result.data as? [String: Any], let success = response["success"] as? Bool, success {
                print("Successfully added friends to each other's friends list via Cloud Function.")
                
                // Update the notification status to 'accepted'
                try await updateNotificationStatus(notification: notification, status: .accepted)
                
                // Update the pending friend request status in the sender's "pending_fr" collection
                let pendingFrRef = UserManager.shared.userPendingFR(uid: notification.fromUserId).document(notification.toUserId)
                try await pendingFrRef.updateData(["status": "accepted"] as [String: String])
                
            } else {
                print("Failed to add friends via Cloud Function.")
            }
        } catch {
            print("Error calling Cloud Function: \(error.localizedDescription)")
        }
    }
}

// MARK: General?
extension SocialVM {
    func updateNotificationStatus(notification: Notification, status: notificationStatus) async throws {
        guard let notificationId = notification.notificationId else {
            print("Error: Notification ID is missing.")
            return
        }
        
        let functions = Functions.functions()
        let data: [String: Any] = [
            "to_uid" : notification.toUserId,
            "notification_id": notificationId,
            "status": status.rawValue
        ]
        
        do {
            let result = try await functions.httpsCallable("updateNotificationStatus").call(data)
            if let response = result.data as? [String: Any], let success = response["success"] as? Bool, success {
                print("Notification status updated to \(status) via Cloud Function")
                
                // Update local cachedNotifications to reflect the status change
                if let index = cachedNotifications.firstIndex(where: { $0.notificationId == notificationId }) {
                    cachedNotifications[index].status = status
                }
            } else {
                print("Error: Unexpected response from updateNotificationStatus Cloud Function.")
            }
        } catch {
            print("Error updating notification status via Cloud Function: \(error.localizedDescription)")
        }
    }
    func filteredFriends(query: String) -> [Friend] {
        if query.isEmpty {
            return cachedFriendsList
        } else {
            return cachedFriendsList.filter { friend in
                (friend.fullName?.localizedCaseInsensitiveContains(query) == true ||
                friend.username?.localizedCaseInsensitiveContains(query) == true)
            }
        }
    }
}
