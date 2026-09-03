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
    /// Multipeer neighbor this payload arrived from. `nil` for locally sent captions.
    let neighborName: String?
    let text: String
    let channel: GossipChannel
    let receivedAt: Date
}

/// Radio on/off and peer count. Changes are rare compared with traffic ticks.
final class P2PRadioChrome: ObservableObject {
    @Published var isListening = false
    @Published var connectedPeerCount = 0
}

/// HUD byte rates. Refreshed on a 1s timer while radio is on.
final class P2PTrafficRates: ObservableObject {
    @Published var bytesSentPerSecond = 0
    @Published var bytesReceivedPerSecond = 0

    func setRates(sent: Int, received: Int) {
        if bytesSentPerSecond != sent {
            bytesSentPerSecond = sent
        }
        if bytesReceivedPerSecond != received {
            bytesReceivedPerSecond = received
        }
    }

    func reset() {
        setRates(sent: 0, received: 0)
    }
}

/// Live nearby log. Observed by the strip and Settings → Activity → Huddle.
final class P2PMessageLog: ObservableObject {
    @Published var messages: [P2PLogEntry] = []

    func clear() {
        messages.removeAll()
    }

    func append(_ entry: P2PLogEntry, cap: Int) {
        messages.append(entry)
        let overflow = messages.count - cap
        if overflow > 0 {
            messages.removeFirst(overflow)
        }
    }
}

/// Lifetime counters and sparkline series. Observed by Settings → KPIs only.
final class P2PRadioMetrics: ObservableObject {
    @Published var peakPeerCount = 0
    @Published var messagesSent = 0
    @Published var messagesReceived = 0
    @Published var messagesForwarded = 0
    @Published var duplicatesDropped = 0
    @Published var ttlDropped = 0
    @Published var connectCount = 0
    @Published var disconnectCount = 0
    @Published var inviteTimeouts = 0
    @Published var lastHop = 0
    @Published var bytesSent = 0
    @Published var bytesReceived = 0
    @Published var peerHistory: [KPIMetricSample] = []
    @Published var connectHistory: [KPIMetricSample] = []
    @Published var disconnectHistory: [KPIMetricSample] = []
    @Published var inviteTimeoutHistory: [KPIMetricSample] = []
    @Published var messagesSentHistory: [KPIMetricSample] = []
    @Published var messagesReceivedHistory: [KPIMetricSample] = []
    @Published var bytesSentHistory: [KPIMetricSample] = []
    @Published var bytesReceivedHistory: [KPIMetricSample] = []

    func reset() {
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
        peerHistory.removeAll()
        connectHistory.removeAll()
        disconnectHistory.removeAll()
        inviteTimeoutHistory.removeAll()
        messagesSentHistory.removeAll()
        messagesReceivedHistory.removeAll()
        bytesSentHistory.removeAll()
        bytesReceivedHistory.removeAll()
    }

    func appendSample(
        _ value: Double,
        to keyPath: ReferenceWritableKeyPath<P2PRadioMetrics, [KPIMetricSample]>,
        at date: Date,
        window: TimeInterval
    ) {
        var next = self[keyPath: keyPath]
        next.append(KPIMetricSample(date: date, value: value))
        let cutoff = date.addingTimeInterval(-window)
        next.removeAll { $0.date < cutoff }
        self[keyPath: keyPath] = next
    }
}

final class P2PInboxService: NSObject, ObservableObject {
    let chrome = P2PRadioChrome()
    let traffic = P2PTrafficRates()
    let log = P2PMessageLog()
    let metrics = P2PRadioMetrics()

