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
                    }
                }
        }
        .ignoresSafeArea()
    }
}
