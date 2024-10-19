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
    
    init(uid: String, timestamp: Date, photoURL: String? = nil, fullName: String? = nil, username: String? = nil) {
        self.uid = uid
        self.timestamp = timestamp
        self.photoURL = photoURL
        self.fullName = fullName
        self.username = username
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

struct Hangout: Codable {
    let hangoutId: String
    let date: Date
    let type: HangoutType
    let status: HangoutStatus
    let participantIds: [String]
    let groupId: String? // Optional identifier if it's a group hangout
    let location: String?
    let title: String?
    let description: String?
    let tags: [String]? // For quick categorization and recall
    let createdAt: Date?
    let updatedAt: Date?

    enum HangoutType: String, Codable {
        case oneOnOne = "one_on_one"
        case group = "group"
    }

    enum HangoutStatus: String, Codable {
        case pending = "pending"
        case confirmed = "confirmed"
        case completed = "completed"
        case cancelled = "cancelled"
    }

    enum CodingKeys: String, CodingKey {
        case hangoutId = "hangout_id"
        case date = "date"
        case type = "type"
        case status = "status"
        case participantIds = "participent_ids"
        case groupId = "group_id"
        case location = "location"
        case title = "title"
        case description = "description"
        case tags = "tags"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(hangoutId: String,
         date: Date,
         type: HangoutType,
         status: HangoutStatus,
         participantIds: [String],
         groupId: String? = nil,
         location: String? = nil,
         title: String? = nil,
         description: String? = nil,
         tags: [String]? = nil,
         createdAt: Date? = nil,
         updatedAt: Date? = nil) {
        self.hangoutId = hangoutId
        self.date = date
        self.type = type
        self.status = status
        self.participantIds = participantIds
        self.groupId = groupId
        self.location = location
        self.title = title
        self.description = description
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.hangoutId = try container.decode(String.self, forKey: .hangoutId)
        self.date = try container.decode(Date.self, forKey: .date)
        self.type = try container.decode(Hangout.HangoutType.self, forKey: .type)
        self.status = try container.decode(Hangout.HangoutStatus.self, forKey: .status)
        self.participantIds = try container.decode([String].self, forKey: .participantIds)
        self.groupId = try container.decodeIfPresent(String.self, forKey: .groupId)
        self.location = try container.decodeIfPresent(String.self, forKey: .location)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hangoutId, forKey: .hangoutId)
        try container.encode(date, forKey: .date)
        try container.encode(type, forKey: .type)
        try container.encode(status, forKey: .status)
        try container.encode(participantIds, forKey: .participantIds)
        try container.encodeIfPresent(groupId, forKey: .groupId)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}
