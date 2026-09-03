//
//  P2PConfig.swift
//  KEEP IN SYNC with ClosedCaptioner/Services/P2PConfig.swift
//

import Foundation
import MultipeerConnectivity

enum P2PConfig {
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

    struct Envelope: Codable, Equatable {
        var v: Int
        var text: String
        var from: String?
        var id: String?
        var hop: Int?
        var ttl: Int?
        var channel: String?

        static func make(
            _ text: String,
            from: String? = nil,
            id: String = UUID().uuidString,
            hop: Int = 0,
            ttl: Int = P2PConfig.defaultTTL,
            channel: String? = "room"
        ) -> Envelope {
            Envelope(
                v: 1,
                text: text,
                from: P2PConfig.normalizedName(from),
                id: id,
                hop: hop,
                ttl: ttl,
                channel: channel ?? "room"
            )
        }
    }

    static func encode(
        _ text: String,
        from: String? = nil,
        id: String = UUID().uuidString,
        hop: Int = 0,
        ttl: Int = P2PConfig.defaultTTL,
        channel: String? = "room"
    ) -> Data? {
        try? JSONEncoder().encode(Envelope.make(text, from: from, id: id, hop: hop, ttl: ttl, channel: channel))
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
                ttl: envelope.ttl,
                channel: envelope.channel ?? "room"
            )
        }
        let raw = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let raw, !raw.isEmpty else { return nil }
        return Envelope(v: 1, text: raw, from: nil, id: nil, hop: nil, ttl: nil, channel: "room")
    }

    static func normalizedName(_ name: String?) -> String? {
        guard let name else { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxDisplayNameLength))
    }
}
