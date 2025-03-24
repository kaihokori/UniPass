//
//  AppColor.swift
//  UniPass
//
//  Created by Kyle Graham on 23/3/2025.
//

import SwiftUI

enum AppColor {
    static var gray5: Color {
        #if os(iOS)
        return Color(UIColor.systemGray5)
        #elseif os(macOS)
        return Color(nsColor: NSColor.controlBackgroundColor.withAlphaComponent(0.3))
        #endif
    }

    static var gray6: Color {
        #if os(iOS)
        return Color(UIColor.systemGray6)
        #elseif os(macOS)
        return Color(nsColor: NSColor.windowBackgroundColor.withAlphaComponent(0.3))
        #endif
    }

    static var systemBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #elseif os(macOS)
        return Color(nsColor: NSColor.windowBackgroundColor)
        #endif
    }
}

