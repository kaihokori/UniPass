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
    @State private var scale: CGFloat = 1.0
    @State private var nodesAreReady = false
    @State private var showMe = false
    @State private var showFirstDegreeLines = false
    @State private var showFirstDegree = false
    @State private var showSecondDegreeLines = false
    @State private var showSecondDegree = false

    let maxDragDistance: CGFloat = 300

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            if let me = profileManager.currentProfile {
                GeometryReader { geo in
                    ZStack {
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(zoomAndPanGesture)
                        
                        ZStack {
                            // 1. Lines go here (at the bottom)
                            ZStack {
                                if showFirstDegreeLines {
                                    ForEach(Array(profileManager.friendsProfiles.enumerated()), id: \.1.uuid) { index, friend in
                                        let angle = Angle(degrees: Double(index) / Double(profileManager.friendsProfiles.count) * 360)
                                        let x = geo.size.width / 2 + 120 * CGFloat(cos(angle.radians))
                                        let y = geo.size.height / 2 + 120 * CGFloat(sin(angle.radians))
                                        
                                        AnimatedLine(start: CGPoint(x: geo.size.width / 2, y: geo.size.height / 2), end: CGPoint(x: x, y: y), progress: 1)
                                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
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
                                                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                                                .animation(.easeOut(duration: 1).delay(Double(index) * 0.05), value: showSecondDegreeLines)
                                        }
                                    }
                                }
                            }
                            
                            // 2. Nodes go here (on top)
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
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        print("Meetups Tapped")
                    } label: {
                        Label("Meetups", systemImage: "calendar")
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(UIColor.systemGray6))
                            )
                    }

                    Button {
                        print("Interaction Log Tapped")
                    } label: {
                        Image(systemName: "person.2")
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color(UIColor.systemGray6))
                            )
                    }
                }
                Spacer()
                Button {
                    withAnimation {
                        scale = 1.0
                    }
                } label: {
                    Label("Reset Zoom", systemImage: "arrow.counterclockwise.circle")
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(UIColor.systemGray6))
                        )
                }
                .disabled(isGraphAtDefaultPosition)
                .opacity(isGraphAtDefaultPosition ? 0.5 : 1.0)
            }
            .padding()
        }
        .onChange(of: didLoadAllNodes) {
            if didLoadAllNodes && !nodesAreReady {
                nodesAreReady = true
                Task {
                    withAnimation(.easeOut(duration: 1)) {
                        showMe = true
                    }
                    try? await Task.sleep(nanoseconds: 1_000_000_000)

                    withAnimation(.easeOut(duration: 1)) {
                        showFirstDegreeLines = true
                    }
                    try? await Task.sleep(nanoseconds: 500_000_000)

                    withAnimation(.easeOut(duration: 1)) {
                        showFirstDegree = true
                    }
                    try? await Task.sleep(nanoseconds: 1_000_000_000)

                    withAnimation(.easeOut(duration: 1)) {
                        showSecondDegreeLines = true
                    }
                    try? await Task.sleep(nanoseconds: 500_000_000)

                    withAnimation(.easeOut(duration: 1)) {
                        showSecondDegree = true
                    }
                }
            }
        }
    }
    
    var didLoadAllNodes: Bool {
        return !profileManager.friendsProfiles.isEmpty && !profileManager.secondDegreeProfiles.isEmpty
    }
    
    var isGraphAtDefaultPosition: Bool {
        abs(scale - 1.0) < 0.01
    }
    
    var zoomAndPanGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = max(0.5, min(1.5, value))
            }
    }

    func profileNode(for profile: UserProfile, size: CGFloat) -> some View {
        let shouldShow: Bool = {
            if profile.uuid == profileManager.uuid {
                return showMe
            } else if profileManager.friendsProfiles.contains(where: { $0.uuid == profile.uuid }) {
                return showFirstDegree
            } else {
                return showSecondDegree
            }
        }()

        return VStack {
            if let image = profile.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue)
                    .frame(width: size, height: size)
                    .overlay(
                        Text(String(profile.name.prefix(1)))
                            .font(.title)
                            .foregroundColor(.white)
                    )
            }
        }
        .opacity(shouldShow ? 1 : 0)
        .scaleEffect(shouldShow ? 1 : 0.5)
        .animation(.easeOut(duration: 1).delay(Double.random(in: 0...0.2)), value: shouldShow)
        .onTapGesture {
            if profile.uuid == profileManager.uuid {
                navigationPath.append(Destination.profile)
            } else {
                navigationPath.append(Destination.friendProfile(profile))
            }
        }
    }
}
