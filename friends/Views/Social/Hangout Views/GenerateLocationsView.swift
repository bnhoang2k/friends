//
//  GenerateLocationsView.swift
//  friends
//
//  Created by Bryan Hoang on 12/6/24.
//

import SwiftUI

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
                    ForEach(locations, id: \.name) { location in
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
            
            if let parsedLocations = parseStructuredOutput(vvm.outputText) {
                DispatchQueue.main.async {
                    self.locations = parsedLocations
                }
            } else {
                DispatchQueue.main.async {
                    print("Error: Failed to parse locations.")
                    // Optionally show an alert or error UI to the user
                }
            }
        }
    }
    
    func parseStructuredOutput(_ output: String) -> [Location]? {
        guard let data = output.data(using: .utf8) else {
            print("Failed to convert output to Data")
            return nil
        }
        do {
            // Try decoding as an array of locations first
            if let locations = try? JSONDecoder().decode([Location].self, from: data) {
                for location in locations {
                    vvm.previousSuggestions.insert(location.name)
                }
                return locations
            }
        
            print("Failed to decode as array or object")
            return nil
        }
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
                    .foregroundColor(.primary) // Adaptable text color
                Spacer()
            }
            Text(location.description)
                .font(.subheadline)
                .foregroundColor(.secondary) // Adaptable text color
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground)) // Adaptable background
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
