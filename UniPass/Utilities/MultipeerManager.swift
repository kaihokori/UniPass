//
//  MultipeerManager.swift
//  UniPass
//
//  Created by Kyle Graham on 23/3/2025.
//

import Foundation
import MultipeerConnectivity

class MultipeerManager: NSObject, ObservableObject {
    private let serviceType = "unipass-demo"
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    private let myPeerID: MCPeerID

    @Published var discoveredUUIDs: [String] = []

    override init() {
        // Use the same UUID as in ProfileManager
        let myUUID = UserDefaults.standard.string(forKey: "userUUID") ?? UUID().uuidString
        UserDefaults.standard.set(myUUID, forKey: "userUUID")
        myPeerID = MCPeerID(displayName: myUUID)

        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)

        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)

        super.init()

        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }

    private func sendMyUUID(to peerID: MCPeerID) {
        guard session.connectedPeers.contains(peerID) else { return }
        if let uuid = UserDefaults.standard.string(forKey: "userUUID"),
           let data = uuid.data(using: .utf8) {
            try? session.send(data, toPeers: [peerID], with: .reliable)
        }
    }
}

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // no-op for now
    }

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if state == .connected {
            sendMyUUID(to: peerID)
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let uuid = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                print("🔗 Received UUID from peer: \(uuid)")
                if !self.discoveredUUIDs.contains(uuid) {
                    self.discoveredUUIDs.append(uuid)
                }
            }
        }
    }

    // unused but required:
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    
    func startScanning() {
        print("STARTED")
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }
}
