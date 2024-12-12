//
//  FriendStatisticsView.swift
//  friends
//
//  Created by Bryan Hoang on 12/11/24.
//

import SwiftUI

struct FriendStatisticsView: View {
    // Dependency to calculate statistics
    let friendUtilities = FriendUtilities()
    
    // Data passed into the view
    var friendId: String = ""
    var hangoutList: [Hangout] = []
    
    var body: some View {
        VStack (spacing: 20) {
            // Personality Gradient
            PersonalityGradientView(personalityGradient: calculateFriendStatistics().personalityGradient)
            // Hard Stats
            HardStatsView(hardStats: calculateFriendStatistics().hardStats)
        }
        .padding()
    }
    
    // Function to calculate friend statistics based on friendId and hangoutList
    func calculateFriendStatistics() -> (personalityGradient: [String: Any], hardStats: [String: Any]) {
        return friendUtilities.calculateFriendStatistics(for: friendId, from: hangoutList)
    }
}

struct PersonalityGradientView: View {
    
    var personalityGradient: [String: Any] = [:]
    
    var body: some View {
        Section {
            HStack {
                Text("Vibe:")
                Spacer()
                Text("\(personalityGradient["mostCommonVibe"] as? String ?? "Unknown")")
            }
            HStack {
                Text("Outdoor Preference:")
                Spacer()
//                Text("\(Int((personalityGradient["indoorOutdoorRatio"] as? Double ?? 0) * 100))% outdoors")
            }
            HStack {
                Text("Hangout Duration:")
                Spacer()
                Text("\(personalityGradient["mostCommonDuration"] as? String ?? "Unknown")")
            }
        } header : {
            HStack {
                Text("Personality Gradient").font(.headline)
                Spacer()
                Image(systemName: "theatermasks")
            }
        }
    }
}

struct HardStatsView: View {
    
    var hardStats: [String: Any] = [:]
    
    var body: some View {
        Section {
            HStack {
                Text("Total Hangouts:")
                Spacer()
                Text("\(hardStats["totalHangouts"] as? Int ?? 0)")
            }
            HStack {
                Text("Average Budget: ")
                Spacer()
                Text("$\(String(format: "%.2f", hardStats["averageBudget"] as? Double ?? 0))")
            }
            HStack {
                Text("Vibes")
                    .font(.headline)
                Spacer()
                Image(systemName: "figure.2.arms.open")
            }
            // Display vibe counts dynamically
            if let vibesCount = hardStats["vibesCounts"] as? [HangoutVibe: Int] {
                
                let maxCount = vibesCount.values.max() ?? 1
                
                ForEach(vibesCount.sorted(by: { $0.value > $1.value }), id: \.key) { key, value in
                    HStack {
                        Label(key.rawValue.capitalized, systemImage: key.symbolName)
                        Spacer()
                        Text("\(value)") // Display the count
                    }
                    GeometryReader { geo in
                        Capsule()
                            .fill(Color.primary) // Customize bar color
                            .frame(width: geo.size.width * CGFloat(value) / CGFloat(maxCount), height: 10)
                            .animation(.easeInOut, value: value)
                    }
                    .frame(height: 10)
                }
            }
        } header: {
            HStack {
                Text("Hard Statistics")
                    .font(.headline)
                Spacer()
                Image(systemName: "chart.bar.xaxis")
            }
        }
    }
}

#Preview {
    // Sample data generation (for preview only)
    let friendUtilities = FriendUtilities()
    let dummyHangouts: [Hangout] = Utilities.shared.generateRandomHangouts(count: 100)
    
    return FriendStatisticsView(
        friendId: "1",
        hangoutList: dummyHangouts
    )
}
