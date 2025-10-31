//
//  HistoryManager.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import Foundation
import Combine

/// Manages the history of caption texts, including persistence to UserDefaults
class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    /// Published array of captions, maintained in descending order (newest first)
    @Published var captions: [CaptionText] = []
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "CaptionHistory"
    
    private init() {
        loadHistory()
    }
    
    /// Adds a caption to the history with validation
    /// - Parameter caption: The caption to add
    /// - Returns: True if the caption was successfully added, false otherwise
    /// - Note: Captions must have at least 2 words to be added
    func addCaption(_ caption: CaptionText) -> Bool {
        // Guard rails: text cannot be empty and must have at least 2 words
        let trimmedText = caption.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return false }
        
        let words = trimmedText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard words.count >= 2 else { return false }
        
        captions.insert(caption, at: 0) // Insert at beginning for O(1) operation
        saveHistory()
        return true
    }
    
    /// Removes a caption at the specified index
    /// - Parameter index: The index of the caption to remove
    func removeCaption(at index: Int) {
        guard index >= 0 && index < captions.count else { return }
        captions.remove(at: index)
        saveHistory()
    }
    
    /// Removes a caption by its unique identifier
    /// - Parameter id: The UUID of the caption to remove
    func removeCaption(id: UUID) {
        captions.removeAll { $0.id == id }
        saveHistory()
    }
    
    /// Clears all caption history
    func clearHistory() {
        captions.removeAll()
        saveHistory()
    }
    
    /// Returns captions in descending order (newest first)
    /// - Note: This is a computed property that returns a sorted copy.
    ///   The internal array is already maintained in sorted order for performance.
    var sortedCaptions: [CaptionText] {
        // Since we insert at index 0, captions are already in descending order
        return captions
    }
    
    /// Saves the current history to UserDefaults
    private func saveHistory() {
        do {
            let encoded = try JSONEncoder().encode(captions)
            userDefaults.set(encoded, forKey: historyKey)
        } catch {
            print("[HistoryManager] ERROR: Failed to save history: \(error)")
        }
    }
    
    /// Loads history from UserDefaults
    private func loadHistory() {
        guard let data = userDefaults.data(forKey: historyKey) else { return }
        
        do {
            captions = try JSONDecoder().decode([CaptionText].self, from: data)
        } catch {
            print("[HistoryManager] ERROR: Failed to load history: \(error)")
            captions = []
        }
    }
}

