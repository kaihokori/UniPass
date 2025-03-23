//
//  RippleBackgroundView.swift
//  UniPass
//
//  Created by Kyle Graham on 23/3/2025.
//

import SwiftUI

struct RippleBackgroundView: View {
    let rippleCount = 3
    let maxScale: CGFloat = 5.0
    let baseSize: CGFloat = 100
    let rippleColor: Color = .accentColor

    @State private var isAnimating = true

    var body: some View {
        ZStack {
            ForEach(0..<rippleCount, id: \.self) { i in
                RippleCircle(
                    color: rippleColor,
                    delay: Double(i) * 0.5,
                    baseSize: baseSize,
                    maxScale: maxScale
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isAnimating = true
        }
    }
}
