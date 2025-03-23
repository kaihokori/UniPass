//
//  InteractionRowView.swift
//  UniPass
//
//  Created by Kyle Graham on 23/3/2025.
//

import SwiftUI

struct InteractionRowView: View {
    let profile: UserProfile
    let degree: String?
    let date: Date?
    let myTags: Set<String>
    let onTap: () -> Void
    let goingToMeetup: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading) {
                HStack {
                    if let image = profile.profileImage {
                        #if os(iOS)
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(goingToMeetup ? Color.purple : Color.clear, lineWidth: 3)
                            )
                        #else
                        Image(nsImage: image)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(goingToMeetup ? Color.purple : Color.clear, lineWidth: 3)
                            )
                        #endif
                    } else {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 40, height: 40)
                            .overlay(Text(profile.name.prefix(1)).foregroundColor(.white))
                            .overlay(
                                Circle()
                                    .stroke(goingToMeetup ? Color.purple : Color.clear, lineWidth: 3)
                            )
                    }

                    VStack(alignment: .leading) {
                        Text(profile.name).bold()

                        Text("\(profile.studying) • \(profile.year) • \(profile.hometown)")
                            .font(.caption)
                            .foregroundColor(.gray)

                        if let date = date {
                            Text("Met on \(date.formatted(.dateTime.month().day().year()))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if !profile.tags.isEmpty {
                    tagRow
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .onTapGesture {
            onTap()
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColor.gray6)
        )
    }

    var tagRow: some View {
        let sorted = profile.tags.sorted { lhs, rhs in
            let lhsIsCommon = myTags.contains(lhs)
            let rhsIsCommon = myTags.contains(rhs)
            return lhsIsCommon && !rhsIsCommon
        }

        let displayed = Array(sorted.prefix(3))

        return HStack(spacing: 6) {
            ForEach(displayed, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(myTags.contains(tag) ? Color.accentColor : AppColor.gray5)
                    )
                    .foregroundColor(myTags.contains(tag) ? .white : .primary)
            }
        }
    }
}
