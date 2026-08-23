//
//  P2PInboxService.swift
//  ClosedCaptioner
//
//  Radio on: browse + advertise on cc-p2p. Incoming text goes to the live log.
//  Swipe-up send uses broadcast(_:from:). Does not touch ads or IAP.
//

import Foundation
import MultipeerConnectivity
#if os(iOS)
import UIKit
#endif

struct P2PLogEntry: Identifiable, Equatable {
    let id: UUID
    let senderName: String
    let text: String
    let receivedAt: Date
}

final class P2PInboxService: NSObject, ObservableObject {
    /// Radio toggle. False until the user turns it on.
    @Published private(set) var isListening = false
    /// Newest messages are last. Capped at `P2PConfig.maxLogCount`.
    @Published private(set) var messages: [P2PLogEntry] = []

    private let instanceID = UUID().uuidString
    private let peerID: MCPeerID
    private var session: MCSession?
    private var browser: MCNearbyServiceBrowser?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var invitedPeerIDs = Set<MCPeerID>()

    override init() {
        let rawName: String
        #if os(iOS)
        rawName = UIDevice.current.name
        #else
        rawName = "ClosedCaptioner"
        #endif
        let display = rawName.isEmpty ? "ClosedCaptioner" : String(rawName.prefix(P2PConfig.maxDisplayNameLength))
        self.peerID = MCPeerID(displayName: display)
        super.init()
    }

    deinit {
        stopListening()
    }

    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    func startListening() {
        stopListening()
        let session = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        session.delegate = self
        self.session = session

        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: P2PConfig.serviceType)
        browser.delegate = self
        self.browser = browser

        let advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: [
                P2PConfig.discoveryRoleKey: P2PConfig.discoveryRoleEmitter,
                P2PConfig.discoveryPeerIDKey: instanceID
            ],
            serviceType: P2PConfig.serviceType
        )
        advertiser.delegate = self
        self.advertiser = advertiser

        isListening = true
        browser.startBrowsingForPeers()
        advertiser.startAdvertisingPeer()
        print("[P2P] Radio on — browsing + advertising \(P2PConfig.serviceType)")
    }

    func stopListening() {
        browser?.stopBrowsingForPeers()
        browser?.delegate = nil
        browser = nil
        advertiser?.stopAdvertisingPeer()
        advertiser?.delegate = nil
        advertiser = nil
        session?.disconnect()
        session?.delegate = nil
        session = nil
        invitedPeerIDs.removeAll()
        if isListening {
            print("[P2P] Radio off")
        }
        isListening = false
    }

    /// Sends `text` to connected peers. On success, appends a local log row under `from`.
    /// With no peers yet, the local log row still counts as a successful send (broadcast into an empty room).
    @discardableResult
    func broadcast(_ text: String, from displayName: String) -> Bool {
        guard isListening, let session else { return false }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let sender = P2PConfig.normalizedName(displayName) ?? peerID.displayName
        guard let data = P2PConfig.encode(trimmed, from: sender) else { return false }

        let peers = session.connectedPeers
        if !peers.isEmpty {
            do {
                try session.send(data, toPeers: peers, with: .reliable)
            } catch {
                print("[P2P] Send failed: \(error.localizedDescription)")
                return false
            }
        }

        appendMessage(senderName: sender, text: trimmed)
        print("[P2P] Broadcast \(trimmed.count) chars as \(sender) to \(peers.count) peer(s)")
        return true
    }

    private func appendMessage(senderName: String, text: String) {
        let name = P2PConfig.normalizedName(senderName) ?? "Unknown"
        let entry = P2PLogEntry(
            id: UUID(),
            senderName: name,
            text: text,
            receivedAt: Date()
        )
        messages.append(entry)
        let overflow = messages.count - P2PConfig.maxLogCount
        if overflow > 0 {
            messages.removeFirst(overflow)
        }
    }

    private func shouldInvite(_ other: MCPeerID, info: [String: String]?) -> Bool {
        if let remoteID = info?[P2PConfig.discoveryPeerIDKey], remoteID == instanceID {
            return false
        }
        if other == peerID {
            return false
        }
        if session?.connectedPeers.contains(other) == true || invitedPeerIDs.contains(other) {
            return false
        }
        if let info, info[P2PConfig.discoveryRoleKey] != P2PConfig.discoveryRoleEmitter {
            return false
        }
        let remoteID = info?[P2PConfig.discoveryPeerIDKey] ?? other.displayName
        return instanceID < remoteID
    }
}

extension P2PInboxService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async {
            guard self.isListening, self.browser === browser, self.session != nil else { return }
            guard self.shouldInvite(peerID, info: info) else { return }
            guard let session = self.session else { return }
            self.invitedPeerIDs.insert(peerID)
            print("[P2P] Inviting \(peerID.displayName)")
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 12)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.invitedPeerIDs.remove(peerID)
            print("[P2P] Lost peer \(peerID.displayName)")
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("[P2P] Browser failed: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.stopListening()
        }
    }
}

extension P2PInboxService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        DispatchQueue.main.async {
            guard self.isListening else {
                invitationHandler(false, nil)
                return
            }
            print("[P2P] Accepting \(peerID.displayName)")
            invitationHandler(true, self.session)
        }
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("[P2P] Advertise failed: \(error.localizedDescription)")
    }
}

extension P2PInboxService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            let label: String
            switch state {
            case .notConnected:
                self.invitedPeerIDs.remove(peerID)
                label = "notConnected"
            case .connecting:
                label = "connecting"
            case .connected:
                label = "connected"
            @unknown default:
                label = "unknown"
            }
            print("[P2P] Session \(peerID.displayName) → \(label)")
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let envelope = P2PConfig.decode(data) else {
            print("[P2P] Ignored undecodable payload from \(peerID.displayName)")
            return
        }
        let sender = envelope.from ?? peerID.displayName
        DispatchQueue.main.async {
            guard self.isListening else { return }
            self.appendMessage(senderName: sender, text: envelope.text)
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {}

    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {}
}
