//
//  FriendUtilities.swift
//  friends
//
//  Created by Bryan Hoang on 12/11/24.
//

class FriendUtilities {
    func calculateFriendStatistics(for friendId: String,
                                   from hangouts: [Hangout]) -> (personalityGradient: [String: Any],
                                                                 hardStats: [String: Any]) {
        // Personality Gradient
        let vibeCounts = Dictionary(grouping: hangouts, by: { $0.vibe }).mapValues { $0.count }
        let mostCommonVibe = vibeCounts.max(by: { $0.value < $1.value })?.key
        let indoorOutdoorRatio = hangouts.isEmpty ? "Data Unavailable" : "\(Double(hangouts.filter { $0.isOutdoor }.count) / Double(hangouts.count))"
        let durationCounts = Dictionary(grouping: hangouts, by: { $0.duration }).mapValues { $0.count }
        let mostCommonDuration = durationCounts.max(by: { $0.value < $1.value })?.key
        
        // Hard Stats
        let totalHangouts = hangouts.count
        let averageBudget = hangouts.isEmpty ? 0 : hangouts.map { $0.budget }.reduce(0, +) / Double(hangouts.count)
        
        return (
            personalityGradient: [
                "mostCommonVibe": mostCommonVibe?.rawValue ?? "Unknown",
                "indoorOutdoorRatio": indoorOutdoorRatio,
                "mostCommonDuration": mostCommonDuration?.rawValue ?? "Unknown"
            ],
            hardStats: [
                "totalHangouts": totalHangouts,
                "averageBudget": averageBudget,
                "vibesCounts": vibeCounts,
            ]
        )
    }
}
