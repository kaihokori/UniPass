//
//  InteractionView.swift
//  UniPass
//
//  Created by Kyle Graham on 23/3/2025.
//

import SwiftUI

struct InteractionView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @Binding var navigationPath: NavigationPath

    var body: some View {
        let nearbyUUIDs = Set(profileManager.nearbyProfiles.map { $0.uuid })
        
        let filteredInteractions = profileManager.interactionLog
            .filter { !nearbyUUIDs.contains($0.user.uuid) }
            .sorted(by: { $0.date > $1.date })

        let sortedNearby = profileManager.nearbyProfiles
            .sorted { lhs, rhs in
                lhs.name < rhs.name
            }

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
                }
                Text("Interaction History")
                    .font(.headline)
            }
            .padding(.horizontal, 15)
            .padding(.top)
            
            VStack(alignment: .leading) {
                if !filteredInteractions.isEmpty {
                    Text("People You've Met")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top)

                    ForEach(filteredInteractions, id: \.id) { record in
                        InteractionRowView(
                            profile: record.user,
                            degree: record.degree,
                            date: record.date,
                            myTags: Set(profileManager.currentProfile?.tags ?? []),
                            onTap: {
                                navigationPath.append(Destination.friendProfile(record.user))
                            }
                        )
                        .padding(.horizontal)
                    }

                    if !profileManager.secondDegreeProfiles.isEmpty {
                        Text("People You Might Know")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top)

                        ForEach(profileManager.secondDegreeProfiles, id: \.uuid) { profile in
                            InteractionRowView(
                                profile: profile,
                                degree: nil,
                                date: nil,
                                myTags: Set(profileManager.currentProfile?.tags ?? []),
                                onTap: {
                                    navigationPath.append(Destination.friendProfile(profile))
                                }
                            )
                            .padding(.horizontal)
                        }

                    }
                }

                if sortedNearby.isEmpty && filteredInteractions.isEmpty {
                    Text("No interactions yet!")
                        .font(.headline)
                        .padding(.top)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("Go meet some people by exploring campus!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        #if os(iOS)
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
        #endif
        .onAppear {
            profileManager.fetchInteractionLog()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                print("👀 Degrees in interaction log:")
                for record in profileManager.interactionLog {
                    print("• \(record.user.name): \(record.degree)")
                }
            }
        }

    }
}
