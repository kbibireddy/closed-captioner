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
    private var cancellables = Set<AnyCancellable>()
    
    /// Maximum recording time in seconds before auto-stop
    static let MAX_RECORDING_TIME_IN_SEC: TimeInterval = 15.0
    
    /// Initializes the mic controller with a speech service
    /// - Parameter speechService: The speech recognition service to use
    init(speechService: SpeechService) {
        self.speechService = speechService
        
        speechService.$isRecording
            .assign(to: &$isRecording)

        speechService.$isRecording
            .filter { !$0 }
            .sink { [weak self] _ in
                self?.recordingTimer?.invalidate()
                self?.recordingTimer = nil
            }
            .store(in: &cancellables)
    }
    
    /// Starts recording audio and sets up an auto-stop timer.
    /// The timer is armed only when speech recognition actually started.
    func startRecording() {
        guard !isRecording else { return }
        print("[MicController] Starting recording")
        speechService.startRecording()
        guard speechService.isRecording else { return }
        
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: Self.MAX_RECORDING_TIME_IN_SEC, repeats: false) { [weak self] _ in
            self?.stopRecording()
        }
    }
    
    /// Stops recording audio and cleans up the timer
    func stopRecording() {
        guard isRecording else { return }
        print("[MicController] Stopping recording")
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        speechService.stopRecording()
    }
    
    /// Cleans up timer resources on deallocation
    deinit {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
}
