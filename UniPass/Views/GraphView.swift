//
//  GraphView.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

import SwiftUI

struct GraphView: View {
    @Binding var navigationPath: NavigationPath

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button {
                        print("Meetups Tapped")
                    } label: {
                        Label("Meetups", systemImage: "calendar")
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.gray.opacity(0.2))
                            )
                    }

                    Button {
                        print("Interaction Log Tapped")
                    } label: {
                        Image(systemName: "person.2")
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                            )
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
            
            Button {
                navigationPath.append(Destination.profile)
            } label: {
                Image(systemName: "person.circle")
                    .font(.system(size: 30))
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                    )
            }
        }
    }
}


#Preview {
    GraphView(navigationPath: .constant(NavigationPath()))
}
