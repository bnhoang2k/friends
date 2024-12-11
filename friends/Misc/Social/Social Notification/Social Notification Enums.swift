//
//  Social Notification Enums.swift
//  friends
//
//  Created by Bryan Hoang on 12/10/24.
//

import Foundation

enum NotificationType: String, Codable {
    case friendRequest = "friendRequest"
    case hangoutRequest = "hangoutRequest"
    case reminder = "reminder"
    case placeholder = "placeholder"
}

enum NotificationStatus: String, Codable {
    case accepted = "accepted"
    case rejected = "rejected"
    case pending = "pending"
    case read = "read"
    case unread = "unread"
}
