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
    @Published var cachedNotifications: [Notification] = []
    // Dictionary to store Friend UID and corresponding DBUser data
    @Published var cachedFriendsList: [String: DBUser] = [:]
    @Published var cachedFriendRequests: [friendRequest] = []
    @Published var cachedHangoutsList: [HangoutReference: Hangout] = [:]
    private var listeners: [ListenerRegistration] = []
    
    private var currentHangoutListener: ListenerRegistration?
    @Published var selectedFriendId: String?
    
    func loadData(uid: String) async throws {
        listenForNotificationChanges(uid: uid)
        listenForFriendsListChanges(uid: uid)
        listenForPendingFriendRequests(uid: uid)
//        listenForHangouts(for: selectedFriendId ?? "", uid: uid)
        try await fetchNotifications(uid: uid)
        try await fetchFriendsList(uid: uid)
        try await fetchPendingFR(uid: uid)
        /// MARK: We're not going to fetch hangouts on load. We're going to try
        /// to fetch it on demand; i.e., when the user clicks on a friend.
//        try await fetchHangouts(uid: uid)
    }
    
}

// MARK: Listener Functions
extension SocialVM {
    // Listener to see if any changes occur in the friends list of the user.
    // Changes that can occur:
    // 1. Friends are added/deleted
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
    // Listener to check for notifications sent to the user.
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
    // Listener to see if any new friend requests are sent to the current user.
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
    
    func listenForHangouts(for friendId: String, uid: String) {
        // Stop the current listener if it's already active
        if currentHangoutListener != nil {
            stopCurrentHangoutListener()
        }
        
        // Update the selected friend ID
        self.selectedFriendId = friendId
        
        // Start a new listener for the selected friend
        let hangoutsCollection = HangoutManager.shared.userHangoutCollection(uid: uid)
            .whereField(HangoutReference.CodingKeys.participantIds.rawValue, arrayContains: friendId)
            .limit(to: 10)
            .order(by: "creation_date", descending: true)
        
        currentHangoutListener = hangoutsCollection.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            guard let snapshot = snapshot else {
                print("Error fetching hangouts for \(friendId): \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            snapshot.documentChanges.forEach { diff in
                switch diff.type {
                case .added:
                    if let hangoutRef = try? diff.document.data(as: HangoutReference.self) {
                        Task { await self.fetchHangoutDetails(hangoutReference: hangoutRef) }
                    }
                case .modified:
                    if let hangoutRef = try? diff.document.data(as: HangoutReference.self) {
                        Task { await self.fetchHangoutDetails(hangoutReference: hangoutRef, forceUpdate: true) }
                    }
                case .removed:
                    if let hangoutRef = try? diff.document.data(as: HangoutReference.self) {
                        self.cachedHangoutsList.removeValue(forKey: hangoutRef)
                    }
                }
            }
        }
    }

    func stopCurrentHangoutListener() {
        // Stop the currently active listener if it exists
        currentHangoutListener?.remove()
        currentHangoutListener = nil
        self.selectedFriendId = nil
        print("Current hangout listener stopped.")
    }
    
    // Stop all listeners when not needed
    func stopAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        currentHangoutListener?.remove()
    }
}

// MARK: Initial Fetch Functions
extension SocialVM {
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
    func fetchHangouts(uid: String, friendId: String) async throws {
        let hangoutList = HangoutManager.shared.userHangoutCollection(uid: uid)
        
        let query = hangoutList
            .whereField(HangoutReference.CodingKeys.participantIds.rawValue, arrayContains: friendId)
            .limit(to: 10)
            .order(by: "creation_date", descending: true)
        
        let snapshot = try await query.getDocuments()
        for doc in snapshot.documents {
            guard let request = try? doc.data(as: HangoutReference.self) else { continue }
            await fetchHangoutDetails(hangoutReference: request)
        }
    }
    func fetchHangoutDetails(hangoutReference: HangoutReference, forceUpdate: Bool = false) async {
        // Check if hangout details are already cached
        if let _ = cachedHangoutsList[hangoutReference], !forceUpdate {
            return
        }
        let hangoutRef = HangoutManager.shared.hangoutDocument(hangoutId: hangoutReference.hangoutId)
        do {
            let document = try await hangoutRef.getDocument()
            if let hangout = try? document.data(as: Hangout.self) {
                self.cachedHangoutsList[hangoutReference] = hangout
            }
        } catch {
            print("Error fetching hangout details: \(error.localizedDescription)")
        }
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
    func handleFriendRequest(notification: Notification, status: NotificationStatus) async throws {
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

// MARK: Hangout Functions
extension SocialVM {
    func createHangout(uid: String, hangout: Hangout) async throws {
        try await HangoutManager.shared.createHangout(uid: uid, hangout: hangout)
    }
    func getFilteredHangoutsByFriend(friendId: String) -> [Hangout] {
        // Extract hangouts from the cachedHangoutsList dictionary
        var filteredHangouts = Array(cachedHangoutsList.values)
        
        // Sort the hangouts by creation date, with a tiebreaker using hangout ID
        filteredHangouts.sort { (hangout1, hangout2) in
            if hangout1.creationDate != hangout2.creationDate {
                return hangout1.creationDate > hangout2.creationDate // Sort by most recent date
            } else {
                return hangout1.hangoutId < hangout2.hangoutId // Use hangout ID as tiebreaker
            }
        }
        
        // Return the sorted list
        return filteredHangouts
    }
}
