//
//  NotificationsVM.swift
//  friends
//
//  Created by Bryan Hoang on 1/14/25.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions

@MainActor
class NotificationsVM: ObservableObject {
    @Published var cachedNotifications: [Notification] = []
    private var listeners: [ListenerRegistration] = []
}

/// Initial Fetch Function
extension NotificationsVM {
    func fetchNotifications(uid: String) async throws {
        let notifications = UserManager.shared
            .userNotificationsList(uid: uid)
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
        let snapshot = try await notifications.getDocuments()
        self.cachedNotifications = snapshot.documents.compactMap({ doc in
            guard let notification = try? doc.data(as: Notification.self) else {
                return nil
            }
            return notification
        })
    }
}

///  Notificaiton Functions
extension NotificationsVM {
    func updateNotificationStatus(notification: Notification, status: NotificationStatus) async throws {
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
}

extension NotificationsVM {
    /// Listener to check for notifications sent to the user.
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
    
    func removeListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
}
