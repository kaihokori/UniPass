//
//  MeetupsView.swift
//  UniPass
//
//  Created by Kyle Graham on 23/3/2025.
//

import SwiftUI

struct MeetupsView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @Binding var navigationPath: NavigationPath
    @State private var meetups: [Meetup] = []
    @State private var showDeleteWarning = false
    @State private var meetupToLeave: Meetup?
    @State private var meetupToJoin: Meetup?
    @State private var showJoinWarning = false

    var body: some View {
        ScrollView {
            ZStack {
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
                    if profileManager.currentMeetup == nil {
                        Button {
                            navigationPath.append(Destination.createMeetup)
                        } label: {
                            Label("Create", systemImage: "plus")
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(AppColor.gray6)
                                )
                        }
                    }
                }
                Text("Meetups")
                    .font(.headline)
            }
            .padding(.horizontal, 15)
            .padding(.top)
            
            if meetups.isEmpty {
                Text("No meetups yet!")
                    .font(.headline)
                    .padding(.top)
                Text("Create one yourself and get more connected!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(meetups) { meetup in
                    MeetupRowView(
                        meetup: meetup,
                        currentUserUUID: profileManager.uuid,
                        getUserProfile: getUserProfile,
                        onJoin: {
                            profileManager.joinMeetup(meetup: meetup) { success, needsConfirmation in
                                if success {
                                    loadRelevantMeetups()
                                } else if needsConfirmation {
                                    meetupToJoin = meetup
                                    showJoinWarning = true
                                }
                            }
                        },
                        onLeave: {
                            if meetup.participants.count == 1 {
                                meetupToLeave = meetup
                                showDeleteWarning = true
                            } else {
                                profileManager.leaveMeetup(meetup: meetup) { success in
                                    if success { loadRelevantMeetups() }
                                }
                            }
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top)
                }
            }
            Spacer()
        }
        .onAppear {
            loadRelevantMeetups()
        }
        .onChange(of: profileManager.shouldRefreshMeetups) {
            if profileManager.shouldRefreshMeetups {
                profileManager.shouldRefreshMeetups = false
                loadRelevantMeetups()
            }
        }
        .alert("Leave Meetup?", isPresented: $showDeleteWarning, presenting: meetupToLeave) { meetup in
            Button("Delete Meetup", role: .destructive) {
                profileManager.leaveMeetup(meetup: meetup) { success in
                    if success {
                        loadRelevantMeetups()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { meetup in
            Text("You're the last one going to \"\(meetup.title)\". Leaving will delete the meetup.")
        }
        .alert("Join New Meetup?", isPresented: $showJoinWarning, presenting: meetupToJoin) { meetup in
            Button("Join and Delete Old", role: .destructive) {
                profileManager.joinMeetup(meetup: meetup, force: true) { success, _ in
                    if success {
                        loadRelevantMeetups()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { meetup in
            Text("Joining \"\(meetup.title)\" will delete your current meetup since you're the last one in it. Continue?")
        }
        .navigationBarBackButtonHidden(true)
        #if os(iOS)
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
        #endif
    }

    func loadRelevantMeetups() {
        let allUUIDs = [profileManager.uuid] +
                       profileManager.friendsProfiles.map { $0.uuid } +
                       profileManager.secondDegreeProfiles.map { $0.uuid }

        profileManager.fetchMeetups(for: allUUIDs) { fetched in
            self.meetups = fetched.sorted { $0.date < $1.date }
        }
    }
    
    func getUserProfile(uuid: String) -> UserProfile? {
        if uuid == profileManager.uuid {
            return profileManager.currentProfile
        }
        return profileManager.friendsProfiles.first(where: { $0.uuid == uuid }) ??
               profileManager.secondDegreeProfiles.first(where: { $0.uuid == uuid })
    }
}
