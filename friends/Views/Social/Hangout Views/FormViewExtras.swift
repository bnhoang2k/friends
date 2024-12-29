import SwiftUI
import MapKit

@MainActor
final class MapSearchViewModel: NSObject, ObservableObject {
    /// The user’s search text. As it changes, the searchCompleter updates.
    @Published var searchText: String = "" {
        didSet {
            // Update the query fragment whenever searchText changes
            searchCompleter.queryFragment = searchText
        }
    }
    
    /// The search results (completions) we display in a list.
    @Published var completions: [MKLocalSearchCompletion] = []
    
    /// Apple’s built-in search completer
    private let searchCompleter = MKLocalSearchCompleter()
    
    /// Specify a region for the results, if desired
    private let initialCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    private let regionSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    
    override init() {
        super.init()
        
        // Set up the completer
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest, .query]
        
        // Optionally set a region to help the results be more location-specific
        let region = MKCoordinateRegion(center: initialCoordinate, span: regionSpan)
        searchCompleter.region = region
    }
    
    /// Async/await lookup for the user’s selected completion.
    /// - Returns: A tuple of (name, coordinate).
    func selectCompletion(
        _ completion: MKLocalSearchCompletion
    ) async throws -> (String, CLLocationCoordinate2D) {
        
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        
        let response = try await search.start()
        
        guard let mapItem = response.mapItems.first else {
            throw NSError(domain: "No mapItems returned", code: 0, userInfo: nil)
        }
        
        // If `mapItem.name` is nil, fall back to the completion’s title
        let name = mapItem.name ?? completion.title
        let coordinate = mapItem.placemark.coordinate
        return (name, coordinate)
    }
}

// MARK: - MKLocalSearchCompleterDelegate
extension MapSearchViewModel: MKLocalSearchCompleterDelegate {

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Because this method is nonisolated, we can’t directly touch
        // actor‐isolated properties like `completions`.
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.completions = completer.results
        }
    }
    
    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.completions = []
            print("Search completer failed:", error.localizedDescription)
        }
    }
}

struct MapSearchView: View {
    @Environment(\.dismiss) private var dismiss
    
    /// Callback to return the user’s chosen place name & coordinate.
    let onTap: (String, CLLocationCoordinate2D) -> Void
    
    /// State for pinned location on the map
    @State private var pinnedCoordinate = CLLocationCoordinate2D()
    @State private var placeName: String = ""
    
    /// ViewModel that manages the search
    @StateObject private var viewModel = MapSearchViewModel()
    
    /// For the initial map region
    private let initialCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    private let regionSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search for a place", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Spacer()
                
                Button("OK") {
                    // Return whatever is currently pinned
                    onTap(placeName, pinnedCoordinate)
                    dismiss()
                }
                .padding(.trailing, 16)
            }
            
            // Show completions if non-empty
            if !viewModel.completions.isEmpty {
                List(viewModel.completions, id: \.hashValue) { completion in
                    VStack(alignment: .leading) {
                        Text(completion.title)
                            .font(.headline)
                        if !completion.subtitle.isEmpty {
                            Text(completion.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task {
                            do {
                                // Use async method to fetch final coordinate
                                let (foundName, coordinate) = try await viewModel.selectCompletion(completion)
                                pinnedCoordinate = coordinate
                                placeName = foundName
                                
                                // Clear out suggestions so the user sees the map
                                viewModel.completions = []
                                viewModel.searchText = ""
                            } catch {
                                print("Failed to select completion:", error.localizedDescription)
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .scrollContentBackground(.hidden)
                .listRowInsets(EdgeInsets())
            }
            
            // The map
            InteractiveMapView(
                pinnedCoordinate: $pinnedCoordinate,
                initialCoordinate: initialCoordinate,
                regionSpan: regionSpan
            )
        }
        .onAppear {
            // Set pinned location to initial when the view appears
            pinnedCoordinate = initialCoordinate
        }
    }
}

struct InteractiveMapView: UIViewRepresentable {
    /// A binding to track a pinned coordinate.
    @Binding var pinnedCoordinate: CLLocationCoordinate2D
    
    /// Initial region or center location
    let initialCoordinate: CLLocationCoordinate2D
    let regionSpan: MKCoordinateSpan
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        // Set the map’s initial region
        let region = MKCoordinateRegion(
            center: initialCoordinate,
            span: regionSpan
        )
        mapView.setRegion(region, animated: false)
        
        // Set the delegate
        mapView.delegate = context.coordinator
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Remove old annotations
        mapView.removeAnnotations(mapView.annotations)
        
        // Add an annotation for pinned coordinate
        let annotation = MKPointAnnotation()
        annotation.coordinate = pinnedCoordinate
        mapView.addAnnotation(annotation)
        
        // Re-center the map on pinnedCoordinate
        let region = MKCoordinateRegion(
            center: pinnedCoordinate,
            span: regionSpan
        )
        mapView.setRegion(region, animated: true)
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: InteractiveMapView
        
        init(_ parent: InteractiveMapView) {
            self.parent = parent
        }
    }
}
