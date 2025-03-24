//
//  NodePositionManager.swift
//  UniPass
//
//  Created by Kyle Graham on 24/3/2025.
//

import SwiftUICore

struct NodePositionManager {
    var friendPositions: [String: CGPoint] = [:]
    var secondDegreePositions: [String: CGPoint] = [:]

    mutating func calculatePositions(center: CGPoint, profileManager: ProfileManager) {
        friendPositions = [:]
        secondDegreePositions = [:]

        let friends = profileManager.friendsProfiles
        let secondDegrees = profileManager.secondDegreeProfiles
        let friendRange: ClosedRange<CGFloat> = 100...140
        let secondRange: ClosedRange<CGFloat> = 180...230

        let baseAngle = Double.random(in: 0..<360)

        for (i, friend) in friends.enumerated() {
            let angle = Angle(degrees: baseAngle + Double(i) / Double(friends.count) * 360 + Double.random(in: -15...15))
            let distance = CGFloat.random(in: friendRange)
            let pos = center.moved(by: distance, angle: angle)
            friendPositions[friend.uuid] = pos
        }

        for friend in secondDegrees {
            let connectors = profileManager.friendsProfiles.filter { $0.friends.contains(friend.uuid) }
            let angles = connectors.compactMap { connector in
                friendPositions[connector.uuid].map { center.angle(to: $0) }
            }

            let avgAngle = angles.isEmpty ? Double.random(in: 0..<360) : angles.reduce(0, +) / Double(angles.count)
            let angle = Angle(degrees: avgAngle + Double.random(in: -20...20))
            let distance = CGFloat.random(in: secondRange)
            let pos = center.moved(by: distance, angle: angle)
            secondDegreePositions[friend.uuid] = pos
        }
    }
}
