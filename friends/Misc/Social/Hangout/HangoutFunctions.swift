//
//  HangoutFunctions.swift
//  friends
//
//  Created by Bryan Hoang on 12/10/24.
//

import Foundation

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
        
        if !participantIds.isEmpty {
            let participantInformation = participantIds.filter{ $0 != userID }.map{ cachedFriendsList[$0]?.fullName ?? $0 }
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
