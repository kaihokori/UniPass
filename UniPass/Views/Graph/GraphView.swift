//
//  GraphView.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

import SwiftUI

struct GraphView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @Binding var navigationPath: NavigationPath
    @State private var scale: CGFloat = 0.8
    @State private var nodesAreReady = false
    @State private var showMe = false
    @State private var showFirstDegreeLines = false
    @State private var showFirstDegree = false
    @State private var showSecondDegreeLines = false
    @State private var showSecondDegree = false
    @State private var visibleFirstDegreeUUIDs: Set<String> = []
    @State private var visibleSecondDegreeUUIDs: Set<String> = []
    @State private var isRefreshDisabled = false

    var body: some View {
        ZStack {
            Color(AppColor.systemBackground)
                .ignoresSafeArea()
            
            RippleBackgroundView()

            if let me = profileManager.currentProfile {
                GeometryReader { geo in
                    ZStack {
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(zoomAndPanGesture)
                        
                        ZStack {
                            ZStack {
                                if showFirstDegreeLines {
                                    ForEach(Array(profileManager.friendsProfiles.enumerated()), id: \.1.uuid) { index, friend in
                                        let angle = Angle(degrees: Double(index) / Double(profileManager.friendsProfiles.count) * 360)
                                        let x = geo.size.width / 2 + 120 * CGFloat(cos(angle.radians))
                                        let y = geo.size.height / 2 + 120 * CGFloat(sin(angle.radians))
                                        
                                        AnimatedLine(start: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2), end: CGPoint(x: x, y: y), progress: 1)
                                            .stroke(Color.primary.opacity(0.4), lineWidth: 2)
                                            .animation(.easeOut(duration: 1).delay(Double(index) * 0.05), value: showFirstDegreeLines)
                                    }
                                }
                                
                                if showSecondDegreeLines {
                                    ForEach(Array(profileManager.secondDegreeProfiles.enumerated()), id: \.1.uuid) { index, friend in
                                        let angle = Angle(degrees: Double(index) / Double(profileManager.secondDegreeProfiles.count) * 360)
                                        let x = geo.size.width / 2 + 200 * CGFloat(cos(angle.radians))
                                        let y = geo.size.height / 2 + 200 * CGFloat(sin(angle.radians))
                                        
                                        if let connector = profileManager.friendsProfiles.first(where: { $0.friends.contains(friend.uuid) }) {
                                            let connectorAngle = Angle(degrees: Double(profileManager.friendsProfiles.firstIndex(of: connector) ?? 0) / Double(profileManager.friendsProfiles.count) * 360)
                                            let connectorX = geo.size.width / 2 + 120 * CGFloat(cos(connectorAngle.radians))
                                            let connectorY = geo.size.height / 2 + 120 * CGFloat(sin(connectorAngle.radians))
                                            
                                            AnimatedLine(start: CGPoint(x: connectorX, y: connectorY), end: CGPoint(x: x, y: y), progress: 1)
                                                .stroke(Color.primary.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [4]))
                                                .animation(.easeOut(duration: 1).delay(Double(index) * 0.05), value: showSecondDegreeLines)
                                        }
                                    }
                                }
                            }
                            
                            ZStack {
                                // Me in the center
                                profileNode(for: me, size: 80)
                                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                                
                                // Friends in a circle
                                ForEach(Array(profileManager.friendsProfiles.enumerated()), id: \.1.uuid) { index, friend in
                                    let angle = Angle(degrees: Double(index) / Double(profileManager.friendsProfiles.count) * 360)
                                    let x = geo.size.width / 2 + 120 * CGFloat(cos(angle.radians))
                                    let y = geo.size.height / 2 + 120 * CGFloat(sin(angle.radians))
                                    
                                    profileNode(for: friend, size: 60)
                                        .position(x: x, y: y)
                                }
                                
                                // 2° Friends in outer circle
                                ForEach(Array(profileManager.secondDegreeProfiles.enumerated()), id: \.1.uuid) { index, friend in
                                    let angle = Angle(degrees: Double(index) / Double(profileManager.secondDegreeProfiles.count) * 360)
                                    let x = geo.size.width / 2 + 200 * CGFloat(cos(angle.radians))
                                    let y = geo.size.height / 2 + 200 * CGFloat(sin(angle.radians))
                                    
                                    profileNode(for: friend, size: 50)
                                        .position(x: x, y: y)
                                }
                            }
                        }
                    }
                    .scaleEffect(scale)
                    .gesture(zoomAndPanGesture)
                }
            } else {
                ProgressView("Loading Graph...")
                    .onAppear {
                        profileManager.fetchProfileFromCloudKit()
                    }
            }
            
            if profileManager.friendsProfiles.isEmpty && profileManager.secondDegreeProfiles.isEmpty {
                VStack {
                    Spacer()
                    Spacer()
                    Text("Looking for Nearby Connections")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 40)
                    Spacer()
                }
                .transition(.opacity)
                .animation(.easeInOut, value: profileManager.friendsProfiles)
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        navigationPath.append(Destination.meetups)
                    } label: {
                        Label("Meetups", systemImage: "calendar")
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(AppColor.gray6)
                            )
                    }

                    Button {
                        navigationPath.append(Destination.interaction)
                    } label: {
                        Image(systemName: "person.2")
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(AppColor.gray6)
                            )
                    }
                }
                Spacer()
                
                HStack {
                    Button {
                        withAnimation {
                            isRefreshDisabled = true
                            nodesAreReady = false
                            showMe = false
                            showFirstDegreeLines = false
                            showFirstDegree = false
                            showSecondDegreeLines = false
                            showSecondDegree = false
                            visibleFirstDegreeUUIDs = []
                            visibleSecondDegreeUUIDs = []
                            scale = 0.8
                        }

                        profileManager.fetchProfileFromCloudKit { success in
                            if success {
                                profileManager.fetchMeetups(
                                    for: [profileManager.uuid] + profileManager.friendsProfiles.map { $0.uuid }
                                ) { _ in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        runGraphAnimation()

                                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
                                            isRefreshDisabled = false
                                        }
                                    }
                                }
                            } else {
                                isRefreshDisabled = false
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(AppColor.gray6)
                            )
                    }
                    .disabled(isRefreshDisabled)
                    .opacity(isRefreshDisabled ? 0.5 : 1.0)
                    
                    Spacer()
                }
            }
            .padding()
            
            VStack {
                Spacer()
                Button {
                    withAnimation {
                        scale = 0.8
                    }
                } label: {
                    Label("Reset Zoom", systemImage: "plus.magnifyingglass")
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppColor.gray6)
                        )
                }
                .disabled(isGraphAtDefaultPosition)
                .opacity(isGraphAtDefaultPosition ? 0.5 : 1.0)
                .padding(.bottom, 5)
            }
            .padding()
        }
        .onChange(of: didLoadAllNodes) {
            if didLoadAllNodes && !nodesAreReady {
                runGraphAnimation()
            }
        }
    }
    
    var didLoadAllNodes: Bool {
        return profileManager.currentProfile != nil
    }
    
    var isGraphAtDefaultPosition: Bool {
        abs(scale - 0.8) < 0.01
    }

    var zoomAndPanGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = max(0.5, min(1.5, value))
            }
    }

    func profileNode(for profile: UserProfile, size: CGFloat) -> some View {
        let uuid = profile.uuid
        let isVisible = uuid == profileManager.uuid ||
            visibleFirstDegreeUUIDs.contains(uuid) ||
            visibleSecondDegreeUUIDs.contains(uuid)

        let isGoingToMeetup = profileManager.usersInMeetups.contains(uuid)

        return Group {
            if let image = profile.profileImage {
                #if os(iOS)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isGoingToMeetup ? Color.purple : Color.clear, lineWidth: 4)
                    )
                #else
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isGoingToMeetup ? Color.purple : Color.clear, lineWidth: 4)
                    )
                #endif
            } else {
                Circle()
                    .fill(Color.green)
                    .frame(width: size, height: size)
                    .overlay(
                        Text(String(profile.name.prefix(1)))
                            .font(.title)
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(isGoingToMeetup ? Color.purple : Color.clear, lineWidth: 4)
                    )
            }
        }
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.5)
        .animation(.easeOut(duration: 0.8), value: isVisible)
        .onAppear {
            profileManager.fetchMeetups(for: [profileManager.uuid] + profileManager.friendsProfiles.map { $0.uuid }) { _ in }
            if uuid != profileManager.uuid {
                if profileManager.friendsProfiles.contains(where: { $0.uuid == uuid }) {
                    if !visibleFirstDegreeUUIDs.contains(uuid) {
                        visibleFirstDegreeUUIDs.insert(uuid)
                    }
                } else if profileManager.secondDegreeProfiles.contains(where: { $0.uuid == uuid }) {
                    if !visibleSecondDegreeUUIDs.contains(uuid) {
                        visibleSecondDegreeUUIDs.insert(uuid)
                    }
                }
            }
        }
        .onTapGesture {
            if uuid == profileManager.uuid {
                navigationPath.append(Destination.profile)
            } else {
                navigationPath.append(Destination.friendProfile(profile))
            }
        }
    }
    
    func runGraphAnimation() {
        Task {
            withAnimation(.easeOut(duration: 1)) {
                showMe = true
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            withAnimation(.easeOut(duration: 1)) {
                showFirstDegreeLines = true
            }
            try? await Task.sleep(nanoseconds: 500_000_000)

            visibleFirstDegreeUUIDs = Set(profileManager.friendsProfiles.map { $0.uuid })

            withAnimation(.easeOut(duration: 1)) {
                showFirstDegree = true
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            withAnimation(.easeOut(duration: 1)) {
                showSecondDegreeLines = true
            }
            try? await Task.sleep(nanoseconds: 500_000_000)

            visibleSecondDegreeUUIDs = Set(profileManager.secondDegreeProfiles.map { $0.uuid })

            withAnimation(.easeOut(duration: 1)) {
                showSecondDegree = true
            }

            nodesAreReady = true
        }
    }
}
