//
//  PlaceViewModel.swift
//  friends
//
//  Created by Bryan Hoang on 12/28/24.
//

import Foundation
import SwiftUI
import GooglePlacesSwift

class PlaceViewModel: ObservableObject, Identifiable {
    let id = UUID()
    let place: Place
    
    @Published var photos: [UIImage] = []
    @Published var isLoadingPhotos: Bool = false
    
    init(place: Place) {
        self.place = place
    }
    
    /// Fetch all photos for this place asynchronously.
    func fetchPhotos() async {
        do {
            await MainActor.run { isLoadingPhotos = true }
            let fetchedPhotos = try await PlacesManager.shared.fetchPlacePhotos(place: place)
            await MainActor.run {
                photos = fetchedPhotos
                isLoadingPhotos = false
            }
        } catch {
            await MainActor.run { isLoadingPhotos = false }
            print("Error fetching photos for \(place.displayName ?? "Unknown"):", error)
        }
    }
}
