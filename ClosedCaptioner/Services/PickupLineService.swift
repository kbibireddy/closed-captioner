//
//  PickupLineService.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import Foundation

class PickupLineService {
    static let shared = PickupLineService()
    
    private var pickupLines: [String] = []
    private var lastSelectedIndex: Int? = nil
    private let MAX_SHAKE_STRENGTH: Double = 10.0 // Maximum expected shake strength
    
    private init() {
        loadPickupLines()
    }
    
    private func loadPickupLines() {
        guard let path = Bundle.main.path(forResource: "pickupCatalog", ofType: "txt"),
              let content = try? String(contentsOfFile: path) else {
            print("⚠️ PickupCatalog.txt not found, using fallback")
            pickupLines = [
                "Are you a magician? Because whenever I look at you, everyone else disappears.",
                "You must be a camera because every time I look at you, I smile.",
                "Do you have a map? I keep getting lost in your eyes."
            ]
            return
        }
        
        // Split by lines and filter out empty lines
        pickupLines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        print("✅ Loaded \(pickupLines.count) pickup lines")
    }
    
    func getPickupLine(shakeStrength: Double) -> String? {
        guard !pickupLines.isEmpty else {
            return nil
        }
        
        let totalLines = pickupLines.count
        
        // Normalize shake strength to 0.0 - 1.0 range (clamp to max)
        let normalizedStrength = min(shakeStrength / MAX_SHAKE_STRENGTH, 1.0)
        
        // Calculate target index based on shake strength
        // Higher shake = further toward end of file (more bold/vulgar lines)
        // Formula: targetIndex = normalizedStrength * (totalLines - 1)
        let targetIndex = Int(normalizedStrength * Double(totalLines - 1))
        
        // Create a selection window around the target index for randomness
        // Window size scales with shake strength (stronger shake = narrower window near end)
        let windowSize = max(5, Int(Double(totalLines) * (1.0 - normalizedStrength * 0.7)))
        
        // Calculate window bounds
        let startIndex = max(0, targetIndex - windowSize / 2)
        let endIndex = min(totalLines - 1, targetIndex + windowSize / 2)
        
        // If we picked the same line recently, adjust selection
        var selectedIndex: Int
        var attempts = 0
        repeat {
            // Random selection within the window
            if endIndex > startIndex {
                selectedIndex = Int.random(in: startIndex...endIndex)
            } else {
                selectedIndex = startIndex
            }
            attempts += 1
        } while selectedIndex == lastSelectedIndex && attempts < 10 && totalLines > 1
        
        // Add additional randomness: sometimes pick slightly different index
        // This ensures we don't always get the exact same line for similar shake strengths
        if attempts < 10 {
            // 30% chance to randomly adjust index slightly for more variety
            if Double.random(in: 0...1) < 0.3 {
                let randomOffset = Int.random(in: -3...3)
                selectedIndex = max(0, min(totalLines - 1, selectedIndex + randomOffset))
            }
        }
        
        lastSelectedIndex = selectedIndex
        print("🎯 Shake strength: \(String(format: "%.2f", shakeStrength)), Selected index: \(selectedIndex)/\(totalLines-1) (target: \(targetIndex))")
        
        return pickupLines[selectedIndex]
    }
    
    // Legacy method for backwards compatibility
    func getRandomPickupLine() -> String? {
        // Use minimal shake strength (picks from beginning of file)
        return getPickupLine(shakeStrength: 0.5)
    }
}

