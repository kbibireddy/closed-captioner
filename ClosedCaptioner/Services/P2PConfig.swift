//
//  P2PConfig.swift
//  ClosedCaptioner
//
//  Shared Multipeer contract with tools/p2p-radio.
//  KEEP IN SYNC with tools/p2p-radio/Sources/RadioPeer/P2PConfig.swift
//

import Foundation
import MultipeerConnectivity

/// How long radio stays on after you enable it (including in the background).
enum RadioKeepAlive: String, CaseIterable, Identifiable {
    case thirtyMinutes
    case oneHour
    case fourHours
    case eightHours
    case untilOff

    var id: String { rawValue }

    var title: String {
        switch self {
        case .thirtyMinutes: return "30 min"
        case .oneHour: return "1 hour"
        case .fourHours: return "4 hours"
        case .eightHours: return "8 hours"
        case .untilOff: return "Until off"
        }
    }

    /// `nil` means keep running until the user turns radio off or force-quits.
    var duration: TimeInterval? {
        switch self {
        case .thirtyMinutes: return 30 * 60
        case .oneHour: return 60 * 60
        case .fourHours: return 4 * 60 * 60
        case .eightHours: return 8 * 60 * 60
        case .untilOff: return nil
        }
    }

    var autoOffPhrase: String {
        switch self {
        case .thirtyMinutes: return "It turns off automatically in 30 minutes."
        case .oneHour: return "It turns off automatically in 1 hour."
        case .fourHours: return "It turns off automatically in 4 hours."
        case .eightHours: return "It turns off automatically in 8 hours."
        case .untilOff: return "It stays on until you turn Nearby off or close the app."
        }
    }
}

enum P2PConfig {
    /// Bonjour service type for MCNearbyServiceBrowser / Advertiser (1-15 chars).
    /// Info.plist must list `_cc-p2p._tcp`.
    static let serviceType = "cc-p2p"

    static let discoveryRoleKey = "role"
    static let discoveryRoleEmitter = "emit"
    static let discoveryPeerIDKey = "id"
    static let maxLogCount = 200
    static let maxDisplayNameLength = 63
    static let defaultTTL = 4
    static let maxNeighbors = 6
    static let inviteTimeoutSeconds: TimeInterval = 12
    /// iOS↔macOS Multipeer ICE often fails with `.required` and no identity.
    static let encryptionPreference: MCEncryptionPreference = .optional
    static let inviteRetryLimit = 4
    static let inviteRetryDelaySeconds: TimeInterval = 1.5
    static let maxSeenIDs = 500

    /// v1 compatible JSON. Extra fields are ignored by older decoders.
    struct Envelope: Codable, Equatable {
        var v: Int
        var text: String
        var from: String?
        var id: String?
        var hop: Int?
        var ttl: Int?

        static func make(
            _ text: String,
            from: String? = nil,
            id: String = UUID().uuidString,
            hop: Int = 0,
            ttl: Int = P2PConfig.defaultTTL
        ) -> Envelope {
            Envelope(
                v: 1,
                text: text,
                from: P2PConfig.normalizedName(from),
                id: id,
                hop: hop,
                ttl: ttl
            )
        }
    }

    static func encode(
        _ text: String,
        from: String? = nil,
        id: String = UUID().uuidString,
        hop: Int = 0,
        ttl: Int = P2PConfig.defaultTTL
    ) -> Data? {
        try? JSONEncoder().encode(Envelope.make(text, from: from, id: id, hop: hop, ttl: ttl))
    }

    static func decode(_ data: Data) -> Envelope? {
        if let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
           envelope.v == 1 {
            let trimmed = envelope.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return Envelope(
                v: 1,
                text: trimmed,
                from: normalizedName(envelope.from),
                id: envelope.id,
                hop: envelope.hop,
                ttl: envelope.ttl
            )
        }
        let raw = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let raw, !raw.isEmpty else { return nil }
        return Envelope(v: 1, text: raw, from: nil, id: nil, hop: nil, ttl: nil)
    }

    static func normalizedName(_ name: String?) -> String? {
        guard let name else { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxDisplayNameLength))
    }
}
