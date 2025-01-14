//
//  SocialVM.swift
//  friends
//
//  Created by Bryan Hoang on 10/13/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions

@MainActor
class SocialVM: ObservableObject {
    
    /// Child VMs
    @Published var fvm: FriendsVM
    @Published var nvm: NotificationsVM
    @Published var hvm: HangoutVM
    
    init() {
        self.fvm = FriendsVM()
        self.nvm = NotificationsVM()
        self.hvm = HangoutVM()
    }
    
    func loadData(uid: String?) async throws {
        guard let uid else {
            fatalError("UID must be provided")
        }
        // Load the data
        self.nvm.listenForNotificationChanges(uid: uid)
        self.fvm.listenForFriendsListChanges(uid: uid)
        self.fvm.listenForPendingFriendRequests(uid: uid)
        try await nvm.fetchNotifications(uid: uid)
        try await fvm.fetchFriendsList(uid: uid)
        try await fvm.fetchPendingFR(uid: uid)
        print(fvm.cachedFriendsList)
    }
    
    func stopListeners() {
        nvm.removeListeners()
        fvm.removeListeners()
        hvm.removeListeners()
    }
}

extension SocialVM {
    func handleFriendRequest(notification: Notification, status: NotificationStatus) async throws {
        let cloudFunctionSucceeded = try await fvm.handleFriendRequest(notification: notification, status: status)
        
        // If the user accepted and the Cloud Function succeeded:
        if status == .accepted && cloudFunctionSucceeded {
            // (1) Update the notification status to 'accepted'
            try await nvm.updateNotificationStatus(notification: notification, status: .accepted)
            
            // (2) Update the pending friend request in Firestore
            let pendingFrRef = UserManager.shared .userPendingFR(uid: notification.fromUserId).document(notification.toUserId)
            
            do {
                try await pendingFrRef.updateData(["status": "accepted"] as [String: String])
                print("Friend request status in Firestore updated to 'accepted'")
            } catch {
                print("Error updating friend request document: \(error.localizedDescription)")
            }
        }
    }
}
