//
//  CGPoint.swift
//  UniPass
//
//  Created by Kyle Graham on 24/3/2025.
//

import SwiftUI

extension CGPoint {
    func moved(by distance: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(
            x: self.x + distance * CGFloat(cos(angle.radians)),
            y: self.y + distance * CGFloat(sin(angle.radians))
        )
    }

    func angle(to point: CGPoint) -> Double {
        let dx = point.x - self.x
        let dy = point.y - self.y
        return atan2(dy, dx) * 180 / Double.pi
    }

    func distance(to point: CGPoint) -> CGFloat {
        sqrt(pow(point.x - x, 2) + pow(point.y - y, 2))
    }
}
