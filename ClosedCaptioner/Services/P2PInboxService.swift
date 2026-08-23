//
//  P2PInboxService.swift
//  ClosedCaptioner
//
//  Radio on: browse + advertise on cc-p2p. Incoming text goes to the live log.
//  Relay (settings, default off) forwards envelopes that have an `id` (TTL 4).
//

import Foundation
import MultipeerConnectivity
#if os(iOS)
import UIKit
import UserNotifications
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
    /// Settings: Relays messages. Default off. No effect unless radio is on.
    var relayEnabled = false
    /// Newest messages are last. Capped at `P2PConfig.maxLogCount`.
    @Published private(set) var messages: [P2PLogEntry] = []
    /// Seconds after radio-on to stop automatically. `nil` = until the user turns it off.
    var autoStopAfter: TimeInterval? = RadioKeepAlive.thirtyMinutes.duration
    /// Live radio KPIs. Persist across radio on/off until the user resets them.
    @Published private(set) var connectedPeerCount = 0
    @Published private(set) var peakPeerCount = 0
    @Published private(set) var messagesSent = 0
    @Published private(set) var messagesReceived = 0
    @Published private(set) var messagesForwarded = 0
    @Published private(set) var duplicatesDropped = 0
    @Published private(set) var ttlDropped = 0
    @Published private(set) var connectCount = 0
    @Published private(set) var disconnectCount = 0
    @Published private(set) var inviteTimeouts = 0
    @Published private(set) var lastHop = 0
    @Published private(set) var bytesSent = 0
    @Published private(set) var bytesReceived = 0

    private let instanceID = UUID().uuidString
    private let peerID: MCPeerID
    private var session: MCSession?
    private var browser: MCNearbyServiceBrowser?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var invitedPeerIDs = Set<MCPeerID>()
    private var inviteAttempts: [MCPeerID: Int] = [:]
    private var seenMessageIDs: [String] = []
    private var knownConnected = Set<MCPeerID>()
    private var listeningStartedAt: Date?
    private var autoStopTimer: Timer?
    #if os(iOS)
    private var backgroundTask = UIBackgroundTaskIdentifier.invalid
    #endif

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
        startSession(resetStats: false)
        listeningStartedAt = Date()
        scheduleAutoStop()
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = true
        NearbyMeshNotice.requestPermissionIfNeeded()
        #endif
    }

    /// Rebuild after returning from background. No-op if the session is already up
    /// (e.g. Control Center → `.inactive` → `.active` without a suspend).
    func rebuildSessionIfListening() {
        stopBackgroundTask()
        checkAutoStopIfNeeded()
        guard isListening else { return }
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = true
        #endif
        guard session == nil else { return }
        startSession(resetStats: false)
        scheduleAutoStop()
    }

    /// Keep browse / advertise / session running while the app is backgrounded.
    /// iOS may still freeze the process after a while; we do not tear the radio down ourselves.
    func prepareForBackground() {
        guard isListening else { return }
        checkAutoStopIfNeeded()
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = false
        startBackgroundTask()
        #endif
    }

    func applyAutoStopAfter(_ interval: TimeInterval?) {
        autoStopAfter = interval
        guard isListening else { return }
        scheduleAutoStop()
    }

    func stopListening() {
        autoStopTimer?.invalidate()
        autoStopTimer = nil
        listeningStartedAt = nil
        stopBackgroundTask()
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = false
        NearbyMeshNotice.clear()
        #endif
        recordDisconnectsForRemainingPeers()
        tearDownSession()
        if isListening {
            AppLog.debug("[P2P] Radio off")
        }
        isListening = false
        refreshPeerCount()
    }

    private func scheduleAutoStop() {
        autoStopTimer?.invalidate()
        autoStopTimer = nil
        guard isListening, let listeningStartedAt, let autoStopAfter else { return }
        let remaining = autoStopAfter - Date().timeIntervalSince(listeningStartedAt)
        if remaining <= 0 {
            stopListening()
            return
        }
        autoStopTimer = Timer.scheduledTimer(withTimeInterval: remaining, repeats: false) { [weak self] _ in
            self?.stopListening()
        }
        if let autoStopTimer {
            RunLoop.main.add(autoStopTimer, forMode: .common)
        }
    }

    private func checkAutoStopIfNeeded() {
        guard isListening, let listeningStartedAt, let autoStopAfter else { return }
        if Date().timeIntervalSince(listeningStartedAt) >= autoStopAfter {
            stopListening()
        }
    }

    #if os(iOS)
    private func startBackgroundTask() {
        stopBackgroundTask()
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "nearby-radio") { [weak self] in
            self?.stopBackgroundTask()
        }
    }

    private func stopBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
    #else
    private func stopBackgroundTask() {}
    #endif

    /// Zeros traffic counters. Live peer count is refreshed if radio is still on.
    func resetKPIs() {
        resetStats()
        refreshPeerCount()
    }

    /// Sends `text` to connected peers. On success, appends a local log row under `from`.
    /// Returns false when radio is off, the text is empty, nobody is connected, or the send fails.
    @discardableResult
    func broadcast(_ text: String, from displayName: String) -> Bool {
        guard isListening, let session else { return false }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let peers = session.connectedPeers
        guard !peers.isEmpty else {
            AppLog.debug("[P2P] Broadcast skipped — no connected peers")
            return false
        }

        let sender = P2PConfig.normalizedName(displayName) ?? peerID.displayName
        let messageID = UUID().uuidString
        guard let data = P2PConfig.encode(trimmed, from: sender, id: messageID, hop: 0) else { return false }

        do {
            try session.send(data, toPeers: peers, with: .reliable)
        } catch {
            AppLog.debug("[P2P] Send failed: \(error.localizedDescription)")
            return false
        }

        rememberSeen(messageID)
        messagesSent += 1
        bytesSent += data.count
        appendMessage(senderName: sender, text: trimmed)
        lastHop = 0
        AppLog.debug("[P2P] Broadcast \(trimmed.count) chars as \(sender) to \(peers.count) peer(s)")
        return true
    }

    private func startSession(resetStats shouldReset: Bool) {
        tearDownSession()
        let session = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: P2PConfig.encryptionPreference
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

        if shouldReset {
            resetStats()
            seenMessageIDs.removeAll()
        }
        knownConnected.removeAll()
        invitedPeerIDs.removeAll()
        inviteAttempts.removeAll()
        isListening = true
        refreshPeerCount()
        browser.startBrowsingForPeers()
        advertiser.startAdvertisingPeer()
        AppLog.debug("[P2P] Radio on — browsing + advertising \(P2PConfig.serviceType)")
    }

    private func tearDownSession() {
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
        inviteAttempts.removeAll()
        knownConnected.removeAll()
        connectedPeerCount = 0
    }

    private func resetStats() {
        connectedPeerCount = 0
        peakPeerCount = 0
        messagesSent = 0
        messagesReceived = 0
        messagesForwarded = 0
        duplicatesDropped = 0
        ttlDropped = 0
        connectCount = 0
        disconnectCount = 0
        inviteTimeouts = 0
        lastHop = 0
        bytesSent = 0
        bytesReceived = 0
    }

    private func refreshPeerCount() {
        let count = session?.connectedPeers.count ?? 0
        connectedPeerCount = count
        if count > peakPeerCount {
            peakPeerCount = count
        }
    }

    private func recordDisconnectsForRemainingPeers() {
        let leftover = knownConnected.count
        if leftover > 0 {
            disconnectCount += leftover
        }
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

    private func rememberSeen(_ id: String) {
        if seenMessageIDs.contains(id) { return }
        seenMessageIDs.append(id)
        if seenMessageIDs.count > P2PConfig.maxSeenIDs {
            seenMessageIDs.removeFirst(seenMessageIDs.count - P2PConfig.maxSeenIDs)
        }
    }

    private func neighborSlotsFull() -> Bool {
        let connected = session?.connectedPeers.count ?? 0
        return connected + invitedPeerIDs.count >= P2PConfig.maxNeighbors
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
        if neighborSlotsFull() {
            return false
        }
        if let info, info[P2PConfig.discoveryRoleKey] != P2PConfig.discoveryRoleEmitter {
            return false
        }
        let remoteID = info?[P2PConfig.discoveryPeerIDKey] ?? other.displayName
        return instanceID < remoteID
    }

    private func runOnMainSync(_ work: () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.sync(execute: work)
        }
    }

    private func invite(_ other: MCPeerID, using browser: MCNearbyServiceBrowser) {
        guard isListening, let session else { return }
        invitedPeerIDs.insert(other)
        scheduleInviteTimeout(other)
        AppLog.debug("[P2P] Inviting \(other.displayName)")
        browser.invitePeer(other, to: session, withContext: nil, timeout: P2PConfig.inviteTimeoutSeconds)
    }

    private func retryInviteIfNeeded(_ other: MCPeerID) {
        guard isListening else { return }
        let attempts = inviteAttempts[other, default: 0]
        guard attempts < P2PConfig.inviteRetryLimit else {
            AppLog.debug("[P2P] Gave up inviting \(other.displayName)")
            return
        }
        inviteAttempts[other] = attempts + 1
        let delay = P2PConfig.inviteRetryDelaySeconds
        AppLog.debug("[P2P] Retry \(attempts + 1)/\(P2PConfig.inviteRetryLimit) \(other.displayName)")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.isListening, let browser = self.browser else { return }
            guard self.session?.connectedPeers.contains(other) != true else { return }
            self.invite(other, using: browser)
        }
    }

    private func scheduleInviteTimeout(_ peer: MCPeerID) {
        DispatchQueue.main.asyncAfter(deadline: .now() + P2PConfig.inviteTimeoutSeconds) { [weak self] in
            guard let self, self.isListening else { return }
            guard self.invitedPeerIDs.contains(peer) else { return }
            if self.session?.connectedPeers.contains(peer) == true { return }
            self.invitedPeerIDs.remove(peer)
            self.inviteTimeouts += 1
            AppLog.debug("[P2P] Invite timed out \(peer.displayName)")
        }
    }

    private func handleIncoming(_ envelope: P2PConfig.Envelope, data: Data, from neighbor: MCPeerID) {
        bytesReceived += data.count
        lastHop = envelope.hop ?? 0

        if let messageID = envelope.id, !messageID.isEmpty {
            if seenMessageIDs.contains(messageID) {
                duplicatesDropped += 1
                return
            }
            rememberSeen(messageID)
        }

        messagesReceived += 1
        let sender = envelope.from ?? neighbor.displayName
        appendMessage(senderName: sender, text: envelope.text)

        guard relayEnabled else { return }
        guard let messageID = envelope.id, !messageID.isEmpty else { return }

        let hop = envelope.hop ?? 0
        let ttl = envelope.ttl ?? P2PConfig.defaultTTL
        if hop + 1 >= ttl {
            ttlDropped += 1
            return
        }

        forward(envelope, id: messageID, hop: hop + 1, ttl: ttl, excluding: neighbor)
    }

    private func forward(
        _ envelope: P2PConfig.Envelope,
        id: String,
        hop: Int,
        ttl: Int,
        excluding originNeighbor: MCPeerID
    ) {
        guard let session else { return }
        let targets = session.connectedPeers.filter { $0 != originNeighbor }
        guard !targets.isEmpty else { return }
        guard let data = P2PConfig.encode(
            envelope.text,
            from: envelope.from,
            id: id,
            hop: hop,
            ttl: ttl
        ) else { return }
        do {
            try session.send(data, toPeers: targets, with: .reliable)
            messagesForwarded += 1
            bytesSent += data.count
        } catch {
            AppLog.debug("[P2P] Forward failed: \(error.localizedDescription)")
        }
    }
}

