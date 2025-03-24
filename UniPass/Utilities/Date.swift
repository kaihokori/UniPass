//
//  Date.swift
//  UniPass
//
//  Created by Kyle Graham on 23/3/2025.
//

import Foundation

extension Date {
    func roundedToNearestFuture(minutes: Int) -> Date {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: self)

        let stripped = calendar.date(bySetting: .second, value: 0, of: self) ?? self

        let remainder = minute % minutes
        let half = minutes / 2

        var adjusted: Date

        if remainder < half {
            adjusted = calendar.date(byAdding: .minute, value: -remainder, to: stripped) ?? stripped
        } else {
            adjusted = calendar.date(byAdding: .minute, value: minutes - remainder, to: stripped) ?? stripped
        }

        if adjusted < Date() {
            adjusted = calendar.date(byAdding: .minute, value: minutes, to: adjusted) ?? adjusted
        }

        return adjusted
    }
}
