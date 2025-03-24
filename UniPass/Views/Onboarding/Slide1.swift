//
//  Slide1.swift
//  UniPass
//
//  Created by Kyle Graham on 24/3/2025.
//

import SwiftUI

struct Slide1: View {
    var body: some View {
        VStack {
            Text("Welcome to UniPass")
                .font(.title)
                .bold()

            Spacer()
            
            Image("Logo")
                .resizable()
                .scaledToFit()
                .padding(.top)
                .padding(.horizontal)
                .offset(y: 7)

            ZStack {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 300)

                Text("Build connections in the moment")
                    .font(.headline)
                    .padding(.bottom, 100)
            }
        }
        .padding(.top, 140)
    }
}
