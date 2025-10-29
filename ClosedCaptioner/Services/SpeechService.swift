//
//  SpeechService.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import Speech
import AVFoundation

class SpeechService: ObservableObject {
    @Published var currentText: String = ""
    @Published var isRecording: Bool = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var inputNode: AVAudioInputNode?
    
    // Track if text is from speech recognition (for emoji logic)
    private var textIsFromSpeech: Bool = false
    
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
                    let newText = result.bestTranscription.formattedString
                    self.currentText = newText
                }
            }
            
            if let error = error {
                print("Recognition error: \(error.localizedDescription)")
            }
        }
    }
    
    private func stopRecognition() {
        print("🛑 Stopping speech recognition...")
        
        // Mark as not recording immediately
        isRecording = false
        
        recognitionTask?.finish()
        recognitionRequest?.endAudio()
        
        audioEngine.stop()
        inputNode?.removeTap(onBus: 0)
        
        // Always add emojis if text came from speech recognition
        if textIsFromSpeech && !currentText.isEmpty {
            // Add emojis to the speech-text
            addEmojisToText()
            textIsFromSpeech = false
        }
        
        recognitionRequest = nil
        recognitionTask = nil
        inputNode = nil
        
        print("✅ Speech recognition stopped")
    }
    
    private func addEmojisToText() {
        // Check if emojis are already added to current text
        if currentText.unicodeScalars.contains(where: { $0.properties.isEmoji }) {
            return
        }
        
        // Perform emoji analysis on background thread for better performance
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let emojis = EmojiService.shared.analyzeTextForEmojis(text: self.currentText)
            
            DispatchQueue.main.async {
                if !emojis.isEmpty {
                    self.currentText = self.currentText + " " + emojis
                } else {
                    // Final fallback - always add at least one emoji
                    self.currentText = self.currentText + " " + "💭"
                }
            }
        }
    }
}

