import GooglePlacesSwift
import MapKit
//
//  MapItemDetailView.swift
//  friends
//
//  Created by Bryan Hoang on 12/21/24.
//
import SwiftUI

struct PlaceSheetView: View {
    
    @Environment(\.dismiss) var dismiss
    
    let place: Place
    let photos: [UIImage]
    
    @State private var hoursExpanded: Bool = true
    
    var onAdd: (Place) -> Void
    
    var body: some View {
        List {
            VStack(alignment: .leading) {
                HStack {
                    Text(place.displayName ?? "Unknown Place")
                        .font(.title)
                        .bold()
                    Spacer()
                    Button {
                        onAdd(place)
                        dismiss()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                    }
                    .buttonStyle(.plain)
                }
                SecondaryDetailView(types: place.types,
                                    priceLevel: place.priceLevel,
                                    rating: place.rating,
                                    numberOfUserRatings: place.numberOfUserRatings)
            }
            .listRowBackground(Color.clear)  // Remove gray background
            .listRowInsets(EdgeInsets())  // Remove list insets
            Section {
                MapView(coordinate: place.location)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .onTapGesture {
                        guard let displayName = place.displayName else {
                            return
                        }
                        openBusinessInAppleMaps(
                            name: displayName, near: place.location)
                    }
            }
            .listRowInsets(EdgeInsets())  // Remove list insets
            .frame(maxWidth: .infinity)  // Ensure it spans the full width
            if let currentWeek = place.currentOpeningHours?.weekdayText {
                Section {
                    DisclosureGroup(isExpanded: $hoursExpanded) {
                        VStack(alignment: .leading) {
                            ForEach(currentWeek, id: \.self) {curr_day in
                                Text("\(curr_day)")
                                    .padding(.leading, -20)
                            }
                        }
                    } label: {
                        Text("Hours")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Section {
                // PHONE
                if let phoneNumber = place.internationalPhoneNumber {
                    HStack {
                        Text("Phone")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Link(phoneNumber, destination: URL(string: "tel://\(phoneNumber)")!)
                            .foregroundColor(.blue)
                    }
                }
                
                // WEBSITE
                if let website = place.websiteURL {
                    HStack {
                        Text("Website")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Link(website.absoluteString, destination: website)
                            .foregroundColor(.blue)
                    }
                }
                
                // ADDRESS
                if let address = place.formattedAddress {
                    HStack(alignment: .top) {
                        Text("Address")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(address)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            Section {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(photos, id: \.self) { photo in
                            Image(uiImage: photo)
                                .resizable()
                                .frame(width: 200, height: 200)
                        }
                    }
                }
            }
        }
    }
}

extension PlaceSheetView {
    func openBusinessInAppleMaps(
        name: String, near coordinate: CLLocationCoordinate2D
    ) {
        // 1. Create an MKLocalSearch request
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = name  // e.g., "Joe's Coffee"
        
        // 2. Define a region around the coordinate
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        request.region = MKCoordinateRegion(center: coordinate, span: span)
        
        // 3. Start the local search
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, !response.mapItems.isEmpty else {
                print(
                    "No map items found or error: \(error?.localizedDescription ?? "none")"
                )
                return
            }
            
            // 4. Pick the first (or best) match
            let mapItem = response.mapItems[0]
            
            // 5. Open it in Apple Maps
            mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey:
                    MKLaunchOptionsDirectionsModeDriving
            ])
        }
    }
}

struct SecondaryDetailView: View {
    let types: Set<PlaceType>
    let priceLevel: PriceLevel
    let rating: Float?
    let numberOfUserRatings: Int
    
    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Filter out `.pointOfInterest` before sorting and passing to ForEach
                    ForEach(
                        types.filter { $0 != .pointOfInterest }  // Exclude "point of interest"
                            .sorted(by: { $0.rawValue < $1.rawValue }),
                        id: \.self
                    ) { type in
                        Text(convertTypeToString(type: type))
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
            }
            HStack {
                Text("\(generatePriceString()) | \(String(format: "%.2f", rating ?? 0.0))")
                    .font(.headline)
                
                Image(systemName: "hand.thumbsup.fill") // Thumbs-up SF symbol
                    .font(.headline)
                
                Text("(\(numberOfUserRatings))")
                    .font(.headline)
                
                Spacer()
            }
        }
    }
    
    private func generatePriceString() -> AttributedString {
        var attributedString = AttributedString()
        let dollarCount = priceLevelTo$(priceLevel: priceLevel)
        
        if dollarCount == 0 {
            // Use a shrugging emoji if price level is unspecified
            attributedString = AttributedString("🤷")
        } else {
            // Append highlighted dollar signs
            for _ in 0..<dollarCount {
                var attributes = AttributeContainer()
                attributes.foregroundColor = Color.primary
                attributedString += AttributedString(
                    "$", attributes: attributes)
            }
            
            // Append grayed-out dollar signs
            for _ in dollarCount..<4 {
                var attributes = AttributeContainer()
                attributes.foregroundColor = Color.gray
                attributedString += AttributedString(
                    "$", attributes: attributes)
            }
        }
        
        return attributedString
    }
    
    private func priceLevelTo$(priceLevel: PriceLevel) -> Int {
        switch priceLevel {
        case .free: return 0
        case .inexpensive: return 1
        case .moderate: return 2
        case .expensive: return 3
        case .veryExpensive: return 4
        case .unspecified: return 0
        @unknown default: return 0
        }
    }
    
    private func convertTypeToString(type: PlaceType) -> String {
        return type.rawValue.capitalized.replacingOccurrences(
            of: "_",
            with: " ")
    }
}

// A simple MapView wrapper for SwiftUI
struct MapView: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        //        mapView.isUserInteractionEnabled = false
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        mapView.setRegion(region, animated: true)
    }
}
