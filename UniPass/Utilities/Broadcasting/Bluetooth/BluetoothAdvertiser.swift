//
//  BluetoothAdvertiser.swift
//  UniPass
//
//  Created by Kyle Graham on 25/3/2025.
//

import CoreBluetooth

class BluetoothAdvertiser: NSObject, CBPeripheralManagerDelegate {
    private var peripheralManager: CBPeripheralManager?
    private var advertisedUUID: String

    init(uuid: String) {
        self.advertisedUUID = uuid
        super.init()
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            startAdvertising()
        } else {
            peripheral.stopAdvertising()
        }
    }

    private func startAdvertising() {
        guard let peripheralManager = peripheralManager else { return }

        let advertisementData: [String: Any] = [
            CBAdvertisementDataLocalNameKey: advertisedUUID.prefix(8).description,
            CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: "180D")]
        ]

        peripheralManager.startAdvertising(advertisementData)
        print("📡 Started Bluetooth advertising as \(advertisedUUID.prefix(8))")
    }

    func stopAdvertising() {
        peripheralManager?.stopAdvertising()
        print("📴 Stopped Bluetooth advertising")
    }
}
