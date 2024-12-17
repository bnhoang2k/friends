//
//  Hangout.swift
//  friends
//
//  Created by Bryan Hoang on 11/7/24.
//

import Foundation

struct Hangout: Codable {
    var hangoutId: String
    /// Variable that holds when the hangout was created from a coding perspective
    /// user will not really interact with it.
    var creationDate: Date
    /// Date variables that the user WILL interact with
    var startDate: Date?
    var endDate: Date?
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
        case hangoutId = "hangout_id"
        case creationDate = "creation_date"
        case startDate = "start_date"
        case endDate = "end_date"
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
        case createdAt = "created_at"
    }
    
    // Default initializer for UI binding
    static func defaultHangout() -> Hangout {
        return Hangout(
            hangoutId: "",
            date: Date(),
            duration: .quick,
            vibe: .chill,
            status: .pending,
            participantIds: [],
            budget: 20.0,
            isOutdoor: false
        )
    }
    
    init(hangoutId: String,
         date: Date,
         startDate: Date? = nil,
         endDate: Date? = nil,
         duration: HangoutDuration,
         vibe: HangoutVibe,
         status: HangoutStatus,
         participantIds: [String],
         location: String? = nil,
         title: String? = nil,
         description: String? = nil,
         tags: [String]? = nil,
         budget: Double,
         isOutdoor: Bool) {
        self.hangoutId = hangoutId
        self.creationDate = date
        self.startDate = startDate
        self.endDate = endDate
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
        self.hangoutId = try container.decode(String.self, forKey: .hangoutId)
        self.creationDate = try container.decode(Date.self, forKey: .creationDate)
        self.startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        self.endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
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
        try container.encode(hangoutId, forKey: .hangoutId)
        try container.encode(creationDate, forKey: .creationDate)
        try container.encodeIfPresent(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
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
    var hangout_id : String
    
    enum CodingKeys: String, CodingKey {
        case hangoutId = "hangout_id"
    }
    
    init(hangoutId: String) {
        self.hangout_id = hangoutId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hangout_id = try container.decode(String.self, forKey: .hangoutId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hangout_id, forKey: .hangoutId)
    }
}
