//
//  NotificationVM.swift
//  friends
//
//  Created by Bryan Hoang on 10/11/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseFunctions

@MainActor
class NotificationViewModel: ObservableObject {
    @Published var cachedNotifications: [Notification] = []
    @Published var friendRequestStatuses: [String: String] = [:]
    private var listeners: [ListenerRegistration] = []
    
    // Fetch all notifications and update the friend request statuses
    func fetchNotifications(uid: String) async throws {
        let notifications = Firestore.firestore().collection("notifications")
            .whereField("to_uid", isEqualTo: uid)
            .order(by: "timestamp", descending: true)
            .limit(to: 25)
        let snapshot = try await notifications.getDocuments()
        // Reset cached notifications before updating
        self.cachedNotifications = snapshot.documents.compactMap { doc in
            // Decode the notification
            guard let notification = try? doc.data(as: Notification.self) else {
                return nil
            }
            
            // Store incoming friend requests or other notifications
            return notification
        }
        
        handlePendingFriendRequests() // Ensure friend request statuses are updated after fetching
    }
    
    func fetchPendingFriendRequests(fromUserId: String) async throws {
        let requests = Firestore.firestore().collection("notifications")
            .whereField("from_uid", isEqualTo: fromUserId)
            .whereField("type", isEqualTo: notificationType.friendRequest.rawValue)
            .whereField("status", isEqualTo: "pending")
        
        let snapshot = try await requests.getDocuments()
        
        // Reset friend request statuses before updating
        friendRequestStatuses.removeAll()
        
        for document in snapshot.documents {
            if let notification = try? document.data(as: Notification.self) {
                // Store the notificationId for this friend request
                friendRequestStatuses[notification.toUserId] = notification.notificationId
            }
        }
    }
    
    // Function to listen for real-time updates to notifications
    func listenForNotificationChanges(uid: String) {
        stopAllListeners() // Stop any existing listeners before adding a new one
        let notifications = Firestore.firestore()
            .collection("notifications")
            .whereField("to_uid", isEqualTo: uid)
        
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
            
            handlePendingFriendRequests()
        }
        
        // Append the listener to the listeners array
        self.listeners.append(listener)
    }
    
    func handlePendingFriendRequests() {
        let pendingRequests = cachedNotifications.filter {
            $0.type == .friendRequest && $0.status == .pending
        }
        
        for request in pendingRequests {
            friendRequestStatuses[request.toUserId] = request.notificationId
        }
    }
    
    // Stop all listeners when not needed
    func stopAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
}

// MARK: Social functions
extension NotificationViewModel {
    // Function to send friend request (as a Notification)
    func sendFriendRequest(fromUserId: String,
                           fromUsername: String,
                           fromUserPP: [String],
                           toUserId: String) async {
        // Check if there's already a pending friend request in local state
        if let existingRequestId = friendRequestStatuses[toUserId],
           cachedNotifications.contains(where: { $0.notificationId == existingRequestId && $0.status == .pending }) {
            print("A pending friend request already exists for \(toUserId)")
            return
        }
        
        // Check if any of the values are null or empty ("")
        guard !fromUserId.isEmpty, !toUserId.isEmpty, !fromUsername.isEmpty, !fromUserPP.isEmpty else {
            print("Error: One or more parameters are missing.")
            return
        }
        
        let functions = Functions.functions()
        let data: [String: Any] = [
            "from_uid": fromUserId,
            "to_uid": toUserId,
            "from_username": fromUsername,
            "from_pp": fromUserPP
        ]
        
        do {
            let result = try await functions.httpsCallable("handleFriendRequests").call(data)
            guard let notificationData = result.data as? [String: Any],
                  let notificationId = notificationData["notification_id"] as? String else {
                print("Error: Invalid data received from Cloud Function.")
                return
            }
            
            let friendRequestNotification = Notification(
                notificationId: notificationId,
                fromUserId: fromUserId,
                fromUserPP: fromUserPP,
                toUserId: toUserId,
                type: .friendRequest,
                message: "Friend request from \(fromUsername)",
                status: .pending
            )
            
            // Store the notificationId in friendRequestStatuses for future reference
            self.friendRequestStatuses[toUserId] = notificationId
            
            // Update cachedNotifications to include the new friend request
            self.cachedNotifications.append(friendRequestNotification)
            print("Notification successfully sent via Cloud Function: \(friendRequestNotification)")
        } catch {
            print("Error sending friend request via Cloud Function: \(error.localizedDescription)")
        }
    }
    
    // Function to unsend a friend request
    func unsendFriendRequest(toUserId: String, fromUserId: String) async {
        // Use the stored notificationId from friendRequestStatuses
        guard let notificationId = friendRequestStatuses[toUserId] else {
            print("Error: Could not find stored notification ID for unsending")
            return
        }

        let functions = Functions.functions()
        let data: [String: Any] = [
            "notification_id": notificationId
        ]

        do {
            let result = try await functions.httpsCallable("unsendFriendRequest").call(data)
            if let response = result.data as? [String: Any], let success = response["success"] as? Bool, success {
                print("Notification \(notificationId) successfully deleted via Cloud Function")

                // Remove from friendRequestStatuses (outgoing request)
                friendRequestStatuses[toUserId] = nil

                // Remove the notification from cachedNotifications
                self.cachedNotifications.removeAll { $0.notificationId == notificationId }
            } else {
                print("Error: Unexpected response from unsendFriendRequest Cloud Function.")
            }
        } catch {
            print("Error unsending friend request via Cloud Function: \(error.localizedDescription)")
        }
    }
    
    // General function for updating notification status.
    func updateNotificationStatus(notification: Notification, status: notificationStatus) async {
        guard let notificationId = notification.notificationId else {
            print("Error: Notification ID is missing.")
            return
        }

        let functions = Functions.functions()
        let data: [String: Any] = [
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
    
    func handleFriendRequest(notification: Notification) async {
        await updateNotificationStatus(notification: notification, status: .accepted)
    }
}
