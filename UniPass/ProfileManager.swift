//
//  ProfileManager.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

import Foundation
import CloudKit
import UIKit

class ProfileManager: ObservableObject {
    @Published var currentProfile: UserProfile?
    @Published var friendsProfiles: [UserProfile] = []
    @Published var secondDegreeProfiles: [UserProfile] = []
    static let shared = ProfileManager()

    // ✅ Explicit container ID
    private let container = CKContainer(identifier: "iCloud.dev.kylegraham.unipass")
    private let uuidKey = "userUUID"
    
    // Will be set after container loads
    private var publicDB: CKDatabase {
        container.publicCloudDatabase
    }

    @Published var uuid: String = ""
    @Published var isProfileCreated: Bool = false
    @Published var profileImage: UIImage?

    init() {
        loadOrCreateUUID()
        checkiCloudStatus()
    }

    private func loadOrCreateUUID() {
        // Testing: Reset UUID for testing
        // UserDefaults.standard.removeObject(forKey: uuidKey)

        if let savedUUID = UserDefaults.standard.string(forKey: uuidKey) {
            uuid = savedUUID
            print("Loaded existing UUID: \(uuid)")
        } else {
            let newUUID = UUID().uuidString
            uuid = newUUID
            UserDefaults.standard.set(newUUID, forKey: uuidKey)
            print("Generated new UUID: \(uuid)")
            createProfileInCloudKit()
        }
    }

