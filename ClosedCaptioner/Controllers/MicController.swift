//
//  MicController.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import Foundation

class MicController: ObservableObject, MicControlProtocol {
    @Published var isRecording: Bool = false
    
    private let speechService: SpeechService
    
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
    }
    
    func stopRecording() {
        guard isRecording else { return }
        print("🎤 MicController: Stopping recording")
        speechService.stopRecording()
        // State will be updated via binding
    }
}

