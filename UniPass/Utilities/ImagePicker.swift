//
//  ImagePicker.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

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
        config.selectionLimit = 1 // Limit to one selection
        config.filter = .images // Only images are allowed
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed for this case
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
                // Get selected asset
                result.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.image") { (data, error) in
                    DispatchQueue.main.async {
                        if let data = data {
                            self.selectedImageData = data
                        }
                        self.isPresented = false // Dismiss picker
                    }
                }
            } else {
                self.isPresented = false // Dismiss picker if nothing is selected
            }
        }
    }
}
