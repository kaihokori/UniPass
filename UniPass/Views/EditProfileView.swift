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

    var body: some View {
        ScrollView {
            MapView(viewModel: locationViewModel, hometown: hometown)
                .transition(.opacity)
                .frame(height: 200)
                .ignoresSafeArea()
                .onChange(of: hometown, initial: true) { oldValue, newValue in
                    guard !newValue.isEmpty else { return }
                    locationViewModel.fetchCoordinates(for: newValue)
                }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("About Me")
                    .font(.title2)
                    .fontWeight(.semibold)
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
                            .background(Color.white)
                            .frame(minHeight: 200)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .systemBackground))
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
                                                .fill(year == yearOption ? Color.blue : Color(UIColor.systemGray5))
                                        )
                                        .foregroundColor(year == yearOption ? .white : .primary)
                                }
                            }
                        }
                        .padding(.horizontal, 15)
                    }
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: .systemBackground))
                    )
                }
                
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
                            .fill(Color(uiColor: .systemBackground))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $showingTagSelector) {
                    TagSelectionView(selectedTags: $selectedTags)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
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
        .background(Color(.systemGray6))
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
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
        )
    }

    func saveProfile() {
        profileManager.updateProfile(
            name: name,
            studying: studying,
            year: year,
            tags: selectedTags,
            bio: bio,
            hometown: hometown
        )
    }
}
