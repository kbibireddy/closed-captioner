//
//  HistoryManager.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import Foundation

class HistoryManager {
    static let shared = HistoryManager()
    
    @Published var captions: [CaptionText] = []
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "CaptionHistory"
    
    private init() {
        loadHistory()
    }
    
    func addCaption(_ caption: CaptionText) {
        captions.append(caption)
        saveHistory()
    }
    
    func clearHistory() {
        captions.removeAll()
        saveHistory()
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

