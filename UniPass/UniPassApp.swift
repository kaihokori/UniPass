//
//  UniPassApp.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

import SwiftUI

@main
struct UniPassApp: App {
    @StateObject var profileManager = ProfileManager.shared
    @StateObject var multipeerManager = MultipeerManager()
    @StateObject var discoveredManager = DiscoveredManager()
    @StateObject var bluetoothAdvertiser = BluetoothAdvertiser()
    @StateObject var bluetoothScanner = BluetoothScanner()

    var body: some Scene {
        WindowGroup {
            if UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
                RootView()
                    .environmentObject(profileManager)
                    .environmentObject(multipeerManager)
                    .environmentObject(discoveredManager)
                    .onChange(of: bluetoothScanner.discoveredUUIDs) { _, uuids in
                        guard profileManager.isProfileCreated else {
                            print("⏳ Skipping CB-discovered UUIDs; profile not ready")
                            return
                        }

                        for uuid in uuids {
                            discoveredManager.handleNewUUID(uuid)
                            profileManager.addFriendIfNeeded(uuid: uuid)
                            print("✅ CoreBluetooth: Attempting to add friend from CB scan → \(uuid)")
                        }
                    }
                    .ignoresSafeArea()
                    .onAppear {
                        print("🟢 App appeared – Starting peer discovery")
                        
                        multipeerManager.startScanning()
                        bluetoothScanner.startScanning()
                        
                        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { _ in
                            print("🔙 App going to background")
                            multipeerManager.stopScanning()
                            bluetoothScanner.stopScanning()
                            bluetoothAdvertiser.startAdvertising()
                        }

                        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
                            print("🔛 App returned to foreground")
                            bluetoothAdvertiser.stopAdvertising()
                            multipeerManager.startScanning()
                            bluetoothScanner.startScanning()
                        }
                    }
            } else {
                OnboardingView()
                    .background(AppColor.systemBackground)
                    .environmentObject(profileManager)
                    .environmentObject(multipeerManager)
                    .environmentObject(discoveredManager)
                    .ignoresSafeArea()
            }
        }
    }
}
