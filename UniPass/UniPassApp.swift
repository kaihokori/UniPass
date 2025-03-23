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
                    .onChange(of: multipeerManager.discoveredUUIDs) {
                        for uuid in multipeerManager.discoveredUUIDs {
                            discoveredManager.handleNewUUID(uuid)
                            profileManager.addFriendIfNeeded(uuid: uuid)
                        }
                    }
                    .ignoresSafeArea()
            } else {
                OnboardingView()
                    .environmentObject(profileManager)
                    .environmentObject(multipeerManager)
                    .environmentObject(discoveredManager)
                    .ignoresSafeArea()
            }
        }
    }
}
