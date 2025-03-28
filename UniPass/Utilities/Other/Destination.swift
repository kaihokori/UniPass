//
//  Destination.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

import Foundation

enum Destination: Hashable {
    case profile
    case editprofile
    case friendProfile(UserProfile)
    case meetups
    case createMeetup
    case interaction
}
