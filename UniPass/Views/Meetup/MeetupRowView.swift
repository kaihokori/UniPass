//
//  MeetupRowView.swift
//  UniPass
//
//  Created by Kyle Graham on 24/3/2025.
//

import SwiftUI

struct MeetupRowView: View {
    let meetup: Meetup
    let currentUserUUID: String
    let getUserProfile: (String) -> UserProfile?
    let onJoin: (() -> Void)?
    let onLeave: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(meetup.title)
                    .font(.headline)
                Spacer()
                HStack(spacing: -15) {
                    ForEach(meetup.participants.prefix(5), id: \.self) { uuid in
                        if let user = getUserProfile(uuid) {
                            if let image = user.profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.purple, lineWidth: 2))
                            } else {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 36, height: 36)
                                    .overlay(Text(String(user.name.prefix(1))).foregroundColor(.white))
                                    .overlay(Circle().stroke(Color.purple, lineWidth: 2))
                            }
                        }
                    }

                    if meetup.participants.count > 5 {
                        Text("+\(meetup.participants.count - 5)")
                            .font(.caption)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(AppColor.gray6))
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                }
            }

            Text(meetup.description)
                .font(.body)

            HStack {
                Text(meetup.location)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text(meetup.date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            if let onJoin = onJoin, !meetup.participants.contains(currentUserUUID) {
                Button(action: onJoin) {
                    Text("Join")
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            if let onLeave = onLeave, meetup.participants.contains(currentUserUUID) {
                Button(action: onLeave) {
                    Text("Leave")
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(AppColor.gray6))
        .frame(maxWidth: .infinity)
    }
}
