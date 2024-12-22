//
//  GenerateLocationsView.swift
//  friends
//
//  Created by Bryan Hoang on 12/6/24.
//

import SwiftUI
import GooglePlacesSwift
import MapKit
import Kingfisher

struct GenerateLocationsView: View {
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var svm: SocialVM
    @ObservedObject var vvm: VertexViewModel
    @Binding var hangout: Hangout
    @Binding var showAddHangout: Bool
    
    @State private var parsed: [Place:[UIImage]] = [:]
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
                    ForEach(Array(parsed), id: \.key) { place, photos in
                        PlaceCardView(place: place,
                                      description: "test test test",
                                      isSelected: selectedPlace == place,
                                      photos: photos) {
                            selectedPlace = (selectedPlace == place) ? nil : place
                            isDetailPresented.toggle()
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .onTapGesture { dismissKeyboard() }
        .padding()
        .sheet(isPresented: $isDetailPresented) {
            selectedPlace = nil
        } content: {
            if let selectedPlace = selectedPlace {
                PlaceSheetView(place: selectedPlace,
                               photos: parsed[selectedPlace] ?? [],
                               showAddHangout: $showAddHangout) { place in
                    Task {
                        hangout.location = place.displayName
                        try await svm.createHangout(uid: avm.user?.uid ?? "", hangout: hangout)
                    }
                }
            }
        }
    }
}

extension GenerateLocationsView {
    func onGenerateTapped() {
        Task {
            isFetching = true      // Start fetching
            parsed = [:]          // Clear current items to prevent UI flickering
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
    let photos: [UIImage]
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
            ScrollView(.horizontal) {
                HStack {
                    ForEach(photos, id: \.self) {photo in
                        Image(uiImage: photo)
                            .resizable()
                            .frame(width: 200, height: 200)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
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
        }), showAddHangout: .constant(true))
        .environmentObject(AuthenticationVM())
        .environmentObject(SocialVM())
}
