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
