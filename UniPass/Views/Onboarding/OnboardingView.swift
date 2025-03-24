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
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @StateObject private var locationViewModel = LocationViewModel()

    @State private var currentIndex = 0
    @State private var showMainView = false
    @State private var showingImagePicker = false
    
    @State private var name = ""
    @State private var studying = ""
    @State private var year = ""
    @State private var selectedTags: [String] = []
    @State private var bio = ""
    @State private var hometown = ""
    @State private var selectedImageData: Data?
    
    @State private var showValidationAlert = false
    @State private var validationMessage = ""

    var body: some View {
        ZStack {
            TabView(selection: $currentIndex) {
                Slide1()
                    .tag(0)
                    .ignoresSafeArea()
                Slide2()
                    .tag(1)
                    .ignoresSafeArea()
                Slide3()
                    .tag(2)
                    .ignoresSafeArea()
                Slide4()
                    .tag(3)
                    .ignoresSafeArea()
                ProfileSetup1(hometown: $hometown, name: $name, bio: $bio, selectedImageData: $selectedImageData, showingImagePicker: $showingImagePicker, locationViewModel: locationViewModel)
                    .tag(4)
                    .ignoresSafeArea()
                ProfileSetup2(hometown: $hometown, name: $name, studying: $studying, year: $year, selectedImageData: $selectedImageData, selectedTags: $selectedTags, locationViewModel: locationViewModel)
                    .tag(5)
                    .ignoresSafeArea()
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .animation(.easeInOut, value: currentIndex)
            
            VStack {
                Spacer()
                if currentIndex == 3 {
                    styledButton(label: "Setup Profile", action: {
                        handleSlideTransition(index: currentIndex)
                    })
                } else if currentIndex == 4 {
                    Text("All fields are required")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    styledButton(label: "Continue", action: {
                        handleSlideTransition(index: currentIndex)
                    })
                } else if currentIndex == 5 {
                    Text("All fields are required")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    styledButton(label: "Finish", action: {
                        handleSlideTransition(index: currentIndex)
                    })
                } else {
                    styledButton(label: "Continue", action: {
                        handleSlideTransition(index: currentIndex)
                    })
                }
                
                HStack(spacing: 8) {
                    ForEach(0..<6, id: \.self) { index in
                        Circle()
                            .fill(currentIndex == index ? Color.accentColor : Color.gray.opacity(0.4))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .padding(.bottom, 20)
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showMainView) {
            RootView()
                .environmentObject(profileManager)
                .environmentObject(multipeerManager)
                .environmentObject(discoveredManager)
                .onChange(of: multipeerManager.discoveredUUIDs) { _, uuids in
                    guard profileManager.isProfileCreated else {
                        print("⏳ Skipping discovered UUIDs; profile not ready")
                        return
                    }

                    for uuid in uuids {
                        discoveredManager.handleNewUUID(uuid)
                        profileManager.addFriendIfNeeded(uuid: uuid)
                    }
                }
                .ignoresSafeArea()
                .onAppear {
                    multipeerManager.startScanning()
                    
                    bluetoothManager.start(uuid: profileManager.uuid) { discoveredUUID in
                        guard profileManager.isProfileCreated else { return }
                        discoveredManager.handleNewUUID(discoveredUUID)
                        profileManager.addFriendIfNeeded(uuid: discoveredUUID)
                    }
                }
        }
        #elseif os(macOS)
        .sheet(isPresented: $showMainView) {
            RootView()
                .environmentObject(profileManager)
                .environmentObject(multipeerManager)
                .environmentObject(discoveredManager)
                .onChange(of: multipeerManager.discoveredUUIDs) { _, uuids in
                    guard profileManager.isProfileCreated else {
                        print("⏳ Skipping discovered UUIDs; profile not ready")
                        return
                    }

                    for uuid in uuids {
                        discoveredManager.handleNewUUID(uuid)
                        profileManager.addFriendIfNeeded(uuid: uuid)
                    }
                }
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    multipeerManager.startScanning()
                    
                    bluetoothManager.start(uuid: profileManager.uuid) { discoveredUUID in
                        guard profileManager.isProfileCreated else { return }
                        discoveredManager.handleNewUUID(discoveredUUID)
                        profileManager.addFriendIfNeeded(uuid: discoveredUUID)
                    }
                }
        }
        #endif
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(isPresented: $showingImagePicker, selectedImageData: $selectedImageData)
        }
        .alert(isPresented: $showValidationAlert) {
            Alert(
                title: Text("Missing Information"),
                message: Text(validationMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    func handleSlideTransition(index: Int) {
        if index == 5 {
            // Validation checks
            if name.trimmingCharacters(in: .whitespaces).isEmpty {
                validationMessage = "Please enter your name."
                showValidationAlert = true
                currentIndex = 4
                return
            }

            if hometown.trimmingCharacters(in: .whitespaces).isEmpty {
                validationMessage = "Please enter your hometown."
                showValidationAlert = true
                currentIndex = 4
                return
            }

            if bio.trimmingCharacters(in: .whitespaces).isEmpty {
                validationMessage = "Please enter your bio."
                showValidationAlert = true
                currentIndex = 4
                return
            }

            if studying.trimmingCharacters(in: .whitespaces).isEmpty {
                validationMessage = "Please specify what you're studying."
                showValidationAlert = true
                return
            }

            if year.isEmpty {
                validationMessage = "Please select your year."
                showValidationAlert = true
                return
            }

            if selectedTags.isEmpty {
                validationMessage = "Please select at least one tag."
                showValidationAlert = true
                return
            }

            let image: PlatformImage? = {
                guard let data = selectedImageData else { return nil }
                #if os(iOS)
                return UIImage(data: data)
                #elseif os(macOS)
                return NSImage(data: data)
                #endif
            }()

            profileManager.updateProfile(
                name: name,
                studying: studying,
                year: year,
                tags: selectedTags,
                bio: bio,
                hometown: hometown,
                image: image
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                multipeerManager.startScanning()
                UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                showMainView = true
            }
        } else {
            currentIndex += 1
        }
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
