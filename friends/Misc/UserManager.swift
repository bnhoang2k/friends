
//  UserManager.swift
//  friends
//
//  Created by Bryan Hoang on 8/12/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

struct DBUser: Codable {
    // Some field information is acquired differently based on sign-in method.
    // We'll separate the fields out based on that fact.
    
    // Norm.
    var uid: String
    var dateCreated: Date?
    var username: String?
    
    // Dependent
    var email: String?
    var photoURL: String?
    var fullName: String?
    
    init(uid: String,
         dateCreated: Date? = nil,
         username: String? = nil,
         email: String? = nil,
         photoURL: String? = nil,
         fullName: String? = nil) {
        self.uid = uid
        self.dateCreated = dateCreated
        self.username = username
        self.email = email
        self.photoURL = photoURL
        self.fullName = fullName
    }
    
    init(auth: AuthDataResultModel) {
        self.uid = auth.uid
        self.dateCreated = Date()
        self.username = auth.username
        
        self.email = auth.email
        self.photoURL = auth.photo_url
        self.fullName = auth.fullName
    }
    
    func updateUsername(newUsername: String) -> DBUser {
        return DBUser(uid: uid,
                      dateCreated: dateCreated,
                      username: newUsername,
                      email: email,
                      photoURL: photoURL,
                      fullName: fullName)
    }
    
    func updateFN(newFN: String) -> DBUser {
        return DBUser(uid: uid,
                      dateCreated: dateCreated,
                      username: username,
                      email: email,
                      photoURL: photoURL,
                      fullName: newFN)
    }
    
    func updateEmail(newEmail: String) -> DBUser {
        return DBUser(uid: uid,
                      dateCreated: dateCreated,
                      username: username,
                      email: newEmail,
                      photoURL: photoURL,
                      fullName: fullName)
    }
    
    enum CodingKeys: String, CodingKey {
        case uid = "uid"
        case dateCreated = "date_created"
        case username = "username"
        case email = "email"
        case photoURL = "photo_url"
        case fullName = "full_name"
        case id  // Add id for decoding, but we won't use it directly
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode `uid`, if not present, try `id`
        if let uidValue = try container.decodeIfPresent(String.self, forKey: .uid) {
            self.uid = uidValue
        }
        else if let idValue = try container.decodeIfPresent(String.self, forKey: .id) {
            self.uid = idValue
        }
        else {
            // If neither uid nor id are present, provide a default value
            self.uid = ""
        }
        
        self.dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated)
        self.username = try container.decodeIfPresent(String.self, forKey: .username)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        self.fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Encode `uid` into the `uid` key, or `id` if `uid` is being used differently in other cases.
        try container.encode(self.uid, forKey: .uid)
        try container.encodeIfPresent(self.dateCreated, forKey: .dateCreated)
        try container.encodeIfPresent(self.username, forKey: .username)
        try container.encodeIfPresent(self.email, forKey: .email)
        try container.encodeIfPresent(self.photoURL, forKey: .photoURL)
        try container.encodeIfPresent(self.fullName, forKey: .fullName)
    }
}

final class UserManager {
    static let shared = UserManager()
    private init() {}
    
    private let userCollection = Firestore.firestore().collection("users")
    
    func userDocument(uid: String) -> DocumentReference {
        return userCollection.document(uid)
    }
    
    func userFriendsList(uid: String) -> CollectionReference {
        return userCollection.document(uid).collection("friends")
    }
    
    func userNotificationsList(uid: String) -> CollectionReference {
        return userCollection.document(uid).collection("notifications")
    }
    
