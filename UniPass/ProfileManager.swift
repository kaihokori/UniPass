//
//  ProfileManager.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

import Foundation
import CloudKit
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

class ProfileManager: ObservableObject {
    @Published var currentProfile: UserProfile?
    @Published var friendsProfiles: [UserProfile] = []
    @Published var secondDegreeProfiles: [UserProfile] = []
    @Published var currentMeetup: Meetup?
    @Published var interactionLog: [InteractionRecord] = []
    @Published var nearbyProfiles: [UserProfile] = []
    @Published var shouldRefreshMeetups: Bool = false
    @Published var usersInMeetups: Set<String> = []
    @Published var allFetchedMeetups: [Meetup] = []
    private var pendingFriendAdditions: [String] = []
    static let shared = ProfileManager()

    // ✅ Explicit container ID
    private let container = CKContainer(identifier: "iCloud.dev.kylegraham.unipass")
    private let uuidKey = "userUUID"
    
    // Will be set after container loads
    private var publicDB: CKDatabase {
        container.publicCloudDatabase
    }

    @Published var uuid: String = ""
    @Published var isProfileCreated: Bool = false {
        didSet {
            if isProfileCreated {
                print("🚀 Profile is ready — retrying pending friend additions...")

                for uuid in pendingFriendAdditions {
                    addFriendIfNeeded(uuid: uuid)
                }

                pendingFriendAdditions.removeAll()
            }
        }
    }
    @Published var profileImage: PlatformImage?

    init() {
        loadOrCreateUUID()
        checkiCloudStatus()
    }

