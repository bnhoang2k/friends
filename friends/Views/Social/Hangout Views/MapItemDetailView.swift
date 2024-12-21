//
//  MapItemDetailView.swift
//  friends
//
//  Created by Bryan Hoang on 12/21/24.
//
import SwiftUI
import MapKit

struct MapItemDetailView: View {
    let mapItem: MKMapItem
    
    var body: some View {
        List {
            VStack {
                HStack {
                    Text(mapItem.name ?? "Unknown Place")
                        .font(.title)
                        .bold()
                    Spacer()
                }
                HStack {
                    Text(formattedCategory(for: mapItem.pointOfInterestCategory))
                    Spacer()
                }
            }
            .listRowBackground(Color.clear) // Remove gray background
            .listRowInsets(EdgeInsets()) // Remove list insets
            Section {
                MapView(coordinate: mapItem.placemark.coordinate)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .onTapGesture {
                        mapItem.openInMaps()
                    }
            }
            .listRowInsets(EdgeInsets()) // Remove list insets
            .frame(maxWidth: .infinity) // Ensure it spans the full width
            Group {
                VStack(alignment: .leading, spacing: 10) {
                    if let phoneNumber = mapItem.phoneNumber {
                        Section {
                            HStack {
                                Link("\(phoneNumber)", destination: URL(string: "tel:\(phoneNumber)")!)
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                        } header: {
                            Text("Phone")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                    }
                    if let website = mapItem.url?.absoluteString {
                        Section {
                            HStack {
                                Link("\(website)", destination: URL(string: "\(website)")!)
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                        } header: {
                            Text("Website")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    if let address = mapItem.placemark.title {
                        Section {
                            HStack {
                                Text(address)
                                Spacer()
                            }
                        } header: {
                            Text("Address")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

extension MapItemDetailView {
    // Helper function to format the category name
    func formattedCategory(for category: MKPointOfInterestCategory?) -> String {
        guard let category = category else { return "Unknown Category" }
        
        // Remove the "MKPOICategory" prefix
        let rawValue = category.rawValue.replacingOccurrences(of: "MKPOICategory", with: "")
        
        // Split the remaining string based on capital letters
        let words = rawValue.splitBeforeCapitalLetters()
        return words.joined(separator: " ")
    }
}

extension String {
    /// Splits a string at each capital letter.
    func splitBeforeCapitalLetters() -> [String] {
        var words: [String] = []
        var currentWord = ""

        for character in self {
            if character.isUppercase && !currentWord.isEmpty {
                // Start a new word when encountering an uppercase letter
                words.append(currentWord)
                currentWord = String(character)
            } else {
                currentWord.append(character)
            }
        }

        // Add the final word if it's not empty
        if !currentWord.isEmpty {
            words.append(currentWord)
        }

        return words
    }
}

// A simple MapView wrapper for SwiftUI
struct MapView: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isUserInteractionEnabled = false
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

#Preview {
    let coordinate = CLLocationCoordinate2D(latitude: 40.5853, longitude: -105.0844)
    
    // Mock placemark with new initialization
    let placemark = MKPlacemark(coordinate: coordinate)
    
    // Mock MKMapItem
    let mapItem = MKMapItem(placemark: placemark)
    
    // MapItemDetailView with the mock mapItem
    MapItemDetailView(mapItem: mapItem)
}
