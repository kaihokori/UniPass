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

    var body: some Scene {
        WindowGroup {
            if UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
                RootView()
                    .environmentObject(profileManager)
                    .environmentObject(multipeerManager)
                    .environmentObject(discoveredManager)
                    .onChange(of: multipeerManager.discoveredUUIDs) { _, uuids in
                        guard profileManager.isProfileCreated else {
                            print("⏳ Skipping discovered UUIDs; profile not ready")
                            return
                        }

                        for uuid in uuids {
                            discoveredManager.handleNewUUID(uuid)
                            profileManager.addFriendIfNeeded(uuid: uuid)
                        }
                    }
                    .ignoresSafeArea()
                    .onAppear {
                        multipeerManager.startScanning()
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
