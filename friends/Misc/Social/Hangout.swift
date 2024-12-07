//
//  Hangout.swift
//  friends
//
//  Created by Bryan Hoang on 11/7/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Hangout: Codable {
    var hangoutId: String
    var date: Date
    var duration: HangoutDuration
    var vibe: HangoutVibe
    var status: HangoutStatus
    var participants: [String]
    var location: String?
    var title: String?
    var description: String?
    var tags: [String]? // For quick categorization and recall
    var budget: Double
    var isOutdoor: Bool
    
    enum HangoutVibe: String, Codable, CaseIterable {
        case calm = "Calm"
        case relaxing = "Relaxing"
        case chill = "Chill"
        case social = "Social"
        case energetic = "Energetic"
        case exciting = "Exciting"
        case adventurous = "Adventurous"
        case wild = "Wild"
        
        var description: String {
            switch self {
            case .calm:
                return "Calm and peaceful"
            case .relaxing:
                return "Relaxed and laid-back"
            case .chill:
                return "Easy-going and casual"
            case .social:
                return "Low-key social hangout"
            case .energetic:
                return "Uplifting and active"
            case .exciting:
                return "Upbeat and fun"
            case .adventurous:
                return "High-energy and adventurous"
            case .wild:
                return "Exciting and physically demanding"
            }
        }
    }
    
    enum HangoutStatus: String, Codable {
        case pending = "pending"
        case confirmed = "confirmed"
        case completed = "completed"
        case cancelled = "cancelled"
    }
    
    enum HangoutDuration: String, Codable, CaseIterable {
        case quick = "quick"
        case halfDay = "half_day"
        case fullDay = "full_day"
        case overnight = "overnight"
        
        var description: String {
            switch self {
            case .quick:
                return "Quick"
            case .halfDay:
                return "Half Day"
            case .fullDay:
                return "Full Day"
            case .overnight:
                return "Overnight"
            }
        }
    }
    
    struct FoodAndDrinkPreferences: Codable {
        let diningOut: Bool
    }
    
    enum CodingKeys: String, CodingKey {
        case hangoutId = "hangout_id"
        case date = "date"
        case duration = "duration"
        case vibe = "vibe"
        case status = "status"
        case participantIds = "participant_ids"
        case groupId = "group_id"
        case location = "location"
        case title = "title"
        case description = "description"
        case tags = "tags"
        case budget = "budget"
        case isOutdoor = "is_outdoor"
        case foodAndDrinkPreferences = "food_and_drink_preferences"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Default initializer for UI binding
    static func defaultHangout() -> Hangout {
        return Hangout(
            hangoutId: UUID().uuidString,
            date: Date(),
            duration: .quick,
            vibe: .chill,
            status: .pending,
            participantIds: [],
            budget: 20.0,
            isOutdoor: false,
            foodAndDrinkPreferences: FoodAndDrinkPreferences(
                diningOut: true
            )
        )
    }
    
    init(hangoutId: String,
         date: Date,
         duration: HangoutDuration,
         vibe: HangoutVibe,
         status: HangoutStatus,
         participantIds: [String],
         groupId: String? = nil,
         location: String? = nil,
         title: String? = nil,
         description: String? = nil,
         tags: [String]? = nil,
         budget: Double,
         isOutdoor: Bool,
         foodAndDrinkPreferences: FoodAndDrinkPreferences,
         createdAt: Date? = nil,
         updatedAt: Date? = nil) {
        self.hangoutId = hangoutId
        self.date = date
        self.duration = duration
        self.vibe = vibe
        self.status = status
        self.participants = participantIds
        self.location = location
        self.title = title
        self.description = description
        self.tags = tags
        self.budget = budget
        self.isOutdoor = isOutdoor
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.hangoutId = try container.decode(String.self, forKey: .hangoutId)
        self.date = try container.decode(Date.self, forKey: .date)
        self.duration = try container.decode(HangoutDuration.self, forKey: .duration)
        self.vibe = try container.decode(HangoutVibe.self, forKey: .vibe)
        self.status = try container.decode(HangoutStatus.self, forKey: .status)
        self.participants = try container.decode([String].self, forKey: .participantIds)
        self.location = try container.decodeIfPresent(String.self, forKey: .location)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags)
        self.budget = try container.decode(Double.self, forKey: .budget)
        self.isOutdoor = try container.decode(Bool.self, forKey: .isOutdoor)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hangoutId, forKey: .hangoutId)
        try container.encode(date, forKey: .date)
        try container.encode(duration, forKey: .duration)
        try container.encode(vibe, forKey: .vibe)
        try container.encode(status, forKey: .status)
        try container.encode(participants, forKey: .participantIds)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encode(budget, forKey: .budget)
        try container.encode(isOutdoor, forKey: .isOutdoor)
    }
}

extension Hangout {
    func getHangoutVibe(for value: Double) -> HangoutVibe {
        switch value {
        case 0.875...1.0:
            return .wild
        case 0.75..<0.875:
            return .adventurous
        case 0.625..<0.75:
            return .exciting
        case 0.5..<0.625:
            return .energetic
        case 0.375..<0.5:
            return .social
        case 0.25..<0.375:
            return .chill
        case 0.125..<0.25:
            return .relaxing
        default:
            return .calm
        }
    }
}

extension Hangout {
    // Converts the Hangout object into a descriptive text representation for the LLM model in a human-friendly paragraph format.
    func hangoutToText(userID: String, cachedFriendsList: [String: DBUser]) -> String {
        var textComponents: [String] = []
        
        textComponents.append("On \(formattedDate(date)), a hangout is planned with a \(duration.description.lowercased()) duration, aiming for a \(vibe.description.lowercased()) vibe.")
        
        if let title = title {
            textComponents.append("The event is titled '\(title)'.")
        }
        
        if let description = description {
            textComponents.append("Here's a bit more about it: \(description).")
        }
        
        if !participants.isEmpty {
            let participantInformation = participants.filter{ $0 != userID }.map{ cachedFriendsList[$0]?.fullName ?? $0 }
            if !participantInformation.isEmpty {
                textComponents.append("The participants include: \(participantInformation.joined(separator: ", ")).")
            }
        }
        
        if let location = location {
            textComponents.append("The hangout will take place at \(location).")
        }
        
        if let tags = tags, !tags.isEmpty {
            textComponents.append("It is categorized under: \(tags.joined(separator: ", ")).")
        }
        
        textComponents.append("The budget for this hangout is approximately $\(String(format: "%.2f", budget)).")
        textComponents.append("This hangout is \(isOutdoor ? "outdoors" : "indoors")")
        
        return textComponents.joined(separator: " ")
    }
    
    // Helper function to format the date
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

final class HangoutManager {
    static let shared = HangoutManager()
    private init() {}
    
    // High-level hangout collection
    private let hangoutCollection = Firestore.firestore().collection("hangouts")
    
    // Low-level hangout collection holding hangout reference files.
    func userHangoutCollection(uid: String) -> CollectionReference {
        return UserManager.shared.userDocument(uid: uid).collection("hangouts")
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

extension HangoutManager {
    func create_HighLevelHangout(hangout: Hangout) async throws {
        
    }
}
