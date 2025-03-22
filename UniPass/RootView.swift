//
//  RootView.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

import SwiftUI

struct RootView: View {
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            GraphView(navigationPath: $navigationPath)
                .navigationDestination(for: Destination.self) { destination in
                    switch destination {
                    case .profile:
                        ProfileView(navigationPath: $navigationPath)
                    case .editprofile:
                        EditProfileView(navigationPath: $navigationPath)
                    }
                }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    RootView()
}
