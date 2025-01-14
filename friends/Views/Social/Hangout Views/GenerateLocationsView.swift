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
    
    @Environment(\.dismiss) private var dismissNavStack
    
    @EnvironmentObject private var avm: AuthenticationVM
    @EnvironmentObject private var svm: SocialVM
    @ObservedObject var vvm: VertexViewModel
    @Binding var hangout: Hangout
    
    @State private var placeViewModels: [PlaceViewModel] = []
    @State private var selectedPlace: PlaceViewModel?
    @State private var isFetching: Bool = false
    @State private var isDetailPresented: Bool = false
    
    var body: some View {
        VStack {
            Button("Regenerate") {
                onGenerateTapped()
            }
            if isFetching {
                ProgressView()
            }
            else {
                ScrollView {
                    ForEach(placeViewModels, id: \.id) { placeVM in
                        PlaceCardView(
                            placeVM: placeVM,
                            isSelected: selectedPlace?.id == placeVM.id
                        ) {
                            selectedPlace = (selectedPlace?.id == placeVM.id) ? nil : placeVM
                            isDetailPresented.toggle()
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding()
        .sheet(isPresented: $isDetailPresented) {
            selectedPlace = nil
        } content: {
            if let placeVM = selectedPlace {
                PlaceSheetView(place: placeVM.place,
                               photos: placeVM.photos) { place in
                    Task {
                        hangout.location = Location(name: place.displayName ?? "PLACE NAME ERROR", coordinate: place.location)
                        dismissNavStack()
                    }
                }
            }
        }
    }
}

// MARK: - Generate
extension GenerateLocationsView {
    func onGenerateTapped() {
        Task {
            isFetching = true
            placeViewModels = []
            selectedPlace = nil
            
            // 1. Build user prompt
            vvm.userInput = hangout.hangoutToText(
                userID: avm.user?.uid ?? "",
                cachedFriendsList: svm.fvm.cachedFriendsList
            )
            
            // 2. Generate AI response
            await vvm.reason()
            
            // 3. Parse the JSON output -> [PlaceViewModel]
            let placeVMs = await vvm.parseStructuredOutput(vvm.outputText)
            placeViewModels = placeVMs
            
            // 4. Fetch photos in parallel for each place
            for vm in placeViewModels {
                Task {
                    await vm.fetchPhotos()
                }
            }
            
            isFetching = false
        }
    }
}

struct PlaceCardView: View, Equatable {
    @ObservedObject var placeVM: PlaceViewModel
    let isSelected: Bool
    var onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            // Place name & address
            Text(placeVM.place.displayName ?? "Unknown Place")
                .font(.headline)
            Text(placeVM.place.formattedAddress ?? "Unknown Address")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Photo area
            if placeVM.isLoadingPhotos {
                VStack {
                    Spacer()
                    ProgressView("Loading photos...")
                    Spacer()
                }
                .frame(height: 200)              // Reserve some vertical space
                .frame(maxWidth: .infinity)     // Fill the horizontal width
            } else if placeVM.photos.isEmpty {
                Text("No photos found")
                    .frame(height: 200)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(placeVM.photos, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 200, height: 200)
                                .clipped()
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .frame(maxWidth: .infinity)
        .onTapGesture {
            onTap()
        }
    }
    
    static func == (lhs: PlaceCardView, rhs: PlaceCardView) -> Bool {
        // You might refine this if you want more fine-grained control
        return lhs.placeVM.id == rhs.placeVM.id && lhs.isSelected == rhs.isSelected
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