extension P2PInboxService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        runOnMainSync {
            guard self.isListening, self.browser === browser else { return }
            guard self.shouldInvite(peerID, info: info) else { return }
            self.invite(peerID, using: browser)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        runOnMainSync {
            self.invitedPeerIDs.remove(peerID)
            AppLog.debug("[P2P] Lost peer \(peerID.displayName)")
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        AppLog.debug("[P2P] Browser failed: \(error.localizedDescription)")
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
        var accept = false
        var session: MCSession?
        runOnMainSync {
            guard self.isListening, let live = self.session else { return }
            if self.neighborSlotsFull() && live.connectedPeers.contains(peerID) != true {
                return
            }
            accept = true
            session = live
            AppLog.debug("[P2P] Accepting \(peerID.displayName)")
        }
        invitationHandler(accept, session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        AppLog.debug("[P2P] Advertise failed: \(error.localizedDescription)")
    }
}

extension P2PInboxService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .notConnected:
                let wasInviting = self.invitedPeerIDs.contains(peerID)
                self.invitedPeerIDs.remove(peerID)
                if self.knownConnected.contains(peerID) {
                    self.knownConnected.remove(peerID)
                    self.disconnectCount += 1
                }
                if wasInviting {
                    self.retryInviteIfNeeded(peerID)
                }
            case .connecting:
                break
            case .connected:
                self.invitedPeerIDs.remove(peerID)
                self.inviteAttempts[peerID] = 0
                if self.knownConnected.insert(peerID).inserted {
                    self.connectCount += 1
                }
            @unknown default:
                break
            }
            AppLog.debug("[P2P] Session \(peerID.displayName) → \(String(describing: state))")
            self.refreshPeerCount()
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let envelope = P2PConfig.decode(data) else {
            AppLog.debug("[P2P] Ignored undecodable payload from \(peerID.displayName)")
            return
        }
        DispatchQueue.main.async {
            guard self.isListening else { return }
            self.handleIncoming(envelope, data: data, from: peerID)
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

    func session(
        _ session: MCSession,
        didReceiveCertificate certificate: [Any]?,
        fromPeer peerID: MCPeerID,
        certificateHandler: @escaping (Bool) -> Void
    ) {
        certificateHandler(true)
    }
}

