//
//  MapLocation.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

import MapKit

struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
