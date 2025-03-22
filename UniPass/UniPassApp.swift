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
            RootView()
                .environmentObject(profileManager)
                .ignoresSafeArea()
        }
    }
}