#if os(iOS)
/// System notification (lock screen / Notification Center), not an in-app banner.
enum NearbyMeshNotice {
    private static let identifier = "closedcaptioner.nearby-mesh-still-on"

    static func requestPermissionIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                AppLog.debug("[Nearby] Notification auth error: \(error.localizedDescription)")
            } else {
                AppLog.debug("[Nearby] Notification permission granted=\(granted)")
            }
        }
    }

    /// Must run on the main thread and add the request immediately. Waiting on
    /// `getNotificationSettings` lets iOS suspend the app before anything is scheduled.
    static func postStillOnMesh(keepAlive: RadioKeepAlive) {
        let work = {
            addRequest(keepAlive: keepAlive)
        }
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    static func cancelPending() {
        let work = {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        }
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    static func clear() {
        let work = {
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            center.removeDeliveredNotifications(withIdentifiers: [identifier])
        }
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    private static func addRequest(keepAlive: RadioKeepAlive) {
        let content = UNMutableNotificationContent()
        content.title = "Nearby is still on"
        content.body = "This phone is still on the mesh. It can receive and send nearby messages. Turn Nearby off or close the app to leave. \(keepAlive.autoOffPhrase)"
        content.sound = .default
        content.interruptionLevel = .active

        // Immediate (`trigger: nil`) is dropped if iOS still considers us on screen.
        // Register a 1s timer with the system now — do not wait on permission APIs.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.add(request) { error in
            if let error {
                AppLog.debug("[Nearby] Failed to schedule notification: \(error.localizedDescription)")
            } else {
                AppLog.debug("[Nearby] Scheduled mesh-still-on notification")
            }
        }
    }
}
#endif
