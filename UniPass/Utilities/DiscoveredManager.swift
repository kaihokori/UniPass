//
//  DiscoveredManager.swift
//  UniPass
//
//  Created by Kyle Graham on 23/3/2025.
//

import Foundation
import CloudKit

class DiscoveredManager: ObservableObject {
    @Published var recentlyFoundProfiles: [UserProfile] = []

    func handleNewUUID(_ uuid: String) {
        guard !recentlyFoundProfiles.contains(where: { $0.uuid == uuid }) else { return }

        let predicate = NSPredicate(format: "uuid == %@", uuid)
        let query = CKQuery(recordType: "Profile", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1

        operation.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                let profile = UserProfile(
                    uuid: record["uuid"] as? String ?? "",
                    name: record["name"] as? String ?? "Unnamed",
                    studying: record["studying"] as? String ?? "",
                    year: record["year"] as? String ?? "",
                    tags: record["tags"] as? [String] ?? [],
                    bio: record["bio"] as? String ?? "",
                    hometown: record["hometown"] as? String ?? "",
                    socialScore: (record["friends"] as? [String] ?? []).count,
                    profileImage: nil,
                    friends: record["friends"] as? [String] ?? []
                )

                DispatchQueue.main.async {
                    self.recentlyFoundProfiles.append(profile)
                    print("✅ Loaded discovered profile: \(profile.name)")
                }

            case .failure(let error):
                print("❌ Failed to fetch discovered profile: \(error.localizedDescription)")
            }
        }

        CKContainer.default().publicCloudDatabase.add(operation)
    }
}
