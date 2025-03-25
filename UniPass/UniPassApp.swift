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

    var body: some Scene {
        WindowGroup {
            if UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
                RootView()
                    .environmentObject(profileManager)
                    .ignoresSafeArea()
            } else {
                OnboardingView()
                    .background(AppColor.systemBackground)
                    .environmentObject(profileManager)
                    .ignoresSafeArea()
            }
        }
    }
}