    private func createProfileInCloudKit() {
        let record = CKRecord(recordType: "Profile")
        record["uuid"] = uuid
        record["socialScore"] = 0 as NSNumber
        record["photo"] = nil
        record["name"] = "New User" as NSString
        record["studying"] = "" as NSString
        record["year"] = "" as NSString
        record["tags"] = [] as NSArray
        record["bio"] = "" as NSString
        record["hometown"] = "" as NSString
        record["friends"] = [] as NSArray

        print("Saving record with UUID: \(uuid)")

        publicDB.save(record) { record, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error creating profile: \(error.localizedDescription)")
                } else {
                    print("✅ Profile created in CloudKit: \(record?.recordID.recordName ?? "Unknown ID")")
                    self.isProfileCreated = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.fetchProfileFromCloudKit()
                    }
                }
            }
        }
    }
    
    private func checkiCloudStatus() {
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ iCloud account check error: \(error.localizedDescription)")
                } else {
                    switch status {
                    case .available:
                        print("✅ iCloud account available")
                    case .noAccount:
                        print("⚠️ No iCloud account signed in")
                    case .restricted:
                        print("⚠️ iCloud restricted (e.g. parental controls)")
                    case .couldNotDetermine:
                        print("⚠️ Could not determine iCloud status")
                    case .temporarilyUnavailable:
                        print("⚠️ Temporarily Unavailable")
                    @unknown default:
                        print("⚠️ Unknown iCloud status")
                    }
                }
            }
        }
    }
    
    func fetchProfileFromCloudKit() {
        let predicate = NSPredicate(format: "uuid == %@", uuid)
        let query = CKQuery(recordType: "Profile", predicate: predicate)

        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = ["uuid", "name", "studying", "tags", "hometown", "bio", "socialScore", "year", "name", "photo", "friends"]
        operation.resultsLimit = 1

        var fetchedProfile: UserProfile?

        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                let friends = record["friends"] as? [String] ?? []

                if let photoAsset = record["photo"] as? CKAsset,
                   let fileURL = photoAsset.fileURL,
                   let imageData = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: imageData) {

                    fetchedProfile = UserProfile(
                        uuid: record["uuid"] as? String ?? "",
                        name: record["name"] as? String ?? "Unnamed",
                        studying: record["studying"] as? String ?? "",
                        year: record["year"] as? String ?? "",
                        tags: record["tags"] as? [String] ?? [],
                        bio: record["bio"] as? String ?? "",
                        hometown: record["hometown"] as? String ?? "",
                        socialScore: Int(record["socialScore"] as? Int64 ?? 0),
                        profileImage: image,
                        friends: friends
                    )
                } else {
                    fetchedProfile = UserProfile(
                        uuid: record["uuid"] as? String ?? "",
                        name: record["name"] as? String ?? "Unnamed",
                        studying: record["studying"] as? String ?? "",
                        year: record["year"] as? String ?? "",
                        tags: record["tags"] as? [String] ?? [],
                        bio: record["bio"] as? String ?? "",
                        hometown: record["hometown"] as? String ?? "",
                        socialScore: Int(record["socialScore"] as? Int64 ?? 0),
                        profileImage: nil,
                        friends: friends
                    )
                }

                self.fetchFriendsProfiles(friendUUIDs: friends)

            case .failure(let error):
                print("❌ Record match error: \(error.localizedDescription)")
            }
        }

        operation.queryResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if let profile = fetchedProfile {
                        self.currentProfile = profile
                        print("✅ Loaded profile: \(profile.name)")
                    } else {
                        print("⚠️ No profile found for UUID: \(self.uuid)")
                    }
                case .failure(let error):
                    print("❌ Failed to fetch profile: \(error.localizedDescription)")
                }
            }
        }

        publicDB.add(operation)
    }
    
    func fetchFriendsProfiles(friendUUIDs: [String]) {
        guard !friendUUIDs.isEmpty else {
            print("⚠️ No friend UUIDs to fetch.")
            DispatchQueue.main.async {
                self.friendsProfiles = []
            }
            return
        }

        print("📥 Attempting to fetch friend UUIDs: \(friendUUIDs)")

        let predicate = NSPredicate(format: "uuid IN %@", friendUUIDs)
        let query = CKQuery(recordType: "Profile", predicate: predicate)

        let operation = CKQueryOperation(query: query)

        // ✅ Add 'friends' so you can support second-degree later, and ensure all fields are fetched
        operation.desiredKeys = [
            "uuid",
            "name",
            "studying",
            "year",
            "tags",
            "bio",
            "hometown",
            "socialScore",
            "photo",
            "friends"
        ]

        var profiles: [UserProfile] = []

        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                let uuid = record["uuid"] as? String ?? "no-uuid"
                print("🔗 Fetched friend record for uuid: \(uuid)")

                var image: UIImage? = nil
                if let photoAsset = record["photo"] as? CKAsset,
                   let fileURL = photoAsset.fileURL,
                   let imageData = try? Data(contentsOf: fileURL),
                   let loadedImage = UIImage(data: imageData) {
                    image = loadedImage
                }

                let profile = UserProfile(
                    uuid: uuid,
                    name: record["name"] as? String ?? "Unnamed",
                    studying: record["studying"] as? String ?? "",
                    year: record["year"] as? String ?? "",
                    tags: record["tags"] as? [String] ?? [],
                    bio: record["bio"] as? String ?? "",
                    hometown: record["hometown"] as? String ?? "",
                    socialScore: Int(record["socialScore"] as? Int64 ?? 0),
                    profileImage: image,
                    friends: record["friends"] as? [String] ?? []
                )

                profiles.append(profile)

            case .failure(let error):
                print("❌ Error loading a friend profile: \(error.localizedDescription)")
            }
        }

        operation.queryResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.friendsProfiles = profiles
                    print("✅ Loaded \(profiles.count) friend profiles:")
                    profiles.forEach { print("   • \($0.name) (\($0.uuid))") }
                    
                    // Collect all second-degree UUIDs
                    let secondDegreeUUIDs = profiles
                        .flatMap { $0.friends }
                        .filter { friendUUID in
                            friendUUID != self.uuid &&  // not you
                            !self.friendsProfiles.contains(where: { $0.uuid == friendUUID }) // not already a direct friend
                        }

                    let uniqueSecondDegreeUUIDs = Array(Set(secondDegreeUUIDs))

                    print("🔁 Fetching second-degree UUIDs: \(uniqueSecondDegreeUUIDs)")

                    self.fetchSecondDegreeProfiles(uuids: uniqueSecondDegreeUUIDs)
                case .failure(let error):
                    print("❌ Failed to fetch friend profiles: \(error.localizedDescription)")
                }
            }
        }

        publicDB.add(operation)
    }
    
    func fetchSecondDegreeProfiles(uuids: [String]) {
        guard !uuids.isEmpty else {
            print("ℹ️ No second-degree profiles to fetch.")
            DispatchQueue.main.async {
                self.secondDegreeProfiles = []
            }
            return
        }

        let predicate = NSPredicate(format: "uuid IN %@", uuids)
        let query = CKQuery(recordType: "Profile", predicate: predicate)

        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = [
            "uuid", "name", "studying", "year", "tags", "bio",
            "hometown", "socialScore", "photo", "friends"
        ]

        var profiles: [UserProfile] = []

        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                let uuid = record["uuid"] as? String ?? "no-uuid"
                print("🔗 2° Fetched profile for uuid: \(uuid)")

                var image: UIImage? = nil
                if let photoAsset = record["photo"] as? CKAsset,
                   let fileURL = photoAsset.fileURL,
                   let imageData = try? Data(contentsOf: fileURL),
                   let loadedImage = UIImage(data: imageData) {
                    image = loadedImage
                }

                let profile = UserProfile(
                    uuid: uuid,
                    name: record["name"] as? String ?? "Unnamed",
                    studying: record["studying"] as? String ?? "",
                    year: record["year"] as? String ?? "",
                    tags: record["tags"] as? [String] ?? [],
                    bio: record["bio"] as? String ?? "",
                    hometown: record["hometown"] as? String ?? "",
                    socialScore: Int(record["socialScore"] as? Int64 ?? 0),
                    profileImage: image,
                    friends: record["friends"] as? [String] ?? []
                )

                profiles.append(profile)

            case .failure(let error):
                print("❌ Error loading second-degree profile: \(error.localizedDescription)")
            }
        }

        operation.queryResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.secondDegreeProfiles = profiles
                    print("✅ Loaded \(profiles.count) 2° friend profiles")
                case .failure(let error):
                    print("❌ Failed to fetch 2° profiles: \(error.localizedDescription)")
                }
            }
        }

        publicDB.add(operation)
    }
    
    func updateProfile(name: String, studying: String, year: String, tags: [String], bio: String, hometown: String, image: UIImage?) {
        let predicate = NSPredicate(format: "uuid == %@", uuid)
        let query = CKQuery(recordType: "Profile", predicate: predicate)

        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = nil
        operation.resultsLimit = 1

        var fetchedRecord: CKRecord?

        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                fetchedRecord = record
            case .failure(let error):
                print("❌ Failed to match record: \(error.localizedDescription)")
            }
        }

        operation.queryResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    guard let record = fetchedRecord else {
                        print("⚠️ No matching profile found to update")
                        return
                    }

                    // 📝 Update text fields
                    record["name"] = name as NSString
                    record["studying"] = studying as NSString
                    record["year"] = year as NSString
                    record["tags"] = tags as NSArray
                    record["bio"] = bio as NSString
                    record["hometown"] = hometown as NSString

                    // 📸 Updated image handling with logs
                    if let selectedImage = image {
                        print("📸 Got image, attempting to save...")

                        if let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                            let tempDir = FileManager.default.temporaryDirectory
                            let fileURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")

                            do {
                                try imageData.write(to: fileURL)
                                let photoAsset = CKAsset(fileURL: fileURL)
                                record["photo"] = photoAsset
                                print("✅ Image written to temp file: \(fileURL.path)")
                            } catch {
                                print("❌ Failed to write image to disk: \(error.localizedDescription)")
                            }
                        } else {
                            print("❌ Failed to convert UIImage to JPEG data")
                        }
                    } else {
                        print("⚠️ No image provided to save")
                    }

                    print("🚀 Attempting to save record with values:")
                    print("Name:", name)
                    print("Studying:", studying)
                    print("Year:", year)
                    print("Tags:", tags)
                    print("Bio:", bio)
                    print("Hometown:", hometown)
                    print("Photo:", record["photo"] != nil ? "✅ Asset present" : "❌ No image")
                    
                    // 💾 Save updated record
                    self.publicDB.save(record) { savedRecord, saveError in
                        DispatchQueue.main.async {
                            if let saveError = saveError {
                                print("❌ Error saving profile: \(saveError.localizedDescription)")
                            } else {
                                print("✅ Profile updated successfully!")
                                self.fetchProfileFromCloudKit()
                            }
                        }
                    }

                case .failure(let error):
                    print("❌ Error executing query: \(error.localizedDescription)")
                }
            }
        }

        self.publicDB.add(operation)
    }
}
