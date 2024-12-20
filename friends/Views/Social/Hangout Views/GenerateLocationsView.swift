//
//  GenerateLocationsView.swift
//  friends
//
//  Created by Bryan Hoang on 12/6/24.
//

import SwiftUI
import MapKit
import Kingfisher

struct GenerateLocationsView: View {
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var svm: SocialVM
    @ObservedObject var vvm: VertexViewModel
    @Binding var hangout: Hangout

    @State private var mapItems: [MKMapItem] = []
    @State private var selectedMapItem: MKMapItem? // Track selected map item
    @State private var isFetching: Bool = false   // Track fetch state

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
            } else if mapItems.isEmpty {
                Text("No locations available. Tap 'Regenerate' to try again.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                ScrollView {
                    ForEach(mapItems, id: \.self) { mapItem in
                        MapItemCardView(mapItem: mapItem,
                                        isSelected: selectedMapItem == mapItem) {
                            selectedMapItem = (selectedMapItem == mapItem) ? nil : mapItem
                        }
                        .padding()
                    }
                }
                Button {
                    hangout.location = selectedMapItem?.name ?? ""
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
            isFetching = true      // Start fetching
            mapItems = []          // Clear current items to prevent UI flickering
            selectedMapItem = nil  // Clear selection
            
            // Update the user input and start generating suggestions
            vvm.userInput = hangout.hangoutToText(userID: avm.user?.uid ?? "",
                                                  cachedFriendsList: svm.cachedFriendsList)
            await vvm.reason()

            // Fetch the new map items from VertexViewModel's output
            if let parsedMapItems = await vvm.parseStructuredOutput(vvm.outputText) {
                mapItems = parsedMapItems
            } else {
                print(vvm.outputText)
                print("Error: Failed to parse locations.")
            }

            isFetching = false     // Done fetching
        }
    }
}

struct MapItemCardView: View, Equatable {
    let mapItem: MKMapItem
    let isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(mapItem.name ?? "Unknown Place")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            if let address = mapItem.placemark.title {
                Text(address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if let url = mapItem.url {
                Text(url.absoluteString)
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
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

    static func == (lhs: MapItemCardView, rhs: MapItemCardView) -> Bool {
        return lhs.mapItem == rhs.mapItem && lhs.isSelected == rhs.isSelected
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
