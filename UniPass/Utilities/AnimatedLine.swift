//
//  AnimatedLine.swift
//  UniPass
//
//  Created by Kyle Graham on 23/3/2025.
//

import SwiftUICore

struct AnimatedLine: Shape {
    var start: CGPoint
    var end: CGPoint
    var progress: CGFloat // from 0.0 to 1.0

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let dx = end.x - start.x
        let dy = end.y - start.y
        let currentEnd = CGPoint(x: start.x + dx * progress, y: start.y + dy * progress)

        path.move(to: start)
        path.addLine(to: currentEnd)
        return path
    }
}
