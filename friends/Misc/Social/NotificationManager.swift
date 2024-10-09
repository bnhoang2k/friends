//
//  NotificationManager.swift
//  friends
//
//  Created by Bryan Hoang on 10/9/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum notificationType: String, Codable {
    case friendRequest = "friendRequest"
    case hangoutRequest = "hangoutRequest"
    case reminder = "reminder"
    case placeholder = "placeholder"
}

struct Notification: Codable {
    var notificationId: String? // Store the generated notification ID
    var fromUserId: String
    var fromUserPP: [String]?
    var toUserId: String
    var type: notificationType
    var message: String?
    var status: String
    var timestamp: Date
    
    init(notificationId: String? = nil,
         fromUserId: String,
         fromUserPP: [String],
         toUserId: String,
         type: notificationType,
         message: String?,
         status: String = "unread",
         timestamp: Date = Date()) {
        self.notificationId = notificationId
        self.fromUserId = fromUserId
        self.fromUserPP = fromUserPP
        self.toUserId = toUserId
        self.type = type
        self.message = message
        self.status = status
        self.timestamp = timestamp
    }
    
    enum CodingKeys: String, CodingKey {
        case notificationId = "notification_id"
        case fromUserId = "from_uid"
        case fromUserPP = "from_pp"
        case toUserId = "to_uid"
        case type = "type"
        case message = "message"
        case status = "status"
        case timestamp = "timestamp"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.notificationId = try container.decodeIfPresent(String.self, forKey: .notificationId)
        self.fromUserId = try container.decode(String.self, forKey: .fromUserId)
        self.fromUserPP = try container.decode([String].self, forKey: .fromUserPP)
        self.toUserId = try container.decode(String.self, forKey: .toUserId)
        self.type = try container.decode(notificationType.self, forKey: .type)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        self.status = try container.decode(String.self, forKey: .status)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.notificationId, forKey: .notificationId)
        try container.encodeIfPresent(self.fromUserId, forKey: .fromUserId)
        try container.encodeIfPresent(self.fromUserPP, forKey: .fromUserPP)
        try container.encodeIfPresent(self.toUserId, forKey: .toUserId)
        try container.encodeIfPresent(self.type, forKey: .type)
        try container.encodeIfPresent(self.message, forKey: .message)
        try container.encodeIfPresent(self.status, forKey: .status)
        try container.encodeIfPresent(self.timestamp, forKey: .timestamp)
    }
}

extension UserManager {
    func fetchNotifications(uid: String) async throws -> [Notification] {
        let notifications = userNotificationsList(uid: uid)
        let snapshot = try await notifications.getDocuments()
        return snapshot.documents.compactMap {try? $0.data(as: Notification.self)}
    }
}

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
        print("Updated friendRequestStatuses: \(friendRequestStatuses)")
    }
    
    // Function to listen for real-time updates to notifications
    func listenForNotificationChanges(uid: String) {
        let notifications = Firestore.firestore().collection("notifications").whereField("to_uid", isEqualTo: uid)
        
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
                        self.cachedNotifications.append(newNotification)
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
        // Append the listener to the listeners array
        self.listeners.append(listener)
    }
    
    func listenForPendingFriendRequests(uid: String) {
        let query = Firestore.firestore().collection("notifications")
            .whereField("to_uid", isEqualTo: uid)
            .whereField("type", isEqualTo: notificationType.friendRequest.rawValue)
            .whereField("status", isEqualTo: "pending")
        
        query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            guard let snapshot = snapshot else {
                print("Error fetching pending friend requests: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            snapshot.documentChanges.forEach { diff in
                switch diff.type {
                case .added:
                    // Handle new friend request
                    if let newRequest = try? diff.document.data(as: Notification.self) {
                        if !self.cachedNotifications.contains(where: { $0.notificationId == newRequest.notificationId }) {
                            self.cachedNotifications.append(newRequest)
                        }
                    }
                case .modified:
                    // Handle modified friend request
                    if let updatedRequest = try? diff.document.data(as: Notification.self),
                       let index = self.cachedNotifications.firstIndex(where: { $0.notificationId == updatedRequest.notificationId }) {
                        self.cachedNotifications[index] = updatedRequest
                    }
                case .removed:
                    // Handle removed friend request
                    if let removedRequest = try? diff.document.data(as: Notification.self) {
                        self.cachedNotifications.removeAll { $0.notificationId == removedRequest.notificationId }
                    }
                }
            }
        }
    }
    
    // Stop all listeners when not needed
    func stopAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
}

extension NotificationViewModel {
    // Function to send friend request (as a Notification)
    func sendFriendRequest(fromUserId: String,
                           fromUsername: String,
                           fromUserPP: [String],
                           toUserId: String) async {
        // Check if there's already a pending friend request
        if friendRequestStatuses[toUserId] != nil {
            print("A pending friend request already exists for \(toUserId)")
            return
        }

        let notificationRef = Firestore.firestore().collection("notifications").document()
        let notificationId = notificationRef.documentID

        let friendRequestNotification = Notification(
            notificationId: notificationId,
            fromUserId: fromUserId,
            fromUserPP: fromUserPP,
            toUserId: toUserId,
            type: .friendRequest,
            message: "Friend request from \(fromUsername)",
            status: "pending"
        )

        do {
            try notificationRef.setData(from: friendRequestNotification, merge: false, encoder: Firestore.Encoder())
            print("Notification successfully sent: \(friendRequestNotification)")

            // Store the notificationId in friendRequestStatuses for future reference
            friendRequestStatuses[toUserId] = notificationId
        } catch {
            print("Error sending friend request: \(error.localizedDescription)")
        }
    }
    
    // Function to unsend a friend request
    func unsendFriendRequest(toUserId: String, fromUserId: String) async {
        // Use the stored notificationId from friendRequestStatuses
        guard let notificationId = friendRequestStatuses[toUserId] else {
            print("Error: Could not find stored notification ID for unsending")
            return
        }

        let notificationRef = Firestore.firestore().collection("notifications").document(notificationId)

        do {
            try await notificationRef.delete()
            print("Notification \(notificationId) successfully deleted")

            // Remove from friendRequestStatuses (outgoing request)
            friendRequestStatuses[toUserId] = nil
        } catch {
            print("Error unsending friend request: \(error.localizedDescription)")
        }
    }
}
