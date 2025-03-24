//
//  Slide2.swift
//  UniPass
//
//  Created by Kyle Graham on 24/3/2025.
//

import SwiftUI

struct Slide2: View {
    var body: some View {
        VStack {
            Text("Peer-To-Peer Discovery")
                .font(.title)
                .bold()

            Spacer()
            
            Image("Slide2")
                .resizable()
                .scaledToFit()
                .padding(.top)
                .padding(.horizontal)
                .offset(y: 7)

            ZStack {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 300)

                Text("Expand your network by being near others")
                    .font(.headline)
                    .padding(.bottom, 100)
            }
        }
        .padding(.top, 140)
    }
}
