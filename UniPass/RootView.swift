//
//  RootView.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

import SwiftUI

struct RootView: View {
    @State private var navigationPath = NavigationPath()
    @EnvironmentObject var profileManager: ProfileManager
    @StateObject var multipeerManager = MultipeerManager()
    @StateObject var discoveredManager = DiscoveredManager()
    @StateObject var bluetoothAdvertiser = BluetoothAdvertiser()
    @StateObject var bluetoothScanner = BluetoothScanner()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            GraphView(navigationPath: $navigationPath)
                .navigationDestination(for: Destination.self) { destination in
                    switch destination {
                    case .profile:
                        ProfileView(navigationPath: $navigationPath, profileToDisplay: profileManager.currentProfile)
                    case .editprofile:
                        EditProfileView(navigationPath: $navigationPath)
                    case .friendProfile(let friend):
                        ProfileView(navigationPath: $navigationPath, profileToDisplay: friend)
                    case .meetups:
                        MeetupsView(navigationPath: $navigationPath)
                    case .createMeetup:
                        CreateMeetupView(navigationPath: $navigationPath)
                    case .interaction:
                        InteractionView(navigationPath: $navigationPath)
                    }
                }
                .onAppear {
                    print("🟢 RootView appeared – Starting discovery")

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

        }
        .ignoresSafeArea()
    }
}
