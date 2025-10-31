//
//  MicController.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import Foundation
import Combine

class MicController: ObservableObject, MicControlProtocol {
    @Published var isRecording: Bool = false
    
    private let speechService: SpeechService
    private var recordingTimer: Timer?
    
    // Maximum recording time in seconds
    static let MAX_RECORDING_TIME_IN_SEC: TimeInterval = 15.0
    
    init(speechService: SpeechService) {
        self.speechService = speechService
        
        // Observe speech service recording state
        speechService.$isRecording
            .assign(to: &$isRecording)
    }
    
    func startRecording() {
        guard !isRecording else { return }
        print("🎤 MicController: Starting recording")
        speechService.startRecording()
        isRecording = true
        
        // Start timer for auto-stop after MAX_RECORDING_TIME_IN_SEC
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: Self.MAX_RECORDING_TIME_IN_SEC, repeats: false) { [weak self] _ in
            self?.stopRecording()
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        print("🎤 MicController: Stopping recording")
        
        // Invalidate timer
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        speechService.stopRecording()
        // State will be updated via binding
    }
    
    deinit {
        recordingTimer?.invalidate()
    }
}

