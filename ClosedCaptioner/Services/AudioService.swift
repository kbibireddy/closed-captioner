//
//  AudioService.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import AVFoundation

/// Service that manages audio session configuration and microphone permissions
class AudioService {
    /// Shared singleton instance
    static let shared = AudioService()
    
    private init() {}
    
    /// Configures the audio session for recording and playback
    /// - Throws: An error if the audio session cannot be configured
    func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    /// Requests microphone permission from the user
    /// - Parameter completion: Callback with true if permission granted, false otherwise
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { allowed in
            DispatchQueue.main.async {
                completion(allowed)
            }
        }
    }
}

