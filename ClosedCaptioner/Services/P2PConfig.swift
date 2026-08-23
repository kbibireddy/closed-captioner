//
//  P2PConfig.swift
//  ClosedCaptioner
//
//  Shared Multipeer contract with tools/p2p-radio.
//  KEEP IN SYNC with tools/p2p-radio/Sources/RadioPeer/P2PConfig.swift
//

import Foundation

enum P2PConfig {
    /// Bonjour service type for MCNearbyServiceBrowser / Advertiser (1–15 chars).
    /// Info.plist must list `_cc-p2p._tcp`.
    static let serviceType = "cc-p2p"

    static let discoveryRoleKey = "role"
    static let discoveryRoleEmitter = "emit"
    static let discoveryPeerIDKey = "id"
    static let maxLogCount = 200
    static let maxDisplayNameLength = 63

    struct Envelope: Codable, Equatable {
        var v: Int
        var text: String
        var from: String?

        static func make(_ text: String, from: String? = nil) -> Envelope {
            Envelope(v: 1, text: text, from: P2PConfig.normalizedName(from))
        }
    }

    static func encode(_ text: String, from: String? = nil) -> Data? {
        try? JSONEncoder().encode(Envelope.make(text, from: from))
    }

    static func decode(_ data: Data) -> Envelope? {
        if let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
           envelope.v == 1 {
            let trimmed = envelope.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return Envelope(v: 1, text: trimmed, from: normalizedName(envelope.from))
        }
        let raw = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let raw, !raw.isEmpty else { return nil }
        return Envelope(v: 1, text: raw, from: nil)
    }

    static func normalizedName(_ name: String?) -> String? {
        guard let name else { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxDisplayNameLength))
    }
}
