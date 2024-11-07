//
//  Hangout.swift
//  friends
//
//  Created by Bryan Hoang on 11/7/24.
//

import Foundation

struct Hangout: Codable {
    var hangoutId: String
    var date: Date
    var duration: HangoutDuration
    var vibe: HangoutVibe
    var category: HangoutCategory
    var status: HangoutStatus
    var participants: [String]
    var groupId: String? // Optional identifier if it's a group hangout
    var location: String?
    var title: String?
    var description: String?
    var tags: [String]? // For quick categorization and recall
    var budget: Double
    var isOutdoor: Bool
    var activityLevel: ActivityLevel
    var foodAndDrinkPreferences: FoodAndDrinkPreferences
    var createdAt: Date?
    var updatedAt: Date?
    
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
    
    enum HangoutCategory: String, Codable, CaseIterable {
        case oneOnOne = "one_on_one"
        case group = "group"
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
    }
    
    enum ActivityLevel: String, Codable {
        case low
        case moderate
        case high
    }
    
    struct FoodAndDrinkPreferences: Codable {
        let diningOut: Bool
    }
    
    enum CodingKeys: String, CodingKey {
        case hangoutId = "hangout_id"
        case date = "date"
        case duration = "duration"
        case vibe = "vibe"
        case category = "category"
        case status = "status"
        case participantIds = "participant_ids"
        case groupId = "group_id"
        case location = "location"
        case title = "title"
        case description = "description"
        case tags = "tags"
        case budget = "budget"
        case isOutdoor = "is_outdoor"
        case activityLevel = "activity_level"
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
            category: .group,
            status: .pending,
            participantIds: [],
            budget: 20.0,
            isOutdoor: false,
            activityLevel: .low,
            foodAndDrinkPreferences: FoodAndDrinkPreferences(
                diningOut: true
            )
        )
    }
    
    init(hangoutId: String,
         date: Date,
         duration: HangoutDuration,
         vibe: HangoutVibe,
         category: HangoutCategory,
         status: HangoutStatus,
         participantIds: [String],
         groupId: String? = nil,
         location: String? = nil,
         title: String? = nil,
         description: String? = nil,
         tags: [String]? = nil,
         budget: Double,
         isOutdoor: Bool,
         activityLevel: ActivityLevel,
         foodAndDrinkPreferences: FoodAndDrinkPreferences,
         createdAt: Date? = nil,
         updatedAt: Date? = nil) {
        self.hangoutId = hangoutId
        self.date = date
        self.duration = duration
        self.vibe = vibe
        self.category = category
        self.status = status
        self.participants = participantIds
        self.groupId = groupId
        self.location = location
        self.title = title
        self.description = description
        self.tags = tags
        self.budget = budget
        self.isOutdoor = isOutdoor
        self.activityLevel = activityLevel
        self.foodAndDrinkPreferences = foodAndDrinkPreferences
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.hangoutId = try container.decode(String.self, forKey: .hangoutId)
        self.date = try container.decode(Date.self, forKey: .date)
        self.duration = try container.decode(HangoutDuration.self, forKey: .duration)
        self.vibe = try container.decode(HangoutVibe.self, forKey: .vibe)
        self.category = try container.decode(HangoutCategory.self, forKey: .category)
        self.status = try container.decode(HangoutStatus.self, forKey: .status)
        self.participants = try container.decode([String].self, forKey: .participantIds)
        self.groupId = try container.decodeIfPresent(String.self, forKey: .groupId)
        self.location = try container.decodeIfPresent(String.self, forKey: .location)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags)
        self.budget = try container.decode(Double.self, forKey: .budget)
        self.isOutdoor = try container.decode(Bool.self, forKey: .isOutdoor)
        self.activityLevel = try container.decode(ActivityLevel.self, forKey: .activityLevel)
        self.foodAndDrinkPreferences = try container.decode(FoodAndDrinkPreferences.self, forKey: .foodAndDrinkPreferences)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hangoutId, forKey: .hangoutId)
        try container.encode(date, forKey: .date)
        try container.encode(duration, forKey: .duration)
        try container.encode(vibe, forKey: .vibe)
        try container.encode(category, forKey: .category)
        try container.encode(status, forKey: .status)
        try container.encode(participants, forKey: .participantIds)
        try container.encodeIfPresent(groupId, forKey: .groupId)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encode(budget, forKey: .budget)
        try container.encode(isOutdoor, forKey: .isOutdoor)
        try container.encode(activityLevel, forKey: .activityLevel)
        try container.encode(foodAndDrinkPreferences, forKey: .foodAndDrinkPreferences)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
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
