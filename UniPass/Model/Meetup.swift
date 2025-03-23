//
//  Meetup.swift
//  UniPass
//
//  Created by Kyle Graham on 23/3/2025.
//

import CloudKit

struct Meetup: Identifiable {
    var id: CKRecord.ID
    var title: String
    var description: String
    var location: String
    var date: Date
    var participants: [String]
}
