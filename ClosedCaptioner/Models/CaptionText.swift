//
//  CaptionText.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import Foundation

struct CaptionText: Identifiable, Codable {
    let id: UUID
    var text: String
    let timestamp: Date
    var hasEmojis: Bool
    
    init(text: String, timestamp: Date = Date(), hasEmojis: Bool = false) {
        self.id = UUID()
        self.text = text
        self.timestamp = timestamp
        self.hasEmojis = hasEmojis
    }
}

