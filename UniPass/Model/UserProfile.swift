//
//  UserProfile.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

import Foundation
import CloudKit
import UIKit

struct UserProfile: Equatable, Hashable {
    var uuid: String
    var name: String
    var studying: String
    var year: String
    var tags: [String]
    var bio: String
    var hometown: String
    var socialScore: Int
    var profileImage: UIImage?
    var friends: [String]
}
