//
//  ImageComponent.swift
//  UniPass
//
//  Created by Kyle Graham on 24/3/2025.
//

import SwiftUI

struct ImageComponent: View {
    enum ImageType: Equatable {
        case asset(name: String)
        case sfSymbol(name: String)
    }
    
    let imageType: ImageType
    let color: Color?

    init(
        imageType: ImageType,
        color: Color? = nil
    ) {
        self.imageType = imageType
        self.color = color
    }

    var body: some View {
        Group {
            switch imageType {
            case .asset(let name):
                Image(name)
                    .resizable()
            case .sfSymbol(let name):
                Image(systemName: name)
                    .resizable()
            }
        }
        .scaledToFit()
        .padding()
        .foregroundStyle(color ?? Color.primary)
    }
}

extension ImageComponent.ImageType {
    var isAsset: Bool {
        if case .asset = self { return true }
        return false
    }
}
