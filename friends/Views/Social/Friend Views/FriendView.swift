//
//  FriendView.swift
//  friends
//
//  Created by Bryan Hoang on 10/19/24.
//

import SwiftUI

struct FriendView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var svm: SocialVM
    
    let friend: DBUser
    @State private var searchText: String = ""
    
    // Dependency to calculate statistics
    let friendUtilities = FriendUtilities()
    // Store pre-computed statistics
    private var friendStatistics: (personalityGradient: [String: Any],
                    hardStats: [String: Any]) {
                    friendUtilities.calculateFriendStatistics(for: friend.uid, from: filteredHangoutList)
                }
    
    @State private var filteredHangoutList: [Hangout] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Personality Gradient
                    PersonalityGradientView(personalityGradient: friendStatistics.personalityGradient)
                    // Hard Stats
                    HardStatsView(hardStats: friendStatistics.hardStats)
                    // Hangouts
                    RecentHangoutView(hangoutList: $filteredHangoutList,
                                      searchText: $searchText)
                    .environmentObject(svm)
                }
            }
            .scrollIndicators(.hidden)
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AddHangoutView(friendID: friend.uid)
                        .environmentObject(avm)
                        .environmentObject(svm)
                        .onDisappear {
                            filteredHangoutList = svm.getFilteredHangoutsByFriend(friendId: friend.uid)
                        }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            filteredHangoutList = svm.getFilteredHangoutsByFriend(friendId: friend.uid)
        }
        .font(.custom(GlobalVariables.shared.APP_FONT,
                      size: GlobalVariables.shared.textBody))
        .tint(.primary)
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
                Text("\((personalityGradient["indoorOutdoorRatio"] as? String == "Data Unavailable") ? "Data Unavailable" : "\(Int((Double(personalityGradient["indoorOutdoorRatio"] as? String ?? "0") ?? 0) * 100))% outdoors")")
                
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
    
    @State private var isVibesExpanded: Bool = true // Tracks the expanded/collapsed state of "Vibes"
    @State private var isAnimating: Bool = false // Prevents spamming during animation
    
    var body: some View {
        Section {
            VStack(spacing: 10) {
                // Total Hangouts
                HStack {
                    Text("Total Hangouts:")
                    Spacer()
                    Text("\(hardStats["totalHangouts"] as? Int ?? 0)")
                }
                
                // Average Budget
                HStack {
                    Text("Average Budget:")
                    Spacer()
                    Text("$\(String(format: "%.2f", hardStats["averageBudget"] as? Double ?? 0))")
                }
                
                // Vibes Section
                VStack(spacing: 0) {
                    // Header for "Vibes"
                    Button(action: {
                        guard !isAnimating else { return } // Prevent spamming
                        isAnimating = true
                        withAnimation(Animation.easeInOut(duration: 0.3)) {
                            isVibesExpanded.toggle()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isAnimating = false
                        }
                    }) {
                        HStack {
                            Text("Vibes")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "sparkles")
                        }
                        .contentShape(Rectangle()) // Makes the entire header tappable
                    }
                    
                    // Collapsible Content for "Vibes"
                    if isVibesExpanded {
                        if let vibesCount = hardStats["vibesCounts"] as? [HangoutVibe: Int] {
                            
                            let maxCount = vibesCount.values.max() ?? 1
                            
                            Group {
                                ForEach(vibesCount.sorted(by: { $0.value > $1.value }), id: \ .key) { key, value in
                                    VStack {
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
                            }
                            .padding(.top)
                            .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity)) // Control animation direction
                        }
                    }
                }
            }
        }
        header: {
            HStack {
                Text("Hard Statistics").font(.headline)
                Spacer()
                Image(systemName: "chart.bar.xaxis")
            }
        }
    }
}

struct RecentHangoutView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var svm: SocialVM
    @Binding var hangoutList: [Hangout]
    @Binding var searchText: String
    
    var body: some View {
        NavigationLink {
            HangoutListView(hangoutList: $hangoutList,
                            searchText: $searchText)
            .environmentObject(svm)
        } label: {
            HStack {
                Text("Your most recent hangouts")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        // Show up to five most recent hangouts
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(hangoutList.indices, id: \.self) { index in
                    if index < 5 {
                        NavigationLink {
                            HangoutInformationView(hangout: $hangoutList[index])
                                .environmentObject(avm)
                                .environmentObject(svm)
                        } label: {
                            HangoutCardView(hangout: hangoutList[index])
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let hangoutList = Utilities.shared.generateRandomHangouts(count: 100)
    NavigationStack {
        FriendView(friend: DBUser(uid: "1"))
        .environmentObject(AuthenticationVM())
        .environmentObject(SocialVM())
    }
}
