//
//  NotificationManager.swift
//  friends
//
//  Created by Bryan Hoang on 10/9/24.
//

import Foundation

enum notificationType: String, Codable {
    case friendRequest = "friendRequest"
    case hangoutRequest = "hangoutRequest"
    case reminder = "reminder"
    case placeholder = "placeholder"
}

enum notificationStatus: String, Codable {
    case accepted = "accepted"
    case rejected = "rejected"
    case pending = "pending"
    case read = "read"
    case unread = "unread"
}

struct Notification: Codable {
    var notificationId: String? // Store the generated notification ID
    var fromUserId: String
    var fromUserPP: [String]?
    var toUserId: String
    var type: notificationType
    var message: String?
    var status: notificationStatus
    var timestamp: Date
    
    init(notificationId: String? = nil,
         fromUserId: String,
         fromUserPP: [String],
         toUserId: String,
         type: notificationType,
         message: String?,
         status: notificationStatus = .unread,
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
        self.status = try container.decode(notificationStatus.self, forKey: .status)
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

struct Friend: Codable {
    var uid: String
    var timestamp: Date
    var photoURL: String?
    var fullName: String?
    var username: String?
    
    enum CodingKeys: String, CodingKey {
        case uid = "uid"
        case timestamp = "timestamp"
        case photoURL = "photo_url"
        case fullName = "full_name"
        case username = "username"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uid = try container.decode(String.self, forKey: .uid)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        self.fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        self.username = try container.decodeIfPresent(String.self, forKey: .username)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.uid, forKey: .uid)
        try container.encode(self.timestamp, forKey: .timestamp)
        try container.encodeIfPresent(self.photoURL, forKey: .photoURL)
        try container.encodeIfPresent(self.fullName, forKey: .fullName)
        try container.encodeIfPresent(self.username, forKey: .username)
    }
}

struct friendRequest: Codable {
    let friendId: String
    let requestDate: Date
    let recipientNId: String?
    let status: notificationStatus
    
    enum CodingKeys: String, CodingKey {
        case friendId = "friend_id"
        case requestDate = "request_date"
        case recipientNId = "recipient_nid"
        case status = "status"
    }
    
    init(friendId: String, 
         requestDate: Date,
         recipientNId: String,
         status: notificationStatus) {
        self.friendId = friendId
        self.requestDate = requestDate
        self.recipientNId = recipientNId
        self.status = status
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.friendId = try container.decode(String.self, forKey: .friendId)
        self.requestDate = try container.decode(Date.self, forKey: .requestDate)
        self.recipientNId = try container.decode(String.self, forKey: .recipientNId)
        self.status = try container.decode(notificationStatus.self, forKey: .status)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.friendId, forKey: .friendId)
        try container.encode(self.requestDate, forKey: .requestDate)
        try container.encode(self.recipientNId, forKey: .recipientNId)
        try container.encode(self.status, forKey: .status)
    }
}
