//
//  ProfileManager.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

import Foundation
import CloudKit

class ProfileManager: ObservableObject {
    @Published var currentProfile: UserProfile?
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
        
        print("Saving record with UUID: \(uuid)")

        publicDB.save(record) { record, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error creating profile: \(error.localizedDescription)")
                } else {
                    print("✅ Profile created in CloudKit: \(record?.recordID.recordName ?? "Unknown ID")")
                    self.isProfileCreated = true
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
        operation.desiredKeys = ["uuid", "name", "studying", "tags", "hometown", "bio", "socialScore", "year", "name"]
        operation.resultsLimit = 1

        var fetchedProfile: UserProfile?

        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                fetchedProfile = UserProfile(
                    uuid: record["uuid"] as? String ?? "",
                    name: record["name"] as? String ?? "Unnamed",
                    studying: record["studying"] as? String ?? "",
                    year: record["year"] as? String ?? "",
                    tags: record["tags"] as? [String] ?? [],
                    bio: record["bio"] as? String ?? "",
                    hometown: record["hometown"] as? String ?? "",
                    socialScore: Int(record["socialScore"] as? Int64 ?? 0)
                )
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

    func updateProfile(name: String, studying: String, year: String, tags: [String], bio: String, hometown: String) {
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

                    // 📝 Update fields
                    record["name"] = name as NSString
                    record["studying"] = studying as NSString
                    record["year"] = year as NSString
                    record["tags"] = tags as NSArray
                    record["bio"] = bio as NSString
                    record["hometown"] = hometown as NSString

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