    /// Radio toggle. False until the user turns it on.
    var isListening: Bool { chrome.isListening }
    /// Settings: Relays messages. Default off. No effect unless radio is on.
    var relayEnabled = false
    /// Newest messages are last. Capped at `P2PConfig.maxLogCount`.
    var messages: [P2PLogEntry] { log.messages }
    /// Seconds after radio-on to stop automatically. `nil` = until the user turns it off.
    var autoStopAfter: TimeInterval? = RadioKeepAlive.thirtyMinutes.duration

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
    private var trafficSamples: [(at: Date, sent: Int, received: Int)] = []
    private var trafficRateTimer: Timer?
    private var kpiHistoryTimer: Timer?
    private var lastFastKPIHistoryAt: Date?
    private var lastSlowKPIHistoryAt: Date?
    /// Tracks peers that were connected and dropped — candidates for re-invite.
    private var recentlyDroppedPeers: [MCPeerID: Date] = [:]
    /// How many times browse/advertise has been retried after a transient failure.
    private var browseRetryCount = 0
    /// Health-check timer: detects stale sessions and restarts browse/advertise.
    private var healthCheckTimer: Timer?
    /// Timestamp when peers last dropped to zero (for stale-session detection).
    private var zeroPeersSince: Date?
    #if os(iOS)
    private var backgroundTask = UIBackgroundTaskIdentifier.invalid
    #endif

    override init() {
        // Multipeer peer labels are visible on the LAN — never use UIDevice.current.name.
        let key = "ClosedCaptioner.displayName"
        let defaults = UserDefaults.standard
        let rawName: String
        if let saved = defaults.string(forKey: key),
           let normalized = P2PConfig.normalizedName(saved),
           !AppStateViewModel.isDeviceHostName(normalized) {
            rawName = normalized
        } else {
            let generated = AppStateViewModel.generatedDisplayName()
            defaults.set(generated, forKey: key)
            rawName = generated
        }
        let display = String(rawName.prefix(P2PConfig.maxDisplayNameLength))
        self.peerID = MCPeerID(displayName: display.isEmpty ? "neon_fern" : display)
        super.init()
    }

    deinit {
        kpiHistoryTimer?.invalidate()
        stopListening()
    }

    func clearLog() {
        log.clear()
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
        startKPIHistory()
        startHealthCheck()
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = true
        NearbyMeshNotice.requestPermissionIfNeeded()
        #endif
    }

    /// Rebuild after returning from background. Checks session *health*, not just
    /// whether the object exists — MC can freeze internals during a long suspend
    /// while leaving the MCSession object non-nil.
    func rebuildSessionIfListening() {
        stopBackgroundTask()
        checkAutoStopIfNeeded()
        guard isListening else { return }
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = true
        #endif

        let needsRebuild: Bool
        if session == nil {
            // Session was torn down (B1-classic path).
            needsRebuild = true
            AppLog.debug("[P2P] Foreground rebuild: session was nil")
        } else if browser == nil || advertiser == nil {
            // Browse/advertise died (e.g. transient error killed them).
            needsRebuild = true
            AppLog.debug("[P2P] Foreground rebuild: browser or advertiser missing")
        } else {
            needsRebuild = false
        }

        if needsRebuild {
            startSession(resetStats: false)
            scheduleAutoStop()
        } else {
            // Session object exists but MC may be stale after a long suspend.
            // Restart browse/advertise to re-discover peers quickly.
            restartBrowseAdvertise()
        }
        browseRetryCount = 0
        startHealthCheck()
    }