    private let encoder: Firestore.Encoder = {
        let encoder = Firestore.Encoder()
        //        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    
    private let decoder: Firestore.Decoder = {
        let decoder = Firestore.Decoder()
        //        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

// MARK: User Functions
extension UserManager {
    func createNewUser(user: DBUser) async throws {
        // TODO: Convert to update data instead. 34:03 #10
        try userDocument(uid: user.uid).setData(from: user,
                                                merge: false,
                                                encoder: encoder)
    }
    
    func getUser(uid: String) async throws -> DBUser {
        try await userDocument(uid: uid).getDocument(as: DBUser.self,
                                                     decoder: decoder)
    }
}

// MARK: User Settings Change Functions
extension UserManager {
    func doesUserExist(uid: String) async throws -> Bool {
        let document = try await userDocument(uid: uid).getDocument()
        return document.exists
    }
    
    func updateUsername(user: DBUser) async throws {
        let data: [String:Any] = [
            "username" : user.username ?? "USERNAME ERROR"
        ]
        try await userDocument(uid: user.uid).updateData(data)
    }
    
    func updateFN(user: DBUser) async throws {
        let data: [String:Any] = [
            "full_name" : user.fullName ?? "FULLNAME ERROR"
        ]
        try await userDocument(uid: user.uid).updateData(data)
    }
    
    func updateEmail(user: DBUser) async throws {
        let data: [String:Any] = [
            "email" : user.email ?? "EMAIL ERROR"
        ]
        try await userDocument(uid: user.uid).updateData(data)
    }
    
    func updateUser(_ originalUser: DBUser, with modifiedUser: DBUser) async throws {
        var data: [String: Any] = [:]
        
        if originalUser.username != modifiedUser.username {
            data["username"] = modifiedUser.username
        }
        
        if originalUser.fullName != modifiedUser.fullName {
            data["full_name"] = modifiedUser.fullName
        }
        
        if originalUser.email != modifiedUser.email {
            data["email"] = modifiedUser.email
        }
        
        if originalUser.photoURL != modifiedUser.photoURL {
            data["photo_url"] = modifiedUser.photoURL
        }
        
        // If there are changes, update the Firestore document
        if !data.isEmpty {
            try await userDocument(uid: modifiedUser.uid).updateData(data)
        }
    }
    
    func uploadProfileImage(uid: String, imageData: Data) async throws -> String {
        let storageRef = Storage.storage().reference()
        let profileImageRef = storageRef.child("users/\(uid)/profile_picture.jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload the image data
        let _ = try await profileImageRef.putDataAsync(imageData, metadata: metadata)
        
        // Retrieve the download URL
        let downloadURL = try await profileImageRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    func updateUserProfileImageURL(uid: String, downloadURL: String) async throws {
        let data: [String: Any] = ["photo_url": downloadURL]
        try await userCollection.document(uid).updateData(data)
    }
}

enum notificationType: String, Codable {
    case friendRequest = "friendRequest"
    case hangoutRequest = "hangoutRequest"
    case reminder = "reminder"
    case placeholder = "placeholder"
}

struct Notification: Codable {
    var notificationId: String? // Store the generated notification ID
    var fromUserId: String
    var toUserId: String
    var type: notificationType
    var message: String?
    var status: String
    var timestamp: Date
    
    init(notificationId: String? = nil, fromUserId: String, toUserId: String, type: notificationType, message: String?, status: String = "unread", timestamp: Date = Date()) {
        self.notificationId = notificationId
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.type = type
        self.message = message
        self.status = status
        self.timestamp = timestamp
    }
    
    enum CodingKeys: String, CodingKey {
        case notificationId = "notification_id"
        case fromUserId = "from_uid"
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
        try container.encodeIfPresent(self.toUserId, forKey: .toUserId)
        try container.encodeIfPresent(self.type, forKey: .type)
        try container.encodeIfPresent(self.message, forKey: .message)
        try container.encodeIfPresent(self.status, forKey: .status)
        try container.encodeIfPresent(self.timestamp, forKey: .timestamp)
    }
}

// MARK: Notification Functions
extension UserManager {
    func sendFriendRequest(fromUserId: String, toUserId: String) async throws {
        // Step 1: Create a reference for the new notification
        let notificationRef = userNotificationsList(uid: toUserId).document()
        
        // Step 2: Create the notification and set the document ID as the notification_id
        let notification = Notification(
            notificationId: notificationRef.documentID, // Use the Firestore-generated document ID
            fromUserId: fromUserId,
            toUserId: toUserId,
            type: .friendRequest,
            message: "You have received a friend request!",
            status: "pending",
            timestamp: Date()
        )
        
        // Step 3: Save the notification to Firestore with the document ID
        try notificationRef.setData(from: notification, merge: false, encoder: encoder)
    }
    
    func checkForExistingFriendRequest(fromUserId: String, toUserId: String) async throws -> Notification? {
        // Query the recipient's notifications for any pending friend request from the same user
        let query = userNotificationsList(uid: toUserId)
            .whereField("from_uid", isEqualTo: fromUserId)
            .whereField("type", isEqualTo: notificationType.friendRequest.rawValue)
            .whereField("status", isEqualTo: "pending")
        
        let querySnapshot = try await query.getDocuments()
        
        if let document = querySnapshot.documents.first {
            return try? document.data(as: Notification.self)
        } else {
            return nil
        }
    }
    
    func cancelFriendRequest(fromUserId: String, toUserId: String) async throws {
        // Query the recipient's notifications for any pending friend request from the same user
        let query = userNotificationsList(uid: toUserId)
            .whereField("from_uid", isEqualTo: fromUserId)
            .whereField("type", isEqualTo: notificationType.friendRequest.rawValue)
            .whereField("status", isEqualTo: "pending")
        
        let querySnapshot = try await query.getDocuments()
        
        // If a pending request exists, delete it
        if let document = querySnapshot.documents.first {
            let notificationId = document.documentID
            try await userNotificationsList(uid: toUserId).document(notificationId).delete()
        }
    }
    
    // Fetch notifications for the current user
    func fetchNotifications(uid: String) async throws -> [Notification] {
        let notificationsSnapshot = try await userNotificationsList(uid: uid)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        var notifications = [Notification]()
        for document in notificationsSnapshot.documents {
            if let notification = try? document.data(as: Notification.self) {
                notifications.append(notification)
            }
        }
        
        return notifications
    }
}
