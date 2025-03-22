//
//  LocationViewModel.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

import Foundation
import CoreLocation

class LocationViewModel: ObservableObject {
    @Published var coordinate: CLLocationCoordinate2D?
    private var geocoder = CLGeocoder()
    private var lastGeocodedPlace: String?

    func fetchCoordinates(for place: String) {
        guard !place.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("⛔️ Empty hometown string — skipping geocoding.")
            return
        }

        if place == lastGeocodedPlace {
            print("✅ Already geocoded this place.")
            return
        }

        geocoder.geocodeAddressString(place) { [weak self] placemarks, error in
            if let location = placemarks?.first?.location {
                DispatchQueue.main.async {
                    var coordinate = location.coordinate
                    coordinate.latitude += 0.016
                    
                    self?.coordinate = coordinate
                    self?.lastGeocodedPlace = place
                    print("📍 Adjusted coordinate: \(coordinate)")
                }
            } else {
                print("❌ Geocoding failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}
