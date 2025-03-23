//
//  PlatformImage.swift
//  UniPass
//
//  Created by Kyle Graham on 23/3/2025.
//

// PlatformImage.swift
#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

extension PlatformImage {
    func toJPEGData(compressionQuality: CGFloat = 0.8) -> Data? {
        #if os(iOS)
        return self.jpegData(compressionQuality: compressionQuality)
        #elseif os(macOS)
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
        #endif
    }
}
