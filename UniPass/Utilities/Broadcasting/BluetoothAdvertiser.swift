//
//  BluetoothAdvertiser.swift
//  UniPass
//
//  Created by Kyle Graham on 25/3/2025.
//

import CoreBluetooth

class BluetoothAdvertiser: NSObject, CBPeripheralManagerDelegate, ObservableObject {
    private var peripheralManager: CBPeripheralManager?
    private var shouldStartAdvertising = false
    private(set) var isAdvertising = false
    private var uuid: String = ""

    override init() {
        super.init()
        self.uuid = UserDefaults.standard.string(forKey: "userUUID") ?? UUID().uuidString
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func startAdvertising() {
        guard !isAdvertising else { return }

        if peripheralManager?.state == .poweredOn {
            actuallyStartAdvertising()
        } else {
            shouldStartAdvertising = true
        }
    }

    func stopAdvertising() {
        if isAdvertising {
            peripheralManager?.stopAdvertising()
            isAdvertising = false
            print("⛔️ CoreBluetooth: Stopped advertising")
        }
        shouldStartAdvertising = false
    }

    private func actuallyStartAdvertising() {
        guard let peripheralManager = peripheralManager else { return }

        let advertisementData: [String: Any] = [
            CBAdvertisementDataLocalNameKey: String(uuid.prefix(28))
        ]

        peripheralManager.startAdvertising(advertisementData)
        isAdvertising = true
        print("📡 CoreBluetooth: Started advertising UUID in background")
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("ℹ️ Peripheral manager state: \(peripheral.state.rawValue)")
        if peripheral.state == .poweredOn && shouldStartAdvertising {
            actuallyStartAdvertising()
        }
    }
}
