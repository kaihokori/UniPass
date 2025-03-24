//
//  ImagePicker.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

#if os(iOS)

import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedImageData: Data?

    func makeCoordinator() -> Coordinator {
        return Coordinator(isPresented: $isPresented, selectedImageData: $selectedImageData)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        @Binding var isPresented: Bool
        @Binding var selectedImageData: Data?

        init(isPresented: Binding<Bool>, selectedImageData: Binding<Data?>) {
            _isPresented = isPresented
            _selectedImageData = selectedImageData
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            if let result = results.first {
                result.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, error in
                    DispatchQueue.main.async {
                        if let data = data {
                            self.selectedImageData = data
                        }
                        self.isPresented = false
                    }
                }
            } else {
                self.isPresented = false
            }
        }
    }
}

#elseif os(macOS)

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ImagePicker: View {
    @Binding var isPresented: Bool
    @Binding var selectedImageData: Data?
    
    var body: some View {
        EmptyView()
            .onAppear {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [.image]
                panel.canChooseDirectories = false
                panel.allowsMultipleSelection = false
                
                if panel.runModal() == .OK, let url = panel.url,
                   let data = try? Data(contentsOf: url) {
                    selectedImageData = data
                }
                
                isPresented = false
            }
    }
}

#endif