    /// Keep browse / advertise / session running while the app is backgrounded.
    /// iOS may still freeze the process after a while; we do not tear the radio down ourselves.
    func prepareForBackground() {
        guard isListening else { return }
        checkAutoStopIfNeeded()
        stopHealthCheck()
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
        stopHealthCheck()
        recentlyDroppedPeers.removeAll()
        browseRetryCount = 0
        zeroPeersSince = nil
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = false
        NearbyMeshNotice.clear()
        #endif
        recordDisconnectsForRemainingPeers()
        tearDownSession()
        if isListening {
            AppLog.debug("[P2P] Radio off")
        }
        chrome.isListening = false
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
            // B6: iOS is about to suspend us. Log it so KPIs/debug show what happened.
            AppLog.debug("[P2P] Background task expiring — iOS will suspend shortly")
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
    /// With no peers yet, still succeeds (broadcast into an empty room) so the sender sees Sent!
    @discardableResult
    func broadcast(_ text: String, from displayName: String, channel: GossipChannel = .room) -> Bool {
        guard isListening, let session else { return false }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let sender = P2PConfig.normalizedName(displayName) ?? peerID.displayName
        let messageID = UUID().uuidString
        guard let data = P2PConfig.encode(
            trimmed,
            from: sender,
            id: messageID,
            hop: 0,
            channel: channel.rawValue
        ) else { return false }

        let peers = session.connectedPeers
        if !peers.isEmpty {
            do {
                try session.send(data, toPeers: peers, with: .reliable)
            } catch {
                AppLog.debug("[P2P] Send failed: \(error.localizedDescription)")
                return false
            }
        } else {
            AppLog.debug("[P2P] Broadcast into empty room as \(sender)")
        }

        rememberSeen(messageID)
        metrics.messagesSent += 1
        recordTraffic(sent: data.count, received: 0)
        appendMessage(senderName: sender, text: trimmed, neighborName: nil, channel: channel)
        metrics.lastHop = 0
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
        chrome.isListening = true
        refreshPeerCount()
        startTrafficRateTimer()
        browser.startBrowsingForPeers()
        advertiser.startAdvertisingPeer()
        AppLog.debug("[P2P] Radio on - browsing + advertising \(P2PConfig.serviceType)")
    }

    private func tearDownSession() {
        stopTrafficRateTimer()
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
        chrome.connectedPeerCount = 0
        trafficSamples.removeAll()
        traffic.reset()
    }

    private func resetStats() {
        chrome.connectedPeerCount = 0
        metrics.reset()
        trafficSamples.removeAll()
        traffic.reset()
        lastFastKPIHistoryAt = nil
        lastSlowKPIHistoryAt = nil
    }

    // MARK: - Reconnection resilience

    /// Restart browse + advertise on the existing session without tearing down
    /// connections. Useful when returning from background or after a network blip.
    private func restartBrowseAdvertise() {
        guard isListening, let session else { return }
        browser?.stopBrowsingForPeers()
        browser?.delegate = nil
        advertiser?.stopAdvertisingPeer()
        advertiser?.delegate = nil

        let newBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: P2PConfig.serviceType)
        newBrowser.delegate = self
        self.browser = newBrowser

        let newAdvertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: [
                P2PConfig.discoveryRoleKey: P2PConfig.discoveryRoleEmitter,
                P2PConfig.discoveryPeerIDKey: instanceID
            ],
            serviceType: P2PConfig.serviceType
        )
        newAdvertiser.delegate = self
        self.advertiser = newAdvertiser

        // Reset invite bookkeeping so stale entries don't block new invites.
        invitedPeerIDs.removeAll()
        inviteAttempts.removeAll()

