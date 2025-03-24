//
//  ProfileSetup2.swift
//  UniPass
//
//  Created by Kyle Graham on 24/3/2025.
//

import SwiftUI

struct ProfileSetup2: View {
    @Binding var hometown: String
    @Binding var name: String
    @Binding var studying: String
    @Binding var year: String
    @Binding var selectedImageData: Data?
    @Binding var selectedTags: [String]
    @State private var showingTagSelector = false
    @ObservedObject var locationViewModel: LocationViewModel
    
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
