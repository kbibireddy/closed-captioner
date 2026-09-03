//
//  CaptionText.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import Foundation

/// How a caption reached the canvas.
enum CaptionSource: String, Codable, CaseIterable {
    case text
    case speech
    case shake

    /// Short chip label in Activity → Text.
    var chipTitle: String {
        switch self {
        case .text: return "Text"
        case .speech: return "Speech"
        case .shake: return "Shake"
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .text: return "Text"
        case .speech: return "Speech to text"
        case .shake: return "Shake to text"
        }
    }
}

/// Model representing a caption text entry with timestamp and metadata
struct CaptionText: Identifiable, Codable {
    /// Unique identifier for the caption
    let id: UUID
    /// The caption text content
    var text: String
    /// Timestamp when the caption was created
    let timestamp: Date
    /// Whether the text contains emojis
    var hasEmojis: Bool
    /// How the caption was entered. Defaults to text for older history rows.
    var source: CaptionSource

    /// Initializes a new caption text entry
    /// - Parameters:
    ///   - text: The caption text content
    ///   - timestamp: The creation timestamp (defaults to current time)
    ///   - hasEmojis: Whether the text contains emojis (defaults to false)
    ///   - source: How the caption was entered (defaults to typed text)
    init(
        text: String,
        timestamp: Date = Date(),
        hasEmojis: Bool = false,
        source: CaptionSource = .text
    ) {
        self.id = UUID()
        self.text = text
        self.timestamp = timestamp
        self.hasEmojis = hasEmojis
        self.source = source
    }

    enum CodingKeys: String, CodingKey {
        case id, text, timestamp, hasEmojis, source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        hasEmojis = try container.decodeIfPresent(Bool.self, forKey: .hasEmojis) ?? false
        source = try container.decodeIfPresent(CaptionSource.self, forKey: .source) ?? .text
    }
}
