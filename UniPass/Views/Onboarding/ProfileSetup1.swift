//
//  ProfileSetup1.swift
//  UniPass
//
//  Created by Kyle Graham on 24/3/2025.
//

import SwiftUI

struct ProfileSetup1: View {
    @Binding var hometown: String
    @Binding var name: String
    @Binding var bio: String
    @Binding var selectedImageData: Data?
    @Binding var showingImagePicker: Bool
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    @FocusState private var isBioFocused: Bool
    @ObservedObject var locationViewModel: LocationViewModel
    #if os(iOS)
    @StateObject private var keyboard = KeyboardResponder()
    #endif
    
    var body: some View {
        ScrollView {
            ZStack {
                if hometown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Rectangle()
                        .fill(AppColor.gray5)
                        .frame(height: 250)
                        .overlay(
                            Text("Add your hometown to show location")
                                .foregroundColor(.secondary)
                                .font(.body)
                        )
                        .ignoresSafeArea()
                } else {
                    MapView(viewModel: locationViewModel, hometown: hometown)
                        .transition(.opacity)
                        .frame(height: 250)
                        .onChange(of: hometown, initial: true) { oldValue, newValue in
                            locationViewModel.fetchCoordinates(for: newValue)
                        }
                }
                
                if let imageData = selectedImageData, let selectedImage = PlatformImage(data: imageData) {
                    #if os(iOS)
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 5)
                        .offset(y: 120)
                        .padding(.bottom, 20)
                    #else
                    Image(nsImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 5)
                        .offset(y: 120)
                        .padding(.bottom, 20)
                    #endif
                } else {
                    Circle()
                        .fill(Color.green)
                        .overlay(
                            Text(String(name.prefix(1)))
                                .font(.title)
                                .foregroundColor(.white)
                        )
                        .frame(width: 130, height: 130)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 5)
                        .offset(y: 120)
                        .padding(.bottom, 20)
                }
            }
            
            HStack {
                Text("About Me")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    showingImagePicker = true
                }) {
                    Label("Change Image", systemImage: "photo")
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColor.gray5)
                )
            }
            .padding(.top, 70)
            .padding(.horizontal)
            
            styledLabeledField(label: "Name", text: $name)
                .padding(.horizontal)
            
            styledLabeledField(label: "Hometown", text: $hometown)
                .padding(.horizontal)
            
            VStack {
                VStack(alignment: .leading) {
                    Text("Bio")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ZStack(alignment: .topLeading) {
                        if $bio.wrappedValue.isEmpty {
                            Text("Enter your bio...")
                                .foregroundColor(.secondary)
                        }
                        
                        TextEditor(text: $bio)
                            .focused($isBioFocused)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .background(AppColor.gray6)
                            .frame(minHeight: 100)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    if isBioFocused {
                                        Spacer()
                                        Button("Done") {
                                            isBioFocused = false
                                        }
                                    }
                                }
                            }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColor.gray6)
                )
            }
            .padding(.horizontal)
        }
        #if os(iOS)
        .padding(.bottom, keyboard.currentHeight)
        .animation(.easeOut(duration: 0.25), value: keyboard.currentHeight)
        #endif
    }
    
    func styledLabeledField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("", text: text)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.horizontal, 5)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColor.gray6)
        )
    }
}
