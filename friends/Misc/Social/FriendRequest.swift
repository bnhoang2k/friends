//
//  FriendRequest.swift
//  friends
//
//  Created by Bryan Hoang on 10/9/24.
//

import Foundation

struct friendRequest: Codable {
    let friendId: String
    let requestDate: Date
    let recipientNId: String?
    let status: NotificationStatus
    
    enum CodingKeys: String, CodingKey {
        case friendId = "friend_id"
        case requestDate = "request_date"
        case recipientNId = "recipient_nid"
        case status = "status"
    }
    
    init(friendId: String,
         requestDate: Date,
         recipientNId: String,
         status: NotificationStatus) {
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
        self.status = try container.decode(NotificationStatus.self, forKey: .status)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.friendId, forKey: .friendId)
        try container.encode(self.requestDate, forKey: .requestDate)
        try container.encode(self.recipientNId, forKey: .recipientNId)
        try container.encode(self.status, forKey: .status)
    }
}
