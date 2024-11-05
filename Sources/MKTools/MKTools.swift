// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation
import MapKit
import Combine

@available(iOS 15.0, macOS 12.0, *)

public class MKTools: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    // MARK: - Published Properties

    // Single Route Calculation
    @Published public var route: MKRoute?
    @Published public var directions: [String] = []
    @Published public var distance: Double?

    // Multiple Routes
    @Published public var multipleRoutes: [MKRoute] = []
    @Published public var multipleDirections: [[String]] = []
    @Published public var multipleDistances: [Double] = []

    // Location Search
    @Published public var searchResults: [MKLocalSearchCompletion] = []
    private let searchCompleter = MKLocalSearchCompleter()

    // Location Item (Rate-limited)
    @Published public var placemark: MKPlacemark?

    // MARK: - Initializer

    public override init() {
        super.init()
        searchCompleter.delegate = self
    }

    // MARK: - Single Route Calculation

    public func getRoute(
        start: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        transportType: MKDirectionsTransportType
    ) async {
        let request = MKDirections.Request()
        request.transportType = transportType
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))

        do {
            let directions = MKDirections(request: request)
            let response = try await directions.calculate()
            guard let route = response.routes.first else { return }

            self.route = route
            self.directions = route.steps.map { $0.instructions }
            self.distance = route.distance
        } catch {
            print("Error calculating route: \(error)")
        }
    }

    // MARK: - Multiple Routes Calculation

    public func getRoutes(
        start: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        transportType: MKDirectionsTransportType
    ) async {
        let request = MKDirections.Request()
        request.transportType = transportType
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.requestsAlternateRoutes = true

        do {
            let directions = MKDirections(request: request)
            let response = try await directions.calculate()
            self.multipleRoutes = response.routes
            self.multipleDirections = response.routes.map { $0.steps.map { $0.instructions } }
            self.multipleDistances = response.routes.map { $0.distance }
        } catch {
            print("Error calculating multiple routes: \(error)")
        }
    }

    // MARK: - Location Search (Non Rate-limited)

    public func search(query: String) {
        searchCompleter.queryFragment = query
    }

    // MARK: - MKLocalSearchCompleterDelegate Methods

    public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.searchResults = completer.results
    }

    public func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error)")
    }

    // MARK: - Get Placemark (Rate-limited)

    public func getPlacemark(for completion: MKLocalSearchCompletion) async {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            guard let item = response.mapItems.first else { return }
            self.placemark = item.placemark
        } catch {
            print("Error fetching placemark: \(error)")
        }
    }
}
