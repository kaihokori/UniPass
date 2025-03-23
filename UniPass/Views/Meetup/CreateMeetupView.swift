//
//  CreateMeetupView.swift
//  UniPass
//
//  Created by Kyle Graham on 23/3/2025.
//

import SwiftUI

struct CreateMeetupView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @Environment(\.dismiss) var dismiss
    @Binding var navigationPath: NavigationPath
    @State private var showingTagSelector = false
    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var selectedTags: [String] = []
    @State private var date = Date().roundedToNearestFuture(minutes: 15)
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    @FocusState private var isBioFocused: Bool
    
    var body: some View {
        ScrollView {
            ZStack(alignment: .top) {
                HStack {
                    Button {
                        navigationPath.removeLast()
                    } label: {
                        Image(systemName: "chevron.left")
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(AppColor.gray6)
                            )
                    }
                    Spacer()
                    Button {
                        if validateInputs() {
                            profileManager.createMeetup(
                                title: title,
                                description: description,
                                location: location,
                                date: date
                            ) { success in
                                if success {
                                    navigationPath.removeLast()
                                } else {
                                    print("❌ Failed to create meetup")
                                }
                            }
                        } else {
                            showValidationAlert = true
                        }
                    } label: {
                        Label("Create", systemImage: "plus")
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(AppColor.gray6)
                            )
                    }
                }
                .padding(.horizontal, 15)
                
                Text("Create Meetup")
                    .font(.headline)
                    .padding(.top, 10)
            }
            .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 10) {
                styledLabeledField(label: "Title", text: $title)
                
                styledLabeledField(label: "Location", text: $location)
                
                VStack(alignment: .leading) {
                    Text("Description")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ZStack(alignment: .topLeading) {
                        if $description.wrappedValue.isEmpty {
                            Text("Enter a description...")
                                .foregroundColor(.secondary)
                        }

                        TextEditor(text: $description)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .background(AppColor.gray6)
                            .frame(minHeight: 200)
                            .focused($isBioFocused)
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
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Date and Time")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    DatePicker("Meetup Time", selection: $date, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .onChange(of: date) {
                            let rounded = date.roundedToNearestFuture(minutes: 15)
                            if rounded != date {
                                date = rounded
                            }
                        }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColor.gray6)
                )
                
                Button(action: {
                    showingTagSelector = true
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Selected Tags")
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
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        #if os(iOS)
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
        #endif
        .alert(isPresented: $showValidationAlert) {
            Alert(
                title: Text("Missing Information"),
                message: Text(validationMessage),
                dismissButton: .default(Text("OK"))
            )
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
    
    func validateInputs() -> Bool {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = "Please enter a title."
            return false
        }

        if location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = "Please enter a location."
            return false
        }

        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = "Please enter a description."
            return false
        }

        if selectedTags.isEmpty {
            validationMessage = "Please select at least one tag."
            return false
        }

        return true
    }
}