    private func loadOrCreateUUID() {
        // Testing: Reset UUID for
        // UserDefaults.standard.removeObject(forKey: uuidKey)

        // uuid = "D67EA808-518A-4070-8A11-2E7D2508C626"
        // print("🧪 Using hardcoded UUID: \(uuid)")
        
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

                    // 🔁 Retry until it's available
                    self.retryFetchProfileFromCloudKit()
                }
            }
        }
    }

    private func retryFetchProfile(attempts: Int, delay: TimeInterval) {
        guard attempts > 0 else {
            print("❌ Failed to fetch profile after multiple attempts")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.fetchProfileFromCloudKit { success in
                if !success {
                    self.retryFetchProfile(attempts: attempts - 1, delay: delay)
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
    
    func fetchProfileFromCloudKit(completion: ((Bool) -> Void)? = nil) {
        let predicate = NSPredicate(format: "uuid == %@", uuid)
        let query = CKQuery(recordType: "Profile", predicate: predicate)

        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = ["uuid", "name", "studying", "tags", "hometown", "bio", "socialScore", "year", "photo", "friends"]
        operation.resultsLimit = 1

        var fetchedProfile: UserProfile?

        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                let friends = record["friends"] as? [String] ?? []

                let image: PlatformImage? = {
                    if let asset = record["photo"] as? CKAsset,
                       let fileURL = asset.fileURL,
                       let data = try? Data(contentsOf: fileURL) {
                        return PlatformImage(data: data)
                    }
                    return nil
                }()

                fetchedProfile = UserProfile(
                    uuid: record["uuid"] as? String ?? "",
                    name: record["name"] as? String ?? "Unnamed",
                    studying: record["studying"] as? String ?? "",
                    year: record["year"] as? String ?? "",
                    tags: record["tags"] as? [String] ?? [],
                    bio: record["bio"] as? String ?? "",
                    hometown: record["hometown"] as? String ?? "",
                    socialScore: (record["friends"] as? [String] ?? []).count,
                    profileImage: image,
                    friends: friends
                )

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
                        
                        self.isProfileCreated = true
                        
                        // ✅ Process any queued friend additions
                        for uuid in self.pendingFriendAdditions {
                            self.addFriendIfNeeded(uuid: uuid)
                        }
                        self.pendingFriendAdditions.removeAll()

                        completion?(true)
                    } else {
                        print("⚠️ No profile found for UUID: \(self.uuid)")
                        completion?(false)
                    }
                case .failure(let error):
                    print("❌ Failed to fetch profile: \(error.localizedDescription)")
                    completion?(false)
                }
            }
        }

        publicDB.add(operation)
    }
    
    func retryFetchProfileFromCloudKit(maxRetries: Int = 5, delay: TimeInterval = 1.0) {
        var retries = 0

        func attempt() {
            print("⏳ Attempting to fetch profile... (try \(retries + 1)/\(maxRetries))")

            self.fetchProfileFromCloudKit { success in
                if success {
                    print("✅ Profile fetch succeeded after \(retries + 1) attempt(s)")
                } else if retries < maxRetries {
                    retries += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay * pow(2.0, Double(retries))) {
                        attempt()
                    }
                } else {
                    print("❌ Failed to fetch profile after \(maxRetries) retries")
                }
            }
        }

        attempt()
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

                var image: PlatformImage? = nil
                if let photoAsset = record["photo"] as? CKAsset,
                   let fileURL = photoAsset.fileURL,
                   let imageData = try? Data(contentsOf: fileURL),
                   let loadedImage = PlatformImage(data: imageData) {
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
                    socialScore: (record["friends"] as? [String] ?? []).count,
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

                var image: PlatformImage? = nil
                if let photoAsset = record["photo"] as? CKAsset,
                   let fileURL = photoAsset.fileURL,
                   let imageData = try? Data(contentsOf: fileURL),
                   let loadedImage = PlatformImage(data: imageData) {
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
                    socialScore: (record["friends"] as? [String] ?? []).count,
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
    
    func addFriendIfNeeded(uuid: String) {
        guard uuid != self.uuid else { return }

        // Ensure profile is available and CloudKit has indexed it
        guard isProfileCreated, currentProfile != nil else {
            print("🕒 Delaying friend addition, profile not ready.")
            if !pendingFriendAdditions.contains(uuid) {
                pendingFriendAdditions.append(uuid)
            }
            return
        }

        if currentProfile!.friends.contains(uuid) {
            print("👥 \(uuid) is already a friend.")
            return
        }

        let predicate = NSPredicate(format: "uuid == %@", self.uuid)
        let query = CKQuery(recordType: "Profile", predicate: predicate)

        publicDB.fetch(withQuery: query, inZoneWith: nil, desiredKeys: ["friends"], resultsLimit: 1) { result in
            switch result {
            case .failure(let error):
                print("❌ Failed to fetch current user's profile: \(error.localizedDescription)")
            case .success(let (matchResults, _)):
                guard let firstMatch = matchResults.first else {
                    print("❌ No matching profile record found (still indexing?). Queuing...")
                    if !self.pendingFriendAdditions.contains(uuid) {
                        self.pendingFriendAdditions.append(uuid)
                    }
                    return
                }

                let (_, recordResult) = firstMatch

                switch recordResult {
                case .failure(let error):
                    print("❌ Error loading matched record: \(error.localizedDescription)")
                case .success(let record):
                    var friends = record["friends"] as? [String] ?? []
                    if friends.contains(uuid) {
                        print("👥 \(uuid) is already in CloudKit friends list.")
                        return
                    }

                    friends.append(uuid)
                    record["friends"] = friends as NSArray

                    self.publicDB.save(record) { _, error in
                        DispatchQueue.main.async {
                            if let error = error {
                                print("❌ Failed to save updated friends list: \(error.localizedDescription)")
                            } else {
                                print("✅ Added \(uuid) as a new friend and saved to CloudKit.")

                                // Update local copy
                                self.currentProfile?.friends.append(uuid)
                                self.fetchFriendsProfiles(friendUUIDs: self.currentProfile!.friends)

                                // Log interaction
                                self.logInteraction(with: uuid)

                                // Add friend visually
                                self.fetchFriendProfile(uuid: uuid)

                                // Make mutual
                                let friendPredicate = NSPredicate(format: "uuid == %@", uuid)
                                let friendQuery = CKQuery(recordType: "Profile", predicate: friendPredicate)

                                self.publicDB.fetch(withQuery: friendQuery, inZoneWith: nil, desiredKeys: ["friends"], resultsLimit: 1) { result in
                                    switch result {
                                    case .failure(let error):
                                        print("❌ Failed to fetch friend's record for mutual add: \(error.localizedDescription)")
                                    case .success(let (matchResults, _)):
                                        guard let first = matchResults.first else {
                                            print("⚠️ Friend record not found")
                                            return
                                        }

                                        let (_, recordResult) = first
                                        switch recordResult {
                                        case .failure(let error):
                                            print("❌ Failed to load friend's record: \(error.localizedDescription)")
                                        case .success(let friendRecord):
                                            var friendList = friendRecord["friends"] as? [String] ?? []
                                            if !friendList.contains(self.uuid) {
                                                friendList.append(self.uuid)
                                                friendRecord["friends"] = friendList as NSArray

                                                self.publicDB.save(friendRecord) { _, saveError in
                                                    if let saveError = saveError {
                                                        print("❌ Failed to save mutual friendship: \(saveError.localizedDescription)")
                                                    } else {
                                                        print("✅ Mutual friendship saved — they now have you as a friend too.")
                                                        
                                                        self.logReverseInteraction(ownerUUID: uuid, peerUUID: self.uuid)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func fetchFriendProfile(uuid: String) {
        let predicate = NSPredicate(format: "uuid == %@", uuid)
        let query = CKQuery(recordType: "Profile", predicate: predicate)
        let op = CKQueryOperation(query: query)
        op.resultsLimit = 1

        op.desiredKeys = [
            "uuid", "name", "studying", "year", "tags", "bio", "hometown",
            "socialScore", "photo", "friends"
        ]

        var newProfile: UserProfile?

        op.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                var image: PlatformImage? = nil
                if let asset = record["photo"] as? CKAsset,
                   let fileURL = asset.fileURL,
                   let data = try? Data(contentsOf: fileURL) {
                    image = PlatformImage(data: data)
                }

                newProfile = UserProfile(
                    uuid: record["uuid"] as? String ?? "",
                    name: record["name"] as? String ?? "Unnamed",
                    studying: record["studying"] as? String ?? "",
                    year: record["year"] as? String ?? "",
                    tags: record["tags"] as? [String] ?? [],
                    bio: record["bio"] as? String ?? "",
                    hometown: record["hometown"] as? String ?? "",
                    socialScore: (record["friends"] as? [String] ?? []).count,
                    profileImage: image,
                    friends: record["friends"] as? [String] ?? []
                )

            case .failure(let error):
                print("❌ Failed to fetch new friend's profile: \(error.localizedDescription)")
            }
        }

        op.queryResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if let profile = newProfile {
                        // Avoid duplicates
                        if !self.friendsProfiles.contains(where: { $0.uuid == profile.uuid }) {
                            self.friendsProfiles.append(profile)
                            print("✨ Added new friend to UI: \(profile.name)")
                        }

                        // ✅ NEW: Fetch 2° connections
                        let secondDegreeCandidates = profile.friends.filter { friendUUID in
                            friendUUID != self.uuid &&                                // not you
                            !self.friendsProfiles.contains(where: { $0.uuid == friendUUID }) && // not already 1°
                            !self.secondDegreeProfiles.contains(where: { $0.uuid == friendUUID }) // not already in 2°
                        }

                        let uniqueSecondDegree = Array(Set(secondDegreeCandidates))

                        if !uniqueSecondDegree.isEmpty {
                            print("🔁 Fetching new 2° connections: \(uniqueSecondDegree)")
                            self.fetchSecondDegreeProfiles(uuids: uniqueSecondDegree)
                        }

                    }
                case .failure(let error):
                    print("❌ Query failed: \(error.localizedDescription)")
                }
            }
        }

        publicDB.add(op)
    }
    
    func updateProfile(name: String, studying: String, year: String, tags: [String], bio: String, hometown: String, image: PlatformImage?) {
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

                        if let imageData = selectedImage.toJPEGData(compressionQuality: 0.8) {
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
                            print("❌ Failed to convert PlatformImage to JPEG data")
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
    
    func fetchMeetups(for uuids: [String], completion: @escaping ([Meetup]) -> Void) {
        let predicate = NSPredicate(format: "ANY participants IN %@", uuids)
        let query = CKQuery(recordType: "Meetup", predicate: predicate)

        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = ["title", "description", "location", "date", "participants"]

        var meetups: [Meetup] = []
        var allParticipants: Set<String> = []

        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                let participants = record["participants"] as? [String] ?? []
                allParticipants.formUnion(participants)

                let meetup = Meetup(
                    id: record.recordID,
                    title: record["title"] as? String ?? "Untitled",
                    description: record["description"] as? String ?? "",
                    location: record["location"] as? String ?? "Unknown",
                    date: record["date"] as? Date ?? Date(),
                    participants: participants
                )
                meetups.append(meetup)

            case .failure(let error):
                print("❌ Error loading meetup: \(error.localizedDescription)")
            }
        }

        operation.queryResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Loaded \(meetups.count) relevant meetups")

                    self.currentMeetup = meetups.first(where: { $0.participants.contains(self.uuid) })
                    self.usersInMeetups = allParticipants // ✅
                    self.allFetchedMeetups = meetups
                    
                    completion(meetups)

                case .failure(let error):
                    print("❌ Failed to fetch meetups: \(error.localizedDescription)")
                    self.currentMeetup = nil
                    self.usersInMeetups = []
                    completion([])
                }
            }
        }

        publicDB.add(operation)
    }
    
    func createMeetup(title: String, description: String, location: String, date: Date, completion: @escaping (Bool) -> Void) {
        guard !title.isEmpty, !location.isEmpty else {
            print("❌ Title and location must not be empty")
            completion(false)
            return
        }

        guard date >= Date() else {
            print("❌ Date must be in the future")
            completion(false)
            return
        }

        let record = CKRecord(recordType: "Meetup")
        record["title"] = title as NSString
        record["description"] = description as NSString
        record["location"] = location as NSString
        record["date"] = date as NSDate
        record["participants"] = [uuid] as NSArray

        publicDB.save(record) { savedRecord, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error creating meetup: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("✅ Meetup created successfully with ID: \(savedRecord?.recordID.recordName ?? "Unknown")")

                    // 🔁 Delay to allow CloudKit indexing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.shouldRefreshMeetups = true
                    }

                    completion(true)
                }
            }
        }
    }
    
    func removeUserFromExistingMeetups(completion: @escaping () -> Void) {
        let predicate = NSPredicate(format: "ANY participants == %@", uuid)
        let query = CKQuery(recordType: "Meetup", predicate: predicate)

        let queryOp = CKQueryOperation(query: query)
        var recordsToSave: [CKRecord] = []
        var recordIDsToDelete: [CKRecord.ID] = []

        queryOp.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                var participants = record["participants"] as? [String] ?? []
                participants.removeAll { $0 == self.uuid }

                if participants.isEmpty {
                    recordIDsToDelete.append(record.recordID)
                } else {
                    record["participants"] = participants as NSArray
                    recordsToSave.append(record)
                }
            case .failure(let error):
                print("❌ Failed to match record for removal: \(error.localizedDescription)")
            }
        }

        queryOp.queryResultBlock = { result in
            switch result {
            case .success:
                let modifyOp = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
                modifyOp.savePolicy = .changedKeys
                modifyOp.modifyRecordsResultBlock = { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            print("✅ Successfully removed from old meetups")
                            self.currentMeetup = nil
                            completion()
                        case .failure(let error):
                            print("❌ Failed to update/delete old meetups: \(error.localizedDescription)")
                            completion()
                        }
                    }
                }
                self.publicDB.add(modifyOp)

            case .failure(let error):
                print("❌ Failed to query existing meetups: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion()
                }
            }
        }

        publicDB.add(queryOp)
    }
   
    func joinMeetup(meetup: Meetup, force: Bool = false, completion: @escaping (Bool, Bool) -> Void) {
        if !force && willLeavingCurrentMeetupDeleteIt() {
            // ⚠️ Deletion confirmation needed
            completion(false, true)
            return
        }

        removeUserFromExistingMeetups {
            let recordID = meetup.id
            self.publicDB.fetch(withRecordID: recordID) { record, error in
                guard let record = record, error == nil else {
                    print("❌ Failed to fetch meetup to join: \(error?.localizedDescription ?? "Unknown error")")
                    DispatchQueue.main.async { completion(false, false) }
                    return
                }

                var participants = record["participants"] as? [String] ?? []
                if !participants.contains(self.uuid) {
                    participants.append(self.uuid)
                    record["participants"] = participants as NSArray

                    self.publicDB.save(record) { _, saveError in
                        DispatchQueue.main.async {
                            if let saveError = saveError {
                                print("❌ Failed to join meetup: \(saveError.localizedDescription)")
                                completion(false, false)
                            } else {
                                print("✅ Joined meetup: \(meetup.title)")
                                self.currentMeetup = meetup
                                completion(true, false)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(true, false)
                    }
                }
            }
        }
    }

    func leaveMeetup(meetup: Meetup, completion: @escaping (Bool) -> Void) {
        let recordID = meetup.id
        publicDB.fetch(withRecordID: recordID) { record, error in
            guard let record = record else {
                print("❌ Could not find meetup to leave")
                DispatchQueue.main.async { completion(false) }
                return
            }

            var participants = record["participants"] as? [String] ?? []
            participants.removeAll { $0 == self.uuid }

            if participants.isEmpty {
                self.publicDB.delete(withRecordID: recordID) { _, err in
                    DispatchQueue.main.async {
                        if let err = err {
                            print("❌ Failed to delete empty meetup: \(err.localizedDescription)")
                            completion(false)
                        } else {
                            print("🗑️ Meetup deleted (no participants left)")
                            self.currentMeetup = nil
                            completion(true)
                        }
                    }
                }
            } else {
                record["participants"] = participants as NSArray
                self.publicDB.save(record) { _, err in
                    DispatchQueue.main.async {
                        if let err = err {
                            print("❌ Failed to leave meetup: \(err.localizedDescription)")
                            completion(false)
                        } else {
                            print("🚪 Left meetup")
                            self.currentMeetup = nil
                            completion(true)
                        }
                    }
                }
            }
        }
    }

    func willLeavingCurrentMeetupDeleteIt() -> Bool {
        guard let current = currentMeetup else { return false }
        return current.participants.count == 1 && current.participants.contains(uuid)
    }
    
    func logInteraction(with peerUUID: String) {
        guard peerUUID != uuid else { return }

        let record = CKRecord(recordType: "Interaction")
        record["ownerUUID"] = uuid as NSString
        record["peerUUID"] = peerUUID as NSString
        record["date"] = Date() as NSDate

        publicDB.save(record) { saved, error in
            if let error = error {
                print("❌ Failed to log interaction: \(error.localizedDescription)")
            } else {
                print("📌 Logged interaction with \(peerUUID)")
            }
        }
    }
    
    private func logReverseInteraction(ownerUUID: String, peerUUID: String) {
        let record = CKRecord(recordType: "Interaction")
        record["ownerUUID"] = ownerUUID as NSString
        record["peerUUID"] = peerUUID as NSString
        record["date"] = Date() as NSDate

        publicDB.save(record) { saved, error in
            if let error = error {
                print("❌ Failed to log reverse interaction: \(error.localizedDescription)")
            } else {
                print("📌 Logged reverse interaction: \(ownerUUID) met \(peerUUID)")
            }
        }
    }
    
    func fetchInteractionLog() {
        let predicate = NSPredicate(format: "ownerUUID == %@", self.uuid)
        let query = CKQuery(recordType: "Interaction", predicate: predicate)

        self.publicDB.fetch(withQuery: query, inZoneWith: nil, desiredKeys: ["ownerUUID", "peerUUID", "date"], resultsLimit: CKQueryOperation.maximumResults) { result in
            switch result {
            case .failure(let error):
                print("❌ Error fetching interaction log: \(error.localizedDescription)")
            case .success(let (matchResults, _)):
                let uuidsWithDates: [(String, Date)] = matchResults.compactMap { _, result in
                    switch result {
                    case .success(let record):
                        guard let peerUUID = record["peerUUID"] as? String,
                              let date = record["date"] as? Date else { return nil }
                        return (peerUUID, date)
                    case .failure(let error):
                        print("❌ Failed to fetch a record from Interaction log: \(error.localizedDescription)")
                        return nil
                    }
                }

                let uuids = uuidsWithDates.map { $0.0 }
                let profilePredicate = NSPredicate(format: "uuid IN %@", uuids)
                let profileQuery = CKQuery(recordType: "Profile", predicate: profilePredicate)

                let op = CKQueryOperation(query: profileQuery)
                op.desiredKeys = ["uuid", "name", "studying", "year", "hometown", "photo", "tags", "bio", "friends", "socialScore"]

                var profiles: [UserProfile] = []

                op.recordMatchedBlock = { _, result in
                    switch result {
                    case .success(let record):
                        let uuid = record["uuid"] as? String ?? ""
                        var image: PlatformImage? = nil
                        if let asset = record["photo"] as? CKAsset,
                           let fileURL = asset.fileURL,
                           let data = try? Data(contentsOf: fileURL) {
                            image = PlatformImage(data: data)
                        }

                        let profile = UserProfile(
                            uuid: uuid,
                            name: record["name"] as? String ?? "Unnamed",
                            studying: record["studying"] as? String ?? "",
                            year: record["year"] as? String ?? "",
                            tags: record["tags"] as? [String] ?? [],
                            bio: record["bio"] as? String ?? "",
                            hometown: record["hometown"] as? String ?? "",
                            socialScore: (record["friends"] as? [String] ?? []).count,
                            profileImage: image,
                            friends: record["friends"] as? [String] ?? []
                        )

                        profiles.append(profile)

                    case .failure(let error):
                        print("❌ Error loading profile in interaction log: \(error.localizedDescription)")
                    }
                }

                op.queryResultBlock = { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            let log: [InteractionRecord] = profiles.compactMap { profile in
                                guard let date = uuidsWithDates.first(where: { $0.0 == profile.uuid })?.1 else { return nil }
                                let degree: String
                                if self.friendsProfiles.contains(where: { $0.uuid == profile.uuid }) {
                                    degree = "1st"
                                } else if self.secondDegreeProfiles.contains(where: { $0.uuid == profile.uuid }) {
                                    degree = "2nd"
                                } else {
                                    degree = "3rd+"
                                }

                                return InteractionRecord(user: profile, degree: degree, date: date)
                            }

                            self.interactionLog = log.sorted(by: { $0.date > $1.date })

                            // ✅ Add this:
                            print("✅ Fetched interaction log with \(log.count) record(s).")

                        case .failure(let error):
                            print("❌ Failed to complete profile query for interactions: \(error.localizedDescription)")
                        }
                    }
                }

                self.publicDB.add(op)
            }
        }
    }
}
