//
//  BluetoothManager.swift
//  UniPass
//
//  Created by Kyle Graham on 25/3/2025.
//

import Foundation

class BluetoothManager: ObservableObject {
    private var advertiser: BluetoothAdvertiser?
    private var scanner: BluetoothScanner?

    func start(uuid: String, onDiscover: @escaping (String) -> Void) {
        advertiser = BluetoothAdvertiser(uuid: uuid)
        scanner = BluetoothScanner(onUUIDDiscovered: onDiscover)
    }

    func stop() {
        advertiser?.stopAdvertising()
        scanner?.stopScanning()
    }
}
