//
//  UserProfile.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

import Foundation
import CloudKit

struct UserProfile: Equatable, Hashable {
    var uuid: String
    var name: String
    var studying: String
    var year: String
    var tags: [String]
    var bio: String
    var hometown: String
    var socialScore: Int
    var profileImage: PlatformImage?
    var friends: [String]
    
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
            return lhs.uuid == rhs.uuid &&
                   lhs.name == rhs.name &&
                   lhs.studying == rhs.studying &&
                   lhs.year == rhs.year &&
                   lhs.tags == rhs.tags &&
                   lhs.bio == rhs.bio &&
                   lhs.hometown == rhs.hometown &&
                   lhs.socialScore == rhs.socialScore &&
                   lhs.friends == rhs.friends
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(uuid)
            hasher.combine(name)
            hasher.combine(studying)
            hasher.combine(year)
            hasher.combine(tags)
            hasher.combine(bio)
            hasher.combine(hometown)
            hasher.combine(socialScore)
            hasher.combine(friends)
        }
}
