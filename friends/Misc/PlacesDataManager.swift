import Foundation
import MapKit
import FirebaseFunctions
import GooglePlacesSwift

final class PlacesManager {
    static let shared = PlacesManager()
    let functions = Functions.functions(region: "us-central1")
    private init () {}
    private var apikey: String = ""
    private var googlePlacesClient: PlacesClient? = nil
}

// Google Cloud
extension PlacesManager {
    func fetchAPIKey() async throws {
        do {
            let result = try await functions.httpsCallable("getGooglePlacesAPIKey").call()
            guard let data = result.data as? [String: Any],
                  let fetchedKey = data["apiKey"] as? String else {
                throw NSError(domain: "PlacesManager",
                              code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])
            }
            PlacesClient.provideAPIKey(fetchedKey)
            apikey = fetchedKey
            googlePlacesClient = await PlacesClient.shared
        } catch {
            print("Error fetching API key: \(error.localizedDescription)")
            throw error
        }
    }
}

// Actual functions
extension PlacesManager {
    /// Fetch nearby place details for a given map item
    func fetchPlaceDetails(name: String) async throws -> [Place] {
        guard let googlePlacesClient else {
            throw NSError(domain: "PlacesManager",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Google Places client not initialized"])
        }
        
        // TODO: Temporary; need to get user location and throw it in here.
        let circularLocationRestriction = CircularCoordinateRegion(center: CLLocationCoordinate2D(latitude: 39.7392,
                                                                                                  longitude: 104.9903),
                                                                   radius: 10000)
        
        let placeProperties: [PlaceProperty] = [
            PlaceProperty.placeID,
            PlaceProperty.displayName,
            PlaceProperty.formattedAddress,
            PlaceProperty.internationalPhoneNumber,
            PlaceProperty.coordinate,
            PlaceProperty.websiteURL,
            PlaceProperty.editorialSummary,
            PlaceProperty.currentOpeningHours,
            PlaceProperty.timeZone,
            PlaceProperty.priceLevel,
            PlaceProperty.rating,
            PlaceProperty.numberOfUserRatings,
            PlaceProperty.photos,
            PlaceProperty.types
        ]
        
        let request = SearchByTextRequest(textQuery: name,
                                          placeProperties: placeProperties,
                                          locationRestriction: circularLocationRestriction,
                                          maxResultCount: 1)
        
        switch await googlePlacesClient.searchByText(with: request) {
        case .success(let places):
            return places
        case .failure(let placesError):
            throw placesError
        }
    }
    /// Fetch photos; this is a needed function because fetchPlaceDetails only grabs the photo's metadata.
    func fetchPlacePhotos(place: Place) async throws -> [UIImage] {
        guard let googlePlacesClient else {
            throw NSError(domain: "PlacesManager",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Google Places client not initialized"])
        }
        guard let photos = place.photos else {
            throw NSError(domain: "PlacesManager",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "No photos found"])
        }
        var res: [UIImage] = []
        for photo in photos {
            let request = FetchPhotoRequest(photo: photo, maxSize: CGSizeMake(600, 600))
            switch await googlePlacesClient.fetchPhoto(with: request) {
            case .success(let uiImage):
                res.append(uiImage)
            case .failure(let placesError):
                throw placesError
            }
        }
        print("\(res.count)")
        return res
    }
}
