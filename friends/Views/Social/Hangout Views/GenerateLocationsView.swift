//
//  GenerateLocationsView.swift
//  friends
//
//  Created by Bryan Hoang on 12/6/24.
//

import SwiftUI
import MarkdownUI

struct GenerateLocationsView: View {
    
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var svm: SocialVM
    @ObservedObject var vvm: VertexViewModel
    @Binding var hangout: Hangout
    
    @State private var locations: [Location] = []
    @State private var selectedLocation: Location? // Track selected location
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    onGenerateTapped()
                } label: {
                    Text("Regenerate")
                }
            }
            if vvm.inProgress {
                ProgressView()
            } else if locations.isEmpty {
                Text("No locations available. Tap 'Regenerate' to try again.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                ScrollView {
                    ForEach(locations) { location in
                        EquatableView(content: LocationCardView(location: location, isSelected: selectedLocation == location) {
                            selectedLocation = (selectedLocation == location) ? nil : location
                        })
                        .padding()
                    }
                }
                Button {
                    hangout.location = selectedLocation?.name
                    Task {
                        try await svm.createHangout(uid: avm.user?.uid ?? "", hangout: hangout)
                    }
                } label: {
                    Text("Finish")
                }
            }
        }
        .onTapGesture { dismissKeyboard() }
        .padding()
    }
}

extension GenerateLocationsView {
    func onGenerateTapped() {
        Task {
            vvm.userInput = hangout.hangoutToText(userID: avm.user?.uid ?? "",
                                                  cachedFriendsList: svm.cachedFriendsList)
            await vvm.reason()
            
            let parsedLocations = parseLocations(from: vvm.outputText)
            DispatchQueue.main.async {
                if parsedLocations.isEmpty {
                    print("Error: No valid locations parsed.")
                    // Optionally show an alert or error UI to the user
                }
                self.locations = parsedLocations
            }
        }
    }
    
    func parseLocations(from markdown: String) -> [Location] {
        var locations = [Location]()
        
        // Split the response into lines
        let lines = markdown.split(separator: "\n")
        
        // Identify the lines that form the markdown table
        let tableLines = lines.filter { $0.contains("|") && !$0.contains("---") }
        
        // Ensure table lines are present
        guard !tableLines.isEmpty else {
            print("Error: No valid markdown table found.")
            return []
        }
        
        // Skip the header row if it matches the expected format
        for line in tableLines {
            // Skip the header if it contains column titles
            if line.lowercased().contains("place name") || line.lowercased().contains("why it's good") {
                continue
            }
            
            let columns = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            
            // Ensure at least two columns are present (Place Name and Why It's Good)
            guard columns.count >= 2 else {
                print("Error: Malformed table row: \(line)")
                continue
            }
            
            // Create a Location object from the parsed columns
            let location = Location(name: columns[0], location: "Unknown", description: columns[1])
            locations.append(location)
        }
        
        return locations
    }
    
}

private struct GenerateButtonSection: View {
    @Binding var userInput: String
    @Binding var hangout: Hangout
    var avm: AuthenticationVM
    var svm: SocialVM
    @Binding var selectedTab: Int
    
    var body: some View {
        Button {
            userInput = hangout.hangoutToText(userID: avm.user?.uid ?? "",
                                              cachedFriendsList: svm.cachedFriendsList)
            selectedTab = 2
        } label: {
            Text("Generate")
                .frame(maxWidth: .infinity)
                .padding([.horizontal])
        }
        .buttonStyle(.borderless)
    }
}

struct LocationCardView: View, Equatable {
    let location: Location
    let isSelected: Bool
    var onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(location.name)
                    .font(.headline)
                Spacer()
            }
            Text(location.description)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
                )
                .shadow(radius: 4)
        )
        .onTapGesture {
            onTap()
        }
    }

    static func == (lhs: LocationCardView, rhs: LocationCardView) -> Bool {
        return lhs.location == rhs.location && lhs.isSelected == rhs.isSelected
    }
}

#Preview {
    var hangout = Hangout.defaultHangout()
    GenerateLocationsView(vvm: VertexViewModel(), hangout: Binding(get: {
        hangout
    }, set: { newValue in
        hangout = newValue
    }))
    .environmentObject(AuthenticationVM())
    .environmentObject(SocialVM())
}
