//
//  SpeechService.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import Speech
import AVFoundation

/// Service that handles speech recognition and converts audio to text
/// Manages recording state, text updates, and automatic emoji insertion
class SpeechService: ObservableObject {
    /// Published property containing the current transcribed text with emojis
    @Published var currentText: String = "" {
        didSet {
            // Track text changes for emoji service
            handleTextChange()
        }
    }
    /// Published property indicating whether speech recognition is currently active
    @Published var isRecording: Bool = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var inputNode: AVAudioInputNode?
    private var hasInputTap = false
    private var isStopping = false
    
    /// Tracks if current text is from speech recognition (affects emoji insertion logic)
    private var textIsFromSpeech: Bool = false
    
    /// Timer for tracking text stability before adding emojis
    private var textStabilityTimer: Timer?
    /// Timestamp of the last text change
    private var lastTextChangeTime: Date = Date()
    /// Interval to wait for text stability before adding emojis (2.5 seconds)
    private let TEXT_STABILITY_INTERVAL: TimeInterval = 2.5
    /// Flag to prevent duplicate emoji insertion
    private var emojisAddedForCurrentText: Bool = false
    
    /// Cleans up all resources on deallocation
    deinit {
        textStabilityTimer?.invalidate()
        textStabilityTimer = nil
        teardownEngine()
    }
    
    /// Extracts base text without emojis for comparison purposes
    /// - Parameter text: The text to process
    /// - Returns: The text with all emoji characters removed
    private func extractBaseText(from text: String) -> String {
        return text.unicodeScalars.filter { !$0.properties.isEmoji }.reduce("") { $0 + String($1) }.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Requests speech recognition authorization from the user
    /// - Parameter completion: Callback with true if authorized, false otherwise
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                completion(authStatus == .authorized)
            }
        }
    }
    
    /// Starts speech recognition recording. `isRecording` is true only after setup succeeds.
    func startRecording() {
        startRecognition()
    }
    
    /// Stops speech recognition recording and adds emojis if needed
    func stopRecording() {
        stopRecognition()
    }
    
    /// Starts speech recognition by setting up the audio engine and recognition task.
    /// Rolls back the tap, engine, and request if any step fails so the UI never
    /// shows Listening with a dead session.
    @discardableResult
    private func startRecognition() -> Bool {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("[SpeechService] ERROR: Speech recognizer not available")
            return false
        }
        
        if isRecording {
            print("[SpeechService] WARNING: Already recording, stopping first")
            stopRecognition()
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request
        
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if hasInputTap {
            inputNode?.removeTap(onBus: 0)
            hasInputTap = false
        }
        
        let input = audioEngine.inputNode
        inputNode = input
        let recordingFormat = input.outputFormat(forBus: 0)
        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            print("[SpeechService] ERROR: Invalid input format")
            abortFailedStart()
            return false
        }
        
        input.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        hasInputTap = true
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("[SpeechService] ERROR: Audio engine could not start: \(error)")
            abortFailedStart()
            return false
        }
        
        textIsFromSpeech = true
        isRecording = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            self?.handleRecognitionUpdate(result: result, error: error)
        }
        return true
    }
    
    private func handleRecognitionUpdate(result: SFSpeechRecognitionResult?, error: Error?) {
        if let error {
            print("[SpeechService] ERROR: Recognition error: \(error.localizedDescription)")
        }
        let shouldStop = result?.isFinal == true || error != nil
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let result {
                self.applyTranscription(result.bestTranscription.formattedString)
            }
            if shouldStop, self.isRecording {
                self.stopRecognition()
            }
        }
    }
    
    private func applyTranscription(_ newRawText: String) {
        let currentBaseText = extractBaseText(from: currentText)
        let newBaseText = extractBaseText(from: newRawText)
        
        if newBaseText != currentBaseText && !newBaseText.isEmpty {
            currentText = newRawText
            emojisAddedForCurrentText = false
            print("[SpeechService] Text changed: '\(currentBaseText)' -> '\(newBaseText)'")
        } else if newBaseText == currentBaseText {
            print("[SpeechService] Text unchanged, keeping existing text with emojis")
        }
    }
    
    /// Drops a half-started session without emoji side effects.
    private func abortFailedStart() {
        teardownEngine()
        isRecording = false
        textIsFromSpeech = false
    }
    
    private func teardownEngine() {
        recognitionRequest?.endAudio()
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if hasInputTap {
            inputNode?.removeTap(onBus: 0)
            hasInputTap = false
        }
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        inputNode = nil
    }
    
    /// Stops speech recognition and cleans up resources
    private func stopRecognition() {
        guard !isStopping else { return }
        isStopping = true
        defer { isStopping = false }
        
        print("[SpeechService] Stopping speech recognition...")
        
        textStabilityTimer?.invalidate()
        textStabilityTimer = nil
        
        isRecording = false
        teardownEngine()
        
        if textIsFromSpeech && !currentText.isEmpty {
            if !emojisAddedForCurrentText && !currentText.unicodeScalars.contains(where: { $0.properties.isEmoji }) {
                addEmojisToText()
            }
            textIsFromSpeech = false
        }
        
        print("[SpeechService] Speech recognition stopped")
    }
    
    /// Handles text changes and schedules emoji insertion after text stabilizes
    /// Waits for TEXT_STABILITY_INTERVAL before adding emojis to avoid rapid updates
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
    
    /// Adds emojis to the current text based on sentiment and content analysis
    /// This method runs emoji analysis on a background thread to avoid blocking the UI
    private func addEmojisToText() {
        // Don't add emojis if they're already present and we've already added them
        if emojisAddedForCurrentText {
            print("[SpeechService] EmojiService: Already added emojis, skipping")
            return
        }
        
        // Check if emojis are already added to current text (avoid duplicates)
        if currentText.unicodeScalars.contains(where: { $0.properties.isEmoji }) {
            print("[SpeechService] EmojiService: Emojis already in text, marking as added")
            emojisAddedForCurrentText = true
            return
        }
        
        guard !currentText.isEmpty else {
            print("[SpeechService] EmojiService: Text is empty, skipping")
            return
        }
        
        print("[SpeechService] EmojiService: Analyzing text: '\(currentText)'")
        
        // Perform emoji analysis on background thread for better performance
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let emojis = EmojiService.shared.analyzeTextForEmojis(text: self.currentText)
            print("[SpeechService] EmojiService: Got emojis: '\(emojis)'")
            
            DispatchQueue.main.async {
                // Double-check text hasn't changed and emojis not already added
                if !self.emojisAddedForCurrentText && !self.currentText.isEmpty {
                    // Check again if emojis were added while processing
                    if !self.currentText.unicodeScalars.contains(where: { $0.properties.isEmoji }) {
                        if !emojis.isEmpty {
                            self.currentText = self.currentText + " " + emojis
                            print("[SpeechService] EmojiService: Added emojis to text")
                        } else {
                            // Final fallback - always add at least one emoji
                            self.currentText = self.currentText + " " + "💭"
                            print("[SpeechService] EmojiService: Added fallback emoji")
                        }
                    }
                    self.emojisAddedForCurrentText = true
                }
            }
        }
    }
}
