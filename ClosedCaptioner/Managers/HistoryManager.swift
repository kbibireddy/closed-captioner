//
//  HistoryManager.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import Foundation
import Combine

class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var captions: [CaptionText] = []
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "CaptionHistory"
    
    private init() {
        loadHistory()
    }
    
    func addCaption(_ caption: CaptionText) -> Bool {
        // Guard rails: text cannot be empty and must have at least 2 words
        let trimmedText = caption.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return false }
        
        let words = trimmedText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard words.count >= 2 else { return false }
        
        captions.append(caption)
        // Sort in descending order (newest first)
        captions.sort { $0.timestamp > $1.timestamp }
        saveHistory()
        return true
    }
    
    func removeCaption(at index: Int) {
        guard index >= 0 && index < captions.count else { return }
        captions.remove(at: index)
        saveHistory()
    }
    
    func removeCaption(id: UUID) {
        captions.removeAll { $0.id == id }
        saveHistory()
    }
    
    func clearHistory() {
        captions.removeAll()
        saveHistory()
    }
    
    var sortedCaptions: [CaptionText] {
        // Return in descending order (newest first)
        captions.sorted { $0.timestamp > $1.timestamp }
    }
    
    func saveHistory() {
        if let encoded = try? JSONEncoder().encode(captions) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }
    
    private func loadHistory() {
        if let data = userDefaults.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([CaptionText].self, from: data) {
            captions = decoded
        }
    }
}

