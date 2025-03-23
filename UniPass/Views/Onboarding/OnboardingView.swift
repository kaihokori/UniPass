//
//  OnboardingView.swift
//  UniPass
//
//  Created by Kyle Graham on 24/3/2025.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var multipeerManager: MultipeerManager
    @EnvironmentObject var discoveredManager: DiscoveredManager
    @StateObject private var locationViewModel = LocationViewModel()

    @State private var currentIndex = 0
    @State private var showMainView = false
    
    @State private var name = ""
    @State private var studying = ""
    @State private var year = ""
    @State private var selectedTags: [String] = []
    @State private var bio = ""
    @State private var hometown = ""
    @State private var showingTagSelector = false
    @State private var showingImagePicker = false
    @State private var selectedImageData: Data?
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    @FocusState private var isBioFocused: Bool
    #if os(iOS)
    @StateObject private var keyboard = KeyboardResponder()
    #endif

    var body: some View {
        ZStack() {
            if currentIndex == 0 {
                Text("asd")
            }
            
            else if currentIndex == 1 {
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
                .padding(.bottom, keyboard.currentHeight)
                .animation(.easeOut(duration: 0.25), value: keyboard.currentHeight)
            }
            
            else if currentIndex == 2 {
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
                        Text("Academics")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top, 10)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 70)
                    
                    styledLabeledField(label: "Studying", text: $studying)
                        .padding(.horizontal)
                    
                    VStack {
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
                                                        .fill(year == yearOption ? Color.accentColor : AppColor.systemBackground)
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
                                .fill(AppColor.gray6)
                        )
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Text("My Interests")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top, 10)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
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
                                .fill(AppColor.gray6)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: $showingTagSelector) {
                        TagSelectionView(selectedTags: $selectedTags)
                    }
                    .padding(.horizontal)
                }
            }
            
            VStack {
                Spacer()
                styledButton(label: "Continue", action: {
                    handleSlideTransition(index: currentIndex)
                    currentIndex += 1
                })
            }
            .padding()
            .padding(.bottom, 40)
        }
        .background(AppColor.systemBackground)
        .fullScreenCover(isPresented: $showMainView) {
            RootView()
                .environmentObject(profileManager)
                .environmentObject(multipeerManager)
                .environmentObject(discoveredManager)
                .onChange(of: multipeerManager.discoveredUUIDs) {
                    for uuid in multipeerManager.discoveredUUIDs {
                        discoveredManager.handleNewUUID(uuid)
                        profileManager.addFriendIfNeeded(uuid: uuid)
                    }
                }
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(isPresented: $showingImagePicker, selectedImageData: $selectedImageData)
        }
        .ignoresSafeArea()
    }

    func handleSlideTransition(index: Int) {
        if index == 4 {
            profileManager.updateProfile(
                name: name,
                studying: studying,
                year: year,
                tags: selectedTags,
                bio: bio,
                hometown: hometown,
                image: nil // selectedImageData
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                multipeerManager.startScanning()
                UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                showMainView = true
            }
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
                .fill(AppColor.gray6)
        )
    }
    
    func styledButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
        }) {
            Text(label)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }
}
