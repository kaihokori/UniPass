//
//  Slide4.swift
//  UniPass
//
//  Created by Kyle Graham on 24/3/2025.
//

import SwiftUI

struct Slide4: View {
    var body: some View {
        VStack {
            Text("Meet Your Network")
                .font(.title)
                .bold()

            Spacer()
            
            Image("Slide4")
                .resizable()
                .scaledToFit()
                .padding(.top)
                .padding(.horizontal)
                .offset(y: 7)

            ZStack {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 300)

                Text("Join meetups and connect in-person")
                    .font(.headline)
                    .padding(.bottom, 100)
            }
        }
        .padding(.top, 140)
    }
}
