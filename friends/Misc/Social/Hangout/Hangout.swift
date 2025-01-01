//
//  Hangout.swift
//  friends
//
//  Created by Bryan Hoang on 11/7/24.
//

import Foundation
import MapKit

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
    var location: Location?
    var title: String?
    var description: String?
    var tags: [String]? // For quick categorization and recall
    var budget: Double
    var isOutdoor: Bool
    var userPictures: [String]?
    
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
        case userPictures = "user_pictures"
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
         location: Location? = nil,
         title: String? = nil,
         description: String? = nil,
         tags: [String]? = nil,
         budget: Double,
         isOutdoor: Bool,
         userPictures: [String]? = nil) {
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
        self.userPictures = userPictures
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
        self.location = try container.decodeIfPresent(Location.self, forKey: .location)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags)
        self.budget = try container.decode(Double.self, forKey: .budget)
        self.isOutdoor = try container.decode(Bool.self, forKey: .isOutdoor)
        self.userPictures = try container.decodeIfPresent([String].self, forKey: .userPictures)
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
        try container.encodeIfPresent(userPictures, forKey: .userPictures)
    }
}

struct HangoutReference: Codable, Hashable {
    var hangoutId: String
    var hangoutPath: String
    var creationDate: Date
    var title: String
    var participantIds: [String]

    enum CodingKeys: String, CodingKey {
        case hangoutId = "hangout_id"
        case hangoutPath = "hangout_path"
        case creationDate = "creation_date"
        case title = "title"
        case participantIds = "participant_ids"
    }

    init(hangoutId: String,
         hangoutPath: String,
         creationDate: Date,
         title: String,
         participantIds: [String]) {
        self.hangoutId = hangoutId
        self.hangoutPath = hangoutPath
        self.creationDate = creationDate
        self.title = title
        self.participantIds = participantIds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hangoutId = try container.decode(String.self, forKey: .hangoutId)
        hangoutPath = try container.decode(String.self, forKey: .hangoutPath)
        creationDate = try container.decode(Date.self, forKey: .creationDate)
        title = try container.decode(String.self, forKey: .title)
        participantIds = try container.decode([String].self, forKey: .participantIds)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hangoutId, forKey: .hangoutId)
        try container.encode(hangoutPath, forKey: .hangoutPath)
        try container.encode(creationDate, forKey: .creationDate)
        try container.encode(title, forKey: .title)
        try container.encode(participantIds, forKey: .participantIds)
    }
}

struct Location: Codable, Equatable {
    var name: String
    var longitude: Double?
    var latitude: Double?
    
    init(name: String,
         coordinate: CLLocationCoordinate2D) {
        self.name = name
        self.longitude = coordinate.longitude
        self.latitude = coordinate.latitude
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, longitude, latitude
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        self.latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(latitude, forKey: .latitude)
    }
}
