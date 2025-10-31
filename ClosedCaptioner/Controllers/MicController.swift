//
//  MicController.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import Foundation
import Combine

/// Controller that manages microphone recording state and auto-stop timer
/// Implements MicControlProtocol for clean separation of concerns
class MicController: ObservableObject, MicControlProtocol {
    /// Published property indicating whether recording is currently active
    @Published var isRecording: Bool = false
    
    private let speechService: SpeechService
    private var recordingTimer: Timer?
    
    /// Maximum recording time in seconds before auto-stop
    static let MAX_RECORDING_TIME_IN_SEC: TimeInterval = 15.0
    
    /// Initializes the mic controller with a speech service
    /// - Parameter speechService: The speech recognition service to use
    init(speechService: SpeechService) {
        self.speechService = speechService
        
        // Observe speech service recording state
        speechService.$isRecording
            .assign(to: &$isRecording)
    }
    
    /// Starts recording audio and sets up an auto-stop timer
    func startRecording() {
        guard !isRecording else { return }
        print("[MicController] Starting recording")
        speechService.startRecording()
        isRecording = true
        
        // Start timer for auto-stop after MAX_RECORDING_TIME_IN_SEC
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: Self.MAX_RECORDING_TIME_IN_SEC, repeats: false) { [weak self] _ in
            self?.stopRecording()
        }
    }
    
    /// Stops recording audio and cleans up the timer
    func stopRecording() {
        guard isRecording else { return }
        print("[MicController] Stopping recording")
        
        // Invalidate timer
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        speechService.stopRecording()
        // State will be updated via binding
    }
    
    /// Cleans up timer resources on deallocation
    deinit {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
}

