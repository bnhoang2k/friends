//
//  Friend.swift
//  friends
//
//  Created by Bryan Hoang on 10/9/24.
//

import Foundation

// Stores metadata; put in a subcollection within the db_user.
struct Friend: Codable {
    var uid: String
    var timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case uid = "uid"
        case timestamp = "timestamp"
    }
    
    init(uid: String, timestamp: Date) {
        self.uid = uid
        self.timestamp = timestamp
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uid = try container.decode(String.self, forKey: .uid)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.uid, forKey: .uid)
        try container.encode(self.timestamp, forKey: .timestamp)
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
