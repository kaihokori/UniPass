//
//  EditProfileSheet.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @StateObject private var locationViewModel = LocationViewModel()
    @Binding var navigationPath: NavigationPath

    @State private var name = ""
    @State private var studying = ""
    @State private var year = ""
    @State private var selectedTags: [String] = []
    @State private var bio = ""
    @State private var hometown = ""
    @State private var showingTagSelector = false
    @State private var showingImagePicker = false
    @State private var selectedImageData: Data?

    var body: some View {
        ScrollView {
            ZStack(alignment: .top) {
                MapView(viewModel: locationViewModel, hometown: hometown)
                    .transition(.opacity)
                    .frame(height: 250)
                    .onChange(of: hometown, initial: true) { oldValue, newValue in
                        guard !newValue.isEmpty else { return }
                        locationViewModel.fetchCoordinates(for: newValue)
                    }
                
                HStack {
                    Button {
                        saveProfile()
                        navigationPath.removeLast()
                    } label: {
                        Image(systemName: "chevron.left")
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color(UIColor.systemGray6))
                            )
                    }
                    .padding(.leading, 15)
                    Spacer()
                }
                .offset(y: 60)
                
                if let imageData = selectedImageData, let selectedImage = UIImage(data: imageData) {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 5)
                        .offset(y: 175)
                        .padding(.bottom, 20)
                } else if let profileImage = profileManager.currentProfile?.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 5)
                        .offset(y: 175)
                        .padding(.bottom, 20)
                } else {
                    Circle()
                        .fill(Color.blue)
                        .overlay(
                            Text(String(profileManager.currentProfile?.name.prefix(1) ?? " "))
                                .font(.title)
                                .foregroundColor(.white)
                        )
                        .frame(width: 130, height: 130)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 5)
                        .offset(y: 175)
                        .padding(.bottom, 20)
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
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
                            .fill(Color(UIColor.systemGray6))
                    )
                }
                .padding(.top, 10)
                
                styledLabeledField(label: "Name", text: $name)
                
                styledLabeledField(label: "Hometown", text: $hometown)
                
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
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .background(Color(UIColor.systemGray6))
                            .frame(minHeight: 200)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemGray6))
                )
                
                Text("Academics")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 10)
                
                styledLabeledField(label: "Studying", text: $studying)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Year")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 15)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(["1st", "2nd", "3rd", "4th", "5th+"], id: \.self) { yearOption in
                                Button(action: {
                                    year = yearOption
                                }) {
                                    Text(yearOption)
                                        .font(.subheadline)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(year == yearOption ? Color.blue : Color(UIColor.systemBackground))
                                        )
                                        .foregroundColor(year == yearOption ? .white : .primary)
                                }
                            }
                        }
                        .padding(.horizontal, 15)
                    }
                }
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemGray6))
                )
                
                Text("My Interests")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 10)

                Button(action: {
                    showingTagSelector = true
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Tags")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(selectedTags.isEmpty ? "None" : selectedTags.joined(separator: ", "))
                                .font(.body)
                                .padding(.vertical, 2)
                                .foregroundColor(selectedTags.isEmpty ? .gray : .primary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.systemGray6))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $showingTagSelector) {
                    TagSelectionView(selectedTags: $selectedTags)
                }
            }
            .padding(.horizontal)
            .padding(.top, 60)
            .padding(.bottom, 50)
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    saveProfile()
                    navigationPath.removeLast()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            if let profile = profileManager.currentProfile {
                name = profile.name
                studying = profile.studying
                year = profile.year
                selectedTags = profile.tags
                bio = profile.bio
                hometown = profile.hometown
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(isPresented: $showingImagePicker, selectedImageData: $selectedImageData)
        }
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
                .fill(Color(UIColor.systemGray6))
        )
    }

    func saveProfile() {
        let imageToSave: UIImage?

        if let selectedImageData = selectedImageData, let selectedImage = UIImage(data: selectedImageData) {
            imageToSave = selectedImage
        } else {
            imageToSave = profileManager.currentProfile?.profileImage
        }

        profileManager.updateProfile(
            name: name,
            studying: studying,
            year: year,
            tags: selectedTags,
            bio: bio,
            hometown: hometown,
            image: imageToSave
        )
    }
}
