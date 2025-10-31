//
//  SpeechService.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import Speech
import AVFoundation

class SpeechService: ObservableObject {
    @Published var currentText: String = "" {
        didSet {
            // Track text changes for emoji service
            handleTextChange()
        }
    }
    @Published var isRecording: Bool = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var inputNode: AVAudioInputNode?
    
    // Track if text is from speech recognition (for emoji logic)
    private var textIsFromSpeech: Bool = false
    
    // Track text stability for emoji service
    private var textStabilityTimer: Timer?
    private var lastTextChangeTime: Date = Date()
    private let TEXT_STABILITY_INTERVAL: TimeInterval = 2.5 // 2-3 seconds
    private var emojisAddedForCurrentText: Bool = false
    
    // Helper to extract base text without emojis
    private func extractBaseText(from text: String) -> String {
        return text.unicodeScalars.filter { !$0.properties.isEmoji }.reduce("") { $0 + String($1) }.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                completion(authStatus == .authorized)
            }
        }
    }
    
    func startRecording() {
        startRecognition()
    }
    
    func stopRecording() {
        stopRecognition()
    }
    
    private func startRecognition() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognizer not available")
            return
        }
        
        // Ensure we're not already recording
        if isRecording {
            print("⚠️ Already recording, stopping first")
            stopRecognition()
        }
        
        // Mark as recording immediately
        isRecording = true
        
        // Create new recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Setup audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
            inputNode?.removeTap(onBus: 0)
        }
        
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else { return }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine could not start: \(error)")
            return
        }
        
        // Mark that upcoming text is from speech
        textIsFromSpeech = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    let newRawText = result.bestTranscription.formattedString
                    
                    // Extract base text (without emojis) from both texts for comparison
                    let currentBaseText = self.extractBaseText(from: self.currentText)
                    let newBaseText = self.extractBaseText(from: newRawText)
                    
                    // Only update if base text actually changed
                    if newBaseText != currentBaseText && !newBaseText.isEmpty {
                        // Remove emojis from previous text if base text changed
                        // This allows new emojis to be generated for the new text
                        self.currentText = newRawText
                        self.emojisAddedForCurrentText = false
                        print("📝 Text changed: '\(currentBaseText)' -> '\(newBaseText)'")
                    } else if newBaseText == currentBaseText {
                        // Base text didn't change, keep the current text with emojis (don't overwrite)
                        print("📝 Text unchanged, keeping existing text with emojis")
                    }
                    // If newBaseText is empty, ignore this update
                }
            }
            
            if let error = error {
                print("Recognition error: \(error.localizedDescription)")
            }
        }
    }
    
    private func stopRecognition() {
        print("🛑 Stopping speech recognition...")
        
        // Cancel text stability timer
        textStabilityTimer?.invalidate()
        textStabilityTimer = nil
        
        // Mark as not recording immediately
        isRecording = false
        
        recognitionTask?.finish()
        recognitionRequest?.endAudio()
        
        audioEngine.stop()
        inputNode?.removeTap(onBus: 0)
        
        // Always add emojis if text came from speech recognition (final call)
        // But only if emojis aren't already present
        if textIsFromSpeech && !currentText.isEmpty {
            // Cancel any pending stability timer since we're stopping
            textStabilityTimer?.invalidate()
            textStabilityTimer = nil
            
            // Only add emojis if they're not already there (to avoid overwriting existing emojis)
            if !emojisAddedForCurrentText && !currentText.unicodeScalars.contains(where: { $0.properties.isEmoji }) {
                addEmojisToText()
            }
            textIsFromSpeech = false
        }
        
        recognitionRequest = nil
        recognitionTask = nil
        inputNode = nil
        
        print("✅ Speech recognition stopped")
    }
    
    private func handleTextChange() {
        // Reset stability timer when text changes
        textStabilityTimer?.invalidate()
        lastTextChangeTime = Date()
        
        // Don't reset emojisAddedForCurrentText here - let it be checked in addEmojisToText
        
        // Only check stability if we're recording and text is from speech
        guard isRecording && textIsFromSpeech && !currentText.isEmpty else {
            return
        }
        
        // Schedule emoji check after stability interval on main thread
        // Use RunLoop.main.add to ensure it runs even when view is scrolling
        let timer = Timer(timeInterval: TEXT_STABILITY_INTERVAL, repeats: false) { [weak self] timer in
            guard let self = self else { return }
            
            // Check if text hasn't changed during the interval
            let timeSinceLastChange = Date().timeIntervalSince(self.lastTextChangeTime)
            if timeSinceLastChange >= self.TEXT_STABILITY_INTERVAL - 0.1 {
                // Text is stable, add emojis if not already added
                if !self.emojisAddedForCurrentText {
                    self.addEmojisToText()
                }
            }
        }
        textStabilityTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
    
    private func addEmojisToText() {
        // Don't add emojis if they're already present and we've already added them
        if emojisAddedForCurrentText {
            print("🎯 EmojiService: Already added emojis, skipping")
            return
        }
        
        // Check if emojis are already added to current text (avoid duplicates)
        if currentText.unicodeScalars.contains(where: { $0.properties.isEmoji }) {
            print("🎯 EmojiService: Emojis already in text, marking as added")
            emojisAddedForCurrentText = true
            return
        }
        
        guard !currentText.isEmpty else {
            print("🎯 EmojiService: Text is empty, skipping")
            return
        }
        
        print("🎯 EmojiService: Analyzing text: '\(currentText)'")
        
        // Perform emoji analysis on background thread for better performance
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let emojis = EmojiService.shared.analyzeTextForEmojis(text: self.currentText)
            print("🎯 EmojiService: Got emojis: '\(emojis)'")
            
            DispatchQueue.main.async {
                // Double-check text hasn't changed and emojis not already added
                if !self.emojisAddedForCurrentText && !self.currentText.isEmpty {
                    // Check again if emojis were added while processing
                    if !self.currentText.unicodeScalars.contains(where: { $0.properties.isEmoji }) {
                        if !emojis.isEmpty {
                            self.currentText = self.currentText + " " + emojis
                            print("🎯 EmojiService: Added emojis to text")
                        } else {
                            // Final fallback - always add at least one emoji
                            self.currentText = self.currentText + " " + "💭"
                            print("🎯 EmojiService: Added fallback emoji")
                        }
                    }
                    self.emojisAddedForCurrentText = true
                }
            }
        }
    }
}

