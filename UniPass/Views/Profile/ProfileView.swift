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
    @State private var selectedTags: [String] = []
    @State private var showDeleteWarning = false
    @State private var meetupToLeave: Meetup?
    private let uuidKey = "userUUID"
    let profileToDisplay: UserProfile?
    var effectiveProfile: UserProfile? {
        if let display = profileToDisplay {
            if display.uuid == profileManager.uuid {
                return profileManager.friendsProfiles.first(where: { $0.uuid == profileManager.uuid }) ?? profileManager.currentProfile
            } else {
                return display
            }
        }
        return profileManager.currentProfile
    }

    var body: some View {
        ScrollView {
            ZStack(alignment: .top) {
                if let profile = effectiveProfile {
                    if locationViewModel.coordinate != nil {
                        MapView(viewModel: locationViewModel, hometown: profile.hometown)
                            .transition(.opacity)
                            .frame(height: 250)
                            .ignoresSafeArea()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 250)
                            .ignoresSafeArea()
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 250)
                        .ignoresSafeArea()
                }
                
                HStack {
                    Button {
                        navigationPath.removeLast()
                    } label: {
                        Image(systemName: "chevron.left")
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(AppColor.gray6)
                            )
                    }
                    Spacer()
                    if let profile = effectiveProfile {
                        if let localUUID = UserDefaults.standard.string(forKey: uuidKey),
                           localUUID == profile.uuid {
                            Button {
                                navigationPath.append(Destination.editprofile)
                            } label: {
                                Label("Edit Profile", systemImage: "pencil")
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(AppColor.gray6)
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, 15)
                .offset(y: 60)
                
                if let profile = effectiveProfile, let image = profile.profileImage {
                    let isGoingToMeetup = profileManager.currentMeetup?.participants.contains(profile.uuid) ?? false
                    #if os(iOS)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(isGoingToMeetup ? Color.purple : Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 5)
                        .offset(y: 165)
                    #else
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(isGoingToMeetup ? Color.purple : Color.white, lineWidth: 4)
                        )
                        .shadow(radius: 5)
                        .offset(y: 165)
                    #endif
                } else {
                    Circle()
                        .fill(Color.green)
                        .overlay(
                            Text(String(profileManager.currentProfile?.name.prefix(1) ?? " "))
                                .font(.title)
                                .foregroundColor(.white)
                        )
                        .frame(width: 130, height: 130)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 5)
                        .offset(y: 165)
                }
            }
            
            VStack {
                if let profile = effectiveProfile {
                    HStack {
                        if !profile.hometown.isEmpty {
                            Label("\(profile.hometown)", systemImage: "house")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 140, alignment: .leading)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Label("\(profile.socialScore)", systemImage: "person")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 140, alignment: .trailing)
                    }
                    
                    Text("\(profile.name)")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 20)
                        .padding(.horizontal, 50)
                    
                    if !profile.studying.isEmpty && !profile.year.isEmpty {
                        Text("\(profile.year) Year")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 50)
                        Text(profile.studying)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 50)
                    }
                    
                    if let meetup = profileManager.allFetchedMeetups.first(where: { $0.participants.contains(profile.uuid) }) {
                        MeetupRowView(
                            meetup: meetup,
                            currentUserUUID: profileManager.uuid,
                            getUserProfile: { uuid in
                                if uuid == profileManager.uuid {
                                    return profileManager.currentProfile
                                }
                                return profileManager.friendsProfiles.first(where: { $0.uuid == uuid }) ??
                                       profileManager.secondDegreeProfiles.first(where: { $0.uuid == uuid })
                            },
                            onJoin: {
                                profileManager.joinMeetup(meetup: meetup) { success, _ in
                                    if success {
                                        profileManager.fetchMeetups(
                                            for: [profileManager.uuid, profile.uuid]
                                        ) { _ in }
                                    }
                                }
                            },
                            onLeave: {
                                if meetup.participants.count == 1 {
                                    meetupToLeave = meetup
                                    showDeleteWarning = true
                                } else {
                                    profileManager.leaveMeetup(meetup: meetup) { success in
                                        if success {
                                            profileManager.fetchMeetups(
                                                for: [profileManager.uuid, profile.uuid]
                                            ) { _ in }
                                        }
                                    }
                                }
                            }
                        )
                    }

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
                    }
                    .padding(.top, 10)
                    
                } else {
                    ProgressView("Loading Profile...")
                        .padding()
                }
            }
            .padding(.horizontal)
            .padding(.top, 70)
            .padding(.bottom, 50)
            .offset(y: -60)
        }
        .ignoresSafeArea()
        .onAppear {
            if let profile = effectiveProfile {
                if profile.uuid != profileManager.uuid,
                   let myTags = profileManager.currentProfile?.tags {
                    selectedTags = profile.tags.filter { myTags.contains($0) }
                } else {
                    selectedTags = []
                }

                if !profile.hometown.isEmpty {
                    if profile.hometown != lastGeocodedHometown || locationViewModel.coordinate == nil {
                        print("🌍 [onAppear] Geocoding hometown: \(profile.hometown)")
                        locationViewModel.coordinate = nil
                        locationViewModel.fetchCoordinates(for: profile.hometown)
                        lastGeocodedHometown = profile.hometown
                    }
                }

                if profile.uuid == profileManager.uuid {
                    profileManager.fetchProfileFromCloudKit()
                }

                if profileManager.allFetchedMeetups.isEmpty {
                    let relevantUUIDs = [profileManager.uuid] + profileManager.friendsProfiles.map { $0.uuid }
                    profileManager.fetchMeetups(for: relevantUUIDs) { _ in }
                }
            }
        }
        .onChange(of: effectiveProfile?.hometown) { oldValue, newValue in
            if oldValue != newValue {
                triggerGeocodingIfNeeded()
            }
        }
        .navigationBarBackButtonHidden(true)
        #if os(iOS)
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
        #endif
        .background(AppColor.systemBackground)
        .alert("Leave Meetup?", isPresented: $showDeleteWarning, presenting: meetupToLeave) { meetup in
            Button("Delete Meetup", role: .destructive) {
                profileManager.leaveMeetup(meetup: meetup) { success in
                    if success {
                        profileManager.fetchMeetups(for: [profileManager.uuid]) { _ in }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { meetup in
            Text("You're the last one going to \"\(meetup.title)\". Leaving will delete the meetup.")
        }
    }
    
    private func triggerGeocodingIfNeeded() {
        guard let profile = effectiveProfile,
              !profile.hometown.isEmpty else { return }

        if profile.hometown != lastGeocodedHometown || locationViewModel.coordinate == nil {
            print("🌍 [geocode trigger] Hometown: \(profile.hometown)")
            locationViewModel.coordinate = nil
            locationViewModel.fetchCoordinates(for: profile.hometown)
            lastGeocodedHometown = profile.hometown
        }
    }
}
