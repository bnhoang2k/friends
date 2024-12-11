//
//  HangoutEnums.swift
//  friends
//
//  Created by Bryan Hoang on 12/10/24.
//

import Foundation

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
