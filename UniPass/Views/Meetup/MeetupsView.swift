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
            .padding(.vertical)
            
            if meetups.isEmpty {
                Text("No meetups yet!")
                    .font(.headline)
                    .padding(.top)
                Text("Create one yourself and get more connected!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(meetups) { meetup in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(meetup.title)
                                .font(.headline)
                            Spacer()
                            Text(meetup.date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                                .font(.subheadline)
                        }
                        Text(meetup.description)
                            .font(.body)
                        HStack {
                            Spacer()
                            Text(meetup.location)
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        if meetup.participants.contains(profileManager.uuid) {
                            Button(action: {
                                if meetup.participants.count == 1 {
                                    meetupToLeave = meetup
                                    showDeleteWarning = true
                                } else {
                                    profileManager.leaveMeetup(meetup: meetup) { success in
                                        if success { loadRelevantMeetups() }
                                    }
                                }
                            }) {
                                Text("Leave")
                                    .frame(maxWidth: .infinity)
                                    .padding(10)
                                    .background(Color.blue)
                                    .foregroundColor(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        } else {
                            Button(action: {
                                profileManager.joinMeetup(meetup: meetup) { success, needsConfirmation in
                                    if success {
                                        loadRelevantMeetups()
                                    } else if needsConfirmation {
                                        meetupToJoin = meetup
                                        showJoinWarning = true
                                    }
                                }
                            }) {
                                Text("Join")
                                    .frame(maxWidth: .infinity)
                                    .padding(10)
                                    .background(Color.blue)
                                    .foregroundColor(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(AppColor.gray6))
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
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
}
