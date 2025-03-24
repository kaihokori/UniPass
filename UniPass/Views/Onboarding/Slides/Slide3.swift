//
//  Slide3.swift
//  UniPass
//
//  Created by Kyle Graham on 24/3/2025.
//

import SwiftUI

struct Slide3: View {
    var body: some View {
        VStack {
            Text("Know the Crowd")
                .font(.title)
                .bold()

            Spacer()
            
            Image("Slide3")
                .resizable()
                .scaledToFit()
                .padding(.top)
                .padding(.horizontal)
                .offset(y: 7)

            ZStack {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 300)

                Text("Find people near you with similar interests")
                    .font(.headline)
                    .padding(.bottom, 100)
            }
        }
        .padding(.top, 140)
    }
}
