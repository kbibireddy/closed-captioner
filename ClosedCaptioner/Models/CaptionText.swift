//
//  CaptionText.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import Foundation

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
    
    /// Initializes a new caption text entry
    /// - Parameters:
    ///   - text: The caption text content
    ///   - timestamp: The creation timestamp (defaults to current time)
    ///   - hasEmojis: Whether the text contains emojis (defaults to false)
    init(text: String, timestamp: Date = Date(), hasEmojis: Bool = false) {
        self.id = UUID()
        self.text = text
        self.timestamp = timestamp
        self.hasEmojis = hasEmojis
    }
}

