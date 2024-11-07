//
//  Friend.swift
//  friends
//
//  Created by Bryan Hoang on 10/9/24.
//

import Foundation

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
