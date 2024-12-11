//
//  Hangout.swift
//  friends
//
//  Created by Bryan Hoang on 11/7/24.
//

import Foundation

struct Hangout: Codable, Identifiable {
    var id: String
    var hangoutId: String
    var date: Date
    var duration: HangoutDuration
    var vibe: HangoutVibe
    var status: HangoutStatus
    var participantIds: [String]
    var location: String?
    var title: String?
    var description: String?
    var tags: [String]? // For quick categorization and recall
    var budget: Double
    var isOutdoor: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "id" // needed for identifiable
        case hangoutId = "hangout_id"
        case date = "date"
        case duration = "duration"
        case vibe = "vibe"
        case status = "status"
        case participantIds = "participant_ids"
        case location = "location"
        case title = "title"
        case description = "description"
        case tags = "tags"
        case budget = "budget"
        case isOutdoor = "is_outdoor"
        case foodAndDrinkPreferences = "food_and_drink_preferences"
        case createdAt = "created_at"
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
        self.id = UUID().uuidString
        self.hangoutId = hangoutId
        self.date = date
        self.duration = duration
        self.vibe = vibe
        self.status = status
        self.participantIds = participantIds
        self.location = location
        self.title = title
        self.description = description
        self.tags = tags
        self.budget = budget
        self.isOutdoor = isOutdoor
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.hangoutId = try container.decode(String.self, forKey: .hangoutId)
        self.date = try container.decode(Date.self, forKey: .date)
        self.duration = try container.decode(HangoutDuration.self, forKey: .duration)
        self.vibe = try container.decode(HangoutVibe.self, forKey: .vibe)
        self.status = try container.decode(HangoutStatus.self, forKey: .status)
        self.participantIds = try container.decode([String].self, forKey: .participantIds)
        self.location = try container.decodeIfPresent(String.self, forKey: .location)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags)
        self.budget = try container.decode(Double.self, forKey: .budget)
        self.isOutdoor = try container.decode(Bool.self, forKey: .isOutdoor)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(hangoutId, forKey: .hangoutId)
        try container.encode(date, forKey: .date)
        try container.encode(duration, forKey: .duration)
        try container.encode(vibe, forKey: .vibe)
        try container.encode(status, forKey: .status)
        try container.encode(participantIds, forKey: .participantIds)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encode(budget, forKey: .budget)
        try container.encode(isOutdoor, forKey: .isOutdoor)
    }
}

struct HangoutReference: Codable {
    var id : String
    var hangout_id : String
    
    enum CodingKeys: String, CodingKey {
        case id
        case hangoutId = "hangout_id"
    }
    
    init(id: String, hangoutId: String) {
        self.id = id
        self.hangout_id = hangoutId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        hangout_id = try container.decode(String.self, forKey: .hangoutId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(hangout_id, forKey: .hangoutId)
    }
}
