//
//  RippleCircle.swift
//  UniPass
//
//  Created by Kyle Graham on 23/3/2025.
//

import SwiftUI

struct RippleCircle: View {
    let color: Color
    let delay: Double
    let baseSize: CGFloat
    let maxScale: CGFloat

    @State private var scale: CGFloat = 1.0

    var body: some View {
        Circle()
            .fill(
                LinearGradient(colors: [
                    color.opacity(0.3),
                    color.opacity(0.05)
                ], startPoint: .top, endPoint: .bottom)
            )
            .frame(width: baseSize, height: baseSize)
            .scaleEffect(scale)
            .opacity(maxScale - scale)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 4)
                        .repeatForever(autoreverses: false)
                        .delay(delay)
                ) {
                    scale = maxScale
                }
            }
    }
}
