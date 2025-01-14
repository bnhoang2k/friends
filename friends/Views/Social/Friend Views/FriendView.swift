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
    @State private var loadingHangouts: Bool = true
    
    var body: some View {
        NavigationStack {
            if !loadingHangouts {
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
                .transition(.opacity.animation(.easeInOut))
            }
            else {
                ProgressView()
                        .transition(.opacity.animation(.easeInOut))
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AddHangoutView(friendID: friend.uid)
                        .environmentObject(avm)
                        .environmentObject(svm)
                        .onDisappear {
                            filteredHangoutList = svm.hvm.getFilteredHangoutsByFriend(friendId: friend.uid)
                        }
                } label: {
                    Image(systemName: "plus")
                }
            }
//            ToolbarItem(placement: .topBarTrailing) {
//                Button {
//                    Task {
//                        for i in 0...25 {
//                            try await svm.createHangout(uid: avm.user?.uid ?? "",
//                                                        hangout: Utilities.shared.createRandomHangout(uid: avm.user?.uid ?? "",
//                                                                                                      friendId: friend.uid))
//                        }
//                    }
//                } label: {
//                    Image(systemName: "testtube.2")
//                }
//            }
        }
        .task {
            do {
                svm.hvm.listenForHangouts(for: friend.uid, uid: avm.user?.uid ?? "")
                try await svm.hvm.fetchHangouts(uid: avm.user?.uid ?? "",
                                                friendId: friend.uid)
                filteredHangoutList = svm.hvm.getFilteredHangoutsByFriend(friendId: friend.uid)
                loadingHangouts = false
            }
            catch {
                print("Error: \(error.localizedDescription)")
            }
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
                    Text("Average Money Spent:")
                    Spacer()
                    Text("$\(String(format: "%.2f", hardStats["averageBudget"] as? Double ?? 0))")
                }
                
                // Vibes Section
                DisclosureGroup(isExpanded: $isVibesExpanded) {
                    if let vibesCount = hardStats["vibesCounts"] as? [HangoutVibe: Int] {
                        let maxCount = vibesCount.values.max() ?? 1
                        let sortedVibes = Array(vibesCount.sorted(by: { $0.value > $1.value }))
                        
                        VStack {
                            ForEach(sortedVibes.indices, id: \.self) { index in
                                let key = sortedVibes[index].key
                                let value = sortedVibes[index].value
                                
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
                                            .animation(.easeInOut(duration: 0.4), value: isVibesExpanded)
                                    }
                                    .frame(height: 10)
                                }
                                .opacity(isVibesExpanded ? 1 : 0) // Fade out
                                .offset(y: isVibesExpanded ? 0 : CGFloat(-20 * index)) // Pull up blinds effect
                                .animation(.easeInOut(duration: 0.2).delay(0.01 * Double(index)), value: isVibesExpanded)
                            }
                        }
                        .padding(.top)
                    }
                } label: {
                    HStack {
                        Text("Vibes")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "sparkles")
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
            .environmentObject(avm)
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
