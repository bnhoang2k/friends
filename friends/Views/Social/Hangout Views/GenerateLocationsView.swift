//
//  GenerateLocationsView.swift
//  friends
//
//  Created by Bryan Hoang on 12/6/24.
//

import SwiftUI
import GooglePlacesSwift
import MapKit

struct GenerateLocationsView: View {
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var svm: SocialVM
    @ObservedObject var vvm: VertexViewModel
    @Binding var hangout: Hangout
    
    @State private var parsed: [Place] = []
    @State private var selectedPlace: Place? // Track selected map item
    @State private var isFetching: Bool = false   // Track fetch state
    @State private var isDetailPresented: Bool = false // Control sheet presentation
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    onGenerateTapped()
                } label: {
                    Text("Regenerate")
                }
            }
            if isFetching {
                ProgressView("Loading...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else if parsed.isEmpty {
                Text("No locations available. Tap 'Regenerate' to try again.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                ScrollView {
                    ForEach(parsed, id: \.self) { place in
                        PlaceCardView(place: place,
                                      description: "test test test",
                                      isSelected: selectedPlace == place) {
                            selectedPlace = (selectedPlace == place) ? nil : place
                            isDetailPresented.toggle()
                        }
                    }
                }
                Button {
                    if let placeName = selectedPlace?.displayName {
                        Task {
                            hangout.location = placeName
                            try await svm.createHangout(uid: avm.user?.uid ?? "", hangout: hangout)
                        }
                    }
                } label: {
                    Text("Finish")
                }
            }
        }
        .onTapGesture { dismissKeyboard() }
        .padding()
        .sheet(isPresented: $isDetailPresented) {
            if let selectedPlace = selectedPlace {
                PlaceSheetView(place: selectedPlace)
            }
        }
    }
}

extension GenerateLocationsView {
    func onGenerateTapped() {
        Task {
            isFetching = true      // Start fetching
            parsed = []          // Clear current items to prevent UI flickering
            selectedPlace = nil  // Clear selection
            
            // Update the user input and start generating suggestions
            vvm.userInput = hangout.hangoutToText(userID: avm.user?.uid ?? "",
                                                  cachedFriendsList: svm.cachedFriendsList)
            await vvm.reason()
            
            // Fetch the new map items from VertexViewModel's output
            if let parsedMapItems = await vvm.parseStructuredOutput(vvm.outputText) {
                parsed = parsedMapItems
            } else {
                print(vvm.outputText)
                print("Error: Failed to parse locations.")
            }
            
            isFetching = false     // Done fetching
        }
    }
}

struct PlaceCardView: View, Equatable {
    let place: Place
    let description: String?
    let isSelected: Bool
    var onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(place.displayName ?? "Unknown Place")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            HStack {
                Text(place.formattedAddress ?? "Unknown Address")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.green : Color.clear,
                                lineWidth: 2)
                )
                .shadow(radius: 4)
        )
        .onTapGesture {
            onTap()
        }
    }
    
    static func == (lhs: PlaceCardView, rhs: PlaceCardView) -> Bool {
        return lhs.place == rhs.place && lhs.isSelected == rhs.isSelected
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
