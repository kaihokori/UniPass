//
//  BluetoothScanner.swift
//  UniPass
//
//  Created by Kyle Graham on 25/3/2025.
//

import CoreBluetooth

class BluetoothScanner: NSObject, CBCentralManagerDelegate {
    private var centralManager: CBCentralManager!
    private var onUUIDDiscovered: (String) -> Void

    init(onUUIDDiscovered: @escaping (String) -> Void) {
        self.onUUIDDiscovered = onUUIDDiscovered
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [CBUUID(string: "180D")], options: nil)
            print("🔍 Started Bluetooth scanning")
        } else {
            centralManager.stopScan()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("🎯 Found peripheral broadcasting UUID: \(name)")
            onUUIDDiscovered(name)
        }
    }

    func stopScanning() {
        centralManager.stopScan()
        print("🛑 Stopped Bluetooth scanning")
    }
}
