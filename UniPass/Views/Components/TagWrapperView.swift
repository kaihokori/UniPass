//
//  TagWrapperView.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

import SwiftUI

struct TagWrapperView: View {
    var tags: [String]
    @Binding var selectedTags: [String]

    var body: some View {
        WrappingHStack(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(tags, id: \.self) { tag in
                tagButton(for: tag)
            }
        }
        .padding()
    }

    private func tagButton(for tag: String) -> some View {
        Button(action: {
            toggleTag(tag)
        }) {
            Text(tag)
                .font(.subheadline)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(selectedTags.contains(tag) ? Color.accentColor : AppColor.gray5)
                )
                .foregroundColor(selectedTags.contains(tag) ? .white : Color.primary)
        }
    }

    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.removeAll { $0 == tag }
        } else {
            selectedTags.append(tag)
        }
    }
}