        newBrowser.startBrowsingForPeers()
        newAdvertiser.startAdvertisingPeer()
        AppLog.debug("[P2P] Restarted browse + advertise (session kept)")
    }

    /// Attempt to reconnect to a peer that was connected and then dropped.
    private func scheduleReconnect(_ droppedPeer: MCPeerID) {
        guard isListening else { return }
        recentlyDroppedPeers[droppedPeer] = Date()
        let delay = P2PConfig.reconnectDelaySeconds
        AppLog.debug("[P2P] Will attempt reconnect to \(droppedPeer.displayName) in \(Int(delay))s")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.isListening, let browser = self.browser else { return }
            // Only re-invite if they haven't already reconnected.
            guard self.session?.connectedPeers.contains(droppedPeer) != true else {
                self.recentlyDroppedPeers.removeValue(forKey: droppedPeer)
                return
            }
            guard !self.neighborSlotsFull() else { return }
            // Reset retry count so we get fresh attempts.
            self.inviteAttempts[droppedPeer] = 0
            self.invite(droppedPeer, using: browser)
            AppLog.debug("[P2P] Re-inviting dropped peer \(droppedPeer.displayName)")
        }
    }

    // MARK: - Health check (B4)

    private func startHealthCheck() {
        stopHealthCheck()
        let timer = Timer(timeInterval: P2PConfig.healthCheckIntervalSeconds, repeats: true) { [weak self] _ in
            self?.performHealthCheck()
        }
        RunLoop.main.add(timer, forMode: .common)
        healthCheckTimer = timer
    }

    private func stopHealthCheck() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }

    private func performHealthCheck() {
        guard isListening else { return }
        let peerCount = session?.connectedPeers.count ?? 0
        refreshPeerCount()

        if peerCount == 0 {
            if zeroPeersSince == nil {
                zeroPeersSince = Date()
            } else if let since = zeroPeersSince,
                      Date().timeIntervalSince(since) >= P2PConfig.staleSessionThresholdSeconds {
                // Peers have been at 0 too long — restart browse/advertise
                // to shake off any stale Bonjour state.
                AppLog.debug("[P2P] Health check: 0 peers for \(Int(P2PConfig.staleSessionThresholdSeconds))s, restarting browse/advertise")
                zeroPeersSince = nil
                restartBrowseAdvertise()
            }
        } else {
            zeroPeersSince = nil
        }

        // Prune stale dropped-peer entries (older than 30s — they're gone).
        let cutoff = Date().addingTimeInterval(-30)
        recentlyDroppedPeers = recentlyDroppedPeers.filter { $0.value > cutoff }
    }

    // MARK: - Browse/advertise failure recovery (B3)

    private func handleBrowseAdvertiseFailure() {
        guard isListening else { return }
        browseRetryCount += 1
        if browseRetryCount > P2PConfig.browseRetryLimit {
            AppLog.debug("[P2P] Exceeded browse retry limit (\(P2PConfig.browseRetryLimit)), stopping radio")
            stopListening()
            return
        }
        let delay = P2PConfig.browseRetryDelaySeconds * Double(browseRetryCount)
        AppLog.debug("[P2P] Browse/advertise retry \(browseRetryCount)/\(P2PConfig.browseRetryLimit) in \(Int(delay))s")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.isListening else { return }
            self.restartBrowseAdvertise()
        }
    }

    // MARK: - Traffic

    private func recordTraffic(sent: Int, received: Int) {
        if sent > 0 { metrics.bytesSent += sent }
        if received > 0 { metrics.bytesReceived += received }
        guard sent > 0 || received > 0 else { return }
        trafficSamples.append((Date(), sent, received))
        refreshTrafficRates()
    }

    private func startTrafficRateTimer() {
        stopTrafficRateTimer()
        trafficRateTimer = Timer.scheduledTimer(
            withTimeInterval: P2PConfig.trafficRateRefreshSeconds,
            repeats: true
        ) { [weak self] _ in
            self?.refreshTrafficRates()
        }
        if let trafficRateTimer {
            RunLoop.main.add(trafficRateTimer, forMode: .common)
        }
        refreshTrafficRates()
    }

    private func stopTrafficRateTimer() {
        trafficRateTimer?.invalidate()
        trafficRateTimer = nil
    }

    private func refreshTrafficRates() {
        let now = Date()
        let window = P2PConfig.trafficRateWindowSeconds
        let cutoff = now.addingTimeInterval(-window)
        trafficSamples.removeAll { $0.at < cutoff }
        let sent = trafficSamples.reduce(0) { $0 + $1.sent }
        let received = trafficSamples.reduce(0) { $0 + $1.received }
        // Partial window after radio-on: divide by elapsed so early traffic isn’t understated.
        let elapsed: TimeInterval
        if let started = listeningStartedAt {
            elapsed = min(window, max(1, now.timeIntervalSince(started)))
        } else {
            elapsed = window
        }
        traffic.setRates(
            sent: Int((Double(sent) / elapsed).rounded()),
            received: Int((Double(received) / elapsed).rounded())
        )
    }

    /// Starts 3s/30s sparkline sampling. Safe to call from radio-on or KPIs appear.
    func startKPIHistory() {
        guard kpiHistoryTimer == nil else { return }
        recordKPIHistory()
        let timer = Timer(timeInterval: AppPerformanceMonitor.fastHistoryInterval, repeats: true) { [weak self] _ in
            self?.recordKPIHistory()
        }
        RunLoop.main.add(timer, forMode: .common)
        kpiHistoryTimer = timer
    }

    private func recordKPIHistory() {
        let now = Date()
        let recordFast = lastFastKPIHistoryAt == nil
            || now.timeIntervalSince(lastFastKPIHistoryAt!) >= AppPerformanceMonitor.fastHistoryInterval - 0.5
        let recordSlow = lastSlowKPIHistoryAt == nil
            || now.timeIntervalSince(lastSlowKPIHistoryAt!) >= AppPerformanceMonitor.slowHistoryInterval - 0.5
        if recordFast {
            lastFastKPIHistoryAt = now
            metrics.appendSample(Double(chrome.connectedPeerCount), to: \.peerHistory, at: now, window: AppPerformanceMonitor.fastHistoryWindow)
            metrics.appendSample(Double(metrics.messagesSent), to: \.messagesSentHistory, at: now, window: AppPerformanceMonitor.fastHistoryWindow)
            metrics.appendSample(Double(metrics.messagesReceived), to: \.messagesReceivedHistory, at: now, window: AppPerformanceMonitor.fastHistoryWindow)
            metrics.appendSample(Double(metrics.bytesSent), to: \.bytesSentHistory, at: now, window: AppPerformanceMonitor.fastHistoryWindow)
            metrics.appendSample(Double(metrics.bytesReceived), to: \.bytesReceivedHistory, at: now, window: AppPerformanceMonitor.fastHistoryWindow)
        }
        if recordSlow {
            lastSlowKPIHistoryAt = now
            metrics.appendSample(Double(metrics.connectCount), to: \.connectHistory, at: now, window: AppPerformanceMonitor.slowHistoryWindow)
            metrics.appendSample(Double(metrics.disconnectCount), to: \.disconnectHistory, at: now, window: AppPerformanceMonitor.slowHistoryWindow)
            metrics.appendSample(Double(metrics.inviteTimeouts), to: \.inviteTimeoutHistory, at: now, window: AppPerformanceMonitor.slowHistoryWindow)
        }
    }

    private func refreshPeerCount() {
        let count = session?.connectedPeers.count ?? 0
        if chrome.connectedPeerCount != count {
            chrome.connectedPeerCount = count
        }
        if count > metrics.peakPeerCount {
            metrics.peakPeerCount = count
        }
    }

    private func recordDisconnectsForRemainingPeers() {
        let leftover = knownConnected.count
        if leftover > 0 {
            metrics.disconnectCount += leftover
        }
    }

    private func appendMessage(
        senderName: String,
        text: String,
        neighborName: String?,
        channel: GossipChannel
    ) {
        let name = P2PConfig.normalizedName(senderName) ?? "Unknown"
        let neighbor = P2PConfig.normalizedName(neighborName)
        let entry = P2PLogEntry(
            id: UUID(),
            senderName: name,
            neighborName: neighbor,
            text: text,
            channel: channel,
            receivedAt: Date()
        )
        log.append(entry, cap: P2PConfig.maxLogCount)
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
            self.metrics.inviteTimeouts += 1
            AppLog.debug("[P2P] Invite timed out \(peer.displayName)")
        }
    }

    private func handleIncoming(_ envelope: P2PConfig.Envelope, data: Data, from neighbor: MCPeerID) {
        recordTraffic(sent: 0, received: data.count)
        metrics.lastHop = envelope.hop ?? 0

        if let messageID = envelope.id, !messageID.isEmpty {
            if seenMessageIDs.contains(messageID) {
                metrics.duplicatesDropped += 1
                return
            }
            rememberSeen(messageID)
        }

        metrics.messagesReceived += 1
        let sender = envelope.from ?? neighbor.displayName
        appendMessage(
            senderName: sender,
            text: envelope.text,
            neighborName: neighbor.displayName,
            channel: GossipChannel.fromWire(envelope.channel)
        )

        guard relayEnabled else { return }
        guard let messageID = envelope.id, !messageID.isEmpty else { return }

        let hop = envelope.hop ?? 0
        let ttl = envelope.ttl ?? P2PConfig.defaultTTL
        if hop + 1 >= ttl {
            metrics.ttlDropped += 1
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
            ttl: ttl,
            channel: envelope.channel
        ) else { return }
        do {
            try session.send(data, toPeers: targets, with: .reliable)
            metrics.messagesForwarded += 1
            recordTraffic(sent: data.count, received: 0)
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
            self.handleBrowseAdvertiseFailure()
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
        DispatchQueue.main.async {
            self.handleBrowseAdvertiseFailure()
        }
    }
}

