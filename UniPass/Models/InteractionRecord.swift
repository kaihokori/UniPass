//
//  InteractionRecord.swift
//  UniPass
//
//  Created by Kyle Graham on 23/3/2025.
//

import Foundation

struct InteractionRecord: Identifiable {
    let user: UserProfile
    let degree: String
    let date: Date

    var id: String {
        user.uuid + date.iso8601String
    }
}

private extension Date {
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }
}
