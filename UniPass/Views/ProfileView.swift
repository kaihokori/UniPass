//
//  ProfileView.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

import SwiftUI
import MapKit

struct ProfileView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @Binding var navigationPath: NavigationPath
    @StateObject private var locationViewModel = LocationViewModel()
    @State private var hasGeocodedHometown = false
    @State private var lastGeocodedHometown: String = ""
    @State private var selectedTags: [String] = [] // To track highlighted tags
    private let uuidKey = "userUUID"

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                if let profile = profileManager.currentProfile {
                    if locationViewModel.coordinate != nil {
                        MapView(viewModel: locationViewModel, hometown: profile.hometown)
                            .transition(.opacity)
                            .frame(height: 250)
                            .ignoresSafeArea()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .ignoresSafeArea()
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .ignoresSafeArea()
                }

                HStack {
                    Button(action: {
                        navigationPath.removeLast()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }

                Circle()
                    .fill(Color.green)
                    .frame(width: 130, height: 130)
                    .offset(y: 120)
            }

            ScrollView {
                VStack {
                    if let profile = profileManager.currentProfile {
                        HStack {
                            Label("\(profile.hometown)", systemImage: "house")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 140, alignment: .leading)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Label("\(profile.socialScore)", systemImage: "star")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 140, alignment: .trailing)
                        }
                        
                        Text("\(profile.name)")
                            .font(.largeTitle)
                            .bold()
                            .padding(.top, 30)
                            .padding(.horizontal, 50)
                        Text("\(profile.studying) - \(profile.year) Year")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 50)

                        VStack(alignment: .leading) {
                            if !profile.bio.isEmpty {
                                Text("Bio: \(profile.bio)")
                                    .italic()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            if !profile.tags.isEmpty {
                                TagWrapperView(tags: profile.tags, selectedTags: $selectedTags)
                                    .allowsHitTesting(false)
                            }

                            if let localUUID = UserDefaults.standard.string(forKey: uuidKey),
                               localUUID == profile.uuid {
                                Button("Edit Profile") {
                                    navigationPath.append(Destination.editprofile)
                                }
                                .padding(.top)
                            }
                        }
                        .padding(.top, 10)

                    } else {
                        ProgressView("Loading Profile...")
                            .padding()
                    }
                }
                .padding()
            }
            .offset(y: -60)
        }
        .onAppear {
            profileManager.fetchProfileFromCloudKit()
        }
        .onChange(of: profileManager.currentProfile) { oldProfile, newProfile in
            guard let profile = newProfile else { return }
            guard !profile.hometown.isEmpty else { return }

            if profile.hometown != lastGeocodedHometown || locationViewModel.coordinate == nil {
                print("🌍 Re-geocoding hometown: \(profile.hometown)")
                locationViewModel.coordinate = nil
                locationViewModel.fetchCoordinates(for: profile.hometown)
                lastGeocodedHometown = profile.hometown
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
        .background(Color(.systemBackground))
    }
}
