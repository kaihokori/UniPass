//
//  BluetoothScanner.swift
//  UniPass
//
//  Created by Kyle Graham on 25/3/2025.
//

import CoreBluetooth

class BluetoothScanner: NSObject, CBCentralManagerDelegate, ObservableObject {
    private var centralManager: CBCentralManager!
    private var seenUUIDs: Set<String> = []

    @Published var discoveredUUIDs: [String] = []

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("⚠️ CoreBluetooth Central not powered on yet")
            return
        }

        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
        print("🔍 CoreBluetooth Scanner: Started scanning for UUIDs")
    }

    func stopScanning() {
        centralManager.stopScan()
        print("⛔️ CoreBluetooth Scanner: Stopped scanning")
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("🔄 CoreBluetooth Central state changed: \(central.state.rawValue)")
        if central.state == .poweredOn {
            startScanning()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String else { return }

        let uuidPattern = "^[0-9A-Fa-f\\-]{20,}$"
        let uuidRegex = try! NSRegularExpression(pattern: uuidPattern)

        let range = NSRange(location: 0, length: name.utf16.count)
        guard uuidRegex.firstMatch(in: name, options: [], range: range) != nil else {
//            print("⚠️ Skipping invalid UUID-like name: \(name)")
            return
        }

        guard !seenUUIDs.contains(name) else {
//            print("🔁 Already processed UUID via CoreBluetooth: \(name)")
            return
        }

        seenUUIDs.insert(name)
        discoveredUUIDs.append(name)
        print("🎯 CoreBluetooth: Detected *valid* UUID → \(name)")

        // 🧠 NEW: Resolve to full UUID and attempt to add as friend
        ProfileManager.shared.resolveFullUUID(from: name) { fullUUID in
            guard let fullUUID = fullUUID else {
                print("⚠️ Could not resolve full UUID for: \(name)")
                return
            }
            ProfileManager.shared.addFriendIfNeeded(uuid: fullUUID)
        }
    }
}
