//
//  GossipUsername.swift
//  ClosedCaptioner
//
//  Offline Reddit-style handles (adjective + noun) and @display formatting.
//

import Foundation

/// How Gossip authors appear in the live strip and Activity log.
enum GossipHandle {
    /// Local rows show as `you` (no @). Everyone else is `@slug`.
    static func authorLabel(senderName: String, isLocal: Bool) -> String {
        if isLocal { return "you" }
        return "@\(slug(senderName))"
    }

    /// Lowercase, trim ends, collapse whitespace runs to `_`.
    static func slug(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "unknown" }
        let lower = trimmed.lowercased()
        let parts = lower.split(whereSeparator: { $0.isWhitespace })
        return parts.joined(separator: "_")
    }
}

/// Offline adjective×noun usernames. Timestamp seed; no server.
enum GossipUsername {
    /// ~25 × ~25 ≈ 625 combos — enough headroom past 200 unique users.
    private static let adjectives: [String] = [
        // Raves / nightlife
        "neon", "bass", "glow", "pulse", "laser", "rave", "disco", "strobe",
        "thump", "synth", "after", "midnight",
        // Nature
        "mossy", "leafy", "misty", "sunny", "stormy", "rocky", "wild", "tidal",
        "piney", "coral", "frosty", "blooming",
        // Cute
        "cozy", "fluffy", "tiny", "bubbly", "soft", "sparkly", "peachy", "snuggly",
        // Funny
        "goofy", "wobbly", "sneaky", "zippy", "bouncy", "quirky", "dizzy", "cheeky"
    ]

    private static let nouns: [String] = [
        // Raves / nightlife
        "beat", "drop", "deck", "crowd", "booth", "laser", "glowstick", "speaker",
        "bassline", "set", "floor", "haze",
        // Nature
        "fern", "owl", "fox", "moss", "river", "pebble", "cedar", "meadow",
        "comet", "spore", "willow", "finch",
        // Cute
        "kitten", "panda", "bean", "muffin", "cloud", "peach", "bunny", "dumpling",
        // Funny
        "pickle", "noodle", "waffle", "goblin", "potato", "sock", "banana", "raccoon"
    ]

    static var combinationCount: Int { adjectives.count * nouns.count }

    /// Picks one adjective and one noun from separate bags using `seed`.
    static func generate(seed: UInt64 = UInt64(Date().timeIntervalSince1970 * 1000)) -> String {
        var state = seed == 0 ? 1 : seed
        func next() -> UInt64 {
            // SplitMix64-ish step for decent mixing without Foundation RNG.
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
        let adj = adjectives[Int(next() % UInt64(adjectives.count))]
        let noun = nouns[Int(next() % UInt64(nouns.count))]
        return "\(adj)_\(noun)"
    }
}
