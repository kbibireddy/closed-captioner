//
//  EmojiService.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import NaturalLanguage

class EmojiService {
    static let shared = EmojiService()
    
    private init() {}
    
    func analyzeTextForEmojis(text: String) -> String {
        let emojis = getEmojisForText(text)
        return emojis
    }
    
    private func getEmojisForText(_ text: String) -> String {
        // Use Natural Language framework for sentiment analysis
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        // Get sentiment scores
        var sentiment: String = ""
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .paragraph, scheme: .sentimentScore) { tag, _ in
            if let tag = tag {
                sentiment = tag.rawValue
            }
            return true
        }
        
        let bestEmojis = selectEmojisBasedOnContent(text: text, sentiment: sentiment)
        
        return bestEmojis
    }
    
    private func selectEmojisBasedOnContent(text: String, sentiment: String) -> String {
        var emojis: Set<String> = []
        
        // Comprehensive emoji mapping based on semantic meaning
        let emojiMap: [String: Set<String>] = [
            // Greetings & Social
            "hello": ["👋", "🙋"],
            "hi": ["👋", "🙋"],
            "thanks": ["🙏", "😊"],
            "thank": ["🙏", "😊"],
            "bye": ["👋", "👋🏻"],
            "goodbye": ["👋", "👋🏻"],
            
            // Emotions - Positive
            "happy": ["😊", "😄", "😃"],
            "great": ["👍", "😊"],
            "good": ["👍", "✅"],
            "excellent": ["⭐️", "🌟"],
            "wonderful": ["✨", "😊"],
            "amazing": ["🤩", "😍"],
            "love": ["❤️", "🥰"],
            "beautiful": ["💐", "🌟"],
            "nice": ["😊", "👍"],
            "yes": ["✅", "👍"],
            
            // Emotions - Negative
            "sad": ["😢", "😔"],
            "bad": ["😞", "😟"],
            "terrible": ["😨", "😰"],
            "awful": ["😞", "😕"],
            "hate": ["😠", "🤬"],
            "no": ["❌", "😐"],
            
            // Emotions - Complex
            "excited": ["🤩", "🥳"],
            "surprised": ["😲", "😮"],
            "worried": ["😟", "😰"],
            "angry": ["😠", "🤬"],
            
            // Activities
            "work": ["💼", "⌚️"],
            "study": ["📚", "📖"],
            "play": ["🎮", "🎯"],
            "exercise": ["🏋️", "🏃"],
            "run": ["🏃", "🏃‍♀️"],
            "walk": ["🚶", "🚶‍♀️"],
            
            // Food & Drink
            "eat": ["🍽️", "🍴"],
            "food": ["🍔", "🍕"],
            "breakfast": ["🍳", "🥞"],
            "lunch": ["🥙", "🍲"],
            "dinner": ["🍽️", "🍖"],
            "coffee": ["☕️", "☕"],
            "drink": ["🥤", "🍹"],
            
            // Weather
            "sunny": ["☀️", "🌞"],
            "rain": ["🌧️", "☔️"],
            "snow": ["❄️", "⛄️"],
            "cloud": ["☁️", "🌥️"],
            "hot": ["🔥", "🌡️"],
            "cold": ["🥶", "❄️"],
            
            // Technology
            "phone": ["📱", "📲"],
            "computer": ["💻", "🖥️"],
            "app": ["📱", "⚙️"],
            "internet": ["🌐", "📡"],
            "wifi": ["📶", "📡"],
            
            // Time
            "morning": ["🌅", "🌄"],
            "afternoon": ["🌆", "🏙️"],
            "evening": ["🌆", "🌃"],
            "night": ["🌙", "🌃"],
            
            // Questions
            "how": ["❓", "🤔"],
            "what": ["❓", "🤔"],
            "where": ["❓", "🗺️"],
            "why": ["❓", "🤔"],
            
            // People & Relationships
            "friend": ["👫", "🤝"],
            "family": ["👨‍👩‍👧‍👦", "👪"],
            "home": ["🏠", "🏡"],
            "help": ["🆘", "🙋‍♂️"]
        ]
        
        let lowercased = text.lowercased()
        
        // Find matching emojis based on content
        for (keyword, emojiSet) in emojiMap {
            if lowercased.contains(keyword) {
                emojis.formUnion(emojiSet)
            }
        }
        
        // Sentiment-based fallback if no matches found
        if emojis.isEmpty {
            let sentimentScore = Double(sentiment) ?? 0.0
            if sentimentScore > 0.3 {
                emojis.insert("😊")
            } else if sentimentScore < -0.3 {
                emojis.insert("😔")
            } else {
                // Random neutral emoji fallback
                let neutralEmojis = ["💬", "💭", "✨", "🌟", "⭐", "📝", "🔤", "💡", "📋", "🎯"]
                if let randomEmoji = neutralEmojis.randomElement() {
                    emojis.insert(randomEmoji)
                } else {
                    emojis.insert("💭") // Final fallback
                }
            }
        }
        
        // Always return at least 1 emoji, up to 3 emojis (limit to best matches)
        let emojiArray = Array(emojis.prefix(3))
        return emojiArray.joined(separator: " ")
    }
}

