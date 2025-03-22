//
//  UserProfile.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

import Foundation
import CloudKit

struct UserProfile: Equatable {
    var uuid: String
    var name: String
    var studying: String
    var year: String
    var tags: [String]
    var bio: String
    var hometown: String
    var socialScore: Int
}
