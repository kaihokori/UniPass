//
//  HometownMapView.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var viewModel: LocationViewModel
    var hometown: String

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)
        )
    )

    var body: some View {
        VStack(alignment: .leading) {
            if viewModel.coordinate != nil {
                Map(position: $cameraPosition)
                    .allowsHitTesting(false)
                    .cornerRadius(12)
                    .onReceive(viewModel.$coordinate) { newCoord in
                        guard let newCoord = newCoord else { return }
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: newCoord,
                                span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)
                            )
                        )
                    }
            } else {
                ProgressView("Locating \(hometown)...")
            }
        }
    }
}