extension P2PInboxService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .notConnected:
                let wasInviting = self.invitedPeerIDs.contains(peerID)
                let wasConnected = self.knownConnected.contains(peerID)
                self.invitedPeerIDs.remove(peerID)
                if wasConnected {
                    self.knownConnected.remove(peerID)
                    self.metrics.disconnectCount += 1
                    // B2: A connected peer dropped — try to re-invite them.
                    self.scheduleReconnect(peerID)
                }
                if wasInviting && !wasConnected {
                    self.retryInviteIfNeeded(peerID)
                }
            case .connecting:
                break
            case .connected:
                self.invitedPeerIDs.remove(peerID)
                self.inviteAttempts[peerID] = 0
                self.recentlyDroppedPeers.removeValue(forKey: peerID)
                self.browseRetryCount = 0
                self.zeroPeersSince = nil
                if self.knownConnected.insert(peerID).inserted {
                    self.metrics.connectCount += 1
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
/// At most one “radio still on” system notice per process lifetime.
/// Posted only if radio is on and the user locked the phone, or left the app
/// for at least 60s. Control Center / quick app switches do not count.
enum NearbyMeshNotice {
    private static let identifier = "closedcaptioner.nearby-mesh-still-on"
    private static let awayDelay: TimeInterval = 60
    private static let lockDelay: TimeInterval = 1

    /// Set once a notice actually lands in Notification Center this launch.
    private static var hasDeliveredThisUptime = false
    /// A 60s or lock trigger is sitting with the system.
    private static var hasPendingLeave = false

    static func requestPermissionIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                AppLog.debug("[Nearby] Notification auth error: \(error.localizedDescription)")
            } else {
                AppLog.debug("[Nearby] Notification permission granted=\(granted)")
            }
        }
    }

    /// Call when the app is actually backgrounded (not merely inactive).
    static func noteWentToBackground(radioOn: Bool, keepAlive: RadioKeepAlive) {
        guard radioOn, !hasDeliveredThisUptime else { return }
        let locked = !UIApplication.shared.isProtectedDataAvailable
        scheduleLeaveNotice(delay: locked ? lockDelay : awayDelay, keepAlive: keepAlive, replace: locked)
    }

    /// Call when the device is locking. Shortens a pending 60s away notice.
    static func noteDeviceLocked(radioOn: Bool, keepAlive: RadioKeepAlive) {
        guard radioOn, !hasDeliveredThisUptime else { return }
        scheduleLeaveNotice(delay: lockDelay, keepAlive: keepAlive, replace: true)
    }

    /// Call when the app is active again. Drops an unfired leave notice.
    static func noteBecameActive() {
        cancelPending()
        hasPendingLeave = false
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                if notifications.contains(where: { $0.request.identifier == identifier }) {
                    hasDeliveredThisUptime = true
                }
            }
        }
    }

    static func cancelPending() {
        runOnMain {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
            hasPendingLeave = false
        }
    }

    static func clear() {
        runOnMain {
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            center.removeDeliveredNotifications(withIdentifiers: [identifier])
            hasPendingLeave = false
        }
    }

    private static func scheduleLeaveNotice(delay: TimeInterval, keepAlive: RadioKeepAlive, replace: Bool) {
        runOnMain {
            guard !hasDeliveredThisUptime else { return }
            if hasPendingLeave && !replace { return }
            addRequest(delay: delay, keepAlive: keepAlive)
            hasPendingLeave = true
        }
    }

    private static func addRequest(delay: TimeInterval, keepAlive: RadioKeepAlive) {
        let content = UNMutableNotificationContent()
        content.title = "Gossip is still on"
        content.body = "This phone is still on Gossip. It can receive and send text. Turn Gossip off or close the app to leave. \(keepAlive.autoOffPhrase)"
        content.sound = .default
        content.interruptionLevel = .active

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, delay), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.add(request) { error in
            if let error {
                AppLog.debug("[Nearby] Failed to schedule notification: \(error.localizedDescription)")
            } else {
                AppLog.debug("[Nearby] Scheduled mesh notice in \(Int(delay))s")
            }
        }
    }

    private static func runOnMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
}
#endif
