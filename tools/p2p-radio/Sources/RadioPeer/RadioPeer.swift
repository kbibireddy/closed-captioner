import Foundation
import MultipeerConnectivity

/// Advertises and browses on `cc-p2p` so the Mac can send and receive.
/// Sends only what you type — nothing on launch.
final class RadioPeer: NSObject {
    private let peerID: MCPeerID
    private let instanceID = UUID().uuidString
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    private var pendingText: String?
    private var invitedPeerIDs = Set<MCPeerID>()
    private var inviteAttempts: [MCPeerID: Int] = [:]
    private let lock = NSLock()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    override init() {
        let host = Host.current().localizedName ?? "CC-Mac"
        self.peerID = MCPeerID(displayName: String(host.prefix(63)))
        self.session = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: P2PConfig.encryptionPreference
        )
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: [
                P2PConfig.discoveryRoleKey: P2PConfig.discoveryRoleEmitter,
                P2PConfig.discoveryPeerIDKey: instanceID
            ],
            serviceType: P2PConfig.serviceType
        )
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: P2PConfig.serviceType)
        super.init()
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }

    func start() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
        print("[p2p-radio] Advertising + browsing as \(peerID.displayName) on \(P2PConfig.serviceType)")
    }

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        lock.lock()
        pendingText = trimmed
        lock.unlock()
        transmitPending()
    }

    private func currentPending() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return pendingText
    }

    private func transmitPending() {
        guard let text = currentPending(), !text.isEmpty else { return }
        let peers = session.connectedPeers
        guard !peers.isEmpty else {
            print("[p2p-radio] Queued until a peer connects.")
            return
        }
        guard let data = P2PConfig.encode(text, from: peerID.displayName) else {
            fputs("[p2p-radio] Failed to encode message\n", stderr)
            return
        }
        do {
            try session.send(data, toPeers: peers, with: .reliable)
            print("[p2p-radio] Sent to \(peers.map(\.displayName).joined(separator: ", "))")
        } catch {
            fputs("[p2p-radio] Send failed: \(error.localizedDescription)\n", stderr)
        }
    }

    private func printIncoming(from sender: String, text: String) {
        let time = Self.timeFormatter.string(from: Date())
        print("[\(sender)] \(text)  \(time)")
    }

    private func shouldInvite(_ other: MCPeerID, info: [String: String]?) -> Bool {
        if let remoteID = info?[P2PConfig.discoveryPeerIDKey], remoteID == instanceID {
            return false
        }
        if other == peerID || other.displayName == peerID.displayName && info?[P2PConfig.discoveryPeerIDKey] == nil {
            return false
        }
        if session.connectedPeers.contains(other) || invitedPeerIDs.contains(other) {
            return false
        }
        if let info, info[P2PConfig.discoveryRoleKey] != P2PConfig.discoveryRoleEmitter {
            return false
        }
        let remoteID = info?[P2PConfig.discoveryPeerIDKey] ?? other.displayName
        return instanceID < remoteID
    }

    private func invite(_ other: MCPeerID) {
        invitedPeerIDs.insert(other)
        print("[p2p-radio] Inviting \(other.displayName)")
        browser.invitePeer(other, to: session, withContext: nil, timeout: P2PConfig.inviteTimeoutSeconds)
    }

    private func retryInviteIfNeeded(_ other: MCPeerID) {
        let attempts = inviteAttempts[other, default: 0]
        guard attempts < P2PConfig.inviteRetryLimit else {
            print("[p2p-radio] Gave up inviting \(other.displayName)")
            return
        }
        inviteAttempts[other] = attempts + 1
        print("[p2p-radio] Retry \(attempts + 1)/\(P2PConfig.inviteRetryLimit) \(other.displayName)")
        DispatchQueue.main.asyncAfter(deadline: .now() + P2PConfig.inviteRetryDelaySeconds) { [weak self] in
            guard let self else { return }
            guard !self.session.connectedPeers.contains(other) else { return }
            self.invite(other)
        }
    }
}

extension RadioPeer: MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        print("[p2p-radio] Accepting \(peerID.displayName)")
        invitationHandler(true, session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        fputs("[p2p-radio] Advertise failed: \(error.localizedDescription)\n", stderr)
    }
}

extension RadioPeer: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        guard shouldInvite(peerID, info: info) else { return }
        invite(peerID)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        invitedPeerIDs.remove(peerID)
        print("[p2p-radio] Lost \(peerID.displayName)")
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        fputs("[p2p-radio] Browse failed: \(error.localizedDescription)\n", stderr)
    }
}

extension RadioPeer: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("[p2p-radio] Connected \(peerID.displayName)")
                self.invitedPeerIDs.remove(peerID)
                self.inviteAttempts[peerID] = 0
                self.transmitPending()
            case .connecting:
                print("[p2p-radio] Connecting \(peerID.displayName)")
            case .notConnected:
                let wasInviting = self.invitedPeerIDs.contains(peerID)
                self.invitedPeerIDs.remove(peerID)
                print("[p2p-radio] Disconnected \(peerID.displayName)")
                if wasInviting {
                    self.retryInviteIfNeeded(peerID)
                }
            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let envelope = P2PConfig.decode(data) else {
            print("[p2p-radio] Ignored undecodable payload from \(peerID.displayName)")
            return
        }
        let sender = envelope.from ?? peerID.displayName
        printIncoming(from: sender, text: envelope.text)
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

    func session(
        _ session: MCSession,
        didReceiveCertificate certificate: [Any]?,
        fromPeer peerID: MCPeerID,
        certificateHandler: @escaping (Bool) -> Void
    ) {
        certificateHandler(true)
    }
}
